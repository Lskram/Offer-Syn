import 'package:flutter/material.dart';

class OfficeReliefMascot extends StatelessWidget {
  const OfficeReliefMascot({
    super.key,
    this.size = 160,
    this.fit = BoxFit.contain,
  });

  static const assetPath = 'assets/branding/office_relief_mascot.png';

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
              borderRadius: BorderRadius.circular(size * 0.24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFDFF3FF),
                  Color(0xFFEAFBFF),
                  Color(0xFFF1FFD8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.pets_rounded,
              size: size * 0.48,
              color: const Color(0xFF0A67D9),
            ),
          );
        },
      ),
    );
  }
}
