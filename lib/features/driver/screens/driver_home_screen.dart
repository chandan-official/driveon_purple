import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../api/api_service.dart';
import '../models/ride_model.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  bool _isLoading = false;
  List<dynamic> _rides = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRides();
  }

  Future<void> _fetchRides() async {
    setState(() => _isLoading = true);
    try {
      await _api.loadToken();
      final data = await _api.getMyPublishedRides();
      
      // Extract list from various possible backend structures
      List<dynamic> list = [];
      if (data is Map) {
        if (data["rides"] is List) list = data["rides"];
        else if (data["data"] is List) list = data["data"];
        else if (data["data"] is Map && data["data"]["data"] is List) list = data["data"]["data"];
      } else if (data is List) {
        list = data;
      }
      
      setState(() => _rides = list);
    } catch (e) {
      debugPrint("Error fetching rides: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "On Going Rides",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  dividerColor: Colors.transparent, // Removes the extra bottom line
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: const [
                    Tab(text: "Current"),
                    Tab(text: "History"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRideList(isHistory: false),
          _buildRideList(isHistory: true),
        ],
      ),
    );
  }

  Widget _buildRideList({required bool isHistory}) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Filter logic: date-based + status-based
    final filtered = _rides.map((r) => Ride.fromJson(r as Map<String, dynamic>)).where((ride) {
      final rideDate = DateTime(ride.travelDate.year, ride.travelDate.month, ride.travelDate.day);
      final isPastDate = rideDate.isBefore(todayDate);
      final isCompletedOrCancelled = ride.status == RideStatus.completed || ride.status == RideStatus.cancelled;

      if (isHistory) {
        // History: past date rides OR completed/cancelled rides
        return isPastDate || isCompletedOrCancelled;
      } else {
        // Current: today or future date rides AND not completed/cancelled
        return !isPastDate && !isCompletedOrCancelled;
      }
    }).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          isHistory ? "No past rides found" : "No current rides found",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRides,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final ride = filtered[index];
          return InkWell(
            onTap: () {
              Navigator.pushNamed(
                context, 
                '/ride_bookings', 
                arguments: {'ride': ride, 'rideId': ride.id},
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: _RideCard(ride: ride),
          );
        },
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;
  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final startCity = ride.route.startCity;
    final endCity = ride.route.endCity;
    
    final travelDate = ride.travelDate;
    final startTime = ride.startTime;

    // Clean up dates for display (e.g. Thursday, 22-Oct-2025)
    String displayDate = "${travelDate.day}-${_getMonth(travelDate.month)}-${travelDate.year}";
    String displayDay = _getDayOfWeek(travelDate.weekday);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayDay, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(displayDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Time", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLocationRow(Icons.location_on, startCity, isStart: true),
                const SizedBox(height: 16),
                _buildLocationRow(Icons.location_on, endCity, isStart: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String city, {required bool isStart}) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isStart ? Colors.black : AppColors.primaryPurple,
              ),
            ),
            if (isStart)
              Positioned(
                top: 10,
                child: Container(width: 2, height: 20, color: Colors.grey.withOpacity(0.3)),
              )
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            city,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  String _getMonth(int m) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[m - 1];
  }

  String _getDayOfWeek(int d) {
    const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return days[d - 1];
  }
}
