import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ── Design Tokens — Identidad oficial Norday ──
class AppColors {
  // Marca
  static const azulNoche = Color(0xFF0A1628);
  static const azulAcero = Color(0xFF23395D);
  static const verdeEsmeralda = Color(0xFF27C76F);
  static const verdeOscuro = Color(0xFF1EA85B);
  static const verdeClaro = Color(0xFF6EE7A8);
  static const grisMuyClaro = Color(0xFFEEF2F6);
  static const grisClaro = Color(0xFFD9E2EC);
  static const grisMedio = Color(0xFF6B7280);
  static const grisOscuro = Color(0xFF374151);

  // Semánticos (sobre la marca)
  static const primary = verdeEsmeralda;
  static const primaryDark = verdeOscuro;
  static const success = verdeOscuro; // apto como texto sobre fondos claros
  static const streak = Color(0xFFF97316);
  static const points = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Light (fondos Gris Muy Claro / Blanco)
  static const bgLight = grisMuyClaro;
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = grisClaro;
  static const textLight = azulNoche;
  static const textMutedLight = grisMedio;

  // Dark DE MARCA (fondos Azul Noche / Azul Acero, no gris genérico)
  static const primaryDarkMode = verdeEsmeralda;
  static const successDarkMode = verdeClaro;
  static const streakDarkMode = Color(0xFFFF8226);
  static const pointsDarkMode = Color(0xFFFFB020);
  static const bgDark = azulNoche;
  static const surfaceDark = azulAcero;
  static const surface2Dark = Color(0xFF2C4570); // Azul Acero elevado
  static const textDark = grisMuyClaro;
  static const textMutedDark = Color(0xFFA3B3C9); // gris azulado sobre noche
}

/// Colores que cambian según el tema — úsalos con tokens(context)
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

  /// Escala tipográfica Manrope oficial:
  /// Títulos 700 · Subtítulos 500 · Cuerpo 400 · Números/Stats 600
  static TextTheme _tipografia(Brightness b) {
    final base = GoogleFonts.manropeTextTheme(
      b == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    return base.copyWith(
      // Títulos (H1-H3) → Bold 700
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      // Subtítulos (H4-H5) → Medium 500
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      // Cuerpo → Regular 400
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w400),
      // Etiquetas/botones → SemiBold 600
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

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
      textTheme: _tipografia(b),
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