import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../models/day_log.dart';
import 'storage_service.dart';
import 'text_overlay_service.dart';

class ExportProgress {
  const ExportProgress(this.current, this.total, this.message);
  final int current;
  final int total;
  final String message;
  double get fraction => total == 0 ? 0 : current / total;
}

class ExportException implements Exception {
  ExportException(this.message);
  final String message;
  @override
  String toString() => 'ExportException: $message';
}

/// รวมคลิปของ "วัน" เป็นไฟล์เดียว:
/// 1) แต่ละคลิป → ตัดตาม trim + scale/pad ให้เท่าผืนผ้าใบ (ratio คลิปแรก) + overlay ป้ายเวลา
/// 2) นำ segment มา concat ต่อกันเป็น mp4 เดียว
class ExportService {
  ExportService(this._storage);
  final StorageService _storage;

  Future<String> exportDay(
    DayLog day, {
    void Function(ExportProgress)? onProgress,
  }) async {
    final clips = day.orderedClips;
    if (clips.isEmpty) {
      throw ExportException('วันนี้ไม่มีคลิปให้รวม');
    }

    // ผืนผ้าใบ = ขนาดคลิปแรก (ทำให้เป็นเลขคู่สำหรับ H.264)
    final w = _even(day.canvasWidth ?? 1080);
    final h = _even(day.canvasHeight ?? 1920);

    final tmp = await getTemporaryDirectory();
    final work = Directory('${tmp.path}/daycap_export');
    if (await work.exists()) await work.delete(recursive: true);
    await work.create(recursive: true);

    final total = clips.length + 1; // + ขั้น concat
    final segments = <String>[];

    for (var i = 0; i < clips.length; i++) {
      onProgress?.call(
          ExportProgress(i, total, 'ประมวลผลคลิป ${i + 1}/${clips.length}'));
      final clip = clips[i];

      // ป้ายเวลา → PNG เท่าผืนผ้าใบ
      final png = await renderLabelPng(label: clip.label, width: w, height: h);
      final pngPath = '${work.path}/label_$i.png';
      await File(pngPath).writeAsBytes(png);

      final input = await _storage.absolutePath(clip.fileName);
      final segPath = '${work.path}/seg_$i.mp4';
      final startSec = (clip.trimStartMs / 1000).toStringAsFixed(3);
      final durSec = (clip.trimmedDurationMs / 1000).toStringAsFixed(3);

      final args = <String>[
        '-y',
        '-ss', startSec,
        '-t', durSec,
        '-i', input,
        '-i', pngPath,
        '-filter_complex',
        '[0:v]scale=$w:$h:force_original_aspect_ratio=decrease,'
            'pad=$w:$h:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1[bg];'
            '[bg][1:v]overlay=0:0[v]',
        '-map', '[v]',
        '-map', '0:a?',
        '-r', '30',
        '-c:v', 'libx264', '-preset', 'veryfast', '-pix_fmt', 'yuv420p',
        '-c:a', 'aac', '-ar', '44100', '-ac', '2',
        '-video_track_timescale', '30000',
        segPath,
      ];
      await _run(args, 'ประมวลผลคลิป ${i + 1}');
      segments.add(segPath);
    }

    // concat
    onProgress?.call(ExportProgress(clips.length, total, 'กำลังรวมคลิป…'));
    final listPath = '${work.path}/list.txt';
    await File(listPath)
        .writeAsString(segments.map((s) => "file '$s'").join('\n'));

    final outPath = '${work.path}/day_cap.mp4';
    try {
      await _run(
        ['-y', '-f', 'concat', '-safe', '0', '-i', listPath, '-c', 'copy',
          '-movflags', '+faststart', outPath],
        'รวมคลิป',
      );
    } catch (_) {
      // เผื่อ stream copy ไม่ลงตัว → re-encode
      await _run(
        ['-y', '-f', 'concat', '-safe', '0', '-i', listPath,
          '-c:v', 'libx264', '-preset', 'veryfast', '-pix_fmt', 'yuv420p',
          '-c:a', 'aac', '-movflags', '+faststart', outPath],
        'รวมคลิป (re-encode)',
      );
    }

    onProgress?.call(ExportProgress(total, total, 'เสร็จแล้ว'));
    return outPath;
  }

  Future<void> _run(List<String> args, String step) async {
    final session = await FFmpegKit.executeWithArguments(args);
    final rc = await session.getReturnCode();
    if (!ReturnCode.isSuccess(rc)) {
      final logs = await session.getAllLogsAsString();
      throw ExportException('$step ล้มเหลว\n${logs ?? ''}');
    }
  }

  int _even(int v) => v.isEven ? v : v - 1;
}
