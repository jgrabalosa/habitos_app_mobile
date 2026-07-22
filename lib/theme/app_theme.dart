import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Básico Claro (crudo frío: fondo un punto más oscuro, tarjetas en blanco roto)
  static const bgLight = Color(0xFFE6ECF2);
  static const surfaceLight = Color(0xFFF7F9FB);
  static const surface2Light = Color(0xFFCFDAE6);
  static const textLight = azulNoche;
  static const textMutedLight = grisMedio;

  // Básico Oscuro DE MARCA (fondos Azul Noche / Azul Acero, no gris genérico)
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

/// ── Escala de espaciado oficial (4/8/16/24) ──
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

/// ── Radios oficiales (generosos, 16-24) ──
class AppRadius {
  static const double sm = 12; // inputs, botones
  static const double md = 16; // chips, sheets
  static const double lg = 20; // cards
  static const double xl = 24; // overlays, diálogos
}

/// Colores que cambian según el tema equipado — úsalos con tokens(context)
class TokensContextuales {
  final Color primary, success, streak, points, bg, surface, surface2, text, textMuted;
  const TokensContextuales({
    required this.primary, required this.success, required this.streak,
    required this.points, required this.bg, required this.surface,
    required this.surface2, required this.text, required this.textMuted,
  });
}

// Fallback de arranque antes de que cargarTemaEquipadoGuardado() resuelva el
// tema real guardado (o para el rarísimo caso de que aún no haya ninguno).
// Es la paleta "Básico Oscuro" — la más característica de la marca.
const TokensContextuales _basicoOscuroPorDefecto = TokensContextuales(
  primary: AppColors.primaryDarkMode, success: AppColors.successDarkMode,
  streak: AppColors.streakDarkMode, points: AppColors.pointsDarkMode,
  bg: AppColors.bgDark, surface: AppColors.surfaceDark,
  surface2: AppColors.surface2Dark, text: AppColors.textDark,
  textMuted: AppColors.textMutedDark,
);

/// El tema actualmente equipado (uno de los 7: 2 básicos + 5 premium).
/// Todas las paletas funcionan exactamente igual — no hay distinción especial.
final ValueNotifier<TokensContextuales> temaEquipadoNotifier =
    ValueNotifier<TokensContextuales>(_basicoOscuroPorDefecto);

TokensContextuales tokens(BuildContext context) => temaEquipadoNotifier.value;

/// ── ThemeData ──
class AppTheme {
  /// ThemeData para el tema actualmente equipado — un único look, construido
  /// a partir de sus tokens. Todas las paletas (básicas o premium) pasan por aquí.
  static ThemeData deTema(TokensContextuales t) {
    final scheme = ColorScheme.fromSeed(
      seedColor: t.primary,
      brightness: Brightness.dark,
      surface: t.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      textTheme: _tipografia(),
      appBarTheme: AppBarTheme(
        backgroundColor: t.surface,
        foregroundColor: t.text,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: t.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Escala tipográfica Manrope oficial:
  /// Títulos 700 · Subtítulos 500 · Cuerpo 400 · Números/Stats 600
  static TextTheme _tipografia() {
    final base = GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme);
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
}