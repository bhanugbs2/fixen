import 'package:flutter/material.dart';

class FixenLogo extends StatelessWidget {
  final double size;
  final bool showLabel;
  final bool showTagline;
  final bool showGlow;

  const FixenLogo({
    super.key,
    this.size = 120,
    this.showLabel = true,
    this.showTagline = false,
    this.showGlow = true,
  });

  static const String assetPath = 'web/logo.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: showGlow
              ? BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF1E3A8A,
                      ).withOpacity(isDark ? 0.35 : 0.15),
                      blurRadius: size * 0.25,
                      offset: Offset(0, size * 0.06),
                    ),
                  ],
                )
              : null,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.home_repair_service_rounded,
              size: size * 0.5,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: size * 0.18),
          Text(
            'FIXEN',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
        if (showTagline) ...[
          SizedBox(height: size * 0.06),
          Text(
            'Verified Home Service Marketplace',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.11,
              letterSpacing: 0.3,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }
}
