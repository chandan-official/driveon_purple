import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green.withOpacity(0.05),
                    AppColors.backgroundLight,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // 1. Success Animation / Icon
                  _buildSuccessAnimation(),

                  const SizedBox(height: 32),

                  // 2. Title & Subtitle
                  Text(
                    "Booking Confirmed!",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Your trip has been booked successfully.\nWe've notified the driver of your request.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 3. Ticket Summary Card
                  _buildTicketSummary(),

                  const SizedBox(height: 50),

                  // 4. Primary Actions
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final args = ModalRoute.of(context)?.settings.arguments;
                        Navigator.pushReplacementNamed(
                          context, 
                          '/track_ride',
                          arguments: args, // Pass along the ride/booking info
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: AppColors.primaryPurple.withOpacity(0.4),
                      ),
                      child: const Text(
                        "Track My Ride",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                    child: Text(
                      "Back to Home",
                      style: GoogleFonts.inter(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

  Widget _buildSuccessAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Rings
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.05),
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
          ),
        ),
        // Main Check Circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.green, Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.check,
            size: 40,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSummaryRow("Trip Type", "Intercity Share"),
                const Divider(height: 32),
                _buildSummaryRow("Status", "Driver Notified", valueColor: Colors.green.shade700),
                const Divider(height: 32),
                _buildSummaryRow("Confirmation", "Instant Confirm"),
              ],
            ),
          ),
          // Dashed Line Simulation
          Row(
            children: List.generate(
              30,
              (index) => Expanded(
                child: Container(
                  height: 1,
                  color: index % 2 == 0 ? Colors.grey.withOpacity(0.3) : Colors.transparent,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Driver info is available in Track Ride",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
