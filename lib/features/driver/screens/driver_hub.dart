import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import 'driver_home_screen.dart';
import 'create_ride_screen.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/screens/chat_inbox_screen.dart';
import 'driver_search_screen.dart';

class DriverHub extends StatefulWidget {
  static final ValueNotifier<int> tabNotifier = ValueNotifier(0);

  const DriverHub({super.key});

  @override
  State<DriverHub> createState() => _DriverHubState();
}

class _DriverHubState extends State<DriverHub> {
  int _currentIndex = 0; // Default to Search as per Image 1

  final List<Widget> _screens = [
    const DriverSearchScreen(),
    const DriverHomeScreen(),
    const ChatInboxScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    DriverHub.tabNotifier.addListener(_onTabNotified);
  }

  @override
  void dispose() {
    DriverHub.tabNotifier.removeListener(_onTabNotified);
    super.dispose();
  }

  void _onTabNotified() {
    if (mounted) {
      setState(() {
        _currentIndex = DriverHub.tabNotifier.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryPurple,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), label: "Rides"),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Inbox"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "$title Screen Coming Soon",
              style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
