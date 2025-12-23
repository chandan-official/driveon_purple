import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Filter States
  double _priceRange = 1500;
  String _selectedTime = "Any";
  String _selectedVehicle = "Any";
  String _rideType = "Pooled"; // SRS Requirement: Pooled vs Full

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content height
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filter Rides",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),

          // 1. Ride Type (SRS Requirement: Pooled vs Full)
          const Text(
            "Ride Type",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _choiceChip(
                "Pooled (Per Seat)",
                _rideType == "Pooled",
                (val) => setState(() => _rideType = "Pooled"),
              ),
              const SizedBox(width: 10),
              _choiceChip(
                "Full Car (Private)",
                _rideType == "Full",
                (val) => setState(() => _rideType = "Full"),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Price Range Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Max Price",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "₹ ${_priceRange.toInt()}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          Slider(
            value: _priceRange,
            min: 100,
            max: 5000,
            divisions: 49,
            activeColor: AppColors.primaryPurple,
            onChanged: (val) => setState(() => _priceRange = val),
          ),
          const SizedBox(height: 10),

          // 3. Departure Time
          const Text(
            "Departure Time",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              _choiceChip(
                "Morning (6-12)",
                _selectedTime == "Morning",
                (_) => setState(() => _selectedTime = "Morning"),
              ),
              _choiceChip(
                "Afternoon (12-6)",
                _selectedTime == "Afternoon",
                (_) => setState(() => _selectedTime = "Afternoon"),
              ),
              _choiceChip(
                "Evening (6+)",
                _selectedTime == "Evening",
                (_) => setState(() => _selectedTime = "Evening"),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Vehicle Type
          const Text(
            "Vehicle Type",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              _choiceChip(
                "Sedan",
                _selectedVehicle == "Sedan",
                (_) => setState(() => _selectedVehicle = "Sedan"),
              ),
              _choiceChip(
                "SUV",
                _selectedVehicle == "SUV",
                (_) => setState(() => _selectedVehicle = "SUV"),
              ),
              _choiceChip(
                "Hatchback",
                _selectedVehicle == "Hatchback",
                (_) => setState(() => _selectedVehicle = "Hatchback"),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Here you would pass these filters back to the list to sort/hide items
              },
              child: const Text("Apply Filters"),
            ),
          ),
          const SizedBox(height: 10), // Safe area buffer
        ],
      ),
    );
  }

  Widget _choiceChip(String label, bool isSelected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primaryPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppColors.backgroundDark,
    );
  }
}
