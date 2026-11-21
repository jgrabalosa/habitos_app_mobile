import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/textos_minutos.dart';
import 'habito.dart';
import 'iconos_habito.dart';

/// Una idea de hábito para empezar: un punto de partida que se puede cambiar
/// entero en el formulario.
///
/// `id` identifica la clave de traducción del nombre, y la categoría se casa
/// por CÓDIGO, no por nombre: el nombre que manda el backend puede venir
/// traducido o cambiar, el código no.
class PlantillaHabito {
  final String id;

  /// El código del icono en el catálogo ([iconosHabito]). Es lo que se guarda
  /// en el hábito que sale de la plantilla.
  final String codigoIcono;
  final String frecuencia;
  final int meta;

  /// Días ISO separados por comas ("2,4,6"), solo en las semanales con días.
  /// Una semanal sin días es flexible: [meta] días cualesquiera de la semana.
  final String? dias;
  final String categoriaCodigo;

  /// En qué se mide. Veces si no se dice.
  final UnidadHabito unidad;

  /// Los minutos por día, solo en las de [UnidadHabito.minutos].
  final int? minutos;

  /// La hora del aviso que propone. El formulario la trae puesta, con el
  /// aviso encendido, y se puede cambiar o apagar.
  final TimeOfDay horaAviso;

  /// Nombres que tuvo la plantilla, en cualquier idioma: un hábito creado con
  /// uno de ellos sigue ocultando la idea.
  final List<String> nombresAntiguos;

  const PlantillaHabito({
    required this.id,
    required this.codigoIcono,
    required this.frecuencia,
    required this.meta,
    this.dias,
    required this.categoriaCodigo,
    this.unidad = UnidadHabito.veces,
    this.minutos,
    required this.horaAviso,
    this.nombresAntiguos = const [],
  });

  /// El dibujo de [codigoIcono], buscado en el catálogo: una sola fuente.
  IconData get icono => iconoDeHabito(codigoIcono);
}

/// Las ideas que se ofrecen, en el orden del día (por la hora del aviso). Son
/// datos: para cambiar cuáles salen o sus valores por defecto, se edita aquí y
/// nada más. Los `id` que ya existían no cambian: van a Analytics (T-007).
///
/// Leer, Meditar, Caminar y Tocar un instrumento son de minutos. Leer era
/// «Leer 20 min» de veces; desde el 15-nov-2026 se llama «Leer» y los 30 min
/// los dice la etiqueta del objetivo. Caminar era de veces hasta el 17-nov.
/// «Un día sin alcohol» y «Dejar el móvil antes de dormir» son hábitos
/// normales que se marcan, con aviso por la noche (D-21).
const List<PlantillaHabito> plantillasHabito = [
  PlantillaHabito(
    id: 'meditar',
    codigoIcono: 'flower2',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_MENTE',
    unidad: UnidadHabito.minutos,
    minutos: 15,
    horaAviso: TimeOfDay(hour: 8, minute: 0),
  ),
  PlantillaHabito(
    id: 'planificarDia',
    codigoIcono: 'listChecks',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_TRABAJO',
    horaAviso: TimeOfDay(hour: 9, minute: 0),
  ),
  PlantillaHabito(
    id: 'beberAgua',
    codigoIcono: 'droplet',
    frecuencia: 'DIARIO',
    meta: 4,
    categoriaCodigo: 'CAT_SALUD',
    horaAviso: TimeOfDay(hour: 10, minute: 0),
  ),
  PlantillaHabito(
    id: 'comerFrutaVerdura',
    codigoIcono: 'apple',
    frecuencia: 'DIARIO',
    meta: 3,
    categoriaCodigo: 'CAT_ALIMENTACION',
    horaAviso: TimeOfDay(hour: 13, minute: 0),
  ),
  PlantillaHabito(
    id: 'caminar',
    codigoIcono: 'footprints',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_SALUD',
    unidad: UnidadHabito.minutos,
    minutos: 30,
    horaAviso: TimeOfDay(hour: 18, minute: 0),
  ),
  PlantillaHabito(
    id: 'tocarInstrumento',
    codigoIcono: 'music',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_CREATIVIDAD',
    unidad: UnidadHabito.minutos,
    minutos: 20,
    horaAviso: TimeOfDay(hour: 18, minute: 30),
  ),
  PlantillaHabito(
    id: 'ejercicio',
    codigoIcono: 'dumbbell',
    frecuencia: 'SEMANAL',
    meta: 3,
    dias: '2,4,6',
    categoriaCodigo: 'CAT_DEPORTE',
    horaAviso: TimeOfDay(hour: 19, minute: 0),
  ),
  PlantillaHabito(
    id: 'llamarQuerido',
    codigoIcono: 'phone',
    frecuencia: 'SEMANAL',
    meta: 2,
    categoriaCodigo: 'CAT_SOCIAL',
    horaAviso: TimeOfDay(hour: 19, minute: 30),
  ),
  PlantillaHabito(
    id: 'apuntarGastos',
    codigoIcono: 'piggyBank',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_FINANZAS',
    horaAviso: TimeOfDay(hour: 21, minute: 0),
  ),
  PlantillaHabito(
    id: 'escribirDiario',
    codigoIcono: 'notebookPen',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_MENTE',
    horaAviso: TimeOfDay(hour: 21, minute: 30),
    nombresAntiguos: ['Escribir diario', 'Escrever diário'],
  ),
  PlantillaHabito(
    id: 'leer',
    codigoIcono: 'bookOpen',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_ESTUDIO',
    unidad: UnidadHabito.minutos,
    minutos: 30,
    horaAviso: TimeOfDay(hour: 22, minute: 0),
  ),
  PlantillaHabito(
    id: 'diaSinAlcohol',
    codigoIcono: 'wineOff',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_SALUD',
    horaAviso: TimeOfDay(hour: 22, minute: 30),
  ),
  PlantillaHabito(
    id: 'dejarMovil',
    codigoIcono: 'phoneOff',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_SUENO',
    horaAviso: TimeOfDay(hour: 22, minute: 30),
  ),
  PlantillaHabito(
    id: 'dormir8h',
    codigoIcono: 'moon',
    frecuencia: 'DIARIO',
    meta: 1,
    categoriaCodigo: 'CAT_SUENO',
    horaAviso: TimeOfDay(hour: 23, minute: 0),
    nombresAntiguos: ['Dormir 8h', 'Sleep 8h'],
  ),
];

