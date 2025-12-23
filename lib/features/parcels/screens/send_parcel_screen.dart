import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class SendParcelScreen extends StatefulWidget {
  const SendParcelScreen({super.key});

  @override
  State<SendParcelScreen> createState() => _SendParcelScreenState();
}

class _SendParcelScreenState extends State<SendParcelScreen> {
  double _weight = 1.0;
  String _selectedType = "Box";
  bool _isAgencyHandled = false; // Toggle for Handling Type

  // Controllers
  final _lController = TextEditingController();
  final _wController = TextEditingController();
  final _hController = TextEditingController();
  final _instructionsController = TextEditingController();

  final List<Map<String, dynamic>> _parcelTypes = [
    {"icon": Icons.inventory_2_outlined, "label": "Box"},
    {"icon": Icons.description_outlined, "label": "Documents"},
    {"icon": Icons.shopping_bag_outlined, "label": "Bag"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          "Send Parcel",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            // 1. Parcel Type
            const Text(
              "What are you sending?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _parcelTypes
                  .map((type) => _typeCard(type['icon'], type['label']))
                  .toList(),
            ),
            const SizedBox(height: 30),

            // 2. Weight Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Weight (kg)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${_weight.toStringAsFixed(1)} kg",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
            Slider(
              value: _weight,
              min: 0.5,
              max: 20.0,
              divisions: 39,
              activeColor: AppColors.primaryPurple,
              onChanged: (val) => setState(() => _weight = val),
            ),

            const SizedBox(height: 20),

            // 3. Dimensions (L x W x H)
            const Text(
              "Dimensions (cm)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _dimField("L", _lController),
                const SizedBox(width: 10),
                _dimField("W", _wController),
                const SizedBox(width: 10),
                _dimField("H", _hController),
              ],
            ),

            const SizedBox(height: 30),

            // 4. Handling Preference (Driver vs Agency)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Handling Preference",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryPurple,
                    title: Text(
                      _isAgencyHandled
                          ? "Agency Handled (Secure)"
                          : "Driver Handled (Express)",
                    ),
                    subtitle: Text(
                      _isAgencyHandled
                          ? "Handled by verified agency partners. Best for high-value items."
                          : "Direct delivery by driver. Faster but standard handling.",
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _isAgencyHandled,
                    onChanged: (val) => setState(() => _isAgencyHandled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 5. Instructions
            const Text(
              "Pickup / Delivery Instructions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _instructionsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "E.g. Call before arrival, Handle with care...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.backgroundDark,
              ),
            ),

            const SizedBox(height: 40),

            // Find Partner Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Simulate Search -> Go directly to Tracking (skipping payment for demo speed)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Searching for delivery partner..."),
                    ),
                  );
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.pushNamed(context, '/parcel_tracking');
                  });
                },
                child: const Text(
                  "Find Delivery Partner",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dimField(String label, TextEditingController controller) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: AppColors.backgroundDark,
        ),
      ),
    );
  }

  Widget _typeCard(IconData icon, String label) {
    bool isSelected = _selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = label),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple
              : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textDark),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
