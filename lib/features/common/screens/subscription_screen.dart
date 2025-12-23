import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "DriveOn Gold",
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
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.orangeAccent,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Become a Gold Member",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Save up to ₹5000 per year on outstation trips.",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Choose your plan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Plan 1: Monthly
            _planCard(
              context,
              title: "Monthly Pass",
              price: "₹ 499 / mo",
              benefits: [
                "10% off on all rides",
                "Priority Driver Allocation",
                "Free Cancellation",
              ],
              isPopular: false,
            ),

            // Plan 2: Yearly
            _planCard(
              context,
              title: "Yearly Pro",
              price: "₹ 3,999 / yr",
              benefits: [
                "15% off on all rides",
                "Zero Convenience Fee",
                "Free Cancellation",
                "Dedicated Support",
              ],
              isPopular: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(
    BuildContext context, {
    required String title,
    required String price,
    required List<String> benefits,
    required bool isPopular,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(15),
        border: isPopular
            ? Border.all(color: Colors.orange, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // REMOVED MainAxisSize.min restrictions to let it flow naturally
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    "MOST POPULAR",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            price,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 20),

          // Benefits List (Simple Column)
          Column(
            children: benefits
                .map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ), // Increased spacing for readability
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Aligns icon with top of text
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(b, style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 25), // Guaranteed spacing before button
          // Subscribe Button
          SizedBox(
            width: double.infinity,
            height: 50, // Explicit height
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular
                    ? Colors.orange
                    : AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Subscribed to $title!")),
                );
              },
              child: const Text(
                "Subscribe Now",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
