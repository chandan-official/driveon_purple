import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/color_constants.dart';
import '../../../api/api_service.dart';
import '../models/partner_role.dart';
import '../widgets/auth_layout.dart';
import '../widgets/brand_components.dart';

class PartnerSignupScreen extends StatefulWidget {
  final PartnerRole role;
  final List<Map<String, dynamic>>? driversOut;
  final bool isAddDriverFlow;

  const PartnerSignupScreen({
    super.key,
    required this.role,
    this.driversOut,
    this.isAddDriverFlow = false,
  });

  @override
  State<PartnerSignupScreen> createState() => _PartnerSignupScreenState();
}

class _PartnerSignupScreenState extends State<PartnerSignupScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  // BASIC
  final _nameCtrl = TextEditingController();
  final _phoneOrEmailCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // REQUIRED
  final _dobCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _rcCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  // Vehicle
  final _vehicleNumberCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _seatingCtrl = TextEditingController();

  // Vendor extra
  final _gstCtrl = TextEditingController();

  bool _isPasswordVisible = false;
  bool _loading = false;

  String? _carType; 
  String? _fuel;

  bool _ac = false;
  bool _wifi = false;
  bool _music = false;
  bool _smoking = false;

  bool _selfieUploaded = false;
  bool _aadharUploaded = false;
  bool _licenseUploaded = false; 
  bool _panUploaded = false;
  bool _rcUploaded = false;

  bool _carFrontUploaded = false;
  bool _carBackUploaded = false;
  bool _carLeftUploaded = false;
  bool _carRightUploaded = false;

  final List<Map<String, dynamic>> _aadharImgs = [];
  final List<Map<String, dynamic>> _rcImgs = [];
  final List<Map<String, dynamic>> _panImg = [];
  final List<Map<String, dynamic>> _driverSelfie = [];
  final List<Map<String, dynamic>> _vehicleImgs = [];

  bool _isEmail(String v) => v.contains("@");
  bool _isPhone(String v) => RegExp(r'^\d{10}$').hasMatch(v);

  String get _roleString => widget.role == PartnerRole.driver ? "DRIVER" : "VENDOR";

  String get _title {
    if (widget.role == PartnerRole.driver) return "Create Driver Account";
    return widget.isAddDriverFlow ? "Add Vendor Driver" : "Create Vendor Account";
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneOrEmailCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _dobCtrl.dispose();
    _aadharCtrl.dispose();
    _licenseCtrl.dispose();
    _rcCtrl.dispose();
    _panCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _yearCtrl.dispose();
    _seatingCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  void _toast(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  void _addDummyCloudinary(List<Map<String, dynamic>> list, String publicId) {
    list.clear();
  }

  void _addDummyAadharImgs() {
    _aadharImgs.clear();
  }

  void _buildVehicleImgs() {
    _vehicleImgs.clear();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final input = _phoneOrEmailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final dob = _dobCtrl.text.trim();
    final aadhar = _aadharCtrl.text.trim();
    final licenseNo = _licenseCtrl.text.trim();
    final rcNo = _rcCtrl.text.trim();
    final panNo = _panCtrl.text.trim();

    final derivedEmail = _isEmail(input) ? input : _emailCtrl.text.trim();
    String? phone;
    if (_isPhone(input)) phone = input;

    if (!_selfieUploaded) return _toast("Please upload Selfie");
    if (!_aadharUploaded) return _toast("Please upload Aadhar photo");
    if (!_licenseUploaded) return _toast("Please upload License photo");
    if (!_panUploaded) return _toast("Please upload PAN photo");
    if (!_rcUploaded) return _toast("Please upload RC photo");

    if (_carType == null) return _toast("Please select car type");
    if (_fuel == null) return _toast("Please select fuel type");

    final seating = int.tryParse(_seatingCtrl.text.trim());
    if (seating == null) return _toast("Enter valid seating capacity");

    final vehicleNumber = _vehicleNumberCtrl.text.trim();
    if (vehicleNumber.isEmpty) return _toast("Vehicle number required");

    final vehicleModel = _vehicleModelCtrl.text.trim();
    if (vehicleModel.isEmpty) return _toast("Vehicle model required");

    final year = _yearCtrl.text.trim();
    if (year.isEmpty) return _toast("Year of manufacture required");

    if (!RegExp(r'^\d{4}$').hasMatch(year)) {
      return _toast("Enter valid year (e.g. 2022)");
    }

    if (widget.role == PartnerRole.vendor && !widget.isAddDriverFlow) {
      if (_gstCtrl.text.trim().isEmpty) return _toast("Please enter GST number");
    }

    if (_aadharUploaded) _addDummyAadharImgs();
    if (_rcUploaded) _addDummyCloudinary(_rcImgs, "rc_999");
    if (_panUploaded) _addDummyCloudinary(_panImg, "pan_123");
    if (_selfieUploaded) _addDummyCloudinary(_driverSelfie, "selfie_123");
    _buildVehicleImgs();

    setState(() => _loading = true);

    try {
      final vehiclePayload = {
        "type": (_carType ?? "").toUpperCase(),
        "vehicleNumber": vehicleNumber,
        "model": vehicleModel,
        "yearOfManufacture": year,
        "seatingCapacity": seating,
        "fuel": (_fuel ?? "").toUpperCase(),
        "amenities": {
          "ac": _ac,
          "wifi": _wifi,
          "music": _music,
          "smoking": _smoking,
        }
      };

      if (widget.role == PartnerRole.vendor && widget.isAddDriverFlow) {
        widget.driversOut?.add({
          "fullname": name,
          "email": derivedEmail,
          "phone": phone,
          "password": pass,
          "role": "DRIVER",
          "dob": dob,
          "aadhar": aadhar,
          "aadharImgs": _aadharImgs,
          "licenseNo": licenseNo,
          "rcNo": rcNo,
          "rcImgs": _rcImgs,
          "panNo": panNo,
          "panImg": _panImg,
          "driverSelfie": _driverSelfie,
          "vehicleImgs": _vehicleImgs,
          "vehicle": vehiclePayload,
        });

        if (!mounted) return;
        _toast("Driver added");
        Navigator.pop(context, true);
        return;
      }

      await _api.registerDriverVendor(
        fullname: name,
        email: derivedEmail,
        phone: phone,
        password: pass,
        role: _roleString,
        dob: dob,
        aadhar: aadhar,
        aadharImgs: _aadharImgs,
        licenseNo: licenseNo,
        rcNo: rcNo,
        rcImgs: _rcImgs,
        panNo: panNo,
        panImg: _panImg,
        driverSelfie: _driverSelfie,
        vehicleImgs: _vehicleImgs,
        vehicle: vehiclePayload,
        gstNo: (widget.role == PartnerRole.vendor && !widget.isAddDriverFlow)
            ? _gstCtrl.text.trim()
            : null,
      );

      print('[PARTNER SIGNUP DEBUG] Attempting auto-login for $phone $derivedEmail');
      if (phone != null) {
        await _api.loginWithPhone(phone: phone, password: pass);
      } else {
        await _api.login(email: derivedEmail, password: pass);
      }
      print('[PARTNER SIGNUP DEBUG] Auto-login successful');

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.role == PartnerRole.driver ? '/driver_home' : '/home',
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (e) {
      if (!mounted) return;
      _toast("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(
          t,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            fontSize: 16,
          ),
        ),
      );

  Widget _uploadTile({
    required String title,
    required bool value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: value ? AppColors.primaryPurple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle : Icons.cloud_upload_outlined,
              color: value ? AppColors.primaryPurple : AppColors.textGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: value ? AppColors.primaryPurple : AppColors.textDark,
                  fontWeight: value ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RyndoAuthLayout(
      title: _title,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sign up to continue your journey.",
              style: TextStyle(fontSize: 16, color: AppColors.textGrey),
            ),
            const SizedBox(height: 20),
            RyndoTextField(
              controller: _nameCtrl,
              hintText: "Full Name",
              validator: (v) => (v == null || v.trim().isEmpty) ? "Enter name" : null,
            ),
            const SizedBox(height: 16),
            RyndoTextField(
              controller: _phoneOrEmailCtrl,
              hintText: "Phone Number or Email",
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final val = v?.trim() ?? "";
                if (val.isEmpty) return "Enter phone/email";
                if (!_isPhone(val) && !_isEmail(val)) return "Enter valid 10-digit phone or email";
                return null;
              },
            ),
            if (_isPhone(_phoneOrEmailCtrl.text.trim())) ...[
              const SizedBox(height: 16),
              RyndoTextField(
                controller: _emailCtrl,
                hintText: "Email Address",
                validator: (v) {
                  final val = v?.trim() ?? "";
                  if (val.isEmpty) return "Email required";
                  if (!_isEmail(val)) return "Enter valid email";
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            RyndoTextField(
              controller: _passCtrl,
              hintText: "Password",
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textGrey,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: (v) {
                final val = v?.trim() ?? "";
                if (val.isEmpty) return "Enter password";
                if (val.length < 6) return "Password must be 6+ chars";
                return null;
              },
            ),
            const SizedBox(height: 16),
            RyndoTextField(
              controller: _dobCtrl,
              hintText: "Birth (YYYY-MM-DD)",
              validator: (v) => (v == null || v.trim().isEmpty) ? "DOB required" : null,
            ),
            const SizedBox(height: 16),
            _uploadTile(
              title: "Upload Selfie",
              value: _selfieUploaded,
              onTap: () => setState(() => _selfieUploaded = true),
            ),

            if (widget.role == PartnerRole.vendor && !widget.isAddDriverFlow) ...[
              _sectionTitle("GST Details"),
              RyndoTextField(
                controller: _gstCtrl,
                hintText: "GST Number",
                validator: (v) => (v == null || v.trim().isEmpty) ? "GST required" : null,
              ),
            ],

            _sectionTitle("Driver Documents"),
            RyndoTextField(
              controller: _aadharCtrl,
              hintText: "Aadhar Number",
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().isEmpty) ? "Aadhar required" : null,
            ),
            const SizedBox(height: 10),
            _uploadTile(
              title: "Upload Aadhar Photo",
              value: _aadharUploaded,
              onTap: () => setState(() => _aadharUploaded = true),
            ),
            const SizedBox(height: 16),
            RyndoTextField(
              controller: _licenseCtrl,
              hintText: "License Number",
              validator: (v) => (v == null || v.trim().isEmpty) ? "License required" : null,
            ),
            const SizedBox(height: 10),
            _uploadTile(
              title: "Upload License Photo",
              value: _licenseUploaded,
              onTap: () => setState(() => _licenseUploaded = true),
            ),
            const SizedBox(height: 16),
            RyndoTextField(
              controller: _panCtrl,
              hintText: "PAN Number",
              validator: (v) => (v == null || v.trim().isEmpty) ? "PAN required" : null,
            ),
            const SizedBox(height: 10),
            _uploadTile(
              title: "Upload PAN Photo",
              value: _panUploaded,
              onTap: () => setState(() => _panUploaded = true),
            ),

            _sectionTitle("RC Details"),
            RyndoTextField(
              controller: _rcCtrl,
              hintText: "RC Number",
              validator: (v) => (v == null || v.trim().isEmpty) ? "RC required" : null,
            ),
            const SizedBox(height: 10),
            _uploadTile(
              title: "Upload RC Photo",
              value: _rcUploaded,
              onTap: () => setState(() => _rcUploaded = true),
            ),

            _sectionTitle("Vehicle Info"),
            RyndoTextField(
              controller: _vehicleNumberCtrl,
              hintText: "Vehicle Number (ex: MH 12 CK 9999)",
              validator: (v) => (v == null || v.trim().isEmpty) ? "required" : null,
            ),
            const SizedBox(height: 16),
            RyndoTextField(
              controller: _vehicleModelCtrl,
              hintText: "Vehicle Model (ex: Swift)",
              validator: (v) => (v == null || v.trim().isEmpty) ? "required" : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RyndoTextField(
                    controller: _yearCtrl,
                    hintText: "Year (2022)",
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: RyndoTextField(
                    controller: _seatingCtrl,
                    hintText: "Seats (4)",
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "required" : null,
                  ),
                ),
              ],
            ),

            _sectionTitle("Car Type"),
            _buildSelectionRow(["MICRO", "SEDAN", "SUV", "LUXURY"], _carType, (v) => setState(() => _carType = v)),

            _sectionTitle("Fuel Type"),
            _buildSelectionRow(["CNG", "PETROL", "DIESEL", "ELECTRIC"], _fuel, (v) => setState(() => _fuel = v)),

            _sectionTitle("Amenities"),
            Theme(
              data: ThemeData(unselectedWidgetColor: AppColors.primaryPurple),
              child: Column(
                children: [
                   CheckboxListTile(title: const Text("AC"), value: _ac, activeColor: AppColors.primaryPurple, onChanged: (v) => setState(() => _ac = v!)),
                   CheckboxListTile(title: const Text("WiFi"), value: _wifi, activeColor: AppColors.primaryPurple, onChanged: (v) => setState(() => _wifi = v!)),
                ],
              ),
            ),

            const SizedBox(height: 30),
            RyndoButton(
              text: widget.isAddDriverFlow ? "Add Driver" : "Create Account",
              isLoading: _loading,
              onPressed: _createAccount,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionRow(List<String> items, String? selected, Function(String) onSelect) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        bool isSelected = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryPurple : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
