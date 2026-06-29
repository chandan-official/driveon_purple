import 'package:flutter/material.dart';

class RyndoAuthLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const RyndoAuthLayout({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      // Prevents keyboard from pushing up and causing new overflows
      resizeToAvoidBottomInset: true, 
      body: Column(
        children: [
          // 1. Asymmetric Purple Header
          Stack(
            children: [
              CustomPaint(
                size: Size(size.width, size.height * 0.32),
                painter: HeaderCurvePainter(),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: 0.56,
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ryndo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Roboto',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Main Login Content - FIXED OVERFLOW
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 35),
                  child, // Your existing login form logic
                  const SizedBox(height: 20), // Bottom padding to prevent clipping
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = const Color(0xFF6F42C1); 
    Path path = Path();

    path.lineTo(0, size.height * 0.70); 
    path.cubicTo(
      size.width * 0.3, size.height * 0.95, 
      size.width * 0.7, size.height * 0.85, 
      size.width * 1.1, size.height * 0.25
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}