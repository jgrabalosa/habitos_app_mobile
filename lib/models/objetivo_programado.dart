import 'habito.dart';
import 'minutos.dart';

/// Un cambio de objetivo que aún no vale: desde cuándo y qué pedirá el hábito
/// entonces. Lo manda el detalle en `objetivoProgramado`.
class ObjetivoProgramado {
  final DateTime desde;
  final UnidadHabito unidad;
  final String frecuencia;
  final int meta;
  final int? minutosObjetivo;
  final String? diasSemana;

  const ObjetivoProgramado({
    required this.desde,
    required this.unidad,
    required this.frecuencia,
    required this.meta,
    this.minutosObjetivo,
    this.diasSemana,
  });

  /// Null si no hay cambio programado, si el backend es anterior y no lo
  /// manda, o si llega sin una fecha que se pueda leer: sin fecha no hay nada
  /// que decir.
  static ObjetivoProgramado? deJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final desde = fechaSinHoraDe(json['desde']);
    if (desde == null) return null;
    return ObjetivoProgramado(
      desde: desde,
      unidad: unidadDe(json['unidad']),
      frecuencia: (json['frecuencia'] as String?) ?? 'DIARIO',
      meta: (json['meta'] as num?)?.toInt() ?? 1,
      minutosObjetivo: (json['minutosObjetivo'] as num?)?.toInt(),
      diasSemana: json['diasSemana'] as String?,
    );
  }

  /// Días planificados como enteros ISO; vacío si no hay días fijos.
  List<int> get diasPlanificados =>
      (diasSemana == null || diasSemana!.trim().isEmpty)
      ? const []
      : diasSemana!.split(',').map((d) => int.parse(d.trim())).toList();
}
