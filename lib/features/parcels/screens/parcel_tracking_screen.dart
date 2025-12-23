import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class ParcelTrackingScreen extends StatefulWidget {
  const ParcelTrackingScreen({super.key});

  @override
  State<ParcelTrackingScreen> createState() => _ParcelTrackingScreenState();
}

class _ParcelTrackingScreenState extends State<ParcelTrackingScreen> {
  int _currentStep = 1; // 0=Pickup, 1=In Transit, 2=Delivered

  void _showPOD() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Proof of Delivery"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ), // Placeholder for POD Image
            ),
            const SizedBox(height: 10),
            const Text(
              "Received by: Ravi Kumar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text("Signed at: 10:45 AM"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Parcel"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Status Icon
            const Icon(
              Icons.local_shipping,
              size: 80,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(height: 10),
            Text(
              _currentStep == 2 ? "Parcel Delivered" : "In Transit",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Est. Delivery: Today, 2:00 PM",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // Timeline
            _timelineStep("Picked up", true, true),
            _timelineStep("In Transit", _currentStep >= 1, true),
            _timelineStep("Out for Delivery", _currentStep >= 1, true),
            _timelineStep("Delivered", _currentStep >= 2, false),

            const Spacer(),

            // Simulation Button (For Testing)
            if (_currentStep < 2)
              ElevatedButton(
                onPressed: () => setState(() => _currentStep++),
                child: const Text("Simulate Progress"),
              ),

            // View POD Button (Only when delivered)
            if (_currentStep == 2)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text("View Proof of Delivery (POD)"),
                  onPressed: _showPOD,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timelineStep(String title, bool isActive, bool showLine) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              Icons.check_circle,
              color: isActive ? AppColors.primaryPurple : Colors.grey.shade300,
            ),
            if (showLine)
              Container(
                height: 40,
                width: 2,
                color: isActive
                    ? AppColors.primaryPurple
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 15),
        Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.textDark : Colors.grey,
          ),
        ),
      ],
    );
  }
}
