import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// แถบความคืบหน้าแบบ IG Story (ภาพ 4) — 1 ช่องต่อ 1 คลิป
/// ช่องที่เล่นผ่านแล้ว = เต็ม, ช่องกำลังเล่น = เติมตาม progress, ช่องถัดไป = จาง
class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.count,
    required this.currentIndex,
    this.progress = 0,
  });

  final int count;
  final int currentIndex;
  final double progress; // 0..1 ของคลิปปัจจุบัน

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Row(
      children: List.generate(count, (i) {
        final double fill;
        if (i < currentIndex) {
          fill = 1;
        } else if (i == currentIndex) {
          fill = progress.clamp(0, 1);
        } else {
          fill = 0;
        }
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(height: 3, color: AppToken.progressTrack),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(height: 3, color: AppToken.progressFill),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
