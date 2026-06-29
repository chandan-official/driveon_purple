import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

class RideMapScreen extends StatefulWidget {
  const RideMapScreen({super.key});

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  bool _within20mToEnd = false; // stub (GPS logic later)

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final ride = args["ride"];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          "Trip Map",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  // ✅ Google Map placeholder (commented until you add API)
                  /*
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentLat, currentLng),
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  )
                  */
                  const Center(
                    child: Text(
                      "Google Map is commented.\nAdd API key later to enable tracking.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.textDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _within20mToEnd
                                  ? "You are within 20m. You can end the trip."
                                  : "Move within 20m of destination to enable End.",
                              style: const TextStyle(color: AppColors.textDark),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Stub toggle (remove after GPS is enabled)
                              setState(() => _within20mToEnd = !_within20mToEnd);
                            },
                            child: const Text("Test"),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _within20mToEnd
                    ? () {
                        // TODO: Call backend "end trip" API when you create it
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Trip ended (stub).")),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  "End",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
