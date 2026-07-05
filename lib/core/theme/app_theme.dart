import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// ธีมของแอป สร้างจาก DS token ทั้งหมด (ไม่มีค่า hardcode)
class AppTheme {
  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: DsColor.accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: DsColor.accent,
      onPrimary: DsColor.secondary, // ตัวอักษรบนพื้น accent = navy (กติกา DS)
      secondary: DsColor.secondary,
      onSecondary: DsColor.white,
      tertiary: DsColor.sage,
      surface: DsColor.paper,
      onSurface: DsColor.ink,
      error: DsColor.ai2,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.black,
    );

    return base.copyWith(
      textTheme: GoogleFonts.hankenGroteskTextTheme(base.textTheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DsColor.accent,
          foregroundColor: DsColor.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: DsType.btn,
            fontWeight: DsType.semibold,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
        ),
      ),
    );
  }
}
