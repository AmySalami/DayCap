import '../core/utils/time_utils.dart';
import 'clip.dart';

/// Log ของหนึ่งวัน = คลิปหลายอันต่อกัน (1 วัน = 1 รีล/หนัง)
class DayLog {
  /// เที่ยงคืนของวันนั้น (คีย์ของวัน)
  final DateTime day;

  /// ขนาดผืนผ้าใบของวัน = ความละเอียดของ "คลิปแรก" ของวัน
  /// คลิปถัดไปที่สัดส่วนต่างจะถูก pad ขอบดำให้พอดีตอน export
  int? canvasWidth;
  int? canvasHeight;

  final List<Clip> clips;

  DayLog({
    required this.day,
    this.canvasWidth,
    this.canvasHeight,
    List<Clip>? clips,
  }) : clips = clips ?? [];

  bool get isEmpty => clips.isEmpty;

  /// คลิปเรียงตามลำดับ
  List<Clip> get orderedClips =>
      [...clips]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  int get totalTrimmedMs =>
      clips.fold(0, (sum, c) => sum + c.trimmedDurationMs);

  /// เพิ่มคลิปต่อท้าย + ล็อก canvas จากคลิปแรกถ้ายังไม่มี
  void addClip(Clip clip, {int? width, int? height}) {
    clip.orderIndex = clips.isEmpty
        ? 0
        : clips.map((c) => c.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
    if (canvasWidth == null && width != null && height != null) {
      canvasWidth = width;
      canvasHeight = height;
    }
    clips.add(clip);
  }

  Map<String, dynamic> toJson() => {
        'day': day.toIso8601String(),
        'canvasWidth': canvasWidth,
        'canvasHeight': canvasHeight,
        'clips': clips.map((c) => c.toJson()).toList(),
      };

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
        day: DateTime.parse(j['day'] as String),
        canvasWidth: j['canvasWidth'] as int?,
        canvasHeight: j['canvasHeight'] as int?,
        clips: (j['clips'] as List)
            .map((e) => Clip.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static DayLog forDate(DateTime dt) => DayLog(day: startOfDay(dt));
}
