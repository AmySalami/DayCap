import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/time_utils.dart';

/// แถบปฏิทิน 7 วัน (อาทิตย์→เสาร์) แบบวงกลม — อยู่ใน Adjust zone
/// วันที่มีคลิป = จุด sage ใต้เลข, วันที่เลือก = วงกลม accent + เลข navy, วันนี้ = ขอบ accent
class WeekCalendarStrip extends StatelessWidget {
  const WeekCalendarStrip({
    super.key,
    required this.selectedDay,
    required this.daysWithClips,
    required this.onSelect,
  });

  final DateTime selectedDay;
  final Set<DateTime> daysWithClips;
  final ValueChanged<DateTime> onSelect;

  static const _dowTh = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  @override
  Widget build(BuildContext context) {
    final days = weekDays(DateTime.now()); // อา.→ส. ของสัปดาห์นี้
    final today = startOfDay(DateTime.now());
    final selected = startOfDay(selectedDay);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (i) {
        final day = days[i];
        return _DayChip(
          dow: _dowTh[i],
          dayNum: day.day,
          isSelected: day == selected,
          isToday: day == today,
          isFuture: day.isAfter(today),
          hasClips: daysWithClips.contains(day),
          onTap: day.isAfter(today) ? null : () => onSelect(day),
        );
      }),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.dow,
    required this.dayNum,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.hasClips,
    required this.onTap,
  });

  final String dow;
  final int dayNum;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final bool hasClips;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final numColor = isSelected
        ? DsColor.secondary // เลขบนพื้น accent = navy
        : DsColor.white.withValues(alpha: isFuture ? 0.35 : 1);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dow,
            style: TextStyle(
              color: DsColor.white.withValues(alpha: isFuture ? 0.3 : 0.7),
              fontSize: DsType.label,
              fontWeight: DsType.semibold,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? DsColor.accent : DsColor.whiteFaint,
              border: isToday && !isSelected
                  ? Border.all(color: DsColor.accent, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$dayNum',
              style: TextStyle(
                color: numColor,
                fontSize: DsType.sm,
                fontWeight: isSelected ? DsType.bold : DsType.semibold,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasClips ? DsColor.sage : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
