/// ตรรกะเวลากลางของ day_cap — จุดที่พลาดง่ายที่สุด จึงแยกเป็น pure functions
/// เพื่อ unit test ได้ครบ (ดู test/time_utils_test.dart)
///
/// กติกา:
/// - สัปดาห์เริ่ม "วันอาทิตย์ 00:00" จบ "วันเสาร์ 23:59"
/// - วันตัดที่ 00:00
/// - ป้ายเวลา = เวลาเริ่มถ่าย ปัดลงเป็นชั่วโมง (floor) → "HH:00"
/// - ล้าง Log ทั้งหมดตอน "อาทิตย์ 00:00" (= ต้นสัปดาห์ถัดไป)
/// - Countdown เริ่ม "เสาร์ 20:00" → นับถอยหลัง 4 ชม. ถึงเวลาล้าง
library;

/// ระยะเวลาก่อนล้างที่เริ่มโชว์ countdown (เสาร์ 20:00 → อาทิตย์ 00:00 = 4 ชม.)
const Duration kCountdownWindow = Duration(hours: 4);

/// ป้ายเวลาของคลิป: ปัดลงเป็นชั่วโมง เช่น 10:01 → "10:00", 12:58 → "12:00"
String hourLabel(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:00';
}

/// เที่ยงคืนของวันนั้น (ตัดเวลาออก) — ใช้แยก "วัน"
DateTime startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// วันอาทิตย์ 00:00 ของสัปดาห์ที่ dt อยู่
/// (Dart weekday: จันทร์=1 ... อาทิตย์=7; อาทิตย์คือวันแรกของสัปดาห์เรา)
DateTime weekStart(DateTime dt) {
  final d = startOfDay(dt);
  final daysSinceSunday = d.weekday % 7; // อา.=0, จ.=1, ..., ส.=6
  // ใช้ DateTime constructor เพื่อให้ปลอดภัยกับ DST และการข้ามเดือน
  return DateTime(d.year, d.month, d.day - daysSinceSunday);
}

/// เวลาที่ Log ของสัปดาห์ที่ขึ้นต้นด้วย [start] จะถูกล้าง = อาทิตย์ถัดไป 00:00
DateTime wipeTimeForWeek(DateTime start) {
  final s = weekStart(start);
  return DateTime(s.year, s.month, s.day + 7);
}

/// ควรล้างหรือยัง: now อยู่คนละสัปดาห์ (ใหม่กว่า) กับข้อมูลที่เก็บไว้
bool shouldWipe(DateTime now, DateTime storedWeekStart) {
  return weekStart(now).isAfter(weekStart(storedWeekStart));
}

/// เวลาที่เริ่มโชว์ countdown (เสาร์ 20:00) ของสัปดาห์ที่ [now] อยู่
DateTime countdownStart(DateTime now) {
  return wipeTimeForWeek(now).subtract(kCountdownWindow);
}

/// อยู่ในช่วง countdown ไหม (เสาร์ 20:00 ถึงก่อนล้าง)
bool isInCountdown(DateTime now) {
  final start = countdownStart(now);
  final wipe = wipeTimeForWeek(now);
  return !now.isBefore(start) && now.isBefore(wipe);
}

/// เวลาที่เหลือก่อนล้าง (0 ถ้าเลยไปแล้ว)
Duration timeUntilWipe(DateTime now) {
  final remaining = wipeTimeForWeek(now).difference(now);
  return remaining.isNegative ? Duration.zero : remaining;
}

/// จัดรูป countdown แบบ Duolingo: "HH:MM" เช่น 3 ชม. 59 นาที → "03:59"
String formatCountdown(Duration d) {
  final safe = d.isNegative ? Duration.zero : d;
  final h = safe.inHours;
  final m = safe.inMinutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// 7 วันของสัปดาห์ที่ [now] อยู่ (อาทิตย์ → เสาร์) สำหรับ Calendar
List<DateTime> weekDays(DateTime now) {
  final s = weekStart(now);
  return List.generate(7, (i) => DateTime(s.year, s.month, s.day + i));
}
