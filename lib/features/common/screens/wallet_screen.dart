import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _api = ApiService();
  late Razorpay _razorpay;

  bool _isLoading = true;
  double _walletBalance = 0.0;
  List<dynamic> _transactions = [];
  String? _errorMessage;
  String? _userEmail;
  String? _userPhone;

  double _pendingTopupAmount = 0.0;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchWalletDetails();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchWalletDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _api.loadToken();
      final res = await _api.getWalletDetails();

      if (res is Map && res['success'] == true && res['data'] != null) {
        final data = res['data'];
        setState(() {
          _walletBalance = (data['walletBalance'] ?? 0.0).toDouble();
          _transactions = data['transactions'] ?? [];
        });
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Failed to load wallet');
      }

      try {
        final profileRes = await _api.getUserProfile();
        if (profileRes is Map && profileRes['data'] is Map) {
          final pData = profileRes['data'];
          _userEmail = pData['email']?.toString();
          _userPhone = pData['phone']?.toString();
        }
      } catch (_) {}
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verifyRes = await _api.verifyWalletTopupPayment(
        amount: _pendingTopupAmount,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (!mounted) return;
      if (verifyRes['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet topped up via Razorpay! ✅')),
        );
        _fetchWalletDetails();
      } else {
        throw verifyRes['message'] ?? 'Verification failed';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}')),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
      );
    }
  }

  void _showTopupDialog() {
    final TextEditingController amountController = TextEditingController(text: "500");
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Top Up Wallet 💳", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select or enter amount to process Razorpay checkout."),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  labelText: "Top Up Amount",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [100, 200, 500, 1000].map((amt) {
                  return ChoiceChip(
                    label: Text("₹$amt"),
                    selected: amountController.text == amt.toString(),
                    onSelected: (selected) {
                      setDialogState(() {
                        amountController.text = amt.toString();
                      });
                    },
                    selectedColor: AppColors.primaryPurple.withOpacity(0.2),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(this.context);
                      final double? val = double.tryParse(amountController.text);
                      if (val == null || val <= 0) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text("Enter a valid amount")),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      dynamic orderRes;
                      try {
                        orderRes = await _api.createWalletTopupOrder(val);
                      } catch (err) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text("Payment setup failed: $err")),
                          );
                        }
                        return;
                      }

                      if (!mounted) return;
                      Navigator.pop(ctx);

                      _pendingTopupAmount = val;
                      setState(() => _isProcessingPayment = true);

                      try {
                        final order = orderRes['order'];
                        final keyId = orderRes['razorpayKeyId'] ?? orderRes['keyId'] ?? orderRes['key'];
                        final String orderId = order?['id']?.toString() ?? '';

                        if (order != null && keyId != null && keyId.toString().isNotEmpty && !orderId.startsWith('order_sim_')) {
                          final options = {
                            'key': keyId.toString(),
                            'amount': order['amount'],
                            'name': 'DriveOn',
                            'description': 'Add ₹$val to DriveOn Wallet',
                            'order_id': orderId,
                            'prefill': {
                              'contact': _userPhone ?? '',
                              'email': _userEmail ?? '',
                            },
                          };
                          _razorpay.open(options);
                        } else if (orderRes['isFallback'] == true || orderId.startsWith('order_sim_')) {
                          // Backend is in simulation/fallback mode
                          await _api.verifyWalletTopupPayment(
                            amount: val,
                            razorpayOrderId: orderId,
                            razorpayPaymentId: 'pay_sim_${DateTime.now().millisecondsSinceEpoch}',
                            razorpaySignature: 'simulated',
                            isFallback: true,
                          );
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text("Wallet topped up (Backend Simulator Mode)! ✅")),
                          );
                          _fetchWalletDetails();
                        } else {
                          throw "Invalid Razorpay order details returned by server";
                        }
                      } catch (err) {
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text("Payment processing failed: $err")),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isProcessingPayment = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Pay & Top Up", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("My Wallet & Ledger", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletDetails,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // WALLET CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text("Wallet Balance", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                              Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "₹${_walletBalance.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _showTopupDialog,
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              label: const Text("Top Up Wallet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text("Transaction Ledger", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),

                    if (_transactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: const [
                              Icon(Icons.history, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text("No wallet transactions yet.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final bool isCredit = tx['type'] == 'CREDIT';
                          final double amt = (tx['amount'] ?? 0.0).toDouble();
                          final String desc = tx['description'] ?? 'Transaction';
                          final String cat = tx['category'] ?? 'WALLET';
                          final String dateStr = tx['createdAt'] != null
                              ? DateTime.parse(tx['createdAt']).toLocal().toString().split('.').first
                              : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isCredit ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text("$cat • $dateStr", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${isCredit ? '+' : '-'}₹${amt.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isCredit ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("Bal: ₹${(tx['balanceAfter'] ?? 0).toString()}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
