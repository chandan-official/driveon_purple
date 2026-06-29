import 'package:flutter/material.dart';
import 'dart:async'; // Required for Timer
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';
import '../../common/screens/chat_screen.dart';

class TrackRideScreen extends StatefulWidget {
  const TrackRideScreen({super.key});

  @override
  State<TrackRideScreen> createState() => _TrackRideScreenState();
}

class _TrackRideScreenState extends State<TrackRideScreen> {
  final ApiService _api = ApiService();
  // 0=Accepted, 1=Arriving, 2=On Trip, 3=Trip Completed
  int _currentStep = 1;
  Map<String, dynamic>? _rideData;
  String _driverName = "Loading driver...";
  String _driverPhone = "";
  String _vehicleInfo = "Vehicle info not available";
  bool _isFetching = false;
  String? _rideId;
  String? _bookingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final r = args['ride'] as Map<String, dynamic>?;
      final b = args['booking'] as Map<String, dynamic>?;
      _rideData = (b != null && b['rideId'] is Map) 
          ? (b['rideId'] as Map<String, dynamic>) 
          : r;
      
      _rideId = (args['rideId'] ?? 
                 (r != null ? (r['_id'] ?? r['id']) : null) ?? 
                 (b != null ? (b['rideId'] is String ? b['rideId'] : (b['rideId'] is Map ? (b['rideId']['_id'] ?? b['rideId']['id']) : null)) : null)
                )?.toString();

      _bookingId = b?['_id']?.toString() ?? args['bookingId']?.toString();

      if (b != null && b['rideId'] is Map) {
        final rideObj = b['rideId'] as Map;
        final driverObj = rideObj['driverId'];
        if (driverObj is Map) {
          final userObj = driverObj['userId'];
          if (userObj is Map) {
            final name = (userObj['fullname'] ?? userObj['name'])?.toString();
            if (name != null && name.isNotEmpty) {
              _driverName = name;
            }
            final phone = (userObj['phone'] ?? userObj['mobile'])?.toString();
            if (phone != null && phone.isNotEmpty) {
              _driverPhone = phone;
            }
          }
        }
      }

      if (_rideData != null) {
        _updateLocalData(_rideData!);
      }

      if (_rideId != null && (_driverName == 'Loading driver...' || _driverName.isEmpty)) {
        _refreshRideData();
      }
    }
  }

  void _updateLocalData(Map<String, dynamic> ride) {
    setState(() {
      final driver = ride['driverId'] is Map 
          ? ride['driverId'] 
          : (ride['driver'] is Map ? ride['driver'] : null);

      if (driver is Map) {
        final userObj = driver['userId'] is Map 
            ? driver['userId'] 
            : (driver['user'] is Map ? driver['user'] : null);
        if (userObj != null) {
          _driverName = (userObj['fullname'] ?? userObj['name'] ?? _driverName).toString();
          _driverPhone = (userObj['phone'] ?? userObj['mobile'] ?? _driverPhone).toString();
        } else {
          final directName = driver['fullname'] ?? driver['name'];
          if (directName != null) _driverName = directName.toString();
          final directPhone = driver['phone'] ?? driver['mobile'];
          if (directPhone != null) _driverPhone = directPhone.toString();
        }
      }

      final vehicle = ride['vehicle'] is Map 
          ? ride['vehicle'] 
          : (ride['vehicleId'] is Map 
             ? ride['vehicleId'] 
             : (driver is Map && driver['vehicle'] is Map ? driver['vehicle'] : null));
          
      if (vehicle is Map) {
        _vehicleInfo = "${vehicle['model'] ?? 'Car'} • ${vehicle['plateNumber'] ?? vehicle['regNo'] ?? vehicle['vehicleNumber'] ?? 'N/A'}";
      }
    });
  }

  Future<void> _refreshRideData() async {
    if (_rideId == null || _isFetching) return;
    setState(() => _isFetching = true);
    try {
      await _api.loadToken();
      final res = await _api.getRideById(_rideId!);
      Map<String, dynamic>? freshRide;
      if (res is Map && res['data'] is Map) {
        freshRide = (res['data'] as Map).cast<String, dynamic>();
      } else if (res is Map) {
        freshRide = res.cast<String, dynamic>();
      }
      
      if (freshRide != null && mounted) {
        _updateLocalData(freshRide);
      }
    } catch (e) {
      debugPrint("Fail-safe fetch failed: $e");
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade50,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text("EMERGENCY SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("Sending alert to Admin & Emergency Contacts with your live location in 3 seconds...", style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SOS ALERT SENT! Help is on the way."), backgroundColor: Colors.red));
              },
              child: const Text("SEND NOW", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDriverProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const CircleAvatar(radius: 40, backgroundColor: AppColors.backgroundDark, child: Icon(Icons.person, size: 50, color: AppColors.textDark)),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_driverName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 18, color: Colors.amber),
                            Text(" 4.8 ", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _infoRow(Icons.directions_car, "Vehicle Details", _vehicleInfo),
                _infoRow(Icons.phone, "Phone", _driverPhone),
                const SizedBox(height: 30),
                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Close Profile"))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }



  void _shareRideDetails() async {
    final link = 'https://drivenon.app/track/$_rideId';
    await SharePlus.instance.share(ShareParams(text: 'Track my ride live on DrivenOn: $link'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Ride"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: LatLng(26.8627, 75.0392), zoom: 12),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          Positioned(
            top: 100,
            right: 20,
            child: GestureDetector(
              onTap: _triggerSOS,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))]),
                child: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20), SizedBox(width: 8), Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Driver Info & Profile Link
                  GestureDetector(
                    onTap: _showDriverProfile,
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _driverName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.blue.shade600,
                                      ),
                                    ],
                                  ),
                                Text(
                                  _vehicleInfo,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Chat/Call Buttons
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                color: AppColors.primaryPurple,
                                size: 20,
                              ),
                              onPressed: () {
                                if (_bookingId != null && _bookingId!.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        bookingId: _bookingId!,
                                        otherPersonName: _driverName,
                                        otherPersonRole: "Driver",
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Chat not available for this booking.")),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            backgroundColor: Colors.green.shade50,
                            child: IconButton(
                              icon: const Icon(
                                Icons.phone,
                                color: Colors.green,
                                size: 20,
                              ),
                              onPressed: () async {
                                if (_driverPhone.isNotEmpty) {
                                  final Uri launchUri = Uri(
                                    scheme: 'tel',
                                    path: _driverPhone,
                                  );
                                  if (await canLaunchUrl(launchUri)) {
                                    await launchUrl(launchUri);
                                  } else {
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch phone dialer")));
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Driver phone number not available")));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status & Actions
                  if (_currentStep < 3)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentStep == 1 ? "Driver Arriving" : "On Trip",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  if (_currentStep == 3) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/payment'),
                        child: const Text("Proceed to Pay"),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text("Share Trip with Contacts"),
                        onPressed: _shareRideDetails,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
