import 'package:flutter_test/flutter_test.dart';
import 'package:day_cap/core/utils/time_utils.dart';

void main() {
  group('timeLabel — เวลาจริง HH:MM', () {
    test('10:01 → 10:01', () {
      expect(timeLabel(DateTime(2026, 7, 3, 10, 1)), '10:01');
    });
    test('12:58 → 12:58', () {
      expect(timeLabel(DateTime(2026, 7, 3, 12, 58)), '12:58');
    });
    test('เที่ยงคืน 00:30 → 00:30', () {
      expect(timeLabel(DateTime(2026, 7, 3, 0, 30)), '00:30');
    });
    test('เติม 0 หน้าเลขหลักเดียว → 09:05', () {
      expect(timeLabel(DateTime(2026, 7, 3, 9, 5)), '09:05');
    });
  });

  group('weekStart — อาทิตย์ 00:00', () {
    // 2026-07-03 เป็นวันศุกร์ → อาทิตย์ของสัปดาห์นี้คือ 2026-06-28
    test('ศุกร์ 3 ก.ค. 2026 → อา. 28 มิ.ย. 2026', () {
      expect(weekStart(DateTime(2026, 7, 3, 14, 0)), DateTime(2026, 6, 28));
    });
    test('วันอาทิตย์เอง → ตัวเอง 00:00', () {
      expect(weekStart(DateTime(2026, 6, 28, 23, 59)), DateTime(2026, 6, 28));
    });
    test('วันเสาร์ → อาทิตย์ก่อนหน้า', () {
      expect(weekStart(DateTime(2026, 7, 4, 12, 0)), DateTime(2026, 6, 28));
    });
    test('ข้ามเดือน: อา. 1 ก.พ. → 1 ก.พ.', () {
      expect(weekStart(DateTime(2026, 2, 1, 8)), DateTime(2026, 2, 1));
    });
  });

  group('wipeTime & shouldWipe', () {
    test('สัปดาห์เริ่ม 28 มิ.ย. → ล้าง 5 ก.ค. 00:00', () {
      expect(wipeTimeForWeek(DateTime(2026, 6, 28)), DateTime(2026, 7, 5));
    });
    test('ยังอยู่สัปดาห์เดิม → ไม่ล้าง', () {
      final stored = weekStart(DateTime(2026, 7, 1));
      expect(shouldWipe(DateTime(2026, 7, 4, 23, 59), stored), false);
    });
    test('ข้ามไปสัปดาห์ใหม่ → ล้าง', () {
      final stored = weekStart(DateTime(2026, 7, 1));
      expect(shouldWipe(DateTime(2026, 7, 5, 0, 1), stored), true);
    });
    test('ข้ามหลายสัปดาห์ (เปิดแอปหลังหายไปนาน) → ล้าง', () {
      final stored = weekStart(DateTime(2026, 7, 1));
      expect(shouldWipe(DateTime(2026, 8, 1), stored), true);
    });
  });

  group('countdown — เสาร์ 20:00 → อาทิตย์ 00:00', () {
    test('countdownStart = เสาร์ 20:00', () {
      // สัปดาห์ 28 มิ.ย.–4 ก.ค. → เสาร์คือ 4 ก.ค., 20:00
      expect(countdownStart(DateTime(2026, 7, 3)), DateTime(2026, 7, 4, 20, 0));
    });
    test('ศุกร์ยังไม่เข้า countdown', () {
      expect(isInCountdown(DateTime(2026, 7, 3, 23, 0)), false);
    });
    test('เสาร์ 20:00 เข้า countdown แล้ว', () {
      expect(isInCountdown(DateTime(2026, 7, 4, 20, 0)), true);
    });
    test('เสาร์ 21:30 ยังอยู่ใน countdown', () {
      expect(isInCountdown(DateTime(2026, 7, 4, 21, 30)), true);
    });
    test('timeUntilWipe ที่เสาร์ 20:00 = 4 ชม.', () {
      expect(timeUntilWipe(DateTime(2026, 7, 4, 20, 0)),
          const Duration(hours: 4));
    });
    test('timeUntilWipe ที่เสาร์ 22:15 = 1 ชม. 45 นาที', () {
      expect(timeUntilWipe(DateTime(2026, 7, 4, 22, 15)),
          const Duration(hours: 1, minutes: 45));
    });
  });

  group('formatCountdown — HH:MM:SS', () {
    test('4 ชม. → 04:00:00', () {
      expect(formatCountdown(const Duration(hours: 4)), '04:00:00');
    });
    test('1 ชม. 45 นาที → 01:45:00', () {
      expect(formatCountdown(const Duration(hours: 1, minutes: 45)), '01:45:00');
    });
    test('3 ชม. 59 นาที 30 วิ → 03:59:30', () {
      expect(
          formatCountdown(
              const Duration(hours: 3, minutes: 59, seconds: 30)),
          '03:59:30');
    });
    test('ติดลบ → 00:00:00', () {
      expect(formatCountdown(const Duration(seconds: -10)), '00:00:00');
    });
  });

  group('stepDay — เลื่อนวันแบบ clamp ไม่วน', () {
    // สัปดาห์ 28 มิ.ย.(อา.) – 4 ก.ค.(ส.) 2026
    final sat = DateTime(2026, 7, 4);
    final sun = DateTime(2026, 6, 28);
    test('เสาร์ + ปัดต่อ = อยู่เสาร์ (ไม่วน)', () {
      expect(stepDay(sat, 1, now: sat), sat);
    });
    test('อาทิตย์ - ปัดต่อ = อยู่อาทิตย์ (ไม่วน)', () {
      expect(stepDay(sun, -1, now: sat), sun);
    });
    test('พุธ +1 = พฤหัส', () {
      expect(stepDay(DateTime(2026, 7, 1), 1, now: sat), DateTime(2026, 7, 2));
    });
    test('พุธ -1 = อังคาร', () {
      expect(stepDay(DateTime(2026, 7, 1), -1, now: sat), DateTime(2026, 6, 30));
    });
    test('เสาร์ -1 = ศุกร์', () {
      expect(stepDay(sat, -1, now: sat), DateTime(2026, 7, 3));
    });
  });

  group('weekDays — 7 วัน อาทิตย์→เสาร์', () {
    test('คืน 7 วันเรียงถูก', () {
      final days = weekDays(DateTime(2026, 7, 3));
      expect(days.length, 7);
      expect(days.first, DateTime(2026, 6, 28)); // อาทิตย์
      expect(days.last, DateTime(2026, 7, 4)); // เสาร์
      expect(days[3], DateTime(2026, 7, 1)); // พุธ
    });
  });
}
