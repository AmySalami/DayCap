import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// เรนเดอร์ป้ายเวลา (เช่น "10:00") เป็น PNG โปร่งใสขนาดเท่าผืนผ้าใบ
/// เพื่อให้ ffmpeg ใช้ overlay ซ้อนทับตอน export (เลี่ยง drawtext/freetype)
///
/// วาดให้ตรงกับ badge ในแอป: กล่องดำโปร่ง มุมมน ข้อความขาวหนา มุมซ้ายบน
Future<Uint8List> renderLabelPng({
  required String label,
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final fontSize = height * 0.045;
  final margin = height * 0.03;
  final padH = fontSize * 0.55;
  final padV = fontSize * 0.32;
  final radius = fontSize * 0.4;

  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        // เงาให้อ่านออกบนพื้นสว่าง
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 4),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final boxRect = Rect.fromLTWH(
    margin,
    margin,
    tp.width + padH * 2,
    tp.height + padV * 2,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(boxRect, Radius.circular(radius)),
    Paint()..color = Colors.black.withValues(alpha: 0.35),
  );
  tp.paint(canvas, Offset(margin + padH, margin + padV));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}
