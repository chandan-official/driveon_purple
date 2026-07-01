import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';
import '../../common/screens/place_picker_field.dart';
import '../../common/widgets/animated_dialog.dart';
import 'driver_home_screen.dart';
import 'driver_hub.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({Key? key}) : super(key: key);

  @override
  _CreateRideScreenState createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final ApiService _api = ApiService();
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Data State
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  double? _pickupLat, _pickupLng;
  double? _dropLat, _dropLng;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);
  int _seatCount = 3;
  final TextEditingController _priceController = TextEditingController(text: "450");

  bool _isPosting = false;
  bool _isEditMode = false;
  String? _editRideId;
  bool _agreeToCostSharing = false;

  double? _minFare;
  double? _maxFare;
  bool _loadingFare = false;

  double? _distanceKm;
  double _platformFee = 0.0;
  double _gstPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      if (args.containsKey('pickup')) {
        _pickupController.text = args['pickup'] ?? '';
      }
      if (args.containsKey('drop')) {
        _dropController.text = args['drop'] ?? '';
      }
      _pickupLat = args['pickupLat'];
      _pickupLng = args['pickupLng'];
      _dropLat = args['dropLat'];
      _dropLng = args['dropLng'];

      _fetchFareRange();
    }
  }

  Future<void> _fetchFareRange() async {
    final pLat = _pickupLat;
    final pLng = _pickupLng;
    final dLat = _dropLat;
    final dLng = _dropLng;

    if (pLat == null || pLng == null || dLat == null || dLng == null) return;
    setState(() => _loadingFare = true);
    try {
      await _api.loadToken();
      final res = await _api.estimateMapFare(
        pickupLocation: {'lat': pLat, 'lng': pLng},
        dropLocation: {'lat': dLat, 'lng': dLng},
      );
      if (res is Map) {
        if (res['metrics'] is Map) {
          _distanceKm = (res['metrics']['distanceKm'] as num?)?.toDouble();
        }
        if (res['fareBreakdown'] is Map) {
          final fb = res['fareBreakdown'];
          setState(() {
            _minFare = (fb['minFare'] as num?)?.toDouble();
            _maxFare = (fb['maxFare'] as num?)?.toDouble();
            _platformFee = (fb['platformFee'] as num?)?.toDouble() ?? 0.0;
            _gstPercent = (fb['gstPercent'] as num?)?.toDouble() ?? 0.0;
            if (_minFare != null) {
              _priceController.text = _minFare!.toStringAsFixed(0);
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching fare range: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingFare = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitRide();
    }
  }

  void _onPickupSelected(PickedPlace place) {
    setState(() {
      _pickupController.text = place.address;
      _pickupLat = place.lat;
      _pickupLng = place.lng;
    });
  }

  void _onDropSelected(PickedPlace place) {
    setState(() {
      _dropController.text = place.address;
      _dropLat = place.lat;
      _dropLng = place.lng;
    });
  }

  Future<void> _submitRide() async {
    final double? price = double.tryParse(_priceController.text);
    if (price == null) {
      showAnimatedDialog(
        context,
        title: "Invalid Price",
        message: "Please enter a valid price per seat.",
        type: AnimatedDialogType.warning,
      );
      return;
    }

    if (_minFare != null && _maxFare != null) {
      if (price < _minFare! || price > _maxFare!) {
        showAnimatedDialog(
          context,
          title: "Price Out of Range",
          message: "Price per seat must be within the recommended range:\n₹${_minFare!.toStringAsFixed(0)} - ₹${_maxFare!.toStringAsFixed(0)}",
          type: AnimatedDialogType.error,
        );
        return;
      }
    }

    final double platformFee = _platformFee;
    final double gst = platformFee * (_gstPercent / 100.0);
    final double totalPrice = price + platformFee + gst;

    setState(() => _isPosting = true);
    try {
      final payload = {
        "route": {
          "startCity": _pickupController.text.trim(),
          "endCity": _dropController.text.trim(),
          "checkpoints": [],
        },
        "travelDate": "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
        "startTime": _selectedTime.format(context),
        "pricing": {
          "pricePerSeat": price,
        },
        "totalSeats": _seatCount,
        "availableSeats": _seatCount,
      };

      await _api.loadToken();
      if (_isEditMode && _editRideId != null) {
        await _api.updateMyRide(_editRideId!, payload);
      } else {
        await _api.createRide(payload);
      }

      if (!mounted) return;
      await showAnimatedDialog(
        context,
        title: _isEditMode ? "Ride Updated" : "Ride Published",
        message: _isEditMode ? "Your ride has been updated successfully!" : "Your ride has been published successfully!",
        type: AnimatedDialogType.success,
      );
      if (mounted) {
        DriverHomeScreen.refreshNotifier.value = true;
        DriverHub.tabNotifier.value = 1; // Index 1 is the "Rides" tab
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showAnimatedDialog(
          context,
          title: "Failed to Publish",
          message: "An error occurred while publishing: $e",
          type: AnimatedDialogType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text("Booking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step Indicator
          Container(
            color: AppColors.primaryPurple,
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => _buildStepDot(index)),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentStep = i),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepCalendar(),
                _buildStepSeats(),
                _buildStepTime(),
                _buildStepFinalPrice(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int index) {
    bool isCompleted = _currentStep > index;
    bool isCurrent = _currentStep == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isCurrent ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? Colors.white : Colors.grey.shade400,
                ),
              ),
      ),
    );
  }

  // --- STEP 2: Calendar ---
  Widget _buildStepCalendar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("When your are going?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selected, focused) => setState(() => _selectedDate = selected),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(color: Color(0xFFD6E4FF), shape: BoxShape.circle),
              selectedTextStyle: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
              todayDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
              todayTextStyle: TextStyle(color: AppColors.primaryPurple),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: false),
          ),
          const Spacer(),
          _buildNextButton(),
        ],
      ),
    );
  }

  // --- STEP 3: Seats ---
  Widget _buildStepSeats() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("So how many passenger can\nyou take?", 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundCounterBtn(Icons.remove, () {
                if (_seatCount > 1) setState(() => _seatCount--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text("$_seatCount", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              ),
              _buildRoundCounterBtn(Icons.add, () {
                if (_seatCount < 8) setState(() => _seatCount++);
              }),
            ],
          ),
          const Spacer(),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildRoundCounterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(color: AppColors.primaryPurple, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }

  // --- STEP 4: Time ---
  Widget _buildStepTime() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("What time will you pick\npassengers up?", 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 60),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _selectedTime);
              if (picked != null) setState(() => _selectedTime = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: Text(
                _selectedTime.format(context),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ),
          const Spacer(),
          _buildNextButton(),
        ],
      ),
    );
  }

  // --- STEP 5: Final Price (Not in image but required for API) ---
  Widget _buildStepFinalPrice() {
    final double chosenPrice = double.tryParse(_priceController.text) ?? 0.0;
    final double platformFee = _platformFee;
    final double gst = platformFee * (_gstPercent / 100.0);
    final double totalPrice = chosenPrice + platformFee + gst;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Lastly, set your price per seat",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_distanceKm != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car, color: AppColors.primaryPurple, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "Total Distance: ${_distanceKm!.toStringAsFixed(1)} km",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "💡 Note: The base price you set goes directly to you. Platform fee and GST will be added on top to determine the final passenger price.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_loadingFare)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple),
                      ),
                    )
                  else if (_minFare != null && _maxFare != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Recommended Base Fare Range: ₹${_minFare!.toStringAsFixed(0)} - ₹${_maxFare!.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                      ),
                    ),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                    decoration: const InputDecoration(
                      prefixText: "₹ ",
                      hintText: "0",
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Price Breakdown Card
                  if (_minFare != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildBreakdownRow("Your Base Share", "₹${chosenPrice.toStringAsFixed(0)}"),
                          const SizedBox(height: 8),
                          _buildBreakdownRow("Platform Fee (Admin)", "₹${platformFee.toStringAsFixed(2)}"),
                          const SizedBox(height: 8),
                          _buildBreakdownRow("GST on Platform Fee (${_gstPercent.toStringAsFixed(0)}%)", "₹${gst.toStringAsFixed(2)}"),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1),
                          ),
                          _buildBreakdownRow(
                            "Final Passenger Price per Seat",
                            "₹${totalPrice.toStringAsFixed(2)}",
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToCostSharing,
                        onChanged: (val) {
                          setState(() {
                            _agreeToCostSharing = val ?? false;
                          });
                        },
                        activeColor: AppColors.primaryPurple,
                      ),
                      const Expanded(
                        child: Text(
                          "This ride is to reduce Travel Cost but not a commercial ride",
                          style: TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildNextButton(label: "Publish Ride"),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.textDark : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppColors.primaryPurple : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton({String label = "Next"}) {
    final bool isPublish = label == "Publish Ride";
    final bool isDisabled = _isPosting || (isPublish && !_agreeToCostSharing);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey : AppColors.primaryPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        onPressed: isDisabled ? null : _nextPage,
        child: _isPosting 
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
              ],
            ),
      ),
    );
  }
}
