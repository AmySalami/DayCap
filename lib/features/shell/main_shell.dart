import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/mode_tabs.dart';
import '../home/home_screen.dart';
import '../record/record_screen.dart';

/// เปลือกหลัก: Camera (ซ้าย) + Home (ขวา) เลื่อนคู่กันแบบ pager
/// tab (Camera | Home) ปักนิ่งล่างสุด ไม่ขยับเวลาสลับหน้า
/// กล้อง mount เฉพาะตอนอยู่/กำลังไปหน้า Camera เพื่อไม่ให้กล้องทำงานค้างบน Home
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide; // 0 = camera, 1 = home
  bool _cameraMounted = false;
  // ความคืบหน้าการเข้า edit mode ของ Home (0=ปกติ, 1=edit) — ใช้เลื่อน tab ลง
  final ValueNotifier<double> _editProgress = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      value: 1, // เริ่มที่ Home
      duration: const Duration(milliseconds: 320),
    );
  }

  void _goCamera() {
    setState(() => _cameraMounted = true);
    _slide.animateTo(0, curve: Curves.easeOutCubic);
  }

  void _goHome() {
    _slide.animateTo(1, curve: Curves.easeOutCubic).then((_) {
      if (mounted && _slide.value >= 0.999) {
        setState(() => _cameraMounted = false);
      }
    });
  }

  @override
  void dispose() {
    _slide.dispose();
    _editProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppToken.videoBackdrop,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _slide,
            builder: (context, _) {
              final v = _slide.value;
              return Stack(
                children: [
                  // Home (ขวา): v=1 → กลางจอ, v=0 → เลื่อนออกขวา
                  Transform.translate(
                    offset: Offset((1 - v) * w, 0),
                    child: HomeScreen(
                      onCamera: _goCamera,
                      editProgress: _editProgress,
                    ),
                  ),
                  // Camera (ซ้าย): v=0 → กลางจอ, v=1 → เลื่อนออกซ้าย
                  if (_cameraMounted)
                    Transform.translate(
                      offset: Offset(-v * w, 0),
                      child: RecordScreen(onExit: _goHome),
                    ),
                ],
              );
            },
          ),

          // tab ปักนิ่งล่างสุดกลางจอ — เลื่อนลง+จางเมื่อ Home เข้า edit mode
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPad - 2,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_slide, _editProgress]),
                builder: (context, _) {
                  final e = _editProgress.value;
                  return IgnorePointer(
                    ignoring: e > 0.02,
                    child: Opacity(
                      opacity: (1 - e).clamp(0, 1),
                      child: FractionalTranslation(
                        translation: Offset(0, e * 2.2),
                        child: ModeTabs(
                          cameraSelected: _slide.value < 0.5,
                          onCamera: _goCamera,
                          onHome: _goHome,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
