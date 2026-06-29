import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class DriverRequestScreen extends StatelessWidget {
  const DriverRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          "New Request",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent back button during request
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. Timer / Urgency
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Expires in 00:25",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 2. Earnings Header
            const Text(
              "Expected Earning",
              style: TextStyle(color: AppColors.textGrey),
            ),
            const Text(
              "₹ 850",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 40),

            // 3. Trip Route (Visual)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Pickup
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pickup",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const Text(
                              "Indiranagar, Bangalore",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "3.5 km away",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(),
                  ),

                  // Drop - (Fixed: Removed 'const' because shade600 is not constant)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Drop",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const Text(
                              "Mysore Palace, Mysore",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "145 km Trip",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Request Tags (Passenger)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tag(Icons.person, "1 Passenger"),
              ],
            ),

            const Spacer(),

            // 5. Action Buttons (Accept / Reject)
            Row(
              children: [
                // Reject Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red.shade100),
                      backgroundColor: Colors.red.shade50,
                    ),
                    child: Text(
                      "Reject",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Accept Button - UPDATED
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 1. Show message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("You accepted the ride!")),
                      );

                      // 2. Navigate to Active Trip (Replace current screen)
                      Navigator.pushReplacementNamed(
                        context,
                        '/driver_active_trip',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Accept Ride",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
