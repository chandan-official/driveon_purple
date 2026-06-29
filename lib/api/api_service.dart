import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService({this.token});

  String? token;

  static const String _kTokenKey = 'token';
  static const Duration _kRequestTimeout = Duration(seconds: 10);

  static String? _workingBaseUrl;

  void _debugLog(String msg) {
    if (kDebugMode) {
      print('[API DEBUG] ${DateTime.now().toIso8601String().split('T').last} $msg');
    }
  }

  static String _normalizeBase(String value) =>
      value.trim().replaceAll(RegExp(r'/+$'), '');

  String get baseUrl {
    final envBase = (dotenv.env['BASE_URL'] ?? '').trim();
    if (envBase.isNotEmpty) {
      return _normalizeBase(envBase);
    }

    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  List<String> get _candidateBaseUrls {
    final bases = <String>[];

    final envPrimary = (dotenv.env['BASE_URL'] ?? '').trim();
    final envFallback = (dotenv.env['BASE_URL_FALLBACK'] ?? '').trim();

    if (envPrimary.isNotEmpty) bases.add(_normalizeBase(envPrimary));
    if (envFallback.isNotEmpty) bases.add(_normalizeBase(envFallback));

    if (kIsWeb) {
      bases.add('http://localhost:3000/api');
    } else {
      if (defaultTargetPlatform == TargetPlatform.android) {
        bases.add('http://10.0.2.2:3000/api');
      }
      bases.add('http://localhost:3000/api');
    }

    final seen = <String>{};
    return bases.where((b) => seen.add(b)).toList(growable: false);
  }

  Future<void> saveToken(String t) async {
    token = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, t);
  }

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_kTokenKey);
    return token;
  }

  Future<void> logout() async {
    try {
      await _get('/auth/logout');
    } catch (_) {
      // Ignore logout API failures and still clear local session.
    }

    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }

  Map<String, String> _headers({bool jsonBody = true}) {
    final headers = <String, String>{};
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    final t = token;
    if (t != null && t.isNotEmpty) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query, String? baseOverride]) {
    final cleanBase = baseOverride ?? baseUrl;
    final full = path.startsWith('http://') || path.startsWith('https://')
      ? path
      : '$cleanBase${path.startsWith('/') ? '' : '/'}$path';

    final parsed = Uri.parse(full);
    if (query == null || query.isEmpty) return parsed;

    return parsed.replace(
      queryParameters: {
        ...parsed.queryParameters,
        ...query.map((k, v) => MapEntry(k, v.toString())),
      },
    );
  }

  dynamic _tryDecodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  dynamic _handle(http.Response res) {
    final body = res.body.trim();
    final url = res.request?.url.toString();
    _debugLog('RESPONSE | URL: $url | STATUS: ${res.statusCode} | BODY: $body');

    final isHtml = body.startsWith('<!DOCTYPE html>') || body.startsWith('<html');
    
    if (isHtml) {
      throw ApiException(
        message: 'Received HTML instead of JSON. The Base URL may be incorrect or hitting a portal/proxy warning.',
        statusCode: 502,
      );
    }

    final decoded = _tryDecodeBody(body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is! Map && (body.isNotEmpty && body != 'ok')) {
        throw ApiException(message: 'Invalid data format from server', statusCode: 500);
      }
      return decoded;
    }

    var message = 'Request failed';
    if (decoded is Map && decoded['message'] != null) {
      message = decoded['message'].toString();
    } else if (decoded is String && decoded.isNotEmpty) {
      message = decoded;
    } else {
      message = 'Request failed (${res.statusCode}) for ${res.request?.url ?? 'unknown endpoint'}.';
    }

    throw ApiException(
      message: message,
      statusCode: res.statusCode,
      payload: decoded,
    );
  }

  Future<http.Response> _safeRequest(
    Future<http.Response> Function() request,
    Uri uri,
  ) async {
    try {
      return await request().timeout(_kRequestTimeout);
    } on TimeoutException {
      throw ApiException(message: 'Connection timed out while contacting backend ($uri).', statusCode: 0);
    } on SocketException {
      throw ApiException(message: 'Cannot connect to backend ($uri).', statusCode: 0);
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Network error while contacting backend ($uri).', statusCode: 0);
    }
  }

  bool _shouldTryNextBase(ApiException e) {
    if (e.statusCode == 0) return true;
    final msg = e.message.toLowerCase();
    return msg.contains('err_ngrok_3200') ||
        (e.statusCode == 403 && msg.contains('base_url may point'));
  }

  Future<dynamic> _requestWithFailover(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    required String method,
  }) async {
    final isAbsolute = path.startsWith('http://') || path.startsWith('https://');
    
    if (isAbsolute) {
      final uri = _uri(path, query);
      _debugLog('REQUEST (ABSOLUTE) | $method $uri');
      final res = await _callWithMethod(uri, method, body);
      return _handle(res);
    }

    // 1. We have a known working URL - use it immediately
    if (_workingBaseUrl != null) {
      final uri = _uri(path, query, _workingBaseUrl);
      _debugLog('REQUEST (CACHED) | $method $uri');
      try {
        final res = await _callWithMethod(uri, method, body);
        return _handle(res);
      } on ApiException catch (e) {
        if (_shouldTryNextBase(e)) {
          _workingBaseUrl = null; 
        } else {
          rethrow;
        }
      }
    }

    // 2. Discover working URL (Parallel Discovery)
    final candidates = _candidateBaseUrls;
    _debugLog('DISCOVERING | Trying ${candidates.length} candidates in parallel for $path');
    final completer = Completer<dynamic>();
    var completed = false;
    var failCount = 0;

    for (var base in candidates) {
      final uri = _uri(path, query, base);
      _callWithMethod(uri, method, body).then((res) {
        if (completed) return;
        try {
          final handled = _handle(res);
          completed = true;
          _workingBaseUrl = base;
          completer.complete(handled);
        } catch (e) {
          failCount++;
          if (failCount >= candidates.length && !completed) {
            completer.completeError(e);
          }
        }
      }).catchError((e) {
        if (completed) return;
        failCount++;
        if (failCount >= candidates.length && !completed) {
          completer.completeError(e is ApiException 
            ? e 
            : ApiException(message: e.toString(), statusCode: 0));
        }
      });
    }

    return completer.future;
  }

  Future<http.Response> _callWithMethod(Uri uri, String method, Object? body) {
    switch (method) {
      case 'GET':
        return _safeRequest(() => http.get(uri, headers: _headers(jsonBody: false)), uri);
      case 'POST':
        return _safeRequest(() => http.post(uri, headers: _headers(), body: body == null ? null : jsonEncode(body)), uri);
      case 'PATCH':
        return _safeRequest(() => http.patch(uri, headers: _headers(), body: body == null ? null : jsonEncode(body)), uri);
      case 'PUT':
        return _safeRequest(() => http.put(uri, headers: _headers(), body: body == null ? null : jsonEncode(body)), uri);
      case 'DELETE':
        return _safeRequest(() => http.delete(uri, headers: _headers(jsonBody: false), body: body == null ? null : jsonEncode(body)), uri);
      default:
        throw ArgumentError('Unsupported method: $method');
    }
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) => _requestWithFailover(path, query: query, method: 'GET');
  Future<dynamic> _post(String path, {Object? body}) => _requestWithFailover(path, body: body, method: 'POST');
  Future<dynamic> _patch(String path, {Object? body}) => _requestWithFailover(path, body: body, method: 'PATCH');
  Future<dynamic> _put(String path, {Object? body}) => _requestWithFailover(path, body: body, method: 'PUT');
  Future<dynamic> _delete(String path, {Object? body}) => _requestWithFailover(path, method: 'DELETE', body: body);

  String? _extractToken(dynamic data) {
    if (data is Map && data['token'] is String) return data['token'] as String;
    if (data is Map && data['data'] is Map && data['data']['token'] is String) return data['data']['token'] as String;
    return null;
  }

  // ------------------ AUTH ------------------

  Future<dynamic> login({required String email, required String password}) async {
    final data = await _post('/auth/login', body: {'email': email.trim(), 'password': password});
    final t = _extractToken(data);
    if (t != null && t.isNotEmpty) await saveToken(t);
    return data;
  }

  Future<dynamic> loginWithPhone({required String phone, required String password}) async {
    final data = await _post('/auth/login', body: {'phone': phone.trim(), 'password': password});
    final t = _extractToken(data);
    if (t != null && t.isNotEmpty) await saveToken(t);
    return data;
  }

  Future<dynamic> register({required String fullname, required String email, required String password, required String phone}) async {
    final body = {
      'fullname': fullname.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'role': 'USER',
    };
    final data = await _post('/auth/register', body: body);
    final t = _extractToken(data);
    if (t != null && t.isNotEmpty) await saveToken(t);
    return data;
  }

  Future<dynamic> getCurrentUser() => _get('/auth/me');

  Future<dynamic> forgotPassword({required String email}) =>
      _post('/auth/forgot-password', body: {'email': email.trim()});

  Future<dynamic> resetPassword({required String resetToken, required String newPassword}) =>
      _put('/auth/reset-password/$resetToken', body: {'password': newPassword});

  Future<dynamic> updatePassword({required String currentPassword, required String newPassword}) =>
      _put('/auth/update-password', body: {'currentPassword': currentPassword, 'newPassword': newPassword});

  // ------------------ USER PROFILE ------------------

  Future<dynamic> getUserProfile() => _get('/users/profile');

  Future<dynamic> updateUserProfile(Map<String, dynamic> fields) => _patch('/users/profile', body: fields);

  Future<dynamic> deleteUserAccount() => _delete('/users/account');

  // ------------------ LEGAL CONTENT ------------------

  Future<dynamic> getContent(String type) => _get('/content/$type');

  // ------------------ RIDES ------------------

  Future<dynamic> getAllRides({int? page, int? limit, String? status}) =>
      _get('/rides', query: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      });

  Future<dynamic> searchRides({String? startCity, String? endCity, String? date}) =>
      _get('/rides', query: {
        if (startCity != null) 'startCity': startCity,
        if (endCity != null) 'endCity': endCity,
        if (startCity != null) 'from': startCity,
        if (endCity != null) 'to': endCity,
        if (date != null) 'date': date,
      });

  Future<dynamic> getRideById(String rideId) => _get('/rides/$rideId');

  // ------------------ MAPS ------------------

  Future<dynamic> estimateMapFare({required Map<String, dynamic> pickupLocation, required Map<String, dynamic> dropLocation}) =>
      _post('/maps/estimate', body: {'pickupLocation': pickupLocation, 'dropLocation': dropLocation});

  Future<dynamic> geocodeAddress(String address) =>
      _get('/maps/geocode', query: {'address': address});

  // ------------------ BOOKINGS ------------------

  Future<dynamic> estimateBooking({required Map<String, dynamic> pickupLocation, required Map<String, dynamic> dropLocation}) =>
      _post('/bookings/estimate', body: {'pickupLocation': pickupLocation, 'dropLocation': dropLocation});

  Future<dynamic> createBooking({
    String? rideId,
    int? seatsBooked,
    String? pickupAddress,
    String? dropAddress,
    Map<String, dynamic>? pickupLocation,
    Map<String, dynamic>? dropLocation,
    required String paymentMode,
  }) {
    final body = {
      'paymentMode': paymentMode,
      if (rideId != null) 'rideId': rideId,
      if (seatsBooked != null) 'seatsBooked': seatsBooked,
      if (pickupAddress != null) 'pickupAddress': pickupAddress,
      if (dropAddress != null) 'dropAddress': dropAddress,
      if (pickupLocation != null) 'pickupLocation': pickupLocation,
      if (dropLocation != null) 'dropLocation': dropLocation,
    };
    return _post('/bookings', body: body);
  }

  Future<dynamic> getMyBookings({String? status, int? page, int? limit}) => _get('/bookings/my-bookings', query: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      });

  Future<dynamic> getBookingById(String bookingId) => _get('/bookings/$bookingId');

  Future<dynamic> updateBooking(String bookingId, Map<String, dynamic> body) => _patch('/bookings/$bookingId', body: body);

  Future<dynamic> cancelBooking(String bookingId, {String? rideId, required String reason}) {
    // If rideId is provided, use the nested ride-management path confirmed by user
    if (rideId != null) {
      return _delete('/rides/$rideId/bookings/$bookingId', body: {'reason': reason});
    }
    return _delete('/bookings/$bookingId', body: {'reason': reason});
  }

  // ------------------ PAYMENTS ------------------

  Future<dynamic> createPaymentOrder(String bookingId) =>
      _post('/payments/create-order', body: {'bookingId': bookingId});

  Future<dynamic> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) => _post('/payments/verify', body: {
    'bookingId': bookingId,
    'razorpay_order_id': razorpayOrderId,
    'razorpay_payment_id': razorpayPaymentId,
    'razorpay_signature': razorpaySignature,
  });

  // ------------------ DRIVER MODULE ------------------

  Future<dynamic> registerDriver({
    required String fullname,
    required String email,
    required String phone,
    required String password,
    required String dob,
    required String aadhar,
    required String rcNo,
    required Map<String, dynamic> vehicle,
    String? licenseNo,
    String? panNo,
  }) async {
    final body = {
      'fullname': fullname.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'dob': dob.trim(),
      'aadhar': aadhar.trim(),
      'rcNo': rcNo.trim(),
      'vehicle': vehicle,
    };
    final data = await _post('/drivers/register', body: body);
    final t = _extractToken(data);
    if (t != null && t.isNotEmpty) await saveToken(t);
    return data;
  }

  Future<dynamic> getDriverProfile() => _get('/drivers/profile');

  Future<dynamic> updateDriverProfile(Map<String, dynamic> fields) => _patch('/drivers/profile', body: fields);

  Future<dynamic> getDriverEarnings() => _get('/drivers/earnings');

  Future<dynamic> createRide(Map<String, dynamic> ridePayload) => _post('/rides', body: ridePayload);

  Future<dynamic> getMyPublishedRides() => _get('/drivers/rides');

  Future<dynamic> updateMyRide(String rideId, Map<String, dynamic> fields) {
    // Sanitize payload to protect backend from generic findByIdAndUpdate vulnerabilities.
    // The driver should ONLY be able to patch these safe fields.
    final Map<String, dynamic> safeFields = Map.of(fields);
    final forbiddenKeys = [
      'driverId', 
      'status', 
      'availableSeats', 
      'startedAt', 
      'completedAt', 
      'availableSeatsUpdatedAt',
      'createdAt',
      'updatedAt',
      '_id',
      '__v'
    ];
    safeFields.removeWhere((key, value) => forbiddenKeys.contains(key));

    return _patch('/rides/$rideId', body: safeFields);
  }

  /// Update only the status of a ride (start / end / cancel)
  /// PATCH /rides/:id/status — { "status": "ONGOING" | "COMPLETED" | "CANCELLED" | "OPEN" | "FULL" }
  Future<dynamic> updateRideStatus(String rideId, String status) =>
      _patch('/rides/$rideId/status', body: {'status': status});

  Future<dynamic> cancelMyRide(String rideId) => _delete('/rides/$rideId');

  Future<dynamic> getRideBookings(String rideId) => _get('/bookings/driver-bookings', query: {'rideId': rideId});

  Future<dynamic> updateDriverBookingStatus(String rideId, String bookingId, String status) {
    if (status == 'COMPLETED') {
      // Backend automatically completes all confirmed bookings when ride is completed
      return _patch('/rides/$rideId/status', body: {'status': status});
    }

    // Original fallback logic for PENDING/CONFIRMED/CANCELLED
    return _patch('/bookings/$bookingId/status', body: {'status': status}).catchError((e) {
      if (e is ApiException && e.statusCode == 404) {
        return _patch('/bookings/$bookingId', body: {'status': status});
      }
      throw e;
    });
  }

  // ------------------ VENDOR MODULE ------------------

  Future<dynamic> registerDriverVendor({
    required String fullname,
    required String email,
    String? phone,
    required String password,
    String? role,
    String? dob,
    String? aadhar,
    List? aadharImgs,
    String? licenseNo,
    String? rcNo,
    List? rcImgs,
    String? panNo,
    List? panImg,
    List? driverSelfie,
    List? vehicleImgs,
    required Map<String, dynamic> vehicle,
    String? gstNo,
  }) async {
    final body = {
      'fullname': fullname.trim(),
      'email': email.trim(),
      if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
      'password': password,
      if (gstNo != null && gstNo.isNotEmpty) 'gstNo': gstNo.trim(),
      if (licenseNo != null && licenseNo.isNotEmpty) 'licenseNo': licenseNo.trim(),
      if (rcNo != null && rcNo.isNotEmpty) 'rcNo': rcNo.trim(),
      if (panNo != null && panNo.isNotEmpty) 'panNo': panNo.trim(),
      'vehicle': vehicle,
    };
    final data = await _post('/vendor/auth/register', body: body);
    final t = _extractToken(data);
    if (t != null && t.isNotEmpty) await saveToken(t);
    return data;
  }
  // ==========================================
  // CHAT APIs
  // ==========================================

  Future<dynamic> getChatThreads() async {
    return await _get('/chat/threads');
  }

  Future<dynamic> getChatThreadByBooking(String bookingId) async {
    return await _get('/chat/threads/$bookingId');
  }

  Future<dynamic> getChatMessages(String bookingId) async {
    return await _get('/chat/threads/$bookingId/messages');
  }

  Future<dynamic> sendChatMessage(String bookingId, String text) async {
    return await _post('/chat/threads/$bookingId/messages', body: {"text": text});
  }

  Future<dynamic> markChatAsRead(String bookingId) async {
    return await _patch('/chat/threads/$bookingId/read', body: {});
  }

  // ==========================================
  // RATING APIs
  // ==========================================

  Future<dynamic> rateDriver(String bookingId, int rating, {String? review}) async {
    return await _post('/bookings/$bookingId/rate-driver', body: {
      'rating': rating,
      if (review != null && review.isNotEmpty) 'review': review,
    });
  }

  Future<dynamic> ratePassenger(String bookingId, int rating, {String? review}) async {
    return await _post('/bookings/$bookingId/rate-passenger', body: {
      'rating': rating,
      if (review != null && review.isNotEmpty) 'review': review,
    });
  }

  // ------------------ WALLET MODULE ------------------

  Future<dynamic> getWalletDetails() => _get('/wallet/details');

  Future<dynamic> topupWallet({required double amount, String? referenceId}) =>
      _post('/wallet/topup', body: {'amount': amount, 'referenceId': referenceId});

  Future<dynamic> createWalletTopupOrder(double amount) =>
      _post('/wallet/topup/create-order', body: {'amount': amount});

  Future<dynamic> verifyWalletTopupPayment({
    required double amount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    bool isFallback = false,
  }) =>
      _post('/wallet/topup/verify', body: {
        'amount': amount,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'isFallback': isFallback,
      });
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic payload;

  ApiException({required this.message, required this.statusCode, this.payload});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
