import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/color_constants.dart';
import '../../../api/api_service.dart';
import '../widgets/auth_layout.dart';
import '../widgets/brand_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _emailOrPhoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isDriverLogin = false;

  bool _isEmail(String v) => v.contains("@");
  bool _isPhone(String v) => RegExp(r'^\d{10}$').hasMatch(v);

  @override
  void dispose() {
    _emailOrPhoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final input = _emailOrPhoneCtrl.text.trim();
      final password = _passwordCtrl.text.trim();

      final data = await _api.login(email: input, password: password);

      String role = 'USER';
      
      // Check for user role in primary login response (structure from logs: data['user']['role'])
      if (data is Map && data['user'] is Map) {
        role = data['user']['role']?.toString() ?? 'USER';
      } else if (data is Map && data['data'] is Map && data['data']['user'] is Map) {
        role = data['data']['user']['role']?.toString() ?? 'USER';
      } else {
        // Fallback: Check profile if login response doesn't have it
        final me = await _api.getUserProfile();
        if (me is Map && me['data'] is Map) {
          role = me['data']['role']?.toString() ?? 'USER';
        }
      }

      if (!mounted) return;

      print('[LOGIN DEBUG] Extracted Role: $role');
      print('[LOGIN DEBUG] Selected Mode: ${_isDriverLogin ? "Carpooler/Driver" : "Co-traveller/Passenger"}');

      // If user chose "Carpooler (Driver)" but their account is not a DRIVER, show clear error
      if (_isDriverLogin && role != 'DRIVER') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This account is not registered as a Driver. Please select Co-traveller or register as a Partner."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        // Don't clear session — just let the user switch to Co-traveller and try again
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful!")),
      );

      final prefs = await SharedPreferences.getInstance();
      // Always save the ACTUAL backend role, not the UI toggle
      await prefs.setString('user_mode', role == 'DRIVER' ? 'driver' : 'rider');

      // Route based on ACTUAL backend role
      final targetRoute = (role == 'DRIVER') ? '/driver_home' : '/home';
      
      Navigator.pushNamedAndRemoveUntil(
        context,
        targetRoute,
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
      title: "Login",
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Unified Role Selector (Reference: Carpooler & Co-traveller)
            Row(
              children: [
                Expanded(
                  child: _buildRoleSelector(
                    icon: Icons.people_outline_rounded,
                    label: "Co-traveller",
                    sublabel: "(Passenger)",
                    isSelected: !_isDriverLogin,
                    onTap: () => setState(() => _isDriverLogin = false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRoleSelector(
                    icon: Icons.drive_eta_rounded,
                    label: "Carpooler",
                    sublabel: "(Driver)",
                    isSelected: _isDriverLogin,
                    onTap: () => setState(() => _isDriverLogin = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            RyndoTextField(
              controller: _emailOrPhoneCtrl,
              hintText: "Email id",
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Please enter email" : null,
            ),
            const SizedBox(height: 20),
            RyndoTextField(
              controller: _passwordCtrl,
              hintText: "Password",
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textGrey,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Please enter password" : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            RyndoButton(
              text: "Login",
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 30),
            const Text(
              "or Login with",
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialIcon('assets/images/google_icon.png', Icons.alternate_email),
                const SizedBox(width: 40),
                _socialIcon('assets/images/apple_icon.png', Icons.apple),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ", style: TextStyle(color: AppColors.textGrey)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Want to offer rides? ", style: TextStyle(color: AppColors.textGrey)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/driver_registration'),
                  child: const Text(
                    "Become a Partner",
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

  Widget _socialIcon(String asset, IconData fallback) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(fallback, size: 28, color: AppColors.textDark),
    );
  }

  Widget _buildRoleSelector({
    required IconData icon,
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerLoginSheet extends StatefulWidget {
  const _PartnerLoginSheet({Key? key}) : super(key: key);

  @override
  State<_PartnerLoginSheet> createState() => _PartnerLoginSheetState();
}

class _PartnerLoginSheetState extends State<_PartnerLoginSheet> {
  final ApiService _api = ApiService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obsecure = true;
  bool _loading = false;

  void _login() async {
    final e = _emailCtrl.text.trim();
    final p = _passCtrl.text.trim();
    if (e.isEmpty || p.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _api.login(email: e, password: p);
      final me = await _api.getUserProfile();
      String role = 'DRIVER';
      if (me is Map && me['data'] is Map) {
        role = me['data']['role']?.toString() ?? 'DRIVER';
      }
      
      print('[PARTNER LOGIN DEBUG] Extracted Role: $role');
      print('[PARTNER LOGIN DEBUG] Full Me: $me');

      if (!mounted) return;

      final targetRoute = (role == 'DRIVER') ? '/driver_home' : '/home';
      Navigator.pushNamedAndRemoveUntil(
        context,
        targetRoute,
        (route) => false,
      );

    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Partner Portal", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          RyndoTextField(
            controller: _emailCtrl,
            hintText: "Driver Email",
          ),
          const SizedBox(height: 16),
          RyndoTextField(
            controller: _passCtrl,
            hintText: "Password",
            obscureText: _obsecure,
            suffixIcon: IconButton(
              icon: Icon(_obsecure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obsecure = !_obsecure),
            ),
          ),
          const SizedBox(height: 24),
          RyndoButton(
            text: "Access Dashboard",
            isLoading: _loading,
            onPressed: _login,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/driver_registration');
              },
              child: const Text("Become a Partner", style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
