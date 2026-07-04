import '../core/utils/time_utils.dart';
import 'day_log.dart';

/// Log ของทั้งสัปดาห์ (อาทิตย์→เสาร์) — โครงสร้างที่เก็บลง storage จริง
/// เมื่อขึ้นสัปดาห์ใหม่ ทั้งก้อนนี้จะถูกล้าง
class WeekLog {
  /// วันอาทิตย์ 00:00 ของสัปดาห์นี้ — ใช้เช็คว่าถึงเวลาล้างหรือยัง
  final DateTime weekStartDate;

  /// วันที่มีคลิป (คีย์ = startOfDay)
  final Map<DateTime, DayLog> days;

  WeekLog({required this.weekStartDate, Map<DateTime, DayLog>? days})
      : days = days ?? {};

  factory WeekLog.current([DateTime? now]) =>
      WeekLog(weekStartDate: weekStart(now ?? DateTime.now()));

  bool get isEmpty => days.values.every((d) => d.isEmpty);

  /// ดึง (หรือสร้าง) DayLog ของวันที่กำหนด
  DayLog dayFor(DateTime dt) {
    final key = startOfDay(dt);
    return days.putIfAbsent(key, () => DayLog(day: key));
  }

  DayLog? dayOrNull(DateTime dt) => days[startOfDay(dt)];

  Map<String, dynamic> toJson() => {
        'weekStartDate': weekStartDate.toIso8601String(),
        'days': days.values.map((d) => d.toJson()).toList(),
      };

  factory WeekLog.fromJson(Map<String, dynamic> j) {
    final days = <DateTime, DayLog>{};
    for (final e in (j['days'] as List)) {
      final d = DayLog.fromJson(e as Map<String, dynamic>);
      days[d.day] = d;
    }
    return WeekLog(
      weekStartDate: DateTime.parse(j['weekStartDate'] as String),
      days: days,
    );
  }
}
