import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';
import '../widgets/ride_card.dart';

class RideResultsScreen extends StatefulWidget {
  const RideResultsScreen({Key? key}) : super(key: key);

  @override
  State<RideResultsScreen> createState() => _RideResultsScreenState();
}

class _RideResultsScreenState extends State<RideResultsScreen> {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>>? _resultsFuture;
  String _from = '';
  String _to = '';
  String? _date;
  int? _seats;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resultsFuture != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _from = (args['from'] ?? '').toString();
      _to = (args['to'] ?? '').toString();
      _date = args['date']?.toString();
      _seats = args['seats'] is int ? args['seats'] as int : int.tryParse('${args['seats']}');
    }

    _resultsFuture = _fetchResults();
  }

  Future<List<Map<String, dynamic>>> _fetchResults() async {
    if (_from.isEmpty || _to.isEmpty) return const [];

    await _api.loadToken();
    final data = await _api.searchRides(
      startCity: _from,
      endCity: _to,
      date: _date,
    );

    dynamic raw = data;
    if (raw is Map && raw['rides'] is List) {
      raw = raw['rides'];
    } else if (raw is Map && raw['data'] is List) {
      raw = raw['data'];
    }

    if (raw is List) {
      List<Map<String, dynamic>> allRides = 
          raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

      // Bulletproof Client-Side Filtering
      final filteredRides = allRides.where((ride) {
        final route = ride['route'] as Map? ?? {};
        final rStart = (route['startCity'] ?? '').toString().toLowerCase();
        final rEnd = (route['endCity'] ?? '').toString().toLowerCase();
        
        // Clean search terms for matching
        String clean(String s) => s.split(',').first.trim().toLowerCase();
        final searchStart = clean(_from);
        final searchEnd = clean(_to);

        // 1. Match Locations (Check if address contains the searched city)
        bool locationMatch = rStart.contains(searchStart) && rEnd.contains(searchEnd);

        // 2. Match Date (Check if same day)
        bool dateMatch = true;
        if (_date != null && _date!.isNotEmpty) {
          final searchDate = _date!.split('T').first; // YYYY-MM-DD
          final rideDate = (ride['travelDate'] ?? '').toString().split('T').first;
          dateMatch = rideDate == searchDate;
        }

        return locationMatch && dateMatch;
      }).toList();

      return filteredRides;
    }
    return const [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Available Rides', style: TextStyle(fontSize: 16)),
            Text(
              '$_from -> $_to',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load rides: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final rides = snapshot.data ?? const [];
          if (rides.isEmpty) {
            return const Center(
              child: Text(
                'No rides found for this route.',
                style: TextStyle(color: AppColors.textGrey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              debugPrint("SEARCH RIDE PAYLOAD: ${jsonEncode(ride)}");
              final pricing = ride['pricing'] is Map ? ride['pricing'] as Map : {};
              final route = ride['route'] is Map ? ride['route'] as Map : {};
              final fare = pricing['pricePerSeat'] ?? ride['fare'] ?? ride['price'] ?? 0;
              final totalSeats = ride['totalSeats'] ?? 0;
              final availableSeats = ride['availableSeats'] ?? totalSeats;
              final time = (ride['startTime'] ?? ride['time'] ?? _fmtTime(ride['departureTime']?.toString() ?? ride['travelDate']?.toString())).toString();
              final rideId = (ride['_id'] ?? ride['id'] ?? '').toString();
              final driverName = (() {
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
                
                String name = 'Driver';
                if (uObj != null) {
                  final fn = uObj['fullname']?.toString() ?? uObj['name']?.toString() ?? uObj['fullName']?.toString() ?? uObj['displayName']?.toString();
                  if (fn != null && fn.trim().isNotEmpty) {
                    name = fn.trim();
                  } else {
                    final firstName = uObj['first_name']?.toString() ?? uObj['firstName']?.toString() ?? '';
                    final lastName = uObj['last_name']?.toString() ?? uObj['lastName']?.toString() ?? '';
                    if (firstName.isNotEmpty || lastName.isNotEmpty) {
                      name = '$firstName $lastName'.trim();
                    } else {
                      final alt = uObj['username']?.toString() ?? uObj['email']?.toString();
                      if (alt != null && alt.trim().isNotEmpty) name = alt.trim();
                    }
                  }
                }

                final v = (d is Map && d['vehicle'] is Map) ? d['vehicle'] : (ride['vehicle'] is Map ? ride['vehicle'] : {});
                final vName = (v['model'] ?? v['brand'] ?? v['vehicleNumber'] ?? v['plateNumber'] ?? '').toString();
                
                if (vName.isNotEmpty) {
                  return '$name ($vName)';
                }
                return name;
              })();
              final startCity = (route['startCity'] ?? _from).toString();
              final endCity = (route['endCity'] ?? _to).toString();

              return RideCard(
                name: driverName,
                time: time,
                price: fare.toString(),
                seats: '$availableSeats available',
                rating: 4.5,
                isVerified: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/ride_detail',
                    arguments: {
                      'rideId': rideId,
                      'ride': ride,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
