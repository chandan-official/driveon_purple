import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/animations/fade_slide_transition.dart';
import '../../../core/animations/bouncing_button.dart';
import '../../../api/api_service.dart';

class DriverRegistrationFormScreen extends StatefulWidget {
  const DriverRegistrationFormScreen({super.key});

  @override
  State<DriverRegistrationFormScreen> createState() =>
      _DriverRegistrationFormScreenState();
}

class _DriverRegistrationFormScreenState
    extends State<DriverRegistrationFormScreen> {
  int _selectedTabIndex = 0; // 0 for Owner, 1 for Driver Only
  bool _isSubmitting = false;

  final ApiService _api = ApiService();

  // ===================== OWNER TAB CONTROLLERS =====================
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _ownerAadharController = TextEditingController();
  final _ownerPanController = TextEditingController();
  final _ownerLicenseController = TextEditingController();
  final _ownerVehicleNumberController = TextEditingController();
  final _ownerRcController = TextEditingController();
  final _ownerVehicleTypeController = TextEditingController();
  final _ownerVehicleNameController = TextEditingController();
  final _ownerVehicleColorController = TextEditingController();
  final _ownerVehicleSeatCapacityController = TextEditingController();
  final _ownerDobController = TextEditingController();

  // ===================== DRIVER ONLY TAB CONTROLLERS =====================
  final _driverNameController = TextEditingController();
  final _driverEmailController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverPasswordController = TextEditingController();
  final _driverAadharController = TextEditingController();
  final _driverPanController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  final _driverVehicleNumberController = TextEditingController();
  final _driverRcController = TextEditingController();
  final _driverVehicleTypeController = TextEditingController();
  final _driverVehicleNameController = TextEditingController();
  final _driverVehicleColorController = TextEditingController();
  final _driverVehicleSeatCapacityController = TextEditingController();
  final _driverDobController = TextEditingController();
  final _authOwnerPhoneController = TextEditingController();
  final _ownerAuthNameController = TextEditingController();

  // ===================== MULTI DRIVERS (OWNER FLOW) =====================
  final List<DriverInfo> _drivers = [];

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _ownerPasswordController.dispose();
    _ownerAadharController.dispose();
    _ownerPanController.dispose();
    _ownerLicenseController.dispose();
    _ownerVehicleNumberController.dispose();
    _ownerRcController.dispose();
    _ownerVehicleTypeController.dispose();
    _ownerVehicleNameController.dispose();
    _ownerVehicleColorController.dispose();
    _ownerVehicleSeatCapacityController.dispose();
    _ownerDobController.dispose();

    _driverNameController.dispose();
    _driverEmailController.dispose();
    _driverPhoneController.dispose();
    _driverPasswordController.dispose();
    _driverAadharController.dispose();
    _driverPanController.dispose();
    _driverLicenseController.dispose();
    _driverVehicleNumberController.dispose();
    _driverRcController.dispose();
    _driverVehicleTypeController.dispose();
    _driverVehicleNameController.dispose();
    _driverVehicleColorController.dispose();
    _driverVehicleSeatCapacityController.dispose();
    _driverDobController.dispose();
    _authOwnerPhoneController.dispose();
    _ownerAuthNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
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

          // Toggle
          _buildPremiumToggle(),

          // Body
          Expanded(
            child: FadeSlideTransition(
              key: ValueKey(_selectedTabIndex),
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

      // Submit Button
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
            onPressed: _isSubmitting ? null : _submitRegistration,
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text(
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

  // ===================== TOGGLE =====================

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
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _selectedTabIndex == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.43,
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

  // ===================== OWNER FORM (ADDED VEHICLE + MULTI DRIVERS) =====================

  Widget _buildOwnerDriverForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("Personal Information"),
        _premiumInput("Full Name", _ownerNameController, Icons.person_outline),
        _premiumInput("Email", _ownerEmailController, Icons.email_outlined),
        _premiumInput("Phone", _ownerPhoneController, Icons.phone_outlined, isNumber: true),
        _premiumInput("Date of Birth (YYYY-MM-DD)", _ownerDobController, Icons.cake_outlined),
        _premiumInput("Password", _ownerPasswordController, Icons.lock_outline),
        _premiumInput(
          "Aadhar Number",
          _ownerAadharController,
          Icons.credit_card,
          isNumber: true,
        ),
        _premiumUpload("Upload Aadhar (Front & Back)"),
        _premiumInput("PAN Number", _ownerPanController, Icons.badge_outlined),
        _premiumUpload("Upload PAN Card"),

        const SizedBox(height: 30),
        _sectionHeader("Vehicle Details"),
        _premiumInput(
          "Driving License",
          _ownerLicenseController,
          Icons.drive_eta_outlined,
        ),
        _premiumUpload("Upload Driving License"),

        // ✅ Added Vehicle Number + RC
        _premiumInput(
          "Vehicle Type (e.g. SEDAN, SUV)",
          _ownerVehicleTypeController,
          Icons.merge_type_outlined,
        ),
        _premiumInput(
          "Vehicle Name",
          _ownerVehicleNameController,
          Icons.directions_car,
        ),
        _premiumInput(
          "Vehicle Color",
          _ownerVehicleColorController,
          Icons.color_lens_outlined,
        ),
        _premiumInput(
          "Seat Capacity",
          _ownerVehicleSeatCapacityController,
          Icons.event_seat_outlined,
          isNumber: true,
        ),
        _premiumInput(
          "Vehicle Number",
          _ownerVehicleNumberController,
          Icons.confirmation_number_outlined,
        ),
        _premiumInput(
          "Vehicle RC Number",
          _ownerRcController,
          Icons.directions_car_outlined,
        ),
        _premiumUpload("Upload Vehicle RC"),
        _premiumUpload("Upload Insurance Policy"),

        const SizedBox(height: 20),
        _sectionHeader("Vehicle Photos"),
        _vehiclePhotoGrid(),

        const SizedBox(height: 30),
        _sectionHeader("Drivers on this Vehicle"),
        _driversList(),
        const SizedBox(height: 14),
        _addDriverButton(),
      ],
    );
  }

  // ===================== DRIVER ONLY FORM (ADDED VEHICLE + PHOTOS) =====================

  Widget _buildDriverOnlyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _premiumInput("Full Name", _driverNameController, Icons.person_outline),
        _premiumInput("Email", _driverEmailController, Icons.email_outlined),
        _premiumInput("Phone", _driverPhoneController, Icons.phone_outlined, isNumber: true),
        _premiumInput("Date of Birth (YYYY-MM-DD)", _driverDobController, Icons.cake_outlined),
        _premiumInput("Password", _driverPasswordController, Icons.lock_outline),
        _premiumInput(
          "Aadhar Number",
          _driverAadharController,
          Icons.credit_card,
          isNumber: true,
        ),
        _premiumUpload("Upload Aadhar (Front & Back)"),
        _premiumInput("PAN Number", _driverPanController, Icons.badge_outlined),
        _premiumUpload("Upload PAN Card"),

        const SizedBox(height: 30),
        _sectionHeader("Driver & Vehicle Details"),
        _premiumInput(
          "Driving License",
          _driverLicenseController,
          Icons.drive_eta_outlined,
        ),
        _premiumUpload("Upload Driving License"),

        // ✅ Added Vehicle Number + RC + Insurance + Photos
        _premiumInput(
          "Vehicle Type (e.g. SEDAN, SUV)",
          _driverVehicleTypeController,
          Icons.merge_type_outlined,
        ),
        _premiumInput(
          "Vehicle Name",
          _driverVehicleNameController,
          Icons.directions_car,
        ),
        _premiumInput(
          "Vehicle Color",
          _driverVehicleColorController,
          Icons.color_lens_outlined,
        ),
        _premiumInput(
          "Seat Capacity",
          _driverVehicleSeatCapacityController,
          Icons.event_seat_outlined,
          isNumber: true,
        ),
        _premiumInput(
          "Vehicle Number",
          _driverVehicleNumberController,
          Icons.confirmation_number_outlined,
        ),
        _premiumInput(
          "Vehicle RC Number",
          _driverRcController,
          Icons.directions_car_outlined,
        ),
        _premiumUpload("Upload Vehicle RC"),
        _premiumUpload("Upload Insurance Policy"),

        const SizedBox(height: 20),
        _sectionHeader("Vehicle Photos"),
        _vehiclePhotoGrid(),

        const SizedBox(height: 30),
        _sectionHeader("Owner Information"),
        _premiumInput("Owner Name", _ownerAuthNameController, Icons.person),
        _premiumInput(
          "Owner Phone",
          _authOwnerPhoneController,
          Icons.phone,
          isNumber: true,
        ),
        _premiumUpload("Authorization Letter"),
      ],
    );
  }

  // ===================== DRIVERS LIST + ADD DRIVER SHEET =====================

  Widget _driversList() {
    if (_drivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_alt_1, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "No drivers added yet. Tap “Add Driver” to add one or more riders.",
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_drivers.length, (i) {
        final d = _drivers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name.isEmpty ? "Driver ${i + 1}" : d.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${d.phone.isEmpty ? "Phone: -" : "Phone: ${d.phone}"}  •  ${d.licenseNo.isEmpty ? "License: -" : "License: ${d.licenseNo}"}",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _miniChip(d.aadharNo.isEmpty
                            ? "Aadhar: -"
                            : "Aadhar: ${d.aadharNo}"),
                        _miniChip(d.panNo.isEmpty ? "PAN: -" : "PAN: ${d.panNo}"),
                        _miniChip("Docs: ${d.docsSummary()}"),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () async {
                      final updated = await _openAddEditDriverSheet(existing: d);
                      if (updated == null) return;
                      setState(() => _drivers[i] = updated);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => setState(() => _drivers.removeAt(i)),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _addDriverButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: () async {
          final created = await _openAddEditDriverSheet();
          if (created == null) return;
          setState(() => _drivers.add(created));
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Driver",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Future<DriverInfo?> _openAddEditDriverSheet({DriverInfo? existing}) {
    return showModalBottomSheet<DriverInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DriverSheet(
          existing: existing,
          title: existing == null ? "Add Driver" : "Edit Driver",
        );
      },
    );
  }

  // ===================== VEHICLE PHOTOS GRID =====================

  Widget _vehiclePhotoGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: const [
        _VehicleUploadTile(title: "Front View"),
        _VehicleUploadTile(title: "Back View"),
        _VehicleUploadTile(title: "Left Side"),
        _VehicleUploadTile(title: "Right Side"),
      ],
    );
  }

  // ===================== PREMIUM UI COMPONENTS =====================

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
          onTap: () {}, // TODO: file picker
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
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

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);
    try {
       await _api.registerDriver(
         fullname: _selectedTabIndex == 0 ? _ownerNameController.text : _driverNameController.text,
         email: _selectedTabIndex == 0 ? _ownerEmailController.text : _driverEmailController.text,
         phone: _selectedTabIndex == 0 ? _ownerPhoneController.text : _driverPhoneController.text,
         dob: _selectedTabIndex == 0 ? _ownerDobController.text : _driverDobController.text,
         password: _selectedTabIndex == 0 ? _ownerPasswordController.text : _driverPasswordController.text,
         aadhar: _selectedTabIndex == 0 ? _ownerAadharController.text : _driverAadharController.text,
         panNo: _selectedTabIndex == 0 ? _ownerPanController.text : _driverPanController.text,
         licenseNo: _selectedTabIndex == 0 ? _ownerLicenseController.text : _driverLicenseController.text,
         rcNo: _selectedTabIndex == 0 ? _ownerRcController.text : _driverRcController.text,
         vehicle: {
           "type": _selectedTabIndex == 0 ? _ownerVehicleTypeController.text : _driverVehicleTypeController.text,
           "vehicleNumber": _selectedTabIndex == 0 ? _ownerVehicleNumberController.text : _driverVehicleNumberController.text,
           "seatingCapacity": int.tryParse(_selectedTabIndex == 0 ? _ownerVehicleSeatCapacityController.text : _driverVehicleSeatCapacityController.text) ?? 4,
           "fuel": "PETROL",
           "amenities": {
             "ac": true,
             "wifi": false
           }
         }
       );
       if (!mounted) return;
       _showSuccessDialog();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

// ===================== DRIVER MODEL =====================

class DriverInfo {
  final String name;
  final String phone;
  final String licenseNo;
  final String aadharNo;
  final String panNo;

  final bool hasDriverPhoto;
  final bool hasAadharPhoto;
  final bool hasPanPhoto;
  final bool hasLicensePhoto;

  const DriverInfo({
    required this.name,
    required this.phone,
    required this.licenseNo,
    required this.aadharNo,
    required this.panNo,
    required this.hasDriverPhoto,
    required this.hasAadharPhoto,
    required this.hasPanPhoto,
    required this.hasLicensePhoto,
  });

  String docsSummary() {
    final items = <String>[];
    if (hasDriverPhoto) items.add("DriverPhoto");
    if (hasAadharPhoto) items.add("Aadhar");
    if (hasPanPhoto) items.add("PAN");
    if (hasLicensePhoto) items.add("License");
    return items.isEmpty ? "None" : items.join(", ");
  }
}

// ===================== ADD/EDIT DRIVER SHEET =====================

class _DriverSheet extends StatefulWidget {
  final DriverInfo? existing;
  final String title;

  const _DriverSheet({required this.existing, required this.title});

  @override
  State<_DriverSheet> createState() => _DriverSheetState();
}

class _DriverSheetState extends State<_DriverSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _licenseCtrl;
  late final TextEditingController _aadharCtrl;
  late final TextEditingController _panCtrl;

  bool _hasDriverPhoto = false;
  bool _hasAadharPhoto = false;
  bool _hasPanPhoto = false;
  bool _hasLicensePhoto = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? "");
    _phoneCtrl = TextEditingController(text: e?.phone ?? "");
    _licenseCtrl = TextEditingController(text: e?.licenseNo ?? "");
    _aadharCtrl = TextEditingController(text: e?.aadharNo ?? "");
    _panCtrl = TextEditingController(text: e?.panNo ?? "");

    _hasDriverPhoto = e?.hasDriverPhoto ?? false;
    _hasAadharPhoto = e?.hasAadharPhoto ?? false;
    _hasPanPhoto = e?.hasPanPhoto ?? false;
    _hasLicensePhoto = e?.hasLicensePhoto ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _aadharCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),

              _sheetInput("Driver Name", _nameCtrl, Icons.person),
              _sheetInput("Phone Number", _phoneCtrl, Icons.phone, isNumber: true),
              _sheetInput("Driving License No", _licenseCtrl, Icons.drive_eta_outlined),
              _sheetInput("Aadhar Number", _aadharCtrl, Icons.credit_card, isNumber: true),
              _sheetInput("PAN Number", _panCtrl, Icons.badge_outlined),

              const SizedBox(height: 10),
              const Text(
                "Uploads",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _toggleUploadTile(
                    title: "Driver Photo",
                    icon: Icons.camera_alt_outlined,
                    value: _hasDriverPhoto,
                    onTap: () => setState(() => _hasDriverPhoto = !_hasDriverPhoto),
                  ),
                  _toggleUploadTile(
                    title: "Aadhar Photo",
                    icon: Icons.credit_card,
                    value: _hasAadharPhoto,
                    onTap: () => setState(() => _hasAadharPhoto = !_hasAadharPhoto),
                  ),
                  _toggleUploadTile(
                    title: "PAN Photo",
                    icon: Icons.badge_outlined,
                    value: _hasPanPhoto,
                    onTap: () => setState(() => _hasPanPhoto = !_hasPanPhoto),
                  ),
                  _toggleUploadTile(
                    title: "License Photo",
                    icon: Icons.drive_eta_outlined,
                    value: _hasLicensePhoto,
                    onTap: () => setState(() => _hasLicensePhoto = !_hasLicensePhoto),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final created = DriverInfo(
                      name: _nameCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim(),
                      licenseNo: _licenseCtrl.text.trim(),
                      aadharNo: _aadharCtrl.text.trim(),
                      panNo: _panCtrl.text.trim(),
                      hasDriverPhoto: _hasDriverPhoto,
                      hasAadharPhoto: _hasAadharPhoto,
                      hasPanPhoto: _hasPanPhoto,
                      hasLicensePhoto: _hasLicensePhoto,
                    );
                    Navigator.pop(context, created);
                  },
                  child: const Text(
                    "Save Driver",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: AppColors.primaryPurple),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  Widget _toggleUploadTile({
    required String title,
    required IconData icon,
    required bool value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: (MediaQuery.of(context).size.width - 18 * 2 - 12) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? Colors.green.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                color: AppColors.backgroundDark,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(
              value ? Icons.check_circle : Icons.add_circle_outline,
              color: value ? Colors.green : Colors.grey.shade500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== VEHICLE PHOTO TILE =====================

class _VehicleUploadTile extends StatelessWidget {
  final String title;
  const _VehicleUploadTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () {}, // TODO: pick photo
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera,
                  color: AppColors.primaryPurple,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tap to upload",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
