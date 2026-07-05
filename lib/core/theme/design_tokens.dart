import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// Amie's Design System — mirror ของ amies-design-system.css
/// Single source of truth: https://github.com/AmySalami/amies_design_system
/// แก้ token ที่นี่ให้ตรงกับ DS — ห้าม hardcode ค่าสี/ขนาดในที่อื่น
/// ═══════════════════════════════════════════════════════════════

/// สีจาก DS
/// กติกาแบรนด์: [accent] (amber) ใช้กับ "พื้น + ไอคอน" เท่านั้น ห้ามใช้กับตัวอักษร
/// [secondary] (navy) ใช้กับหัวข้อ/label/ตัวอักษรบนพื้น accent
class DsColor {
  const DsColor._();

  static const paper = Color(0xFFFBF7F0); // page background
  static const paper2 = Color(0xFFF3ECE0); // raised surfaces / gradients
  static const paperWarm = Color(0xFFFFFDF9); // gradient start
  static const ink = Color(0xFF2A2622); // body + strong text
  static const inkSoft = Color(0xFF5C544B); // secondary text, captions
  static const inkWash = Color.fromRGBO(42, 38, 34, .06); // mono bg
  static const line = Color(0xFFE6DCCC); // borders, dividers
  static const accent = Color(0xFFFFC400); // PRIMARY — fills & icons only
  static const accentDark = Color(0xFFCD9E00); // hover on accent
  static const secondary = Color(0xFF1E3258); // headings, text on accent
  static const accentSoft = Color(0xFFF2D9C6); // soft accent tint
  static const sage = Color(0xFF7E8B6F); // tertiary accent
  static const highlight = Color.fromRGBO(255, 196, 0, .5); // text highlight
  static const white = Color(0xFFFFFFFF);
  static const whiteSoft = Color.fromRGBO(255, 255, 255, .5);
  static const whiteMid = Color.fromRGBO(255, 255, 255, .8);
  static const whiteFaint = Color.fromRGBO(255, 255, 255, .2);

  // ai gradient
  static const ai1 = Color(0xFFF6953C);
  static const ai2 = Color(0xFFF2618A);
  static const ai3 = Color(0xFF9266EF);
  static const ai4 = Color(0xFF4A90F4);
}

/// radius จาก DS
class DsRadius {
  const DsRadius._();
  static const xs = 3.0;
  static const sm = 8.0;
  static const md = 18.0;
  static const lg = 22.0;
  static const pill = 100.0;
}

/// spacing จาก DS
class DsSpace {
  const DsSpace._();
  static const paragraph = 16.0;
  static const takeaway = 20.0;
  static const block = 24.0;
  static const section = 48.0;
  static const zone = 80.0;
  static const region = 160.0;
  static const page = 400.0;
  static const gutter = 32.0;
}

/// elevation จาก DS (แปลง CSS box-shadow → BoxShadow)
class DsElevation {
  const DsElevation._();
  static const subtle = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, .05), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const pill = [
    BoxShadow(
        color: Color.fromRGBO(42, 38, 34, .5),
        offset: Offset(0, 8),
        blurRadius: 20,
        spreadRadius: -14),
  ];
  static const lift = [
    BoxShadow(
        color: Color.fromRGBO(255, 196, 0, .85),
        offset: Offset(0, 16),
        blurRadius: 32,
        spreadRadius: -16),
  ];
  static const panel = [
    BoxShadow(
        color: Color.fromRGBO(42, 38, 34, .4),
        offset: Offset(0, 30),
        blurRadius: 60,
        spreadRadius: -38),
  ];
}

/// typography จาก DS
class DsType {
  const DsType._();

  static const fontDisplay = 'Fraunces';
  static const fontBody = 'Hanken Grotesk';

  // scale (px) — ค่า clamp() บนมือถือใช้ค่ากลางที่เหมาะจอเล็ก
  static const badge = 11.0;
  static const mono = 11.5;
  static const label = 12.0;
  static const eyebrow = 12.5;
  static const tag = 13.0;
  static const caption = 13.5;
  static const sm = 14.0;
  static const btn = 15.0;
  static const lead = 16.0;
  static const body = 18.0;
  static const bodyLg = 19.0;
  static const h3 = 21.0;
  static const icon = 22.0;
  static const quote = 26.0; // clamp(22,3vw,30)
  static const h2 = 32.0; // clamp(28,3.6vw,40)
  static const h1 = 44.0; // clamp(40,6vw,68)

  // weight
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;

  // leading (line-height)
  static const leadingTight = 1.04;
  static const leadingSnug = 1.3;
  static const leadingMedium = 1.5;
  static const leadingRelaxed = 1.6;
  static const leadingNormal = 1.7;

  // tracking (em) — Flutter letterSpacing = px จึงคูณ fontSize เอาผ่าน [track]
  static const trackTight = -0.02;
  static const trackSnug = -0.01;
  static const trackXs = 0.02;
  static const trackSm = 0.03;
  static const trackWide = 0.14;
  static const trackWider = 0.16;
  static const trackWidest = 0.18;

  /// แปลง tracking (em) → letterSpacing (px) ตาม fontSize
  static double track(double em, double fontSize) => em * fontSize;
}
