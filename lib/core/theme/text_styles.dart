import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// สไตล์ตัวอักษรตาม DS — Fraunces (display) / Hanken Grotesk (body)
/// ใช้เมธอดพวกนี้แทนการเขียน TextStyle เอง เพื่อคุมให้ตรง token
class DsText {
  const DsText._();

  /// หัวข้อใหญ่ (Fraunces)
  static TextStyle display({
    double size = DsType.h2,
    Color color = DsColor.secondary,
    FontWeight weight = DsType.medium,
    double height = DsType.leadingTight,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: DsType.track(DsType.trackTight, size),
      );

  /// เนื้อความ (Hanken Grotesk)
  static TextStyle body({
    double size = DsType.body,
    Color color = DsColor.ink,
    FontWeight weight = DsType.regular,
    double height = DsType.leadingMedium,
    double? letterSpacing,
  }) =>
      GoogleFonts.hankenGrotesk(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// eyebrow / label เว้นวรรคกว้าง (uppercase caller เอง)
  /// [size] ปรับได้ (default = DsType.eyebrow) — tracking คำนวณตามขนาดให้อัตโนมัติ
  static TextStyle eyebrow({
    Color color = DsColor.secondary,
    double size = DsType.eyebrow,
  }) => GoogleFonts.hankenGrotesk(
    fontSize: size,
    color: color,
    fontWeight: DsType.semibold,
    letterSpacing: DsType.track(DsType.trackWider, size),
  );

  /// ปุ่ม
  static TextStyle button({Color color = DsColor.secondary}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: DsType.btn,
        color: color,
        fontWeight: DsType.semibold,
      );
}
