import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/color_constants.dart';
import '../../../api/api_service.dart';
import '../models/ride_model.dart';

class StartRideScreen extends StatefulWidget {
  const StartRideScreen({super.key});

  @override
  State<StartRideScreen> createState() => _StartRideScreenState();
}

class _StartRideScreenState extends State<StartRideScreen> {
  final ApiService _api = ApiService();
  GoogleMapController? _mapController;

  Ride? _ride;
  LatLng? _pickup;
  LatLng? _drop;
  LatLng? _driverLocation;
  double _bearing = 0;

  BitmapDescriptor? _carIcon;
  Set<Polyline> _polylines = {};
  Set<Marker> _markerSet = {};

  bool _isLoading = true;
  String _errorMsg = '';
  bool _tripStarted = false;
  bool _actionLoading = false;
  bool _locationReady = false;

  StreamSubscription<Position>? _locationSub;

  String get _apiKey => (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '').trim();

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
  }

  Future<void> _loadCustomIcons() async {
    try {
      final Uint8List markerIcon = await _getBytesFromAsset('assets/images/car_icon.png', 120);
      setState(() {
        _carIcon = BitmapDescriptor.fromBytes(markerIcon);
      });
    } catch (e) {
      debugPrint("Error loading car icon: $e");
    }
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    if (_ride == null) {
      _ride = args['ride'] as Ride?;
      if (_ride != null) {
        _initLocation();
      }
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  double _calculateBearing(LatLng startPoint, LatLng endPoint) {
    double lat1 = startPoint.latitude * math.pi / 180;
    double lon1 = startPoint.longitude * math.pi / 180;
    double lat2 = endPoint.latitude * math.pi / 180;
    double lon2 = endPoint.longitude * math.pi / 180;

    double dLon = lon2 - lon1;

    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double radiansBearing = math.atan2(y, x);
    return (radiansBearing * 180 / math.pi + 360) % 360;
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _errorMsg = 'Location permission denied. Enable it in Settings.';
          _isLoading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _driverLocation = LatLng(pos.latitude, pos.longitude);
        _locationReady = true;
      });

      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen((pos) {
        final newLatLng = LatLng(pos.latitude, pos.longitude);
        
        if (_driverLocation != null) {
          double newBearing = _calculateBearing(_driverLocation!, newLatLng);
          // Only update bearing if moving significant distance to avoid jitter
          if (Geolocator.distanceBetween(
            _driverLocation!.latitude, _driverLocation!.longitude,
            newLatLng.latitude, newLatLng.longitude
          ) > 1.0) {
            _bearing = newBearing;
          }
        }

        setState(() {
          _driverLocation = newLatLng;
          _updateDriverMarker(newLatLng);
        });

        if (_tripStarted && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newLatLng,
                zoom: 18,
                tilt: 60,
                bearing: _bearing,
              ),
            ),
          );
        }
      });

      await _geocodeAndRoute();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Location error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _updateDriverMarker(LatLng pos) {
    _markerSet = {
      ..._markerSet.where((m) => m.markerId.value != 'driver'),
      Marker(
        markerId: const MarkerId('driver'),
        position: pos,
        icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        rotation: _bearing,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: const InfoWindow(title: 'Your Location'),
        zIndex: 10,
      ),
    };
  }

  Future<void> _launchNavigation() async {
    if (_ride == null) return;
    final destination = _ride!.route.endCity;
    final url = 'google.navigation:q=${Uri.encodeComponent(destination)}&mode=d';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}';
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch navigation app.')),
        );
      }
    }
  }

  Future<LatLng?> _geocode(String city) async {
    if (_apiKey.isEmpty) return null;
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=${Uri.encodeQueryComponent(city)}'
      '&key=$_apiKey',
    );
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if ((data['status'] as String?) == 'OK') {
        final loc = data['results'][0]['geometry']['location'];
        return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
      }
    } catch (_) {}
    return null;
  }

  Future<List<LatLng>> _fetchPolyline(LatLng origin, LatLng destination) async {
    if (_apiKey.isEmpty) return [];
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&key=$_apiKey',
    );
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if ((data['status'] as String?) == 'OK') {
        final encoded = data['routes'][0]['overview_polyline']['points'] as String;
        return _decodePolyline(encoded);
      }
    } catch (_) {}
    return [];
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    final len = encoded.length;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<void> _geocodeAndRoute() async {
    if (_ride == null) return;
    if (mounted) setState(() { _isLoading = true; _errorMsg = ''; });

    try {
      final pickup = await _geocode(_ride!.route.startCity);
      final drop = await _geocode(_ride!.route.endCity);

      if (pickup == null || drop == null) {
        if (mounted) setState(() { _isLoading = false; _errorMsg = 'Could not locate cities on map.'; });
        return;
      }

      _pickup = pickup;
      _drop = drop;

      final polylinePoints = await _fetchPolyline(pickup, drop);

      final markers = <Marker>{
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Pickup: ${_ride!.route.startCity}'),
        ),
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Destination: ${_ride!.route.endCity}'),
        ),
        if (_driverLocation != null)
          Marker(
            markerId: const MarkerId('driver'),
            position: _driverLocation!,
            icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            rotation: _bearing,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            infoWindow: const InfoWindow(title: 'You'),
            zIndex: 10,
          ),
      };

      if (mounted) {
        setState(() {
          _markerSet = markers;
          _polylines = {
            if (polylinePoints.isNotEmpty)
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylinePoints,
                color: AppColors.primaryPurple,
                width: 6,
                jointType: JointType.round,
              ),
          };
          _isLoading = false;
        });
      }

      _fitBounds(pickup, drop);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMsg = 'Map error: $e'; });
    }
  }

  void _fitBounds(LatLng a, LatLng b) {
    if (_mapController == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(a.latitude, b.latitude),
        math.min(a.longitude, b.longitude),
      ),
      northeast: LatLng(
        math.max(a.latitude, b.latitude),
        math.max(a.longitude, b.longitude),
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pickup != null && _drop != null) _fitBounds(_pickup!, _drop!);
  }

  Future<void> _startTrip() async {
    if (!_locationReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for GPS signal...')),
      );
      return;
    }
    final ride = _ride;
    if (ride == null) return;

    if (mounted) setState(() => _actionLoading = true);
    try {
      await _api.loadToken();
      await _api.updateRideStatus(ride.id, 'ONGOING');
      if (mounted) setState(() { _tripStarted = true; _actionLoading = false; });

      if (_driverLocation != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _driverLocation!,
              zoom: 18,
              tilt: 60,
              bearing: _bearing,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _actionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _endTrip() async {
    final ride = _ride;
    if (ride == null) return;
    if (mounted) setState(() => _actionLoading = true);
    try {
      await _api.updateRideStatus(ride.id, 'COMPLETED');
      _locationSub?.cancel();
      if (mounted) setState(() => _actionLoading = false);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _actionLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          _tripStarted ? 'Navigating...' : 'Ride Overview',
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_tripStarted)
            IconButton(
              icon: const Icon(Icons.navigation_rounded, color: AppColors.primaryPurple),
              onPressed: _launchNavigation,
              tooltip: "Open in Google Maps",
            ),
        ],
      ),
      body: Stack(
        children: [
          // THE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _driverLocation ?? _pickup ?? const LatLng(20.5937, 78.9629),
              zoom: 14,
            ),
            markers: _markerSet,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: _onMapCreated,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            padding: const EdgeInsets.only(bottom: 120),
          ),

          // TOP OVERLAY (Route info)
          if (ride != null && !_tripStarted)
            Positioned(
              top: 10, left: 15, right: 15,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      _locationRow(Icons.my_location, Colors.green, ride.route.startCity),
                      const Divider(),
                      _locationRow(Icons.location_on, Colors.red, ride.route.endCity),
                    ],
                  ),
                ),
              ),
            ),

          // LOADING OVERLAY
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // BOTTOM ACTION PANEL
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_tripStarted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          const Icon(Icons.navigation, color: AppColors.primaryPurple),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Real-time navigation active", style: TextStyle(fontWeight: FontWeight.bold))),
                          TextButton.icon(
                            onPressed: _launchNavigation,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text("Maps"),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: _actionLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _tripStarted ? _endTrip : (_locationReady ? _startTrip : null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _tripStarted ? Colors.red : (_locationReady ? Colors.green : Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text(
                              _tripStarted ? "COMPLETE RIDE" : "START RIDE",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          if (_errorMsg.isNotEmpty)
            Center(child: Container(color: Colors.white, padding: const EdgeInsets.all(10), child: Text(_errorMsg, style: const TextStyle(color: Colors.red)))),
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
