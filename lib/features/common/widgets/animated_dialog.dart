import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

enum AnimatedDialogType { success, error, warning, info }

class AnimatedDialog extends StatefulWidget {
  final String title;
  final String message;
  final AnimatedDialogType type;
  final String buttonText;

  const AnimatedDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.type,
    this.buttonText = "OK",
  }) : super(key: key);

  @override
  State<AnimatedDialog> createState() => _AnimatedDialogState();
}

class _AnimatedDialogState extends State<AnimatedDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case AnimatedDialogType.success:
        return Icons.check_circle_rounded;
      case AnimatedDialogType.error:
        return Icons.error_rounded;
      case AnimatedDialogType.warning:
        return Icons.warning_rounded;
      case AnimatedDialogType.info:
        return Icons.info_rounded;
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case AnimatedDialogType.success:
        return AppColors.success;
      case AnimatedDialogType.error:
        return AppColors.error;
      case AnimatedDialogType.warning:
        return AppColors.warning;
      case AnimatedDialogType.info:
        return AppColors.primaryPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getColor();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon with subtle pulse glow
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(),
                    color: themeColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                // Dialog Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                    fontFamily: 'Roboto', // standard fallback if Outfit not registered
                  ),
                ),
                const SizedBox(height: 12),
                // Dialog Message
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                    height: 1.4,
                    decoration: TextDecoration.none,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 24),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      _controller.reverse().then((_) {
                        Navigator.of(context).pop();
                      });
                    },
                    child: Text(
                      widget.buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<dynamic> showAnimatedDialog(
  BuildContext context, {
  required String title,
  required String message,
  required AnimatedDialogType type,
  String buttonText = "OK",
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "AnimatedDialog",
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return AnimatedDialog(
        title: title,
        message: message,
        type: type,
        buttonText: buttonText,
      );
    },
  );
}
