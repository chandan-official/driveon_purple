import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  // Trip Stages: 0 = Heading to Pickup, 1 = On the way to Drop, 2 = Completed
  int _tripStage = 0;

  String get _buttonLabel {
    if (_tripStage == 0) return "Arrived at Pickup";
    if (_tripStage == 1) return "Complete Trip";
    return "Trip Finished";
  }

  Color get _buttonColor {
    if (_tripStage == 0) return AppColors.primaryPurple;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. The Map Background (Full Screen)
      body: Stack(
        children: [
          Container(
            color: Colors.grey.shade300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation, size: 80, color: Colors.blue.shade700),
                  const SizedBox(height: 10),
                  const Text(
                    "Turn Right in 200m",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 2. Top Header (Navigation Instructions)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.turn_right, color: Colors.white, size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "200 m",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _tripStage == 0
                              ? "Heading to Indiranagar (Pickup)"
                              : "Heading to Mysore (Drop)",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Action Sheet (Customer Info & Controls)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer Profile
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.backgroundDark,
                        child: Icon(Icons.person, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rahul Verma",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const Text(
                                  " 4.8",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Call Button
                      CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),

                  // Action Button (Changes based on stage)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          if (_tripStage == 0) {
                            _tripStage = 1; // Picked up -> Going to Drop
                          } else if (_tripStage == 1) {
                            // Trip Done -> Go back to Home
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/driver_home',
                              (route) => false,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Trip Completed! ₹850 Added to Wallet.",
                                ),
                              ),
                            );
                          }
                        });
                      },
                      child: Text(
                        _buttonLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
