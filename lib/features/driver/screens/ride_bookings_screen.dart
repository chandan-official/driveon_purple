import 'package:flutter/material.dart';
import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';
import '../models/ride_model.dart';

class RideBookingsScreen extends StatefulWidget {
  const RideBookingsScreen({Key? key}) : super(key: key);

  @override
  State<RideBookingsScreen> createState() => _RideBookingsScreenState();
}

class _RideBookingsScreenState extends State<RideBookingsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String? _rideId;
  Ride? _rideObj;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['rideId'] != null) {
      _rideId = args['rideId'];
      _rideObj = args['ride'] as Ride?;
      _fetchBookings();
    }
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      await _api.loadToken();
      final res = await _api.getRideBookings(_rideId!);
      if (res is Map) {
        // Documentation specifies 'bookings' key for this endpoint
        if (res['bookings'] is List) {
          _bookings = res['bookings'];
        } else if (res['data'] is List) {
          _bookings = res['data'];
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _api.loadToken();
      await _api.updateDriverBookingStatus(_rideId!, bookingId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking marked as $status')),
      );
      // Refresh the list rather than popping the screen
      _fetchBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showRatePassengerSheet(String bookingId, String passengerName) {
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
              Text('Rate $passengerName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('How was your experience with this passenger?', style: TextStyle(color: Colors.grey)),
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
                      final res = await _api.ratePassenger(
                        bookingId,
                        _selectedRating,
                        review: _reviewCtrl.text.trim(),
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res is Map && res['success'] == true
                              ? 'Passenger rated successfully! ⭐'
                              : (res?['message'] ?? 'Rating submitted')),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _fetchBookings();
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: _rideObj == null ? const Text('Ride Bookings') : null,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          if (_rideObj != null && _rideObj!.status != RideStatus.completed && _rideObj!.status != RideStatus.cancelled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context, 
                      '/start_ride',
                      arguments: {'ride': _rideObj},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation, size: 16),
                      SizedBox(width: 8),
                      Text("START TRIP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text("No bookings yet.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final b = _bookings[index];
                    final String bId = b['_id'] ?? '';
                    final String status = (b['status'] ?? b['paymentStatus'] ?? 'UNKNOWN').toString().toUpperCase();
                    final int seats = b['seatsBooked'] ?? 1;
                    final Object rawFare = b['totalAmount'] ?? b['totalFare'] ?? (b['fareBreakdown'] is Map ? b['fareBreakdown']['subtotal'] : null) ?? 0;
                    final double fare = rawFare is num ? rawFare.toDouble() : double.tryParse(rawFare.toString()) ?? 0.0;
                    
                    // Documentation says 'passengerId', fallback to 'user' or 'passenger'
                    final passenger = b['passengerId'] is Map 
                        ? b['passengerId'] 
                        : (b['user'] is Map ? b['user'] : (b['passenger'] is Map ? b['passenger'] : {}));
                    
                    final String passengerName = passenger['fullname'] ?? passenger['name'] ?? 'Passenger';
                    final String passengerPhone = passenger['phone'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  passengerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'CONFIRMED' ? Colors.green.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: status == 'CONFIRMED' ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Phone: $passengerPhone", style: TextStyle(color: Colors.grey.shade700)),
                            Text("Seats: $seats • Fare: ₹$fare", style: TextStyle(color: Colors.grey.shade700)),
                            
                            const SizedBox(height: 12),
                            if (status == 'PENDING' || status == 'CONFIRMED')
                              Row(
                                children: [
                                  if (status == 'PENDING')
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _updateBookingStatus(bId, 'CONFIRMED'),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                                        child: const Text('Confirm'),
                                      ),
                                    ),
                                  if (status == 'PENDING') const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        if (status == 'PENDING' || status == 'CONFIRMED') {
                                          _updateBookingStatus(bId, 'CANCELLED');
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ),
                                  if (status == 'CONFIRMED') const SizedBox(width: 10),
                                  if (status == 'CONFIRMED')
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _updateBookingStatus(bId, 'COMPLETED'),
                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryPurple),
                                        child: const Text('Complete'),
                                      ),
                                    ),
                                ],
                              ),
                            if (status == 'COMPLETED')
                              Row(
                                children: [
                                  if (b['ratingByDriver'] != null)
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Rated: ${b['ratingByDriver']['rating']}/5',
                                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showRatePassengerSheet(bId, passengerName),
                                        icon: const Icon(Icons.star_border_rounded, size: 18),
                                        label: const Text('Rate Passenger'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
