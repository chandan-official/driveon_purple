import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';

// ========================= PAYMENT SCREEN =========================

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _api = ApiService();
  late Razorpay _razorpay;

  int _selectedMethod = 0; // 0=UPI, 1=Card, 2=Cash
  bool _isSubmitting = false;

  String _rideId = '';
  Map<String, dynamic>? _rideObj;
  int _seatsBooked = 1;
  int _amount = 0;
  bool _parsedArgs = false;
  String? _pendingBookingId;
  String? _userEmail;
  String? _userPhone;
  bool _agreeToCostContribution = false;


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
              _policyItem("• Free cancellation up to 6 hours before departure."),
              _policyItem("• 50% refund if cancelled between 2-6 hours."),
              _policyItem("• No refund if cancelled within 2 hours of departure."),
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
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      await _api.loadToken();
      final res = await _api.getUserProfile();
      if (res is Map && res['data'] is Map) {
        final data = res['data'];
        setState(() {
          _userEmail = data['email']?.toString();
          _userPhone = data['phone']?.toString();
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch user data for prefill: $e");
    } finally {

    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      if (_pendingBookingId != null) {
        await _api.verifyPayment(
          bookingId: _pendingBookingId!,
          razorpayOrderId: response.orderId ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        );
      }
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.pushReplacementNamed(
        context, 
        '/booking_success',
        arguments: {
          'ride': _rideObj,
          'seatsBooked': _seatsBooked,
          'amount': _amount,
          'paymentMode': 'ONLINE',
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment verification failed: $e')));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: ${response.message}')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('External Wallet Selected: ${response.walletName}')));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parsedArgs) return;
    _parsedArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _rideId = (args['rideId'] ?? '').toString();
      _rideObj = args['ride'] as Map<String, dynamic>?; // Capture the full ride object
      _seatsBooked = args['seatsRequired'] is int
          ? args['seatsRequired'] as int
          : int.tryParse('${args['seatsRequired']}') ?? 1;
      _amount = args['amount'] is int
          ? args['amount'] as int
          : int.tryParse('${args['amount']}') ?? 0;
    }
  }

  Future<void> _confirmBooking() async {
    if (_rideId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride ID missing. Please select ride again.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.loadToken();
      final isCod = _selectedMethod == 2;
      final paymentMode = isCod ? 'COD' : 'ONLINE';

      // Primary booking endpoint from docs.
      final bookingRes = await _api.createBooking(
        rideId: _rideId,
        seatsBooked: _seatsBooked,
        paymentMode: paymentMode,
      );

      final bookingData = bookingRes['data'] ?? {};
      final bookingId = (bookingData['_id'] ?? bookingData['id'] ?? '').toString();

      if (isCod) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context, 
          '/booking_success',
          arguments: {
            'ride': _rideObj,
            'seatsBooked': _seatsBooked,
            'amount': _amount,
            'paymentMode': 'COD',
          },
        );
      } else {
        _pendingBookingId = bookingId;
        final orderRes = await _api.createPaymentOrder(bookingId);
        
        final order = orderRes['order'];
        final options = {
          'key': orderRes['razorpayKeyId'],
          'amount': order['amount'],
          'name': 'Ryndo',
          'description': 'Ride Booking Payment',
          'order_id': order['id'],
          'prefill': {
            'contact': _userPhone ?? '',
            'email': _userEmail ?? ''
          }
        };

        _razorpay.open(options);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      String friendlyMessage = e.message;
      if (e.message.contains('E11000')) {
        friendlyMessage = "You have already booked this ride!";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          backgroundColor: friendlyMessage.contains('already booked') ? Colors.orange : Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      setState(() => _isSubmitting = false);
    }
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promo Code Section
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
                                content: Text("Promo Code Applied! ₹50 Discount."),
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
                          "Total Cost Contribution",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "₹ $_amount",
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

                  // Payment Methods List
                  const Text(
                    "Select Payment Method",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 15),
                  ...List.generate(_methods.length, (index) {
                    final isSelected = _selectedMethod == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMethod = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryPurple.withValues(alpha: 0.05)
                              : AppColors.backgroundLight,
                          border: Border.all(
                            color: isSelected ? AppColors.primaryPurple : Colors.grey.shade200,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _methods[index]['icon'] as IconData,
                              color: isSelected ? AppColors.primaryPurple : Colors.grey,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              _methods[index]['name'] as String,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primaryPurple : AppColors.textDark,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.primaryPurple),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Pinned Bottom Section
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
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToCostContribution,
                      onChanged: (val) {
                        setState(() {
                          _agreeToCostContribution = val ?? false;
                        });
                      },
                      activeColor: AppColors.primaryPurple,
                    ),
                    const Expanded(
                      child: Text(
                        "It is a cost contribution but not Fare",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isSubmitting || !_agreeToCostContribution) ? Colors.grey : AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (_isSubmitting || !_agreeToCostContribution) ? null : _confirmBooking,
                    child: Text(
                      _isSubmitting
                          ? 'Processing...'
                          : (_selectedMethod == 2 ? "Confirm Cash Contribution" : "Contribute ₹ $_amount"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

// =================== DUMMY PAYMENT PAGE (Hard-coded) ===================

class DummyPaymentProcessingScreen extends StatefulWidget {
  final int amount;
  final String methodName;
  final String rideId;
  final bool isCash;

  const DummyPaymentProcessingScreen({
    super.key,
    required this.amount,
    required this.methodName,
    required this.isCash,
    required this.rideId,
  });

  @override
  State<DummyPaymentProcessingScreen> createState() => _DummyPaymentProcessingScreenState();
}

class _DummyPaymentProcessingScreenState extends State<DummyPaymentProcessingScreen> {
  int _step = 0; // 0=initiated,1=processing,2=success
  late final List<_TxnLine> _timeline;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _timeline = [
      _TxnLine("Initiated", "Creating payment request", now),
      _TxnLine("Processing", widget.isCash ? "Confirming cash booking" : "Contacting bank / UPI network",
          now.add(const Duration(seconds: 2))),
      _TxnLine("Authorized", widget.isCash ? "Cash to be collected on boarding" : "Payment authorized",
          now.add(const Duration(seconds: 4))),
      _TxnLine("Completed", widget.isCash ? "Cash payment marked as pending" : "Payment successful",
          now.add(const Duration(seconds: 6))),
    ];

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _step = 1);
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _step = 2);
    });
  }

  String get _statusText {
    if (_step == 0) return "Initiating…";
    if (_step == 1) return widget.isCash ? "Confirming cash booking…" : "Processing payment…";
    return widget.isCash ? "Cash payment confirmed" : "Payment successful";
  }

  IconData get _statusIcon => _step < 2 ? Icons.hourglass_top : Icons.check_circle;
  Color get _statusColor => _step < 2 ? Colors.orange : Colors.green;

  String _fakeTxnId() => "TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";

  @override
  Widget build(BuildContext context) {
    final txnId = _fakeTxnId();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          "Payment Status",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(_statusIcon, color: _statusColor, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          "Method: ${widget.methodName}",
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Transaction ID: $txnId",
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Amount", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        "₹ ${widget.amount}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Timeline (dummy transactions)
            Expanded(
              child: ListView.builder(
                itemCount: _timeline.length,
                itemBuilder: (context, i) {
                  final item = _timeline[i];
                  final done = _step == 2 || (i <= 1 && _step == 1) || i == 0;
                  final color = done ? Colors.green : Colors.grey.shade400;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        Text(_fmtTime(item.time), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_step < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Still processing… please wait.")),
                    );
                    return;
                  }
                  Navigator.pushReplacementNamed(context, '/rating');
                },
                child: Text(
                  _step < 2 ? "Processing…" : "Continue",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }
}

class _TxnLine {
  final String title;
  final String subtitle;
  final DateTime time;

  _TxnLine(this.title, this.subtitle, this.time);
}
