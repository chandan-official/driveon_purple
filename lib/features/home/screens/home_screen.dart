import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';
import '../../rides/widgets/ride_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsive layout
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      // Custom Drawer for Navigation
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header (Profile & Menu)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: AppColors.textDark),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          color: AppColors.textDark,
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=12',
                            ), // Placeholder
                            backgroundColor: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Greeting Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good Morning,",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      "Yashpal Singh",
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Main Action Buttons (Find vs Offer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: "Find a Ride",
                        subtitle: "Travel Cheap",
                        icon: Icons.search,
                        color: AppColors.primaryPurple,
                        onTap: () =>
                            Navigator.pushNamed(context, '/search_ride'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: "Send Parcel",
                        subtitle: "Fast Delivery",
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.secondaryTeal, // Teal for Parcels
                        onTap: () =>
                            Navigator.pushNamed(context, '/send_parcel'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4. "Ongoing Rides" Section (From Case Study)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ongoing Rides",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text("See All")),
                  ],
                ),
              ),

              // 5. Recent Activity List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Mock Data showing the new Card Style
                    RideCard(
                      name: "Rahul Verma",
                      time: "Today, 05:30 PM",
                      price: "450",
                      seats: "2",
                      rating: 4.8,
                      isVerified: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            accountName: const Text(
              "Yashpal Singh",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text("yashpal@example.com"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                "Y",
                style: TextStyle(fontSize: 24, color: AppColors.primaryPurple),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.textDark),
            title: const Text("My Trips"),
            onTap: () => Navigator.pushNamed(context, '/my_trips'),
          ),
          ListTile(
            leading: const Icon(Icons.payment, color: AppColors.textDark),
            title: const Text("Payments"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.drive_eta,
              color: AppColors.primaryPurple,
            ),
            title: const Text(
              "Drive with DriveOn",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close Drawer
              // Logic to switch to Driver Mode
              Navigator.pushNamed(context, '/driver_home');
            },
          ),
        ],
      ),
    );
  }
}
