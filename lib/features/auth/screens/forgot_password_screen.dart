import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../api/api_service.dart';
import '../widgets/auth_layout.dart';
import '../widgets/brand_components.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _api.forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link sent to your email!')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RyndoAuthLayout(
      title: "Forgot Password?",
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              "Don't worry! It happens. Please enter the email address linked with your account.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            RyndoTextField(
              controller: _emailController,
              hintText: "Enter your email",
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            RyndoButton(
              text: "Send Reset Code",
              isLoading: _isLoading,
              onPressed: _sendResetCode,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Back to Login",
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