/// Nombre de una plantilla en un idioma concreto.
String nombrePlantilla(AppLocalizations l, String id) => switch (id) {
  'beberAgua' => l.plantillaBeberAgua,
  'leer' => l.plantillaLeer,
  'ejercicio' => l.plantillaEjercicio,
  'meditar' => l.plantillaMeditar,
  'dormir8h' => l.plantillaDormir8h,
  'caminar' => l.plantillaCaminar,
  'escribirDiario' => l.plantillaEscribirDiario,
  'planificarDia' => l.plantillaPlanificarDia,
  'comerFrutaVerdura' => l.plantillaComerFrutaVerdura,
  'tocarInstrumento' => l.plantillaTocarInstrumento,
  'llamarQuerido' => l.plantillaLlamarQuerido,
  'apuntarGastos' => l.plantillaApuntarGastos,
  'diaSinAlcohol' => l.plantillaDiaSinAlcohol,
  'dejarMovil' => l.plantillaDejarMovil,
  _ => id,
};

/// Lo que dice cada fila debajo del nombre: cuántas veces y en qué días, o en
/// una de minutos, sus minutos («30 min cada día»).
String descripcionPlantilla(AppLocalizations l, PlantillaHabito p) {
  final minutos = p.minutos;
  if (p.unidad == UnidadHabito.minutos && minutos != null) {
    return etiquetaObjetivoMinutos(
      l,
      minutos,
      diario: p.frecuencia == 'DIARIO',
    );
  }
  if (p.frecuencia == 'SEMANAL' && p.dias != null) {
    final dias = (p.dias!.split(',').map(int.parse).toList()..sort())
        .map((d) => _nombreDia(l, d))
        .join(', ');
    return l.ideasFrecSemanal(p.meta, dias);
  }
  // Semanal sin días fijos: «2 días por semana», no «Cada día».
  if (p.frecuencia == 'SEMANAL') return l.habDiasSemanaMeta(p.meta);
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

/// Si [parte] aparece en [texto] empezando una palabra, y con [entera] además
/// terminándola. «leer» empieza una palabra en «leer 20 min» y «read» en
/// «reading», pero «ler» no en «taller» ni «read» en «bake bread».
bool _empiezaPalabra(String texto, String parte, {bool entera = false}) {
  if (parte.isEmpty) return false;
  final fin = entera ? r'($|[^a-z0-9])' : '';
  return RegExp('(^|[^a-z0-9])${RegExp.escape(parte)}$fin').hasMatch(texto);
}

/// Un hábito ya cubre una idea si se llama igual, si su nombre contiene el
/// de la idea empezando una palabra («Reading» cubre «Read», «Ejercicios»
/// cubre «Ejercicio»), o si su nombre es una palabra entera del de la idea
/// («Agua» cubre «Beber agua», pero «Be» no). Cuentan los nombres de hoy en
/// los tres idiomas y los que tuvo antes ([PlantillaHabito.nombresAntiguos]).
bool _yaExiste(PlantillaHabito p, List<String> nombresExistentes) {
  final variantes = {
    for (final l in _todosLosIdiomas) _normalizar(nombrePlantilla(l, p.id)),
    for (final antiguo in p.nombresAntiguos) _normalizar(antiguo),
  };
  return nombresExistentes.any((nombre) {
    final n = _normalizar(nombre);
    return variantes.any(
      (v) =>
          n == v ||
          _empiezaPalabra(n, v) ||
          _empiezaPalabra(v, n, entera: true),
    );
  });
}

/// Las plantillas que aún no tienen un hábito con su nombre. Un nombre cuenta
/// como existente si es igual o contiene a una de las traducciones.
List<PlantillaHabito> plantillasDisponibles(List<String> nombresExistentes) =>
    plantillasHabito.where((p) => !_yaExiste(p, nombresExistentes)).toList();
