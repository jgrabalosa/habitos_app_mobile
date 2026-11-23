import 'hoy.dart';

/// Un semanal de la semana pasada, tal como lo manda `/semana-pasada`.
class SemanalDeLaSemana {
  final int habitoId;
  final String nombre;
  final String? icono;
  final int hechos;
  final int meta;
  final bool completo;

  const SemanalDeLaSemana({
    required this.habitoId,
    required this.nombre,
    required this.icono,
    required this.hechos,
    required this.meta,
    required this.completo,
  });

  factory SemanalDeLaSemana.fromJson(Map<String, dynamic> j) =>
      SemanalDeLaSemana(
        habitoId: (j['habitoId'] as num?)?.toInt() ?? 0,
        nombre: (j['nombre'] as String?) ?? '',
        icono: j['icono'] as String?,
        hechos: (j['hechos'] as num?)?.toInt() ?? 0,
        meta: (j['meta'] as num?)?.toInt() ?? 0,
        completo: j['completo'] == true,
      );
}

/// El hábito cuyo ritmo más ha subido en la semana.
class HabitoQueMasSube {
  final int habitoId;
  final String nombre;
  final int nivelAntes;
  final int nivelAhora;

  const HabitoQueMasSube({
    required this.habitoId,
    required this.nombre,
    required this.nivelAntes,
    required this.nivelAhora,
  });

  factory HabitoQueMasSube.fromJson(Map<String, dynamic> j) => HabitoQueMasSube(
    habitoId: (j['habitoId'] as num?)?.toInt() ?? 0,
    nombre: (j['nombre'] as String?) ?? '',
    nivelAntes: (j['nivelAntes'] as num?)?.toInt() ?? 1,
    nivelAhora: (j['nivelAhora'] as num?)?.toInt() ?? 1,
  );
}

/// `SemanaPasadaDTO`: lo que se hizo la semana pasada. Solo lo hecho: ni lo
/// que faltó ni los días sin hacer (D-70, las pausas no guardan fechas).
class SemanaPasada {
  /// Lunes y domingo de esa semana (`AAAA-MM-DD`).
  final String desde;
  final String hasta;
  final bool hayActividad;

  /// Hábitos y días hechos, como el avance de Hoy (no unidades).
  final int hechos;
  final int total;
  final int diasCompletos;
  final List<SemanalDeLaSemana> semanales;
  final int? ritmoNivel;
  final TendenciaRitmo? ritmoTendencia;
  final HabitoQueMasSube? masSube;

  const SemanaPasada({
    required this.desde,
    required this.hasta,
    required this.hayActividad,
    required this.hechos,
    required this.total,
    required this.diasCompletos,
    required this.semanales,
    required this.ritmoNivel,
    required this.ritmoTendencia,
    required this.masSube,
  });

  factory SemanaPasada.fromJson(Map<String, dynamic> j) {
    final mas = j['masSube'];
    return SemanaPasada(
      desde: j['desde'] as String,
      hasta: j['hasta'] as String,
      hayActividad: j['hayActividad'] == true,
      hechos: (j['hechos'] as num?)?.toInt() ?? 0,
      total: (j['total'] as num?)?.toInt() ?? 0,
      diasCompletos: (j['diasCompletos'] as num?)?.toInt() ?? 0,
      semanales: [
        for (final s in (j['semanales'] as List<dynamic>? ?? const []))
          if (s is Map<String, dynamic>) SemanalDeLaSemana.fromJson(s),
      ],
      ritmoNivel: (j['ritmoNivel'] as num?)?.toInt(),
      ritmoTendencia: tendenciaDe(j['ritmoTendencia']),
      masSube: mas is Map<String, dynamic>
          ? HabitoQueMasSube.fromJson(mas)
          : null,
    );
  }

  /// Los semanales que llegaron a su objetivo.
  List<SemanalDeLaSemana> get semanalesLogrados =>
      semanales.where((s) => s.completo).toList();
}
