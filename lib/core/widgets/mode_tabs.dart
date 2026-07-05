import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'glass.dart';

/// Tab สลับโหมด: Camera | Home — ไอคอนกล้อง/บ้าน สไตล์กระจกฝ้า (ใช้ค่า glass ร่วมกับปุ่ม)
class ModeTabs extends StatelessWidget {
  const ModeTabs({
    super.key,
    required this.cameraSelected,
    required this.onCamera,
    required this.onHome,
  });

  final bool cameraSelected;
  final VoidCallback onCamera;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kGlassBlur, sigmaY: kGlassBlur),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: kGlassFill,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: kGlassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Seg(
                icon: CupertinoIcons.camera_fill,
                selected: cameraSelected,
                onTap: onCamera,
              ),
              _Seg(
                icon: CupertinoIcons.house_fill,
                selected: !cameraSelected,
                onTap: onHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1FFFFFFF) : const Color(0x00000000),
          borderRadius: BorderRadius.circular(100),
          border: selected
              ? Border.all(color: const Color(0x4DFFFFFF), width: 0.5)
              : null,
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF9A9AA0),
        ),
      ),
    );
  }
}
