import 'package:flutter/material.dart';

/// 앱 전체 색상 팔레트 및 테마 정의
class AppTheme {
  AppTheme._();

  // ── 배경색 ──────────────────────────────────────────
  static const Color bgDark    = Color(0xFF0A0A0F);
  static const Color bgCard    = Color(0xFF1A1A2E);
  static const Color bgDeep    = Color(0xFF0D1B3E);

  // ── 주 색상 ─────────────────────────────────────────
  static const Color primary      = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark  = Color(0xFF0D47A1);
  static const Color accent       = Color(0xFF1A237E);

  // ── FPS 범주 색상 ────────────────────────────────────
  static const Color fpsUltra    = Color(0xFFE91E63); // ≥240  초고속
  static const Color fpsSlow     = Color(0xFFFF5722); // ≥120  슬로우모션
  static const Color fpsHFR      = Color(0xFF4CAF50); // ≥60   고프레임률
  static const Color fpsStandard = Color(0xFF2196F3); // ≥30   표준
  static const Color fpsLow      = Color(0xFF9E9E9E); // <30   저속

  // ── 텍스트 색상 ──────────────────────────────────────
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textHint      = Colors.white54;
  static const Color textDisabled  = Colors.white38;
  static const Color textMuted     = Colors.white24;

  // ── ThemeData ────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: bgDark,
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
  );

  // ── FPS → 색상 유틸 ──────────────────────────────────
  static Color fpsColor(double fps) {
    if (fps >= 240) return fpsUltra;
    if (fps >= 120) return fpsSlow;
    if (fps >= 60)  return fpsHFR;
    if (fps >= 30)  return fpsStandard;
    return fpsLow;
  }

  // ── FPS → 배경색(진하게) ─────────────────────────────
  static Color fpsBgColor(double fps) {
    if (fps >= 240) return const Color(0xFF880E4F);
    if (fps >= 120) return const Color(0xFFBF360C);
    if (fps >= 60)  return const Color(0xFF1B5E20);
    if (fps >= 30)  return const Color(0xFF0D47A1);
    return const Color(0xFF212121);
  }
}
