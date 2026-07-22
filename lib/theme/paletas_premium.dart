import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Paleta fija de un tema — las 7 (2 básicas + 5 premium) funcionan igual.
class Paleta {
  final Color primary, success, streak, points, bg, surface, surface2, text, textMuted;
  const Paleta({
    required this.primary, required this.success, required this.streak,
    required this.points, required this.bg, required this.surface,
    required this.surface2, required this.text, required this.textMuted,
  });

  TokensContextuales get comoTokens => TokensContextuales(
        primary: primary, success: success, streak: streak, points: points,
        bg: bg, surface: surface, surface2: surface2, text: text, textMuted: textMuted,
      );
}

const _keyTemaEquipado = 'tema_premium_codigo'; // nombre de clave histórico, sin migrar

/// Llamar al arrancar la app (junto a cargarAvatarGuardado), antes de runApp,
/// para que el tema equipado aplique sin parpadeo desde el primer frame.
Future<void> cargarTemaEquipadoGuardado() async {
  final prefs = await SharedPreferences.getInstance();
  final codigo = prefs.getString(_keyTemaEquipado);
  if (codigo != null && catalogoPaletas.containsKey(codigo)) {
    temaEquipadoNotifier.value = catalogoPaletas[codigo]!.comoTokens;
  }
  // Si no hay nada guardado todavía (primer arranque antes del regalo de
  // bienvenida), se queda el fallback "Básico Oscuro" ya fijado en app_theme.dart.
}

/// Llamar al equipar un tema — cualquiera de los 7, todos se tratan igual.
Future<void> guardarTemaEquipado(String? codigo) async {
  if (codigo == null || !catalogoPaletas.containsKey(codigo)) {
    return; // no debería pasar: todo producto de categoría Tema tiene entrada aquí
  }
  temaEquipadoNotifier.value = catalogoPaletas[codigo]!.comoTokens;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyTemaEquipado, codigo);
}

/// Registro de paletas por código de producto — nada de hexadecimales en la BD.
const Map<String, Paleta> catalogoPaletas = {
  'TEMA_BASICO_CLARO': Paleta(
    primary: AppColors.primary, success: AppColors.success,
    streak: AppColors.streak, points: AppColors.points,
    bg: AppColors.bgLight, surface: AppColors.surfaceLight, surface2: AppColors.surface2Light,
    text: AppColors.textLight, textMuted: AppColors.textMutedLight,
  ),
  'TEMA_BASICO_OSCURO': Paleta(
    primary: AppColors.primaryDarkMode, success: AppColors.successDarkMode,
    streak: AppColors.streakDarkMode, points: AppColors.pointsDarkMode,
    bg: AppColors.bgDark, surface: AppColors.surfaceDark, surface2: AppColors.surface2Dark,
    text: AppColors.textDark, textMuted: AppColors.textMutedDark,
  ),
  'TEMA_CALIDEZ': Paleta(
    primary: Color(0xFFE07856), success: Color(0xFFD89B4A),
    streak: Color(0xFFF2994A), points: Color(0xFFF5B942),
    bg: Color(0xFF2B1B14), surface: Color(0xFF3D2A1F), surface2: Color(0xFF4F3826),
    text: Color(0xFFF5E6D8), textMuted: Color(0xFFC9A891),
  ),
  'TEMA_NEOTOKYO': Paleta(
    primary: Color(0xFFFF3D81), success: Color(0xFF00E5CC),
    streak: Color(0xFFFF6B35), points: Color(0xFFFFD60A),
    bg: Color(0xFF0D0B1A), surface: Color(0xFF1A1530), surface2: Color(0xFF2A2147),
    text: Color(0xFFF0EAFF), textMuted: Color(0xFF9B8FC7),
  ),
  'TEMA_OCEANO': Paleta(
    primary: Color(0xFF2DD4BF), success: Color(0xFF34D399),
    streak: Color(0xFFFF8F5E), points: Color(0xFFFBBF24),
    bg: Color(0xFF06222E), surface: Color(0xFF0D3648), surface2: Color(0xFF144A61),
    text: Color(0xFFE0F7FA), textMuted: Color(0xFF7FA8B3),
  ),
  'TEMA_BOSQUE': Paleta(
    primary: Color(0xFF4ADE80), success: Color(0xFF86EFAC),
    streak: Color(0xFFF97316), points: Color(0xFFEAB308),
    bg: Color(0xFF0F1F12), surface: Color(0xFF1B3320), surface2: Color(0xFF244430),
    text: Color(0xFFEAF7EC), textMuted: Color(0xFF8FAE97),
  ),
  'TEMA_COBRE': Paleta(
    primary: Color(0xFFC66A3D), success: Color(0xFFD98C5F),
    streak: Color(0xFFE08942), points: Color(0xFFECC079),
    bg: Color(0xFF112240), surface: Color(0xFF1C3357), surface2: Color(0xFF3A506B),
    text: Color(0xFFECE7E1), textMuted: Color(0xFFA9B3C4),
  ),
};