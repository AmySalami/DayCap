import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_utils.dart';
import '../../providers/reel_provider.dart';
import '../calendar/week_calendar_screen.dart';
import '../player/player_screen.dart';
import '../wipe/countdown_banner.dart';
import 'widgets/hold_button.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = false;
  bool _recording = false;
  bool _saving = false;
  DateTime? _startedAt;
  String? _error;

  Timer? _clock;
  String _nowLabel = hourLabel(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
    // อัปเดตป้ายเวลาทุก 30 วิ (ป้ายจริงเปลี่ยนแค่ตอนขึ้นชั่วโมงใหม่)
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      final l = hourLabel(DateTime.now());
      if (l != _nowLabel && mounted) setState(() => _nowLabel = l);
    });
  }

  Future<void> _setupCamera() async {
    if (_initializing) return;
    _initializing = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'ไม่พบกล้องบนอุปกรณ์นี้');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) setState(() => _error = 'เปิดกล้องไม่ได้: $e');
    } finally {
      _initializing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // เข้า background → คืนกล้อง (iOS ตัดการเข้าถึงกล้องอยู่แล้ว)
      if (c != null) {
        _controller = null;
        c.dispose();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      // กลับมา → เปิดกล้องใหม่ถ้ายังไม่มี
      if (_controller == null && !_initializing) {
        _setupCamera();
      }
    }
  }

  Future<void> _startRecording() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isRecordingVideo) return;
    try {
      await c.startVideoRecording();
      _startedAt = DateTime.now();
      setState(() => _recording = true);
    } catch (e) {
      setState(() => _error = 'เริ่มอัดไม่ได้: $e');
    }
  }

  Future<void> _stopRecording() async {
    final c = _controller;
    if (c == null || !c.value.isRecordingVideo) return;
    setState(() {
      _recording = false;
      _saving = true;
    });
    try {
      final file = await c.stopVideoRecording();
      await ref.read(reelProvider.notifier).addRecording(
            tempPath: file.path,
            recordedAt: _startedAt,
          );
    } catch (e) {
      setState(() => _error = 'บันทึกไม่ได้: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final week = ref.watch(reelProvider);
    final todayCount = week.value == null
        ? 0
        : clipsForDay(week.value!, DateTime.now()).length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // พรีวิวกล้อง
          if (_error != null)
            _ErrorView(message: _error!, onRetry: _retry)
          else if (controller != null && controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1080,
                height: controller.value.previewSize?.width ?? 1920,
                child: CameraPreview(controller),
              ),
            )
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),

          // ป้ายเวลา (ตัวที่จะเผาลงวิดีโอ)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: _TimeBadge(label: _nowLabel),
          ),

          // ปุ่มดูปฏิทิน (ขวาบน)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const WeekCalendarScreen())),
            ),
          ),

          // แบนเนอร์นับถอยหลังก่อนล้าง (โผล่เฉพาะเสาร์เย็น)
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 16,
            right: 16,
            child: const Align(
              alignment: Alignment.topCenter,
              child: CountdownBanner(),
            ),
          ),

          // แถบล่าง: จำนวนคลิปวันนี้ + ปุ่มถ่าย + ปุ่ม Play
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 28,
            child: Column(
              children: [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('กำลังบันทึก…',
                        style: TextStyle(color: Colors.white)),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 56),
                    HoldButton(
                      recording: _recording,
                      onStart: _startRecording,
                      onStop: _stopRecording,
                    ),
                    _PlayButton(
                      enabled: todayCount > 0,
                      count: todayCount,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PlayerScreen(day: startOfDay(DateTime.now())),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _retry() {
    setState(() => _error = null);
    _setupCamera();
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.enabled,
    required this.count,
    required this.onTap,
  });
  final bool enabled;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 40,
            icon: Icon(
              Icons.play_circle_fill,
              color: enabled ? Colors.white : Colors.white24,
            ),
            onPressed: enabled ? onTap : null,
          ),
          Text('$count คลิป',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
          ],
        ),
      ),
    );
  }
}
