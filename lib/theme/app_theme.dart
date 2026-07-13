import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ── Design Tokens (mismos que la web) ──
class AppColors {
  // Marca y semánticos
  static const primary = Color(0xFF4A6CF7);
  static const primaryDark = Color(0xFF3A5CE5);
  static const success = Color(0xFF22C55E);
  static const streak = Color(0xFFF97316);
  static const points = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Light
  static const bgLight = Color(0xFFF8FAFC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFF1F5F9);
  static const textLight = Color(0xFF0F172A);
  static const textMutedLight = Color(0xFF64748B);

  // Dark (acentos +10% saturación)
  static const primaryDarkMode = Color(0xFF5D7BFF);
  static const successDarkMode = Color(0xFF2FDD6E);
  static const streakDarkMode = Color(0xFFFF8226);
  static const pointsDarkMode = Color(0xFFFFB020);
  static const bgDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const surface2Dark = Color(0xFF263449);
  static const textDark = Color(0xFFF1F5F9);
  static const textMutedDark = Color(0xFF94A3B8);
}

/// Colores que cambian según el tema — úsalos con AppColors.de(context)
class TokensContextuales {
  final Color primary, success, streak, points, bg, surface, surface2, text, textMuted;
  const TokensContextuales({
    required this.primary, required this.success, required this.streak,
    required this.points, required this.bg, required this.surface,
    required this.surface2, required this.text, required this.textMuted,
  });
}

extension TokensDe on AppColors {
  static TokensContextuales de(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return oscuro
        ? const TokensContextuales(
            primary: AppColors.primaryDarkMode, success: AppColors.successDarkMode,
            streak: AppColors.streakDarkMode, points: AppColors.pointsDarkMode,
            bg: AppColors.bgDark, surface: AppColors.surfaceDark,
            surface2: AppColors.surface2Dark, text: AppColors.textDark,
            textMuted: AppColors.textMutedDark)
        : const TokensContextuales(
            primary: AppColors.primary, success: AppColors.success,
            streak: AppColors.streak, points: AppColors.points,
            bg: AppColors.bgLight, surface: AppColors.surfaceLight,
            surface2: AppColors.surface2Light, text: AppColors.textLight,
            textMuted: AppColors.textMutedLight);
  }
}

TokensContextuales tokens(BuildContext context) => TokensDe.de(context);

/// ── ThemeData ──
class AppTheme {
  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness b) {
    final esOscuro = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: b,
      surface: esOscuro ? AppColors.surfaceDark : AppColors.surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: esOscuro ? AppColors.bgDark : AppColors.bgLight,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        esOscuro ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: esOscuro ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: esOscuro ? AppColors.textDark : AppColors.textLight,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        color: esOscuro ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(esOscuro ? 0.4 : 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: esOscuro ? AppColors.primaryDarkMode : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: esOscuro ? AppColors.primaryDarkMode : AppColors.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esOscuro ? AppColors.primaryDarkMode : AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// ── Gestión del tema con persistencia ──
final ValueNotifier<ThemeMode> temaNotifier = ValueNotifier(ThemeMode.system);

Future<void> cargarTemaGuardado() async {
  final prefs = await SharedPreferences.getInstance();
  final guardado = prefs.getString('tema');
  if (guardado == 'dark') temaNotifier.value = ThemeMode.dark;
  if (guardado == 'light') temaNotifier.value = ThemeMode.light;
}

Future<void> alternarTema(BuildContext context) async {
  final esOscuroAhora = Theme.of(context).brightness == Brightness.dark;
  final nuevo = esOscuroAhora ? ThemeMode.light : ThemeMode.dark;
  temaNotifier.value = nuevo;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('tema', nuevo == ThemeMode.dark ? 'dark' : 'light');
}