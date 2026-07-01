import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';

class RideDetailScreen extends StatefulWidget {
  const RideDetailScreen({super.key});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>>? _rideFuture;
  Map<String, dynamic>? _initialRide;
  String _rideId = '';
  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _fareConfig;

  int _selectedSeats = 1;
  bool _agreeToPassengerSharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rideFuture != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final rideArg = args['ride'];
      if (rideArg is Map) {
        _initialRide = rideArg.cast<String, dynamic>();
      }
      final bookingArg = args['booking'];
      if (bookingArg is Map) {
        _booking = bookingArg.cast<String, dynamic>();
      }
      _rideId = (args['rideId'] ?? _initialRide?['_id'] ?? _initialRide?['id'] ?? '').toString();
    }

    _rideFuture = _loadRide();
  }

  Future<Map<String, dynamic>> _loadRide() async {
    if (_rideId.isEmpty && _initialRide != null) {
      return _initialRide!;
    }

    if (_rideId.isEmpty) {
      throw Exception('Ride details are missing. Please search again.');
    }

    final res = await _api.getRideById(_rideId);
    debugPrint("RIDE DETAIL PAYLOAD: ${jsonEncode(res)}");
    if (res is Map && res['data'] is Map) {
      if (res['fareConfig'] is Map) {
        _fareConfig = (res['fareConfig'] as Map).cast<String, dynamic>();
      }
      return (res['data'] as Map).cast<String, dynamic>();
    }
    if (res is Map) return res.cast<String, dynamic>();
    throw Exception('Invalid ride response from server');
  }

  String _fmtTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso; // Return original if not ISO (e.g. "10:30 AM")
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  String _fmtDate(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return 'N/A';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d-$m-${dt.year}';
  }

  void _showRatingSheet(BuildContext context, String bookingId) {
    int _selectedRating = 5;
    final TextEditingController _reviewCtrl = TextEditingController();
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Rate Your Driver', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('How was your ride experience?', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setSheetState(() => _selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.star_rounded,
                        size: 40,
                        color: star <= _selectedRating ? Colors.amber : Colors.grey.shade300,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _reviewCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Leave a review (optional)...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : () async {
                    setSheetState(() => _isSubmitting = true);
                    try {
                      await _api.loadToken();
                      final res = await _api.rateDriver(
                        bookingId,
                        _selectedRating,
                        review: _reviewCtrl.text.trim(),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res is Map && res['success'] == true
                              ? 'Thanks for rating your driver! ⭐'
                              : (res?['message'] ?? 'Rating submitted')),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh booking state
                      if (mounted) setState(() {
                        if (_booking != null) {
                          _booking!['ratingByPassenger'] = {'rating': _selectedRating};
                        }
                      });
                    } catch (e) {
                      setSheetState(() => _isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _rideFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              title: const Text('Trip Details'),
              backgroundColor: AppColors.backgroundLight,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load ride: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final ride = snapshot.data ?? const <String, dynamic>{};
        final from = (ride['from'] ?? ride['route']?['startCity'] ?? 'From').toString();
        final to = (ride['to'] ?? ride['route']?['endCity'] ?? 'To').toString();
        final departure = ride['departureTime']?.toString() ?? ride['travelDate']?.toString();
        final displayTime = ride['startTime'] ?? ride['time'] ?? _fmtTime(departure);
        final availableSeatsRaw = ride['availableSeats'] ?? ride['seats'] ?? 1;
        final availableSeats = availableSeatsRaw is num ? availableSeatsRaw.toInt() : 1;
        final bool isSoldOut = availableSeats <= 0;

        final fareRaw = ride['fare'] ?? ride['pricing']?['pricePerSeat'] ?? 0;
        final fare = (fareRaw is num) ? fareRaw.toDouble() : double.tryParse('$fareRaw') ?? 0;

        final safeMaxSeats = isSoldOut ? 1 : availableSeats;
        if (_selectedSeats > safeMaxSeats) {
          _selectedSeats = safeMaxSeats;
        }
        if (isSoldOut && _selectedSeats != 0) {
          _selectedSeats = 0;
        }

        final config = _fareConfig ?? {
          'platformFee': 0.0,
          'gstPercent': 5.0,
        };
        final double platformFeeVal = (config['platformFee'] as num?)?.toDouble() ?? 0.0;
        final double gstPercentVal = (config['gstPercent'] as num?)?.toDouble() ?? 0.0;
        final double gstVal = platformFeeVal * (gstPercentVal / 100.0);
        final double totalPricePerSeat = fare + platformFeeVal + gstVal;
        final double totalPrice = totalPricePerSeat * _selectedSeats;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
                decoration: const BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Trip Details',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                from,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(displayTime, style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Icon(Icons.arrow_right_alt, color: AppColors.primaryGold, size: 30),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                to,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_fmtDate(departure), style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            (() {
                              final d = ride['driverId'];
                              Map? uObj;
                              if (d is Map) {
                                if (d['userId'] is Map) uObj = d['userId'];
                                else if (d['user'] is Map) uObj = d['user'];
                                else uObj = d;
                              } else {
                                if (ride['userId'] is Map) uObj = ride['userId'];
                                else if (ride['user'] is Map) uObj = ride['user'];
                                else if (ride['driver'] is Map) uObj = ride['driver'];
                              }
                              
                              String dName = 'Driver';
                              if (uObj != null) {
                                final fn = uObj['fullname']?.toString() ?? uObj['name']?.toString() ?? uObj['fullName']?.toString() ?? uObj['displayName']?.toString();
                                if (fn != null && fn.trim().isNotEmpty) {
                                  dName = fn.trim();
                                } else {
                                  final firstName = uObj['first_name']?.toString() ?? uObj['firstName']?.toString() ?? '';
                                  final lastName = uObj['last_name']?.toString() ?? uObj['lastName']?.toString() ?? '';
                                  if (firstName.isNotEmpty || lastName.isNotEmpty) {
                                    dName = '$firstName $lastName'.trim();
                                  } else {
                                    final alt = uObj['username']?.toString() ?? uObj['email']?.toString();
                                    if (alt != null && alt.trim().isNotEmpty) dName = alt.trim();
                                  }
                                }
                              }

                              final v = (d is Map && d['vehicle'] is Map) ? d['vehicle'] : (ride['vehicle'] is Map ? ride['vehicle'] : {});
                              final vName = (v['model'] ?? v['brand'] ?? v['vehicleNumber'] ?? v['plateNumber'] ?? '').toString();
                              
                              return _buildDetailRow(
                                Icons.person, 
                                'Driver', 
                                vName.isNotEmpty ? '$dName ($vName)' : dName
                              );
                            })(),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                            _buildDetailRow(Icons.calendar_today, 'Departure', _fmtDate(departure)),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                            _buildDetailRow(Icons.access_time, 'Time', displayTime),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                            _buildDetailRow(Icons.airline_seat_recline_normal, 'Available', '$availableSeats seats left'),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                            _buildDetailRow(Icons.currency_rupee, 'Fare / Seat', '₹$fare'),
                          ],
                        ),
                      ),
                      if (_booking != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('My Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 16),
                              _buildDetailRow(Icons.info_outline, 'Status', (_booking!['status'] ?? 'UNKNOWN').toString()),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                              _buildDetailRow(Icons.event_seat, 'Seats Booked', (_booking!['seatsBooked'] ?? 1).toString()),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                              _buildDetailRow(Icons.payment, 'Payment Status', (_booking!['paymentStatus'] ?? 'UNKNOWN').toString()),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                              _buildDetailRow(Icons.payments_outlined, 'Total Paid', '₹${(_booking!['totalAmount'] ?? _booking!['totalFare'] ?? (_booking!['fareBreakdown'] is Map ? _booking!['fareBreakdown']['subtotal'] : null) ?? 0)}'),

                              // RATING SECTION — only show if COMPLETED and not yet rated
                              if ((_booking!['status'] ?? '') == 'COMPLETED') ...[
                                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                                if (_booking!['ratingByPassenger'] != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        'You rated: ${(_booking!['ratingByPassenger']['rating'] ?? 0)}/5',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                                      ),
                                    ],
                                  )
                                else
                                  GestureDetector(
                                    onTap: () => _showRatingSheet(context, _booking!['_id']?.toString() ?? ''),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.amber.shade200),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.star_border_rounded, color: Colors.amber.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Rate Your Driver',
                                            style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        isSoldOut
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        "Fully Booked / No Seats Available",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Select Seats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      children: List.generate(safeMaxSeats, (index) {
                                        final seat = index + 1;
                                        final selected = seat == _selectedSeats;
                                        return ChoiceChip(
                                          label: Text('$seat'),
                                          selected: selected,
                                          onSelected: (_) => setState(() => _selectedSeats = seat),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 14),

                                    // Dynamic Price Breakdown
                                    (() {
                                      final config = _fareConfig ?? {
                                        'platformFee': 0.0,
                                        'gstPercent': 5.0,
                                      };
                                      final double platformFee = (config['platformFee'] as num?)?.toDouble() ?? 0.0;
                                      final double gstPercent = (config['gstPercent'] as num?)?.toDouble() ?? 0.0;

                                      final double gst = platformFee * (gstPercent / 100.0);
                                      final double baseShare = fare;

                                      final double totalBase = baseShare * _selectedSeats;
                                      final double totalPlatform = platformFee * _selectedSeats;
                                      final double totalGst = gst * _selectedSeats;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Divider(height: 24),
                                          const Text(
                                            'Price Breakdown',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Driver Share (${_selectedSeats} seat${_selectedSeats > 1 ? 's' : ''})', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                              Text('₹${totalBase.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Platform Fee (Flat)', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                              Text('₹${totalPlatform.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('GST on Platform Fee (${gstPercent.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                              Text('₹${totalGst.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ],
                                      );
                                    })(),

                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text(
                                          '₹${totalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                            color: AppColors.primaryPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: _booking != null 
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: (() {
                      final bStatus = (_booking!['status'] ?? '').toString().toUpperCase();
                      final alreadyRated = _booking!['ratingByPassenger'] != null;

                      if (bStatus == 'COMPLETED' && !alreadyRated) {
                        return ElevatedButton.icon(
                          icon: const Icon(Icons.star_rounded, color: Colors.white),
                          label: const Text('Rate Your Driver', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _showRatingSheet(context, _booking!['_id']?.toString() ?? ''),
                        );
                      } else if (bStatus == 'COMPLETED' && alreadyRated) {
                        return ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text('Ride Completed', style: TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: null,
                        );
                      } else {
                        final isCancelled = bStatus == 'CANCELLED' || bStatus == 'REFUNDED';
                        if (isCancelled) {
                          return ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Ride Cancelled', style: TextStyle(fontSize: 18, color: Colors.white)),
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: OutlinedButton(
                                onPressed: () => _handleCancellation(context, ride, _booking!),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 6,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/track_ride',
                                    arguments: {
                                      'ride': ride,
                                      'booking': _booking,
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Track Trip',
                                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    })(),
                  ),
                ),
              )
            : Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSoldOut) ...[
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeToPassengerSharing,
                          onChanged: (val) {
                            setState(() {
                              _agreeToPassengerSharing = val ?? false;
                            });
                          },
                          activeColor: AppColors.primaryPurple,
                        ),
                        const Expanded(
                          child: Text(
                            "This is a ride sharing but not a taxi service.",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSoldOut || !_agreeToPassengerSharing
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                '/payment',
                                arguments: {
                                  'ride': ride,
                                  'rideId': (_rideId.isNotEmpty ? _rideId : (ride['_id'] ?? ride['id'] ?? '').toString()),
                                  'seatsRequired': _selectedSeats,
                                  'amount': totalPrice.toInt(),
                                },
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSoldOut
                            ? Colors.grey.shade400
                            : (!_agreeToPassengerSharing ? Colors.grey : AppColors.primaryPurple),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        isSoldOut ? 'Fully Booked' : 'Proceed to Pay',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime _getDepartureDateTime(String travelDateStr, String startTimeStr) {
    try {
      DateTime dt = DateTime.parse(travelDateStr);
      int hours = 0;
      int minutes = 0;
      final timeClean = startTimeStr.trim().toUpperCase();
      if (timeClean.contains('AM') || timeClean.contains('PM')) {
        final ampmMatch = RegExp(r'^(\d+):(\d+)\s*(AM|PM)$').firstMatch(timeClean);
        if (ampmMatch != null) {
          hours = int.parse(ampmMatch.group(1)!);
          minutes = int.parse(ampmMatch.group(2)!);
          final ampm = ampmMatch.group(3)!;
          if (ampm == 'PM' && hours < 12) {
            hours += 12;
          } else if (ampm == 'AM' && hours == 12) {
            hours = 0;
          }
        }
      } else {
        final parts = timeClean.split(':');
        if (parts.length >= 2) {
          hours = int.parse(parts[0]);
          minutes = int.parse(parts[1]);
        }
      }
      return DateTime(dt.year, dt.month, dt.day, hours, minutes);
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _handleCancellation(
    BuildContext context,
    Map<String, dynamic> ride,
    Map<String, dynamic> booking,
  ) async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Fetch cancellation rules from backend
      final rulesRes = await _api.getCancellationRules();
      List<dynamic> rules = [];
      if (rulesRes is Map && rulesRes['data'] is List) {
        rules = rulesRes['data'];
      }

      // Dismiss loading indicator
      if (context.mounted) Navigator.pop(context);

      // 2. Parse departure time and check hours remaining
      final String travelDate = (ride['travelDate'] ?? '').toString();
      final String startTime = (ride['startTime'] ?? ride['time'] ?? '12:00 AM').toString();
      final departureDateTime = _getDepartureDateTime(travelDate, startTime);
      final hoursRemaining = departureDateTime.difference(DateTime.now()).inMinutes / 60.0;

      double refundPercent = 100;
      if (hoursRemaining <= 0) {
        refundPercent = 0;
      } else if (rules.isNotEmpty) {
        // Find matching rule
        dynamic matchedRule;
        for (var rule in rules) {
          final threshold = (rule['hoursBefore'] as num).toDouble();
          if (hoursRemaining >= threshold) {
            matchedRule = rule;
            break;
          }
        }
        refundPercent = matchedRule != null 
            ? (matchedRule['refundPercent'] as num).toDouble() 
            : 0.0;
      }

      final double totalPaid = (booking['totalAmount'] ?? booking['amount'] ?? 0.0).toDouble();
      final double refundAmount = totalPaid * (refundPercent / 100.0);

      // 3. Show dynamic cancellation modal
      if (context.mounted) {
        _showCancellationDialog(
          context: context,
          bookingId: booking['_id']?.toString() ?? booking['id']?.toString() ?? '',
          hoursRemaining: hoursRemaining,
          refundPercent: refundPercent,
          refundAmount: refundAmount,
          totalPaid: totalPaid,
        );
      }
    } catch (e) {
      // Dismiss loading indicator if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate cancellation policy: $e')),
        );
      }
    }
  }

  void _showCancellationDialog({
    required BuildContext context,
    required String bookingId,
    required double hoursRemaining,
    required double refundPercent,
    required double refundAmount,
    required double totalPaid,
  }) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Confirm Cancellation',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cancellation Policy Summary:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  hoursRemaining <= 0
                      ? '• Time remaining: Ride departed.'
                      : '• Time remaining: ${hoursRemaining.toStringAsFixed(1)} hours before departure.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Refund eligibility: ${refundPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Expected Refund: ₹${refundAmount.toStringAsFixed(2)} (out of ₹${totalPaid.toStringAsFixed(2)})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: refundAmount > 0 ? Colors.green.shade700 : Colors.red,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Please provide a reason for cancellation:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Reason...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a cancellation reason')),
                  );
                  return;
                }

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  await _api.cancelBooking(bookingId, reason: reason);
                  // Dismiss loading and dialog
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
                    Navigator.pop(context); // dismiss confirm dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(refundPercent > 0
                            ? 'Cancellation successful. Refund of ₹${refundAmount.toStringAsFixed(2)} initiated!'
                            : 'Booking cancelled successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Navigate back to home
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
                  }
                } catch (e) {
                  // Dismiss loading
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cancellation failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryPurple, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ],
        ),
      ],
    );
  }
}
