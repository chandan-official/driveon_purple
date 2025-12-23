import 'package:flutter/material.dart';
import 'dart:async'; // Required for Timer
import '../../../core/constants/color_constants.dart';

class TrackRideScreen extends StatefulWidget {
  const TrackRideScreen({super.key});

  @override
  State<TrackRideScreen> createState() => _TrackRideScreenState();
}

class _TrackRideScreenState extends State<TrackRideScreen> {
  // 0=Accepted, 1=Arriving, 2=On Trip, 3=Trip Completed
  int _currentStep = 1;
  bool _hasParcel = false;

  // 1. SOS / Emergency Logic
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
              Text(
                "EMERGENCY SOS",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Sending alert to Admin & Emergency Contacts with your live location in 3 seconds...",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("SOS ALERT SENT! Help is on the way."),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
              },
              child: const Text(
                "SEND NOW",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // 2. View Driver Profile (FIXED: Overflow Issue)
  void _showDriverProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Needed for dynamic height content
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          // FIXED: Removed fixed height (height: 500)
          child: SingleChildScrollView(
            // FIXED: Added ScrollView to prevent overflow on small screens
            child: Column(
              mainAxisSize: MainAxisSize.min, // FIXED: Wraps content height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.backgroundDark,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Rahul Verma",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 18,
                              color: Colors.amber,
                            ),
                            Text(
                              " 4.8 ",
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "(124 rides)",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Verification Badges
                const Text(
                  "Verification Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _verificationBadge("KYC Verified", true),
                    const SizedBox(width: 15),
                    _verificationBadge("License Verified", true),
                  ],
                ),
                const SizedBox(height: 30),

                // Vehicle Details
                const Text(
                  "Vehicle Details",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.directions_car,
                  "Model",
                  "Toyota Innova (White)",
                ),
                _infoRow(
                  Icons.confirmation_number,
                  "Plate Number",
                  "KA 01 MX 1234",
                ),
                _infoRow(Icons.badge, "Driving License", "DL-1420110012345"),

                // FIXED: Replaced Spacer() with SizedBox because Spacer requires fixed height
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close Profile"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _verificationBadge(String text, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isVerified ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: isVerified ? Colors.green.shade700 : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ... (Helper Functions: _showCancelDialog, _rescheduleRide, _addParcelToBooking, _shareRideDetails) ...
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Cancel Ride?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure? Penalty may apply."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Ride Cancelled.")));
            },
            child: const Text("Confirm Cancel"),
          ),
        ],
      ),
    );
  }

  void _rescheduleRide() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  void _addParcelToBooking() {
    setState(() => _hasParcel = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Parcel Added!")));
  }

  void _shareRideDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Share Ride Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              "Send current location and ETA to your contacts.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareOption(Icons.message, "SMS", Colors.blue),
                _shareOption(Icons.chat, "WhatsApp", Colors.green),
                _shareOption(Icons.copy, "Copy Link", Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Shared via $label")));
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Ride"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'cancel') _showCancelDialog();
              if (value == 'reschedule') _rescheduleRide();
              if (value == 'add_parcel') _addParcelToBooking();
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'reschedule',
                  child: Text("Reschedule Ride"),
                ),
                const PopupMenuItem(
                  value: 'add_parcel',
                  child: Text("Add Parcel"),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text(
                    "Cancel Ride",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,

      // REMOVED FAB: SOS Button is now in the Stack below
      body: Stack(
        children: [
          // 1. Map Background
          Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 80, color: Colors.blue.shade200),
                  const SizedBox(height: 10),
                  const Text(
                    "Live Map View",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      if (_currentStep < 3) _currentStep++;
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                    ),
                    child: Text("Simulate Trip (Stage $_currentStep)"),
                  ),
                ],
              ),
            ),
          ),

          // 2. FIXED: SOS Button (Positioned Top Right on Map - No Overlap)
          if (_currentStep < 3)
            Positioned(
              top: 100,
              right: 20,
              child: GestureDetector(
                onTap: _triggerSOS,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "SOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. ETA Banner
          if (_currentStep < 3)
            Positioned(
              top: 100,
              left: 20, // Moved left to avoid SOS button collision
              right: 120, // Give space for SOS button
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "5 mins away",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.access_time, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),

          // 4. Bottom Panel
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
                                    const Text(
                                      "Rahul Verma",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
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
                                  "Toyota Innova • KA 01 MX 1234",
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
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/chat'),
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
                              onPressed: () {},
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
