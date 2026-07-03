import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color borderGradientColor;
  final Color bgGradientColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 15.0,
    this.borderGradientColor = const Color(0x33FFFFFF),
    this.bgGradientColor = const Color(0x1AFFFFFF),
    this.padding = const EdgeInsets.all(20.0),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? borderGradientColor : Colors.black12,
              width: 1.5,
            ),
            color: isDark 
                ? bgGradientColor 
                : Colors.white.withOpacity(0.8),
          ),
          child: child,
        ),
      ),
    );
  }
}
