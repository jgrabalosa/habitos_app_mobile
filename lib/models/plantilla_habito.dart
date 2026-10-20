import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_localizations.dart';

/// Una idea de hábito para empezar: un punto de partida que se puede cambiar
/// entero en el formulario.
///
/// `id` identifica la clave de traducción del nombre, y la categoría se casa
/// por CÓDIGO, no por nombre: el nombre que manda el backend puede venir
/// traducido o cambiar, el código no.
class PlantillaHabito {
  final String id;
  final IconData icono;
  final String frecuencia;
  final int meta;

  /// Días ISO separados por comas ("2,4,6"), solo en las semanales con días.
  final String? dias;
  final String categoriaCodigo;

  const PlantillaHabito({
    required this.id,
    required this.icono,
    required this.frecuencia,
    required this.meta,
    this.dias,
    required this.categoriaCodigo,
  });
}

/// Las ideas que se ofrecen. Son datos: para cambiar cuáles salen o sus
/// valores por defecto, se edita aquí y nada más.
const List<PlantillaHabito> plantillasHabito = [
  PlantillaHabito(
    id: 'beberAgua',
    icono: LucideIcons.droplet,
    frecuencia: 'DIARIO',
    meta: 4,
    categoriaCodigo: 'CAT_SALUD',
  ),
  PlantillaHabito(
    id: 'leer20Min',
    icono: LucideIcons.bookOpen,
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_ESTUDIO',
  ),
  PlantillaHabito(
    id: 'ejercicio',
    icono: LucideIcons.dumbbell,
    frecuencia: 'SEMANAL',
    meta: 3,
    dias: '2,4,6',
    categoriaCodigo: 'CAT_DEPORTE',
  ),
  PlantillaHabito(
    id: 'meditar',
    icono: LucideIcons.flower2,
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_MENTE',
  ),
  PlantillaHabito(
    id: 'dormir8h',
    icono: LucideIcons.moon,
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_SUENO',
  ),
  PlantillaHabito(
    id: 'caminar',
    icono: LucideIcons.footprints,
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_SALUD',
  ),
  PlantillaHabito(
    id: 'escribirDiario',
    icono: LucideIcons.notebookPen,
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_MENTE',
  ),
];

/// Nombre de una plantilla en un idioma concreto.
String nombrePlantilla(AppLocalizations l, String id) => switch (id) {
  'beberAgua' => l.plantillaBeberAgua,
  'leer20Min' => l.plantillaLeer20Min,
  'ejercicio' => l.plantillaEjercicio,
  'meditar' => l.plantillaMeditar,
  'dormir8h' => l.plantillaDormir8h,
  'caminar' => l.plantillaCaminar,
  'escribirDiario' => l.plantillaEscribirDiario,
  _ => id,
};

/// Lo que dice cada fila debajo del nombre: cuántas veces y en qué días.
String descripcionPlantilla(AppLocalizations l, PlantillaHabito p) {
  if (p.frecuencia == 'SEMANAL' && p.dias != null) {
    final dias = (p.dias!.split(',').map(int.parse).toList()..sort())
        .map((d) => _nombreDia(l, d))
        .join(', ');
    return l.ideasFrecSemanal(p.meta, dias);
  }
  return p.meta == 1 ? l.ideasFrecDiario : l.ideasFrecDiarioN(p.meta);
}

/// Nombre corto de un día ISO (1 = lunes).
String _nombreDia(AppLocalizations l, int dia) => switch (dia) {
  1 => l.ideasDia1,
  2 => l.ideasDia2,
  3 => l.ideasDia3,
  4 => l.ideasDia4,
  5 => l.ideasDia5,
  6 => l.ideasDia6,
  _ => l.ideasDia7,
};

String _normalizar(String s) => s
    .toLowerCase()
    .trim()
    .replaceAll(RegExp(r'[áàä]'), 'a')
    .replaceAll(RegExp(r'[éèë]'), 'e')
    .replaceAll(RegExp(r'[íìï]'), 'i')
    .replaceAll(RegExp(r'[óòö]'), 'o')
    .replaceAll(RegExp(r'[úùü]'), 'u');

/// Se compara contra las TRES traducciones, no solo la activa: un hábito
/// creado en español debe seguir ocultando su plantilla si el usuario se pasa
/// a inglés.
final List<AppLocalizations> _todosLosIdiomas = [
  lookupAppLocalizations(const Locale('es')),
  lookupAppLocalizations(const Locale('en')),
  lookupAppLocalizations(const Locale('pt')),
];

bool _yaExiste(PlantillaHabito p, List<String> nombresExistentes) {
  final variantes = _todosLosIdiomas
      .map((l) => _normalizar(nombrePlantilla(l, p.id)))
      .toSet();
  return nombresExistentes.any((nombre) {
    final n = _normalizar(nombre);
    return variantes.any((v) => n == v || n.contains(v) || v.contains(n));
  });
}

/// Las plantillas que aún no tienen un hábito con su nombre. Un nombre cuenta
/// como existente si es igual o contiene a una de las traducciones.
List<PlantillaHabito> plantillasDisponibles(List<String> nombresExistentes) =>
    plantillasHabito.where((p) => !_yaExiste(p, nombresExistentes)).toList();
