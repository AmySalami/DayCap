import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/time_utils.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/time_badge.dart';
import '../../providers/reel_provider.dart';
import 'widgets/hold_button.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key, this.onExit});

  /// เรียกเมื่อจะออกจากกล้อง (X / ปัดซ้าย / ถ่ายเสร็จ) — shell จะเลื่อนกลับ Home
  final VoidCallback? onExit;

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _lens = CameraLensDirection.back;
  bool _initializing = false;
  bool _recording = false;
  bool _saving = false;
  bool _torch = false;
  DateTime? _startedAt;
  String? _error;

  // self-timer
  int _timerSec = 0; // 0 = ปิด, 3, 10
  int _countdown = 0; // ตัวเลขนับถอยหลังที่โชว์
  Timer? _countdownTimer;

  // แตะ = อัด 3 วิ auto · กดค้าง = อัดตามที่ค้าง (ขั้นต่ำ 3 วิ)
  static const int _minClipMs = 3000;
  Timer? _autoStopTimer;
  bool _wantStop = false; // ปล่อยนิ้วก่อนที่จะเริ่มอัดจริง (แตะเร็วมาก)

  Timer? _clock;
  String _nowLabel = timeLabel(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final l = timeLabel(DateTime.now());
      if (l != _nowLabel && mounted) setState(() => _nowLabel = l);
    });
  }

  Future<void> _setupCamera() async {
    if (_initializing) return;
    _initializing = true;
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _error = 'ไม่พบกล้องบนอุปกรณ์นี้');
        return;
      }
      final cam = _cameras.firstWhere(
        (c) => c.lensDirection == _lens,
        orElse: () => _cameras.first,
      );
      final controller =
          CameraController(cam, ResolutionPreset.high, enableAudio: true);
      await controller.initialize();
      await _applyStabilization(controller);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _torch = false;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'เปิดกล้องไม่ได้: $e');
    } finally {
      _initializing = false;
    }
  }

  // เปิด video stabilization ของ iOS (OIS+EIS) — เลือกโหมดที่เครื่องรองรับ
  // level1≈standard (latency น้อยสุด) · level2≈cinematic (กันเยอะแต่ delay) · level3≈max
  // เลือก level1 ก่อนเพื่อให้ preview ไม่หน่วง
  Future<void> _applyStabilization(CameraController c) async {
    try {
      final modes = (await c.getSupportedVideoStabilizationModes()).toSet();
      for (final m in const [
        VideoStabilizationMode.level1,
        VideoStabilizationMode.level2,
        VideoStabilizationMode.level3,
      ]) {
        if (modes.contains(m)) {
          await c.setVideoStabilizationMode(m);
          return;
        }
      }
    } catch (_) {
      // เครื่อง/แพลตฟอร์มไม่รองรับ → ข้ามไป (ไม่พัง)
    }
  }

  Future<void> _swapCamera() async {
    if (_recording || _initializing) return;
    _lens = _lens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final old = _controller;
    _controller = null;
    setState(() {});
    await old?.dispose();
    await _setupCamera();
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null || _lens == CameraLensDirection.front) return;
    _torch = !_torch;
    try {
      await c.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _cycleTimer() {
    setState(() => _timerSec = switch (_timerSec) { 0 => 3, 3 => 10, _ => 0 });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (c != null) {
        _controller = null;
        c.dispose();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null && !_initializing) _setupCamera();
    }
  }

  // กดค้าง: ถ้าตั้ง timer → นับถอยหลังก่อน แล้วเริ่มอัด (ยังกดค้างอยู่)
  void _onHoldStart() {
    if (_recording || _countdown > 0) return;
    if (_timerSec > 0) {
      setState(() => _countdown = _timerSec);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _countdown--);
        if (_countdown <= 0) {
          t.cancel();
          _beginRecording();
        }
      });
    } else {
      _beginRecording();
    }
  }

  void _onHoldStop() {
    if (_countdown > 0) {
      _countdownTimer?.cancel();
      setState(() => _countdown = 0);
      return;
    }
    if (!_recording) {
      // ปล่อยก่อน startVideoRecording เสร็จ → ให้ _beginRecording หยุดเองเมื่อพร้อม
      _wantStop = true;
      return;
    }
    _scheduleStop();
  }

  // หยุดอัด แต่การันตีความยาวขั้นต่ำ 3 วิ (แตะ/กดสั้น → อัดต่อให้ครบ)
  void _scheduleStop() {
    final elapsed = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inMilliseconds;
    final remain = _minClipMs - elapsed;
    if (remain > 0) {
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(Duration(milliseconds: remain), () {
        if (mounted && _recording) _stopRecording();
      });
    } else {
      _stopRecording();
    }
  }

  Future<void> _beginRecording() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isRecordingVideo) return;
    try {
      await c.startVideoRecording();
      _startedAt = DateTime.now();
      setState(() {
        _recording = true;
        _countdown = 0;
      });
      // ถ้าปล่อยนิ้วไปแล้วระหว่างรอเริ่มอัด → หยุดเมื่อครบ 3 วิ
      if (_wantStop) {
        _wantStop = false;
        _scheduleStop();
      }
    } catch (e) {
      setState(() => _error = 'เริ่มอัดไม่ได้: $e');
    }
  }

  Future<void> _stopRecording() async {
    _autoStopTimer?.cancel();
    _wantStop = false;
    final c = _controller;
    if (c == null || !c.value.isRecordingVideo) return;
    setState(() {
      _recording = false;
      _saving = true;
    });
    try {
      final file = await c.stopVideoRecording();
      await ref
          .read(reelProvider.notifier)
          .addRecording(tempPath: file.path, recordedAt: _startedAt);
      final cam = _controller;
      _controller = null;
      await cam?.dispose();
      if (mounted) {
        _exit(); // shell เลื่อนกลับ Home (คลิปใหม่ต่อท้ายแล้ว)
        return;
      }
    } catch (e) {
      setState(() => _error = 'บันทึกไม่ได้: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _countdownTimer?.cancel();
    _autoStopTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return Scaffold(
      backgroundColor: AppToken.videoBackdrop,
      body: GestureDetector(
        onHorizontalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -150) _exit();
        },
        child: SafeArea(
          child: Column(
            children: [
              // กรอบกล้องมน
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_error != null)
                          _ErrorView(message: _error!, onRetry: _retry)
                        else if (c != null && c.value.isInitialized)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: c.value.previewSize?.height ?? 1080,
                              height: c.value.previewSize?.width ?? 1920,
                              child: CameraPreview(c),
                            ),
                          )
                        else
                          const ColoredBox(color: AppToken.videoBackdrop),

                        // ป้ายเวลา กลางจอ
                        Center(child: TimeBadge(label: _nowLabel)),

                        // ปุ่มปิด (ขวาบน)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GlassCircle(
                            onTap: _exit,
                            child: const Icon(Icons.close,
                                color: DsColor.white, size: 24),
                          ),
                        ),

                        // แฟลช (ซ้ายล่างในกรอบ)
                        if (_lens == CameraLensDirection.back)
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: GlassCircle(
                              onTap: _toggleTorch,
                              child: Icon(
                                _torch ? Icons.flash_on : Icons.flash_off,
                                color: DsColor.white,
                                size: 24,
                              ),
                            ),
                          ),

                        // countdown self-timer
                        if (_countdown > 0)
                          Center(
                            child: Text('$_countdown',
                                style: DsText.display(
                                    size: 96, color: DsColor.white)),
                          ),

                        if (_saving)
                          const Positioned(
                            bottom: 14,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text('กำลังบันทึก…',
                                  style: TextStyle(color: DsColor.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // แถวควบคุม: timer · shutter · swap
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlassCircle(
                      onTap: _cycleTimer,
                      child: _timerSec > 0
                          ? Text('${_timerSec}s',
                              style: const TextStyle(
                                  color: DsColor.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16))
                          : const Icon(Icons.timer_outlined,
                              color: DsColor.white, size: 24),
                    ),
                    HoldButton(
                      recording: _recording,
                      onStart: _onHoldStart,
                      onStop: _onHoldStop,
                    ),
                    GlassCircle(
                      onTap: _swapCamera,
                      child: const Icon(Icons.cameraswitch,
                          color: DsColor.white, size: 24),
                    ),
                  ],
                ),
              ),
              // เว้นที่ให้ tab ของ shell ที่ปักอยู่ล่างสุด
              const SizedBox(height: 66),
            ],
          ),
        ),
      ),
    );
  }

  void _retry() {
    setState(() => _error = null);
    _setupCamera();
  }

  void _exit() {
    final onExit = widget.onExit;
    if (onExit != null) {
      onExit();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
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
            const Icon(Icons.videocam_off, color: DsColor.whiteMid, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: DsText.body(color: DsColor.whiteMid)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
          ],
        ),
      ),
    );
  }
}
