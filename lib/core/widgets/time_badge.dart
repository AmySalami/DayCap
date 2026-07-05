import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/design_tokens.dart';
import '../theme/text_styles.dart';

/// Component: ป้ายเวลา (HH:MM) ที่ทับบนวิดีโอ
/// ใช้ซ้ำได้ทุกที่ (Home, พรีวิวถ่าย ฯลฯ) — สไตล์ล้อกับป้ายที่เผาลงไฟล์ตอน export
/// สี/ขนาดมาจาก token ทั้งหมด (AppToken.badgeBg/badgeText, DsRadius, DsText)
class TimeBadge extends StatelessWidget {
  const TimeBadge({super.key, required this.label, this.size = DsType.quote});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppToken.badgeBg,
        borderRadius: BorderRadius.circular(DsRadius.md),
      ),
      child: Text(
        label,
        style: DsText.display(
          size: size,
          color: AppToken.badgeText,
          weight: DsType.semibold,
        ),
      ),
    );
  }
}
