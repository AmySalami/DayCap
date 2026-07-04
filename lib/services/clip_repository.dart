import 'dart:convert';

import '../core/utils/time_utils.dart';
import '../models/week_log.dart';
import 'storage_service.dart';

/// อ่าน/เขียน WeekLog ลง storage + บังคับกฎล้างรายสัปดาห์
class ClipRepository {
  ClipRepository(this._storage);

  final StorageService _storage;

  /// โหลด WeekLog ปัจจุบัน
  /// - ถ้าไม่มีไฟล์ → สัปดาห์ใหม่ว่างเปล่า
  /// - ถ้าข้อมูลที่เก็บไว้อยู่คนละสัปดาห์ (เก่ากว่า) → ล้างทิ้งแล้วเริ่มใหม่
  Future<WeekLog> load({DateTime? now}) async {
    final currentNow = now ?? DateTime.now();
    final meta = await _storage.metaFile();

    if (!await meta.exists()) {
      return WeekLog.current(currentNow);
    }

    try {
      final json = jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
      final stored = WeekLog.fromJson(json);
      if (shouldWipe(currentNow, stored.weekStartDate)) {
        await _storage.wipeAll();
        return WeekLog.current(currentNow);
      }
      return stored;
    } catch (_) {
      // ไฟล์เสีย → เริ่มใหม่อย่างปลอดภัย
      await _storage.wipeAll();
      return WeekLog.current(currentNow);
    }
  }

  /// บันทึก WeekLog ลงไฟล์
  Future<void> save(WeekLog week) async {
    final meta = await _storage.metaFile();
    await meta.writeAsString(jsonEncode(week.toJson()));
  }
}
