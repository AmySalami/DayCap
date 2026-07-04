import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../models/clip.dart';
import '../../providers/reel_provider.dart';

/// ตัดคลิปแบบ IG: ลากหัว-ท้ายเข้า/ออก (ตัดกลางไม่ได้)
/// เก็บเป็น metadata (trimStart/trimEnd) — ไม่แก้ไฟล์จริง เผาตอน export
class TrimScreen extends ConsumerStatefulWidget {
  const TrimScreen({super.key, required this.day, required this.clipId});
  final DateTime day;
  final String clipId;

  @override
  ConsumerState<TrimScreen> createState() => _TrimScreenState();
}

class _TrimScreenState extends ConsumerState<TrimScreen> {
  static const double _minGapMs = 500; // ช่วงสั้นสุดที่ตัดได้

  VideoPlayerController? _c;
  Clip? _clip;
  double _startMs = 0;
  double _endMs = 0;
  double _maxMs = 0;
  bool _ready = false;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final week = ref.read(reelProvider).value;
    final clip = week
        ?.dayOrNull(widget.day)
        ?.clips
        .where((c) => c.id == widget.clipId)
        .firstOrNull;
    if (clip == null) return;
    _clip = clip;

    final storage = ref.read(storageProvider);
    final path = await storage.absolutePath(clip.fileName);
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    controller.addListener(_watch);

    final durMs = controller.value.duration.inMilliseconds.toDouble();
    _maxMs = durMs <= 0 ? clip.durationMs.toDouble() : durMs;
    _startMs = clip.trimStartMs.toDouble().clamp(0, _maxMs);
    _endMs = clip.trimEndMs.toDouble().clamp(_startMs + _minGapMs, _maxMs);
    await controller.seekTo(Duration(milliseconds: _startMs.round()));

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _c = controller;
      _ready = true;
    });
  }

  void _watch() {
    final c = _c;
    if (c == null || !c.value.isInitialized || !_previewing) return;
    if (c.value.position.inMilliseconds >= _endMs) {
      // วนเล่นเฉพาะช่วงที่ตัดไว้
      c.seekTo(Duration(milliseconds: _startMs.round()));
    }
  }

  void _onRangeChanged(RangeValues v) {
    final c = _c;
    // กันหัว-ท้ายชนกัน ให้เหลือช่วงขั้นต่ำเสมอ
    var start = v.start;
    var end = v.end;
    if (end - start < _minGapMs) {
      if (start != _startMs) {
        start = end - _minGapMs;
      } else {
        end = start + _minGapMs;
      }
    }
    final movedStart = start != _startMs;
    setState(() {
      _startMs = start.clamp(0, _maxMs);
      _endMs = end.clamp(0, _maxMs);
      _previewing = false;
    });
    // เลื่อนพรีวิวไปเฟรมของหมุดที่กำลังลาก
    c?.pause();
    c?.seekTo(Duration(milliseconds: (movedStart ? _startMs : _endMs).round()));
  }

  void _togglePreview() {
    final c = _c;
    if (c == null) return;
    if (_previewing) {
      c.pause();
      setState(() => _previewing = false);
    } else {
      c.seekTo(Duration(milliseconds: _startMs.round()));
      c.play();
      setState(() => _previewing = true);
    }
  }

  Future<void> _save() async {
    await ref.read(reelProvider.notifier).updateTrim(
          widget.day,
          widget.clipId,
          trimStartMs: _startMs.round(),
          trimEndMs: _endMs.round(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _c?.removeListener(_watch);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final trimmed = _endMs - _startMs;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_clip == null ? 'ตัดคลิป' : 'ตัดคลิป ${_clip!.label}'),
        actions: [
          TextButton(
            onPressed: _ready ? _save : null,
            child: const Text('บันทึก',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: !_ready || c == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _togglePreview,
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(c),
                            if (!_previewing)
                              const Icon(Icons.play_circle_fill,
                                  size: 64, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  color: Colors.black,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(_startMs),
                              style: const TextStyle(color: Colors.white70)),
                          Text('ความยาว ${_fmt(trimmed)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(_fmt(_endMs),
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      RangeSlider(
                        values: RangeValues(_startMs, _endMs),
                        min: 0,
                        max: _maxMs,
                        onChanged: _onRangeChanged,
                      ),
                      const Text('ลากหัว-ท้ายเพื่อตัด (ตัดกลางไม่ได้)',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _fmt(double ms) {
    final total = (ms / 1000).round();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
