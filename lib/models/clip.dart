import '../core/utils/time_utils.dart';

/// หนึ่งคลิป = หนึ่งครั้งที่กดถ่าย
class Clip {
  final String id;

  /// ชื่อไฟล์อย่างเดียว (relative ต่อโฟลเดอร์ clips) — กัน path เปลี่ยนตอนแอปย้ายที่
  final String fileName;

  /// เวลาเริ่มถ่ายจริง (ใช้คำนวณป้ายเวลา + จัดวัน)
  final DateTime recordedAt;

  /// ความยาวคลิปดิบ (ms)
  final int durationMs;

  /// ลำดับต่อคลิปในวัน
  int orderIndex;

  /// จุดตัดหัว-ท้าย (แบบ IG: ย่อ/ขยายปลายทั้งสองด้านเท่านั้น ตัดกลางไม่ได้)
  int trimStartMs;
  int trimEndMs;

  Clip({
    required this.id,
    required this.fileName,
    required this.recordedAt,
    required this.durationMs,
    required this.orderIndex,
    int? trimStartMs,
    int? trimEndMs,
  })  : trimStartMs = trimStartMs ?? 0,
        trimEndMs = trimEndMs ?? durationMs;

  /// ป้ายเวลาที่จะโชว์/เผาลงวิดีโอ = เวลาจริง "HH:MM"
  String get label => timeLabel(recordedAt);

  /// ความยาวหลังตัด
  int get trimmedDurationMs => (trimEndMs - trimStartMs).clamp(0, durationMs);

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'recordedAt': recordedAt.toIso8601String(),
        'durationMs': durationMs,
        'orderIndex': orderIndex,
        'trimStartMs': trimStartMs,
        'trimEndMs': trimEndMs,
      };

  factory Clip.fromJson(Map<String, dynamic> j) => Clip(
        id: j['id'] as String,
        fileName: j['fileName'] as String,
        recordedAt: DateTime.parse(j['recordedAt'] as String),
        durationMs: j['durationMs'] as int,
        orderIndex: j['orderIndex'] as int,
        trimStartMs: j['trimStartMs'] as int?,
        trimEndMs: j['trimEndMs'] as int?,
      );
}
