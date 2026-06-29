import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  
  // Streams for broadcasting socket events to UI
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _threadUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  final _closeController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onThreadUpdated => _threadUpdateController.stream;
  Stream<Map<String, dynamic>> get onRead => _readController.stream;
  Stream<Map<String, dynamic>> get onClosed => _closeController.stream;

  String _normalizeBase(String value) => value.trim().replaceAll(RegExp(r'/api$'), '').replaceAll(RegExp(r'/+$'), '');

  String get _baseUrl {
    final envBase = (dotenv.env['BASE_URL'] ?? '').trim();
    if (envBase.isNotEmpty) return _normalizeBase(envBase);
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(_baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build()
    );

    _socket!.onConnect((_) {
      if (kDebugMode) print('[SOCKET] Connected to $_baseUrl');
    });

    _socket!.on('chat:message', (data) {
      if (data is Map) _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('chat:thread_updated', (data) {
      if (data is Map) _threadUpdateController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('chat:read', (data) {
      if (data is Map) _readController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('chat:closed', (data) {
      if (data is Map) _closeController.add(Map<String, dynamic>.from(data));
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) print('[SOCKET] Disconnected');
    });
  }

  void joinChat(String bookingId) {
    _socket?.emitWithAck('chat:join', {'bookingId': bookingId}, ack: (data) {
      if (kDebugMode) print('[SOCKET] Joined chat: $data');
    });
  }

  void leaveChat(String bookingId) {
    _socket?.emitWithAck('chat:leave', {'bookingId': bookingId}, ack: (data) {
      if (kDebugMode) print('[SOCKET] Left chat: $data');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
