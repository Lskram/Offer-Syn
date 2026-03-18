import 'package:flutter/material.dart';

class OfficeReliefBrandMark extends StatelessWidget {
  const OfficeReliefBrandMark({
    super.key,
    this.size = 88,
    this.showWordmark = true,
    this.center = false,
  });

  static const assetPath = 'assets/branding/office_relief_in_app_logo.png';

  final double size;
  final bool showWordmark;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _FallbackBrandOrb(size: size);
            },
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              'OfficeRelief',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF062348),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FallbackBrandOrb extends StatelessWidget {
  const _FallbackBrandOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF0A5FD0), Color(0xFF18B8E2), Color(0xFFB9F32B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3318B8E2),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Text(
              'OR',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
          ),
          Positioned(
            top: -4,
            right: -2,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDA74),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Color(0xFF8B4D00),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
