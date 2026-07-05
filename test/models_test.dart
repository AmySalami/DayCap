import 'package:flutter_test/flutter_test.dart';
import 'package:day_cap/models/clip.dart';
import 'package:day_cap/models/day_log.dart';
import 'package:day_cap/models/week_log.dart';

Clip _clip(String id, DateTime at, {int dur = 5000}) => Clip(
      id: id,
      fileName: '$id.mp4',
      recordedAt: at,
      durationMs: dur,
      orderIndex: 0,
    );

void main() {
  group('Clip', () {
    test('label = เวลาจริง HH:MM จาก recordedAt', () {
      expect(_clip('a', DateTime(2026, 7, 3, 12, 58)).label, '12:58');
    });
    test('trim default = เต็มคลิป', () {
      final c = _clip('a', DateTime(2026, 7, 3, 10), dur: 8000);
      expect(c.trimmedDurationMs, 8000);
    });
    test('trimmedDuration หลังตัดหัว-ท้าย', () {
      final c = _clip('a', DateTime(2026, 7, 3, 10), dur: 8000)
        ..trimStartMs = 1000
        ..trimEndMs = 6000;
      expect(c.trimmedDurationMs, 5000);
    });
    test('round-trip JSON', () {
      final c = _clip('a', DateTime(2026, 7, 3, 10, 1), dur: 8000)
        ..trimStartMs = 500
        ..trimEndMs = 7000
        ..orderIndex = 2;
      final back = Clip.fromJson(c.toJson());
      expect(back.id, 'a');
      expect(back.recordedAt, DateTime(2026, 7, 3, 10, 1));
      expect(back.trimStartMs, 500);
      expect(back.trimEndMs, 7000);
      expect(back.orderIndex, 2);
      expect(back.label, '10:01');
    });
  });

  group('DayLog', () {
    test('addClip ต่อท้าย + เพิ่ม orderIndex', () {
      final d = DayLog.forDate(DateTime(2026, 7, 3));
      d.addClip(_clip('a', DateTime(2026, 7, 3, 10)));
      d.addClip(_clip('b', DateTime(2026, 7, 3, 11)));
      expect(d.clips[0].orderIndex, 0);
      expect(d.clips[1].orderIndex, 1);
    });
    test('canvas ล็อกจากคลิปแรกเท่านั้น', () {
      final d = DayLog.forDate(DateTime(2026, 7, 3));
      d.addClip(_clip('a', DateTime(2026, 7, 3, 10)),
          width: 1080, height: 1920); // แนวตั้ง
      d.addClip(_clip('b', DateTime(2026, 7, 3, 11)),
          width: 1920, height: 1080); // แนวนอน — ต้องไม่เปลี่ยน canvas
      expect(d.canvasWidth, 1080);
      expect(d.canvasHeight, 1920);
    });
    test('totalTrimmedMs รวมหลังตัด', () {
      final d = DayLog.forDate(DateTime(2026, 7, 3));
      d.addClip(_clip('a', DateTime(2026, 7, 3, 10), dur: 5000));
      d.addClip(_clip('b', DateTime(2026, 7, 3, 11), dur: 5000)
        ..trimEndMs = 3000);
      expect(d.totalTrimmedMs, 8000);
    });
  });

  group('WeekLog', () {
    test('dayFor สร้าง/คืนวันเดิม', () {
      final w = WeekLog.current(DateTime(2026, 7, 3));
      final d1 = w.dayFor(DateTime(2026, 7, 3, 10));
      final d2 = w.dayFor(DateTime(2026, 7, 3, 22));
      expect(identical(d1, d2), true); // วันเดียวกัน → object เดียว
      expect(w.days.length, 1);
    });
    test('คนละวัน → คนละ DayLog', () {
      final w = WeekLog.current(DateTime(2026, 7, 3));
      w.dayFor(DateTime(2026, 7, 3));
      w.dayFor(DateTime(2026, 7, 4));
      expect(w.days.length, 2);
    });
    test('round-trip JSON ทั้งสัปดาห์', () {
      final w = WeekLog.current(DateTime(2026, 7, 3));
      w.dayFor(DateTime(2026, 7, 3))
          .addClip(_clip('a', DateTime(2026, 7, 3, 10)), width: 1080, height: 1920);
      final back = WeekLog.fromJson(w.toJson());
      expect(back.weekStartDate, w.weekStartDate);
      expect(back.days.length, 1);
      final day = back.dayOrNull(DateTime(2026, 7, 3))!;
      expect(day.canvasWidth, 1080);
      expect(day.clips.single.label, '10:00');
    });
  });
}
