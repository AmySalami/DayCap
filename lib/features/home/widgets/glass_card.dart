import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/design_tokens.dart';

/// การ์ดเอฟเฟกต์กระจกฝ้า (frosted glass) — ฐานของ Adjust zone
/// ทำแบบเรียบง่าย: ClipRRect + BackdropFilter blur + พื้นขาวโปร่ง + ขอบบาง
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blur = 18,
    this.radius = DsRadius.lg,
    this.fill = AppToken.glassFill,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double radius;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppToken.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
