import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';
import '../../rides/widgets/ride_card.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: const Text("My Activity"),
          centerTitle: true,
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primaryPurple,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Upcoming"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Upcoming Rides
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader("Today"),
                RideCard(
                  name: "Rahul Verma",
                  time: "05:30 PM",
                  price: "450",
                  seats: "1",
                  rating: 4.8,
                  isVerified: true,
                  onTap: () => Navigator.pushNamed(context, '/ride_detail'),
                ),
                _buildSectionHeader("Tomorrow"),
                RideCard(
                  name: "Priya Sharma",
                  time: "09:00 AM",
                  price: "500",
                  seats: "2",
                  rating: 5.0,
                  isVerified: true,
                  onTap: () => Navigator.pushNamed(context, '/ride_detail'),
                ),
              ],
            ),

            // Tab 2: Completed Rides
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader("Last Week"),
                // We can use the same card, or a slightly "dimmed" version for history
                RideCard(
                  name: "Amit Patel",
                  time: "Completed • 12 Oct",
                  price: "420",
                  seats: "1",
                  rating: 4.6,
                  isVerified: false,
                  onTap: () {}, // History details
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}
