import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class SideDrawer extends StatefulWidget {
  const SideDrawer({super.key});

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  // SIMULATION: Set to FALSE so you can test the "Registration Screen"
  bool isRegisteredDriver = false;

  // Helper to check if we are currently on the Driver Screen
  bool _isDriverMode(BuildContext context) {
    return ModalRoute.of(context)?.settings.name == '/driver_home';
  }

  @override
  Widget build(BuildContext context) {
    bool isCurrentlyDriver = _isDriverMode(context);

    return Drawer(
      backgroundColor: AppColors.backgroundLight,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. User Profile Header (Clickable -> Profile)
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              // Change header color based on mode
              color: isCurrentlyDriver
                  ? Colors.black87
                  : AppColors.primaryPurple,
            ),
            accountName: const Text(
              "John Doe",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text("+91 98765 43210"),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundColor: AppColors.backgroundLight,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: isCurrentlyDriver
                      ? Colors.black87
                      : AppColors.primaryPurple,
                ),
              ),
            ),
          ),

          // 2. Role Switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  isCurrentlyDriver ? Icons.person : Icons.drive_eta,
                  color: AppColors.textDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentlyDriver
                            ? "Switch to Rider"
                            : "Switch to Driver",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        isCurrentlyDriver
                            ? "Book a ride"
                            : "Earn money driving",
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                // The Magic Toggle
                Switch(
                  value: isCurrentlyDriver,
                  activeColor: AppColors.primaryGold,
                  onChanged: (val) {
                    Navigator.pop(context); // Close drawer first

                    if (isCurrentlyDriver) {
                      // SWITCH BACK TO RIDER
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      // TRYING TO SWITCH TO DRIVER
                      if (isRegisteredDriver) {
                        // Success: Go to Driver Dashboard
                        Navigator.pushReplacementNamed(context, '/driver_home');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Welcome back, Driver!"),
                          ),
                        );
                      } else {
                        // Fail: Needs Registration -> Navigate to Form
                        Navigator.pushNamed(context, '/driver_registration');
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // 3. Menu Items (Change based on Role)
          if (isCurrentlyDriver) ...[
            _drawerItem(Icons.dashboard, "Dashboard", () {
              Navigator.pop(context);
            }),
            _drawerItem(Icons.history, "Ride History", () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my_trips');
            }),
            _drawerItem(Icons.car_repair, "My Vehicle", () {}),
          ] else ...[
            _drawerItem(Icons.history, "My Trips", () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my_trips');
            }),
            _drawerItem(Icons.local_shipping_outlined, "My Parcels", () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my_trips');
            }),
            _drawerItem(Icons.payment, "Payments", () {}),
          ],

          const Divider(),
          _drawerItem(Icons.settings, "Settings", () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/profile');
          }),
          _drawerItem(Icons.help_outline, "Support", () {}),
          _drawerItem(Icons.logout, "Logout", () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textGrey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
