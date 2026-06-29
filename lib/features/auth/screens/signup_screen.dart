import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../api/api_service.dart';
import '../widgets/auth_layout.dart';
import '../widgets/brand_components.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final ApiService _api = ApiService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _api.register(
        fullname: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful")),
      );

      Navigator.pushReplacementNamed(context, '/otp_verify');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RyndoAuthLayout(
      title: "Create Account",
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            RyndoTextField(
              controller: _nameCtrl,
              hintText: "Full Name",
              validator: (v) => (v == null || v.trim().isEmpty) ? "Enter full name" : null,
            ),
            const SizedBox(height: 16),
            RyndoTextField(
              controller: _phoneCtrl,
              hintText: "Phone Number",
              keyboardType: TextInputType.phone,
              validator: (v) {
                final val = (v ?? "").trim();
                if (val.isEmpty) return "Enter phone number";
                if (!RegExp(r'^\d{10}$').hasMatch(val)) return "Enter valid 10-digit phone";
                return null;
              },
            ),
            const SizedBox(height: 16),
            RyndoTextField(
              controller: _emailCtrl,
              hintText: "Email Address",
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final val = (v ?? "").trim();
                if (val.isEmpty) return "Enter email";
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val)) return "Enter valid email";
                return null;
              },
            ),
            const SizedBox(height: 16),
            RyndoTextField(
              controller: _passwordCtrl,
              hintText: "Create Password",
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textGrey,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: (v) {
                final val = (v ?? "").trim();
                if (val.isEmpty) return "Enter password";
                if (val.length < 6) return "Password must be 6+ chars";
                return null;
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text(
                    "By signing up, you agree to our ",
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/terms_and_conditions'),
                    child: const Text(
                      "Terms & Conditions",
                      style: TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Text(
                    " and ",
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/privacy_policy'),
                    child: const Text(
                      "Privacy Policy",
                      style: TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            RyndoButton(
              text: "Sign Up",
              isLoading: _isLoading,
              onPressed: _signup,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? ", style: TextStyle(color: AppColors.textGrey)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
