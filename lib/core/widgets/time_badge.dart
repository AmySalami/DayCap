import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/design_tokens.dart';
import '../theme/text_styles.dart';

/// Component: ป้ายเวลา (HH:MM) ที่ทับบนวิดีโอ
/// ใช้ซ้ำได้ทุกที่ (Home, พรีวิวถ่าย ฯลฯ)
/// สไตล์ eyebrow label (เว้นวรรคกว้าง) ขนาด h3 ไม่มีพื้นหลัง/เงา
class TimeBadge extends StatelessWidget {
  const TimeBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: DsText.eyebrow(color: AppToken.badgeText, size: DsType.h3),
    );
  }
}
