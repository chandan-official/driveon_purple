import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/color_constants.dart';
import '../../rides/widgets/ride_card.dart';
import '../../common/screens/chat_inbox_screen.dart';
import '../widgets/side_drawer.dart';
import '../../../api/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  Future<Map<String, dynamic>?>? _profileFuture;
  Future<dynamic>? _bookingsFuture;
  
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _bookingsFuture = _loadBookings();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _currentLocation = loc);
        _mapController?.animateCamera(CameraUpdate.newLatLng(loc));
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    await _api.loadToken();
    final res = await _api.getUserProfile();
    if (res is Map && res['data'] is Map) {
      return res['data'] as Map<String, dynamic>;
    }
    return null;
  }

  Future<dynamic> _loadBookings() async {
    await _api.loadToken(); 
    return await _api.getMyBookings(limit: 3);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      drawer: const SideDrawer(),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: double.infinity,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? const LatLng(28.6139, 77.2090), 
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentLocation != null) {
                  controller.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
                }
              },
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: const Color(0xFFF8F9FA).withValues(alpha: 0.85),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: AppColors.textDark),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.notifications_none, color: AppColors.textDark),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/profile'),
                              child: FutureBuilder<Map<String, dynamic>?>(
                                future: _profileFuture,
                                builder: (context, snapshot) {
                                  final name = snapshot.data?['fullname']?.toString() ?? 'U';
                                  return CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primaryPurple,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: GoogleFonts.inter(fontSize: 16, color: AppColors.textGrey),
                        ),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _profileFuture,
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data?['fullname']?.toString() ?? 'User',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            title: "Find a Ride",
                            subtitle: "Share ride Share cost",
                            icon: Icons.search,
                            color: AppColors.primaryPurple,
                            onTap: () => Navigator.pushNamed(context, '/search_ride'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ongoing Rides",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(onPressed: () {}, child: const Text("See All")),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FutureBuilder<dynamic>(
                      future: _bookingsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        List rides = [];
                        if (snapshot.data is Map) {
                          final rawMap = snapshot.data as Map;
                          if (rawMap['data'] is List) rides = rawMap['data'];
                          else if (rawMap['bookings'] is List) rides = rawMap['bookings'];
                        } else if (snapshot.data is List) {
                          rides = snapshot.data as List;
                        }

                        final activeRides = rides.where((trip) {
                          final status = trip['status']?.toString().toUpperCase() ?? "PENDING";
                          return status == "PENDING" || status == "CONFIRMED" || status == "ONGOING";
                        }).toList();
                        
                        if (activeRides.isEmpty) return const Center(child: Text("No ongoing rides found."));

                        return Column(
                          children: activeRides.take(3).map((trip) {
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
                            final status = trip['status']?.toString() ?? "PENDING";
                            
                            final routeName = to.isEmpty ? from : '$from -> $to';

                            return RideCard(
                              name: routeName,
                              time: "Status: $status",
                              price: fare.toStringAsFixed(0),
                              seats: seats.toString(),
                              rating: 4.7,
                              isVerified: true,
                              onTap: () => Navigator.pushNamed(context, '/ride_detail', arguments: {
                                'ride': ride,
                                'booking': trip,
                              }),
                            );
                          }).toList(),
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(height: size.height * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
