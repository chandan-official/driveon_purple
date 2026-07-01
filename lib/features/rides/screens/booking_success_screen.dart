import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract arguments passed from PaymentScreen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final rideObj = args['ride'] as Map<String, dynamic>?;
    final int seatsBooked = args['seatsBooked'] as int? ?? 1;
    final int amount = args['amount'] as int? ?? 0;
    final String paymentMode = args['paymentMode'] as String? ?? 'COD';

    // Extracting route locations
    final String from = (rideObj?['from'] ?? rideObj?['route']?['startCity'] ?? 'N/A').toString();
    final String to = (rideObj?['to'] ?? rideObj?['route']?['endCity'] ?? 'N/A').toString();

    // Formatting date and time
    final String travelDateRaw = (rideObj?['travelDate'] ?? 'N/A').toString();
    final String travelDate = _formatDate(travelDateRaw);
    final String startTime = (rideObj?['startTime'] ?? rideObj?['time'] ?? 'N/A').toString();

    // Payment details
    final String paymentMethodText = paymentMode == 'COD' 
        ? 'Pay on Boarding (Cash)' 
        : 'Paid Online (UPI/Card)';

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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // 1. Success Animation / Icon
                  _buildSuccessAnimation(),

                  const SizedBox(height: 24),

                  // 2. Title & Subtitle
                  Text(
                    "Booking Confirmed!",
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your trip has been booked successfully.\nWe've notified the driver of your request.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 3. Ticket Summary Card
                  _buildTicketSummary(
                    from: from,
                    to: to,
                    date: travelDate,
                    time: startTime,
                    seats: seatsBooked,
                    amount: amount,
                    paymentMethod: paymentMethodText,
                  ),

                  const SizedBox(height: 32),

                  // 4. Primary Actions
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                    child: Text(
                      "Back to Home",
                      style: GoogleFonts.inter(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.05),
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
          ),
        ),
        // Main Check Circle
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Colors.green, Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.check,
            size: 36,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketSummary({
    required String from,
    required String to,
    required String date,
    required String time,
    required int seats,
    required int amount,
    required String paymentMethod,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route: Source -> Destination
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Source", style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(from, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                        ],
                      ),
                    ),
                    const Icon(Icons.swap_horiz, color: AppColors.primaryPurple, size: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Destination", style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(to, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                // Date & Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Date", style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Departure Time", style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 28),
                // Booking Specific Details
                _buildSummaryRow("Seats Booked", "$seats seat${seats > 1 ? 's' : ''}"),
                const SizedBox(height: 10),
                _buildSummaryRow("Payment Mode", paymentMethod),
                const SizedBox(height: 10),
                _buildSummaryRow("Total Contribution", "₹${amount.toStringAsFixed(0)}", valueColor: AppColors.primaryPurple),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr == 'N/A' || dateStr.isEmpty) return 'N/A';
    try {
      // Handles 2026-07-01T00:00:00.000Z or similar standard ISO formats
      DateTime dt = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      String day = dt.day.toString().padLeft(2, '0');
      String month = months[dt.month - 1];
      String year = dt.year.toString();
      return "$day $month $year";
    } catch (e) {
      // Fallback parser if DateTime.parse fails
      try {
        final cleanDate = dateStr.split('T')[0];
        final parts = cleanDate.split('-');
        if (parts.length == 3) {
          final year = parts[0];
          final monthInt = int.parse(parts[1]);
          final day = parts[2].padLeft(2, '0');
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return "$day ${months[monthInt - 1]} $year";
        }
      } catch (_) {}
      return dateStr;
    }
  }
}
