import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../widgets/ride_card.dart';

class RideResultsScreen extends StatelessWidget {
  const RideResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock Data for Production Testing
    final List<Map<String, dynamic>> rides = [
      {
        "name": "Yashpal Singh",
        "time": "08:30 AM",
        "price": "450",
        "seats": "2",
        "rating": 4.9,
        "verified": true,
      },
      {
        "name": "Rahul Verma",
        "time": "10:00 AM",
        "price": "400",
        "seats": "3",
        "rating": 4.5,
        "verified": false,
      },
      {
        "name": "Priya Sharma",
        "time": "02:00 PM",
        "price": "550",
        "seats": "1",
        "rating": 5.0,
        "verified": true,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark, // Light Grey BG for contrast
      appBar: AppBar(
        title: Column(
          children: const [
            Text("Available Rides", style: TextStyle(fontSize: 16)),
            Text(
              "Bhopal → Indore • Today",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return RideCard(
            name: ride['name'],
            time: ride['time'],
            price: ride['price'],
            seats: ride['seats'],
            rating: ride['rating'],
            isVerified: ride['verified'],
            onTap: () {
              Navigator.pushNamed(context, '/ride_detail');
            },
          );
        },
      ),
    );
  }
}
