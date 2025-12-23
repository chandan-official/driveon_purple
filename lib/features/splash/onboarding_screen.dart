import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/animations/fade_slide_transition.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Exact Text from your Reference Image
  final List<Map<String, String>> _pages = [
    {
      "headline": "Welcome to DriveOn",
      "subHeadline": "Your Ride, Your Way!",
      "image": "assets/images/onboarding_1.png",
    },
    // Keeping placeholders for 2 and 3 consistent with the style
    {
      "headline": "Track Parcels",
      "subHeadline": "Global Delivery Tracking",
      "image": "assets/images/onboarding_2.png",
    },
    {
      "headline": "Earn Money",
      "subHeadline": "Join Our Driver Network",
      "image": "assets/images/onboarding_3.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Get screen height to position elements precisely
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. FULL SCREEN IMAGE
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Image.asset(
                _pages[index]['image']!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Text(
                        "Image not found",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 2. GRADIENT OVERLAYS (Crucial for the "Look")
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // Top: Stronger White Mist (Makes the Black Text Pop)
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.3),

                  // Middle: Transparent
                  Colors.transparent,

                  // Bottom: Dark Fade (Makes Buttons Pop)
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.25, 0.5, 0.8, 1.0],
              ),
            ),
          ),

          // ============================================
          // 3. TOP HEADER: LOGO + TEXT (Exact Placement)
          // ============================================
          Positioned(
            top: topPadding + 15, // Just below status bar
            left: 0,
            right: 0,
            child: Column(
              children: [
                // A. THE LOGO ("DriveOn") - BIGGER
                FadeSlideTransition(
                  delay: 0,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Drive',
                          style: TextStyle(
                            color: AppColors.primaryPurple, // Navy Blue
                            fontSize: 40, // INCREASED SIZE
                            fontWeight: FontWeight.w900, // Extra Bold
                            fontFamily: 'Roboto',
                          ),
                        ),
                        TextSpan(
                          text: 'On',
                          style: TextStyle(
                            color: AppColors.primaryGold, // Orange
                            fontSize: 40, // INCREASED SIZE
                            fontWeight: FontWeight.w900, // Extra Bold
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // B. MAIN HEADLINE ("Welcome to DriveOn") - BLACK
                FadeSlideTransition(
                  delay: 0.1,
                  child: Text(
                    _pages[_currentPage]['headline']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black, // CHANGED TO BLACK
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      // Shadows removed for clean black text
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // C. SUB-HEADLINE ("Your Ride, Your Way!") - BLACK
                FadeSlideTransition(
                  delay: 0.2,
                  child: Text(
                    _pages[_currentPage]['subHeadline']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black, // CHANGED TO BLACK
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      // Shadows removed for clean black text
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ============================================
          // 4. BOTTOM CONTROLS (Exact Layout)
          // ============================================
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // A. INDICATORS (Left Side)
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      height: 6,
                      // Active: Wide Orange Dash, Inactive: Small White Dot
                      width: _currentPage == index ? 24 : 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primaryGold
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

                // B. BUTTONS (Right Side)
                Row(
                  children: [
                    // BACK BUTTON (Glassy/Outline)
                    if (_currentPage > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => _controller.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              // Transparent center, White Border
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(
                                16,
                              ), // Rounded Square
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // NEXT BUTTON (Solid White)
                    GestureDetector(
                      onTap: () {
                        if (_currentPage == _pages.length - 1) {
                          Navigator.pushReplacementNamed(context, '/login');
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.white, // Solid White
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // Rounded Square
                        ),
                        // Icon is Dark for contrast
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
