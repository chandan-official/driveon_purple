import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/animations/fade_slide_transition.dart';
import '../../../core/animations/bouncing_button.dart';

class DriverRegistrationFormScreen extends StatefulWidget {
  const DriverRegistrationFormScreen({super.key});

  @override
  State<DriverRegistrationFormScreen> createState() =>
      _DriverRegistrationFormScreenState();
}

class _DriverRegistrationFormScreenState
    extends State<DriverRegistrationFormScreen> {
  int _selectedTabIndex = 0; // 0 for Owner, 1 for Driver Only

  // Controllers
  final _nameController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _licenseController = TextEditingController();
  final _rcController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Premium Off-White
      appBar: AppBar(
        title: const Text(
          "Partner Application",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BouncingButton(
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // 1. PREMIUM SLIDING TOGGLE
          _buildPremiumToggle(),

          // 2. FORM BODY
          Expanded(
            child: FadeSlideTransition(
              key: ValueKey(_selectedTabIndex), // Animates when tab changes
              delay: 0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                child: _selectedTabIndex == 0
                    ? _buildOwnerDriverForm()
                    : _buildDriverOnlyForm(),
              ),
            ),
          ),
        ],
      ),

      // SUBMIT BUTTON (Floating)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              shadowColor: AppColors.primaryGold.withOpacity(0.5),
            ),
            onPressed: _showSuccessDialog,
            child: const Text(
              "Submit Application",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildPremiumToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // The Sliding Pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _selectedTabIndex == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width:
                  MediaQuery.of(context).size.width *
                  0.43, // Roughly half width minus padding
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // The Text Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  child: Center(
                    child: Text(
                      "I Own the Car",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 0
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  child: Center(
                    child: Text(
                      "I am a Driver",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 1
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerDriverForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("Personal Information"),
        _premiumInput("Full Name", _nameController, Icons.person_outline),
        _premiumInput(
          "Aadhar Number",
          _aadharController,
          Icons.credit_card,
          isNumber: true,
        ),
        _premiumUpload("Upload Aadhar (Front & Back)"),
        _premiumInput("PAN Number", _panController, Icons.badge_outlined),
        _premiumUpload("Upload PAN Card"),

        const SizedBox(height: 30),
        _sectionHeader("Vehicle Details"),
        _premiumInput(
          "Driving License",
          _licenseController,
          Icons.drive_eta_outlined,
        ),
        _premiumUpload("Upload Driving License"),
        _premiumInput(
          "Vehicle RC Number",
          _rcController,
          Icons.directions_car_outlined,
        ),
        _premiumUpload("Upload Vehicle RC"),
        _premiumUpload("Upload Insurance Policy"),
      ],
    );
  }

  Widget _buildDriverOnlyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryPurple),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "You need the car owner's authorization to drive on this platform.",
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        _sectionHeader("Driver Details"),
        _premiumInput("Full Name", _nameController, Icons.person_outline),
        _premiumInput(
          "Driving License",
          _licenseController,
          Icons.drive_eta_outlined,
        ),
        _premiumUpload("Upload Driving License"),

        const SizedBox(height: 30),
        _sectionHeader("Owner Information"),
        _premiumInput("Owner Name", TextEditingController(), Icons.person),
        _premiumInput(
          "Owner Phone",
          _ownerPhoneController,
          Icons.phone,
          isNumber: true,
        ),
        _premiumUpload("Authorization Letter"),
      ],
    );
  }

  // --- PREMIUM COMPONENTS ---

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _premiumInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(icon, color: AppColors.primaryPurple),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _premiumUpload(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ), // Solid border looks cleaner
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    color: AppColors.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(30),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Success!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your application has been received. We will notify you once your documents are verified.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/driver_home',
                    (route) => false,
                  );
                },
                child: const Text(
                  "Enter Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
