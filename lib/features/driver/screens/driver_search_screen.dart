import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/color_constants.dart';
import '../../common/screens/place_picker_field.dart';

class DriverSearchScreen extends StatefulWidget {
  const DriverSearchScreen({super.key});

  @override
  State<DriverSearchScreen> createState() => _DriverSearchScreenState();
}

class _DriverSearchScreenState extends State<DriverSearchScreen> {
  String _pickupAddress = "";
  String _dropAddress = "";
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(20.5937, 78.9629); // India center fallback

  @override
  void initState() {
    super.initState();
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

  void _onPickupSelected(PickedPlace place) {
    setState(() => _pickupAddress = place.address);
  }

  void _onDropSelected(PickedPlace place) {
    setState(() => _dropAddress = place.address);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryPurple,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Where would you like to drop\noff passengers?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PlacePickerField(
                    hintText: "Where is an exact location better?",
                    icon: Icons.search,
                    iconColor: Colors.grey,
                    onPicked: _onPickupSelected,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 12),
                  PlacePickerField(
                    hintText: "e.g. Ntr Circle, Vijayawada",
                    icon: Icons.search,
                    iconColor: Colors.grey,
                    onPicked: _onDropSelected,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                ),
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: AppColors.primaryPurple,
                    onPressed: () {
                      if (_pickupAddress == null || _pickupAddress!.isEmpty ||
                          _dropAddress == null || _dropAddress!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select pickup and drop locations')),
                        );
                        return;
                      }
                      Navigator.pushNamed(context, '/create_ride', arguments: {
                        'pickup': _pickupAddress,
                        'drop': _dropAddress,
                      });
                    },
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
