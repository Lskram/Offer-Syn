import 'package:flutter/material.dart';

class OfficeReliefCompleteState extends StatelessWidget {
  const OfficeReliefCompleteState({
    super.key,
    this.size = 160,
    this.fit = BoxFit.contain,
  });

  static const assetPath = 'assets/branding/office_relief_complete_state.png';

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
                  Color(0xFFDFF7FF),
                  Color(0xFFEFFFF2),
                  Color(0xFFFFFADB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.celebration_rounded,
              size: size * 0.48,
              color: const Color(0xFF0A67D9),
            ),
          );
        },
      ),
    );
  }
}
