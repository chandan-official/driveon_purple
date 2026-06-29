import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';
import '../../rides/widgets/ride_card.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final ApiService _api = ApiService();

  late Future<List<Map<String, dynamic>>> _upcomingFuture;
  late Future<List<Map<String, dynamic>>> _completedFuture;

  @override
  void initState() {
    super.initState();
    // A newly booked ride is typically PENDING. An accepted one is CONFIRMED.
    _upcomingFuture = _fetchTrips(validStatuses: ['PENDING', 'CONFIRMED', 'ONGOING']);
    _completedFuture = _fetchTrips(validStatuses: ['COMPLETED']);
  }

  Future<List<Map<String, dynamic>>> _fetchTrips({required List<String> validStatuses}) async {
    await _api.loadToken();
    // Fetch all bookings without passing a specific status to the backend
    final data = await _api.getMyBookings(page: 1, limit: 50);

    dynamic raw = data;
    if (raw is Map && raw['data'] is List) {
      raw = raw['data'];
    } else if (raw is Map && raw['bookings'] is List) {
      raw = raw['bookings'];
    }

    if (raw is List) {
      final allBookings = raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      // Filter locally based on valid statuses
      return allBookings.where((booking) {
        final status = (booking['status'] ?? '').toString().trim().toUpperCase();
        return validStatuses.contains(status);
      }).toList();
    }
    return const [];
  }

  String _formatTime(dynamic iso) {
    final dt = DateTime.tryParse((iso ?? '').toString());
    if (dt == null) return 'N/A';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
        ),
      ),
    );
  }

  Widget _buildTripsFuture(Future<List<Map<String, dynamic>>> future, {required bool completed}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load trips: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final trips = snapshot.data ?? const [];
        if (trips.isEmpty) {
          return Center(
            child: Text(
              completed ? 'No completed trips yet.' : 'No upcoming trips found.',
              style: const TextStyle(color: AppColors.textGrey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            final ride = (trip['rideDetails'] is Map)
                ? (trip['rideDetails'] as Map).cast<String, dynamic>()
                : (trip['rideId'] is Map)
                    ? (trip['rideId'] as Map).cast<String, dynamic>()
                    : <String, dynamic>{};

            final Object rawFare = trip['totalAmount'] ?? trip['totalFare'] ?? (trip['fareBreakdown'] is Map ? trip['fareBreakdown']['subtotal'] : null) ?? 0;
            final double fare = rawFare is num ? rawFare.toDouble() : double.tryParse(rawFare.toString()) ?? 0.0;
            final seats = trip['seatsBooked'] ?? 1;
            
            final route = ride['route'] is Map ? ride['route'] : {};
            final from = (route['startCity'] ?? ride['from'] ?? 'Trip').toString();
            final to = (route['endCity'] ?? ride['to'] ?? '').toString();
            final time = (ride['startTime'] ?? _formatTime(ride['departureTime'] ?? trip['createdAt'])).toString();
            final routeName = to.isEmpty ? from : '$from -> $to';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0) _buildSectionHeader(completed ? 'Completed' : 'Upcoming'),
                RideCard(
                  name: routeName,
                  time: time,
                  price: '$fare',
                  seats: '$seats',
                  rating: 4.7,
                  isVerified: true,
                  onTap: () => Navigator.pushNamed(context, '/ride_detail', arguments: {
                    'ride': ride,
                    'booking': trip,
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: const Text('My Activity'),
          centerTitle: true,
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primaryPurple,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTripsFuture(_upcomingFuture, completed: false),
            _buildTripsFuture(_completedFuture, completed: true),
          ],
        ),
      ),
    );
  }
}
