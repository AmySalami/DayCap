import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../core/utils/time_utils.dart';
import '../models/clip.dart';
import '../models/week_log.dart';
import '../services/clip_repository.dart';
import '../services/export_service.dart';
import '../services/gallery_service.dart';
import '../services/share_service.dart';
import '../services/storage_service.dart';

final storageProvider = Provider<StorageService>((ref) => StorageService());

final repositoryProvider = Provider<ClipRepository>(
  (ref) => ClipRepository(ref.read(storageProvider)),
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(ref.read(storageProvider)),
);

final galleryServiceProvider =
    Provider<GalleryService>((ref) => GalleryService());

final shareServiceProvider = Provider<ShareService>((ref) => ShareService());

/// State หลักของแอป = WeekLog ปัจจุบัน (โหลด+ล้างอัตโนมัติตอนเปิด)
final reelProvider =
    AsyncNotifierProvider<ReelController, WeekLog>(ReelController.new);

class ReelController extends AsyncNotifier<WeekLog> {
  static const _uuid = Uuid();

  StorageService get _storage => ref.read(storageProvider);
  ClipRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<WeekLog> build() async {
    return _repo.load();
  }

  /// เพิ่มคลิปที่เพิ่งอัดเสร็จ (จาก temp path ของ camera) ต่อท้ายวันปัจจุบัน
  Future<void> addRecording({
    required String tempPath,
    DateTime? recordedAt,
  }) async {
    final at = recordedAt ?? DateTime.now();

    // เผื่อแอปเปิดค้างข้ามสัปดาห์ → โหลดใหม่ (จะล้างให้เองถ้าจำเป็น)
    var week = state.value;
    if (week == null || shouldWipe(at, week.weekStartDate)) {
      week = await _repo.load(now: at);
    }

    final id = _uuid.v4();
    final fileName = '$id.mp4';
    await _storage.importRecording(tempPath, fileName);

    // ตัด guard ขอบ + re-encode (แก้เสียง artifact หัว-ท้ายจากไฟล์กล้อง)
    final absPath = await _storage.absolutePath(fileName);
    final raw = await _probe(absPath);
    await ref
        .read(exportServiceProvider)
        .trimGuardInPlace(absPath, raw.durationMs);

    // อ่านความยาว + ขนาดจริงจากไฟล์ (หลังตัด/re-encode)
    final meta = await _probe(absPath);

    final clip = Clip(
      id: id,
      fileName: fileName,
      recordedAt: at,
      durationMs: meta.durationMs,
      orderIndex: 0,
    );

    week.dayFor(at).addClip(clip, width: meta.width, height: meta.height);
    await _repo.save(week);
    state = AsyncData(week.copy());
  }

  /// ลบคลิป
  Future<void> deleteClip(DateTime day, String clipId) async {
    final week = state.value;
    if (week == null) return;
    final dayLog = week.dayOrNull(day);
    if (dayLog == null) return;
    final idx = dayLog.clips.indexWhere((c) => c.id == clipId);
    if (idx == -1) return;
    final removed = dayLog.clips.removeAt(idx);
    await _storage.deleteClipFile(removed.fileName);
    if (dayLog.isEmpty) week.days.remove(dayLog.day);
    await _repo.save(week);
    state = AsyncData(week.copy());
  }

  /// อัปเดตจุดตัดหัว-ท้ายของคลิป
  Future<void> updateTrim(
    DateTime day,
    String clipId, {
    required int trimStartMs,
    required int trimEndMs,
  }) async {
    final week = state.value;
    if (week == null) return;
    final clip = week.dayOrNull(day)?.clips.firstWhere((c) => c.id == clipId);
    if (clip == null) return;
    clip.trimStartMs = trimStartMs;
    clip.trimEndMs = trimEndMs;
    await _repo.save(week);
    state = AsyncData(week.copy());
  }

  /// จัดลำดับคลิปใหม่ (ลากสลับในหน้า Timeline)
  Future<void> reorderClips(DateTime day, int oldIndex, int newIndex) async {
    final week = state.value;
    if (week == null) return;
    final dayLog = week.dayOrNull(day);
    if (dayLog == null) return;
    final ordered = dayLog.orderedClips; // อ้างอิง Clip object เดิม
    if (newIndex > oldIndex) newIndex -= 1;
    final item = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, item);
    for (var i = 0; i < ordered.length; i++) {
      ordered[i].orderIndex = i;
    }
    await _repo.save(week);
    state = AsyncData(week.copy());
  }

  /// บังคับโหลดใหม่ (เช็ค+ล้างรายสัปดาห์)
  Future<void> refresh() async {
    state = AsyncData(await _repo.load());
  }

  Future<_ProbeResult> _probe(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final size = controller.value.size;
      return _ProbeResult(
        durationMs: controller.value.duration.inMilliseconds,
        width: size.width.round(),
        height: size.height.round(),
      );
    } catch (_) {
      return const _ProbeResult(durationMs: 0, width: 0, height: 0);
    } finally {
      await controller.dispose();
    }
  }
}

class _ProbeResult {
  const _ProbeResult({
    required this.durationMs,
    required this.width,
    required this.height,
  });
  final int durationMs;
  final int width;
  final int height;
}

/// helper: ดึงคลิปเรียงลำดับของวันหนึ่ง (ว่างถ้าไม่มี)
List<Clip> clipsForDay(WeekLog week, DateTime day) {
  return week.dayOrNull(day)?.orderedClips ?? const [];
}
