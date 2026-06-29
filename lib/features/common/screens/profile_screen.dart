import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  late Future<UserModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<UserModel?> _loadProfile() async {
    await _api.loadToken();
    final res = await _api.getUserProfile();

    if (res is Map && res['data'] is Map) {
      return UserModel.fromJson(res['data'].cast<String, dynamic>());
    }
    return null;
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon, {
    bool isDestructive = false,
    bool isHighlight = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: isHighlight ? Border.all(color: AppColors.secondaryTeal.withOpacity(0.5)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withOpacity(0.1)
                : (isHighlight ? AppColors.secondaryTeal.withOpacity(0.1) : AppColors.backgroundDark),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive
                ? AppColors.error
                : (isHighlight ? AppColors.secondaryTeal : AppColors.primaryPurple),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : AppColors.textDark,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textGrey),
        onTap: onTap ?? () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final fullname = profile?.fullname.isNotEmpty == true ? profile!.fullname : 'User';
        final phone = profile?.phone ?? '-';

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, bottom: 40),
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        fullname.isNotEmpty ? fullname[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const CircularProgressIndicator(color: Colors.white)
                    else
                      Text(
                        fullname,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        phone,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildProfileOption(
                        context,
                        'My Wallet & Ledger 💳',
                        Icons.account_balance_wallet_outlined,
                        isHighlight: true,
                        onTap: () => Navigator.pushNamed(context, '/wallet'),
                      ),
                      const SizedBox(height: 16),
                      _buildProfileOption(
                        context,
                        'Support',
                        Icons.headset_mic_outlined,
                        onTap: () => Navigator.pushNamed(context, '/support'),
                      ),
                      const SizedBox(height: 20),
                      _buildProfileOption(
                        context,
                        'Privacy Policy',
                        Icons.privacy_tip_outlined,
                        onTap: () => Navigator.pushNamed(context, '/privacy_policy'),
                      ),
                      const SizedBox(height: 20),
                      _buildProfileOption(
                        context,
                        'Terms & Conditions',
                        Icons.description_outlined,
                        onTap: () => Navigator.pushNamed(context, '/terms_and_conditions'),
                      ),
                      const SizedBox(height: 20),
                      _buildProfileOption(
                        context,
                        'Log Out',
                        Icons.logout,
                        isDestructive: true,
                        onTap: () async {
                          await _api.logout();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildProfileOption(
                        context,
                        'Delete Account',
                        Icons.delete_forever,
                        isDestructive: true,
                        onTap: () => _showDeleteConfirmation(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is permanent and cannot be undone. All your rides, bookings, and profile data will be deleted forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                final res = await _api.deleteUserAccount();
                if (res['success'] == true) {
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deleted successfully')),
                  );
                } else {
                  throw res['message'] ?? 'Deletion failed';
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Forever', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
