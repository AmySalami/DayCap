import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// ปุ่มกดค้างเพื่อถ่าย (ปล่อย = หยุด) แบบ IG Story
/// ตอนกำลังอัด: มีวงเส้นสี accent วิ่งรอบปุ่มเป็น indicator
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.recording,
    required this.onStart,
    required this.onStop,
  });

  final bool recording;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton>
    with SingleTickerProviderStateMixin {
  static const double _ring = 104; // ขนาดวงรอบนอก

  bool _pressed = false;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.recording) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant HoldButton old) {
    super.didUpdateWidget(old);
    if (widget.recording && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.recording && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _start() {
    if (_pressed) return;
    setState(() => _pressed = true);
    widget.onStart();
  }

  void _stop() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onStop();
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ Listener จับ pointer down/up ตรงๆ เพื่อความชัวร์ของ "กดค้าง"
    return Listener(
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _stop(),
      onPointerCancel: (_) => _stop(),
      child: SizedBox(
        width: _ring,
        height: _ring,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // วงเส้น accent วิ่งรอบ (แสดงตอนอัด)
            if (widget.recording)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _spin,
                  builder: (_, _) => CustomPaint(
                    painter: _RingPainter(_spin.value * 2 * math.pi),
                  ),
                ),
              ),
            // ตัวปุ่ม
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _pressed ? 88 : 76,
              height: _pressed ? 88 : 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                color: widget.recording
                    ? Colors.red.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.25),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: widget.recording ? 32 : 56,
                  height: widget.recording ? 32 : 56,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius:
                        BorderRadius.circular(widget.recording ? 8 : 40),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// วาด arc สี accent (comet) หมุนรอบปุ่ม
class _RingPainter extends CustomPainter {
  const _RingPainter(this.rotation);
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2,
    );
    final paint = Paint()
      ..color = DsColor.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // arc ~ 130° วิ่งรอบวง
    canvas.drawArc(rect, rotation, 2.3, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.rotation != rotation;
}
