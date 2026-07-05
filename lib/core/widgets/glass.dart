import 'dart:ui';

import 'package:flutter/widgets.dart';

/// สไตล์กระจกฝ้า (Liquid Glass approximate) ใช้ร่วมกับปุ่มทั้งแอป
/// = backdrop blur + พื้นดำโปร่ง + ขอบบางเรืองแสง
const Color kGlassFill = Color(0x66101012);
const Color kGlassBorder = Color(0x40FFFFFF);
const double kGlassBlur = 22;

/// ปุ่มกลมกระจกฝ้า (สำหรับไอคอน)
class GlassCircle extends StatelessWidget {
  const GlassCircle({
    super.key,
    required this.child,
    this.onTap,
    this.size = 52,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final content = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kGlassBlur, sigmaY: kGlassBlur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: kGlassFill,
            shape: BoxShape.circle,
            border: Border.all(color: kGlassBorder, width: 0.5),
          ),
          child: Center(child: child),
        ),
      ),
    );
    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

/// ปุ่ม/แถบทรงแคปซูลกระจกฝ้า (สำหรับข้อความ หรือกลุ่มไอคอน)
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kGlassBlur, sigmaY: kGlassBlur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: kGlassFill,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: kGlassBorder, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
