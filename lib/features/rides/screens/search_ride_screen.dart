import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';
import '../widgets/horizontal_calendar.dart';
import '../../common/screens/place_picker_field.dart';

class SearchRideScreen extends StatefulWidget {
  const SearchRideScreen({Key? key}) : super(key: key);

  @override
  _SearchRideScreenState createState() => _SearchRideScreenState();
}

class _SearchRideScreenState extends State<SearchRideScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  String _fromAddress = "";
  String _toAddress = "";
  double? _fromLat, _fromLng, _toLat, _toLng;

  int _passengerCount = 1;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  void _searchRides() {
    final from = _fromAddress.isNotEmpty ? _fromAddress : _sourceController.text.trim();
    final to = _toAddress.isNotEmpty ? _toAddress : _destController.text.trim();
    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both source and destination.')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/ride_results',
      arguments: {
        'from': from,
        'to': to,
        'date': DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ).toIso8601String(),
        'seats': _passengerCount,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Find a Ride"),
        centerTitle: true,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Route Inputs — Google Places Autocomplete
            PlacePickerField(
              hintText: "Leaving from...",
              icon: Icons.my_location,
              iconColor: AppColors.primaryPurple,
              onPicked: (place) {
                setState(() {
                  _fromAddress = place.address;
                  _sourceController.text = place.address;
                });
              },
            ),
            const SizedBox(height: 16),
            PlacePickerField(
              hintText: "Going to...",
              icon: Icons.location_on,
              iconColor: AppColors.primaryPurple,
              onPicked: (place) {
                setState(() {
                  _toAddress = place.address;
                  _destController.text = place.address;
                });
              },
            ),

            const SizedBox(height: 32),

            // 2. Horizontal Calendar (Reused Widget)
            HorizontalCalendar(
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),

            const SizedBox(height: 32),

            // 3. Passenger Counter (New Design)
            Text(
              "Passengers",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "How many seats?",
                    style: TextStyle(fontSize: 15, color: AppColors.textGrey),
                  ),
                  Row(
                    children: [
                      _buildCounterBtn(Icons.remove, () {
                        if (_passengerCount > 1)
                          setState(() => _passengerCount--);
                      }),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          "$_passengerCount",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildCounterBtn(Icons.add, () {
                        if (_passengerCount < 5)
                          setState(() => _passengerCount++);
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 4. Search Button (Full Width, Gradient)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _searchRides,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Search Rides",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryPurple),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryPurple),
      ),
    );
  }
}
