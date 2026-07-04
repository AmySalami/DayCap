import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../models/clip.dart';
import '../../providers/reel_provider.dart';
import '../../services/export_service.dart';
import '../edit/timeline_screen.dart';

/// เล่นคลิปของ "วัน" ต่อเนื่องเป็นหนังเรื่องเดียว + ป้ายเวลาทับ
/// รองรับ trim: เล่นเฉพาะช่วง trimStart..trimEnd ของแต่ละคลิป
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.day});
  final DateTime day;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _controller;
  int _index = 0;
  bool _finished = false;
  List<Clip> _clips = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndStart());
  }

  Future<void> _loadAndStart() async {
    final week = ref.read(reelProvider).value;
    if (week == null) return;
    _clips = clipsForDay(week, widget.day);
    if (_clips.isEmpty) return;
    await _playAt(0);
  }

  Future<void> _playAt(int index) async {
    await _controller?.dispose();
    _controller = null;

    if (index >= _clips.length) {
      setState(() => _finished = true);
      return;
    }

    final clip = _clips[index];
    final storage = ref.read(storageProvider);
    final path = await storage.absolutePath(clip.fileName);

    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    await controller.seekTo(Duration(milliseconds: clip.trimStartMs));
    controller.addListener(_watch);
    await controller.play();

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _index = index;
      _finished = false;
    });
  }

  void _watch() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final clip = _clips[_index];
    final pos = c.value.position.inMilliseconds;
    // ถึงจุด trim ท้าย หรือคลิปจบ → ไปคลิปถัดไป
    final reachedTrimEnd = pos >= clip.trimEndMs;
    final ended = c.value.position >= c.value.duration &&
        !c.value.isPlaying &&
        c.value.duration > Duration.zero;
    if (reachedTrimEnd || ended) {
      c.removeListener(_watch);
      _playAt(_index + 1);
    }
  }

  Future<void> _replay() async {
    setState(() => _finished = false);
    await _playAt(0);
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_watch);
    _controller?.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final hasClips = _clips.isNotEmpty;
    final currentLabel = hasClips && _index < _clips.length
        ? _clips[_index].label
        : '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(hasClips ? 'เล่น ${_clips.length} คลิป' : 'ยังไม่มีคลิป'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'จัดการ/ตัดคลิป',
            onPressed: hasClips && !_exporting
                ? () async {
                    _controller?.pause();
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => TimelineScreen(day: widget.day)));
                    // กลับมาแล้วโหลดคลิปใหม่ (เผื่อมีลบ/ตัด/จัดลำดับ)
                    if (mounted) {
                      final w = ref.read(reelProvider).value;
                      _clips =
                          w == null ? const [] : clipsForDay(w, widget.day);
                      await _playAt(0);
                    }
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Save ลงอัลบั้ม',
            onPressed: hasClips && !_exporting ? _save : null,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'แชร์',
            onPressed: hasClips && !_exporting ? _share : null,
          ),
        ],
      ),
      body: !hasClips
          ? const Center(
              child: Text('วันนี้ยังไม่มีคลิป',
                  style: TextStyle(color: Colors.white70)))
          : Stack(
              fit: StackFit.expand,
              children: [
                if (c != null && c.value.isInitialized)
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: VideoPlayer(c),
                      ),
                    ),
                  )
                else
                  const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white)),

                // ป้ายเวลาทับ (มุมซ้ายบน)
                Positioned(
                  top: 16,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(currentLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),

                // ตัวบอกความคืบหน้า (คลิปที่เท่าไหร่)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text('${_index + 1} / ${_clips.length}',
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ),

                // จบแล้ว → เล่นซ้ำ
                if (_finished)
                  Center(
                    child: FilledButton.icon(
                      onPressed: _replay,
                      icon: const Icon(Icons.replay),
                      label: const Text('เล่นอีกครั้ง'),
                    ),
                  ),
              ],
            ),
    );
  }

  // ---- Export / Save / Share ----

  final ValueNotifier<ExportProgress?> _progress = ValueNotifier(null);
  bool _exporting = false;

  Future<String?> _export() async {
    final week = ref.read(reelProvider).value;
    final dayLog = week?.dayOrNull(widget.day);
    if (dayLog == null || dayLog.isEmpty) return null;

    _controller?.pause();
    setState(() => _exporting = true);
    _progress.value = const ExportProgress(0, 1, 'กำลังเริ่ม…');

    _showProgressDialog();
    try {
      final path = await ref
          .read(exportServiceProvider)
          .exportDay(dayLog, onProgress: (p) => _progress.value = p);
      return path;
    } on ExportException catch (e) {
      _closeDialog();
      _snack('รวมวิดีโอไม่สำเร็จ: ${_short(e.message)}');
      return null;
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _save() async {
    final path = await _export();
    if (path == null) return;
    try {
      final ok = await ref.read(galleryServiceProvider).saveVideo(path);
      _closeDialog();
      _snack(ok ? 'บันทึกลงอัลบั้มแล้ว ✅' : 'ไม่ได้รับสิทธิ์เข้าถึงอัลบั้ม');
    } catch (e) {
      _closeDialog();
      _snack('บันทึกไม่สำเร็จ: $e');
    }
  }

  Future<void> _share() async {
    final path = await _export();
    if (path == null) return;
    _closeDialog();
    await ref.read(shareServiceProvider).shareVideo(path);
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: ValueListenableBuilder<ExportProgress?>(
          valueListenable: _progress,
          builder: (_, p, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: p?.fraction),
              const SizedBox(height: 16),
              Text(p?.message ?? 'กำลังประมวลผล…'),
            ],
          ),
        ),
      ),
    );
  }

  void _closeDialog() {
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _short(String s) => s.length > 120 ? '${s.substring(0, 120)}…' : s;
}
