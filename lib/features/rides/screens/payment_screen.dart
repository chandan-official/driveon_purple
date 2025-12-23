import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0; // 0=UPI, 1=Card, 2=Cash
  bool _splitFare = false;

  final List<Map<String, dynamic>> _methods = [
    {"icon": Icons.qr_code_scanner, "name": "UPI / GPay / PhonePe"},
    {"icon": Icons.credit_card, "name": "Credit / Debit Card"},
    {"icon": Icons.money, "name": "Pay on Boarding (Cash)"},
  ];

  void _showCancellationPolicy() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cancellation & Refund Policy",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _policyItem(
                "• Free cancellation up to 6 hours before departure.",
              ),
              _policyItem("• 50% refund if cancelled between 2-6 hours."),
              _policyItem(
                "• No refund if cancelled within 2 hours of departure.",
              ),
              _policyItem("• Full refund if the driver cancels the trip."),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("I Understand"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _policyItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          "Payment",
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
      // LAYOUT STRUCTURE: Scrollable Top + Pinned Bottom
      body: Column(
        children: [
          // 1. SCROLLABLE CONTENT (Top Section)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NEW: Promo Code Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer, color: Colors.orange),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Enter Promo Code",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Promo Code Applied! ₹50 Discount.",
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "APPLY",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount Header
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Total Payable",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "₹ 1,095",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Split Fare Option
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primaryPurple,
                      title: const Row(
                        children: [
                          Icon(
                            Icons.call_split,
                            size: 20,
                            color: AppColors.primaryPurple,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Split Fare",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        "Share cost with co-riders via link",
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _splitFare,
                      onChanged: (val) {
                        setState(() => _splitFare = val);
                        if (val) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "A split link will be generated after booking.",
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Payment Methods List
                  const Text(
                    "Select Payment Method",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 15),
                  ...List.generate(_methods.length, (index) {
                    bool isSelected = _selectedMethod == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMethod = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryPurple.withOpacity(0.05)
                              : AppColors.backgroundLight,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryPurple
                                : Colors.grey.shade200,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _methods[index]['icon'],
                              color: isSelected
                                  ? AppColors.primaryPurple
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              _methods[index]['name'],
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primaryPurple
                                    : AppColors.textDark,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryPurple,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 2. PINNED BOTTOM SECTION (Policy + Button)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cancellation Policy Link
                GestureDetector(
                  onTap: _showCancellationPolicy,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Text(
                      "Read Cancellation & Refund Policy",
                      style: TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Payment Successful!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Navigate to Rating Screen (Replace so user can't go back)
                      Navigator.pushReplacementNamed(context, '/rating');
                    },
                    child: Text(
                      _selectedMethod == 2
                          ? "Confirm Cash Payment"
                          : "Pay ₹ 1,095",
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
        ],
      ),
    );
  }
}
