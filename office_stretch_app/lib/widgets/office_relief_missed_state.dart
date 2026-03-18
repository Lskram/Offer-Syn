import 'package:flutter/material.dart';

class OfficeReliefMissedState extends StatelessWidget {
  const OfficeReliefMissedState({
    super.key,
    this.size = 160,
    this.fit = BoxFit.contain,
  });

  static const assetPath = 'assets/branding/office_relief_missed_state.png';

  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.22),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFF7D6),
                  Color(0xFFFFF1E2),
                  Color(0xFFE7F6FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.notification_important_outlined,
              size: size * 0.48,
              color: const Color(0xFFDD8B00),
            ),
          );
        },
      ),
    );
  }
}
