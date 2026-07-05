import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/reel_provider.dart';

/// แบนเนอร์นับถอยหลังก่อนล้าง Log รายสัปดาห์ (เสาร์ 20:00 → อาทิตย์ 00:00)
/// - โชว์เฉพาะช่วง countdown, HH:MM สไตล์ Duolingo, อัปเดต realtime
/// - ถ้าถึงเวลาล้างตอนแอปเปิดอยู่ → สั่งล้างทันที
class CountdownBanner extends ConsumerStatefulWidget {
  const CountdownBanner({super.key});

  @override
  ConsumerState<CountdownBanner> createState() => _CountdownBannerState();
}

class _CountdownBannerState extends ConsumerState<CountdownBanner> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _wiping = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _maybeWipe();
    });
  }

  /// ถ้าข้ามเข้าสัปดาห์ใหม่ระหว่างเปิดแอป → รีโหลด (จะล้างให้เอง)
  void _maybeWipe() {
    if (_wiping) return;
    final week = ref.read(reelProvider).value;
    if (week != null && shouldWipe(_now, week.weekStartDate)) {
      _wiping = true;
      ref.read(reelProvider.notifier).refresh().whenComplete(() {
        _wiping = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ⚠️ ชั่วคราวสำหรับ preview หน้าตา — ตั้ง false ก่อน production
  static const bool _preview = false;

  @override
  Widget build(BuildContext context) {
    final showing = _preview || isInCountdown(_now);
    if (!showing) return const SizedBox.shrink();
    final remaining = _preview && !isInCountdown(_now)
        ? '03:59:30'
        : formatCountdown(timeUntilWipe(_now));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppToken.alertFill, // accent (amber) ตามกติกา DS
        borderRadius: BorderRadius.circular(DsRadius.md),
        boxShadow: DsElevation.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: AppToken.alertText, size: DsType.icon),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ล้าง Log ใน  $remaining',
                style: const TextStyle(
                  color: AppToken.alertText, // navy บนพื้น accent
                  fontSize: DsType.body,
                  fontWeight: DsType.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'เซฟก่อนหาย! ทุกอย่างจะถูกลบเที่ยงคืนวันอาทิตย์',
                style: TextStyle(
                  color: AppToken.alertText.withValues(alpha: 0.75),
                  fontSize: DsType.badge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
