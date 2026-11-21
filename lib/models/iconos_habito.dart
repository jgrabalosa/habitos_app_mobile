import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_localizations.dart';

/// Los iconos que se pueden poner a un hábito. Es la única fuente: las
/// plantillas guardan un código de aquí y el hábito guarda ese mismo código.
///
/// El código es el nombre del icono en [LucideIcons]. El backend solo guarda
/// el texto; qué dibujo es lo decide esta tabla. Añadir un icono es añadir una
/// línea aquí y su nombre en los tres ARB (`iconoHabito…`) y en
/// [nombreIconoHabito].
const Map<String, IconData> iconosHabito = {
  // Los de las plantillas.
  'flower2': LucideIcons.flower2,
  'listChecks': LucideIcons.listChecks,
  'droplet': LucideIcons.droplet,
  'apple': LucideIcons.apple,
  'footprints': LucideIcons.footprints,
  'music': LucideIcons.music,
  'dumbbell': LucideIcons.dumbbell,
  'phone': LucideIcons.phone,
  'piggyBank': LucideIcons.piggyBank,
  'notebookPen': LucideIcons.notebookPen,
  'bookOpen': LucideIcons.bookOpen,
  'wineOff': LucideIcons.wineOff,
  'phoneOff': LucideIcons.phoneOff,
  'moon': LucideIcons.moon,
  // El resto.
  'salad': LucideIcons.salad,
  'coffee': LucideIcons.coffee,
  'pill': LucideIcons.pill,
  'bike': LucideIcons.bike,
  'heartPulse': LucideIcons.heartPulse,
  'brain': LucideIcons.brain,
  'palette': LucideIcons.palette,
  'languages': LucideIcons.languages,
  'graduationCap': LucideIcons.graduationCap,
  'briefcase': LucideIcons.briefcase,
  'sun': LucideIcons.sun,
  'smile': LucideIcons.smile,
  'sparkles': LucideIcons.sparkles,
};

/// El icono de un hábito que no tiene, o cuyo código no conoce esta versión.
const String codigoIconoPorDefecto = 'sparkles';

/// El icono de [codigo]. Un código nulo o que no está en el catálogo (por
/// ejemplo, de una versión más nueva de la app) da el de por defecto: nunca
/// falla.
IconData iconoDeHabito(String? codigo) =>
    iconosHabito[codigo] ?? iconosHabito[codigoIconoPorDefecto]!;

/// El nombre de [codigo] para el lector de pantalla. Un código desconocido o
/// nulo da el nombre del icono por defecto, igual que [iconoDeHabito] da su
/// dibujo.
String nombreIconoHabito(AppLocalizations l, String? codigo) =>
    switch (codigo) {
      'flower2' => l.iconoHabitoFlower2,
      'listChecks' => l.iconoHabitoListChecks,
      'droplet' => l.iconoHabitoDroplet,
      'apple' => l.iconoHabitoApple,
      'footprints' => l.iconoHabitoFootprints,
      'music' => l.iconoHabitoMusic,
      'dumbbell' => l.iconoHabitoDumbbell,
      'phone' => l.iconoHabitoPhone,
      'piggyBank' => l.iconoHabitoPiggyBank,
      'notebookPen' => l.iconoHabitoNotebookPen,
      'bookOpen' => l.iconoHabitoBookOpen,
      'wineOff' => l.iconoHabitoWineOff,
      'phoneOff' => l.iconoHabitoPhoneOff,
      'moon' => l.iconoHabitoMoon,
      'salad' => l.iconoHabitoSalad,
      'coffee' => l.iconoHabitoCoffee,
      'pill' => l.iconoHabitoPill,
      'bike' => l.iconoHabitoBike,
      'heartPulse' => l.iconoHabitoHeartPulse,
      'brain' => l.iconoHabitoBrain,
      'palette' => l.iconoHabitoPalette,
      'languages' => l.iconoHabitoLanguages,
      'graduationCap' => l.iconoHabitoGraduationCap,
      'briefcase' => l.iconoHabitoBriefcase,
      'sun' => l.iconoHabitoSun,
      'smile' => l.iconoHabitoSmile,
      _ => l.iconoHabitoSparkles,
    };
