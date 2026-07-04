import 'package:flutter/material.dart';

/// ปุ่มกดค้างเพื่อถ่าย (ปล่อย = หยุด) แบบ IG Story
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

class _HoldButtonState extends State<HoldButton> {
  bool _pressed = false;

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _pressed ? 88 : 76,
        height: _pressed ? 88 : 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 5,
          ),
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
    );
  }
}
