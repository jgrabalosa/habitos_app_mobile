import 'habito.dart';

/// Hacia dónde va un ritmo respecto a hace siete días. Lo manda el backend
/// (`SUBE`, `BAJA`, `IGUAL`); la frase la pone la app.
enum TendenciaRitmo { sube, baja, igual }

/// La tendencia que manda el backend, o null si no viene o si es un valor que
/// esta versión de la app no conoce.
TendenciaRitmo? tendenciaDe(Object? codigo) => switch (codigo) {
  'SUBE' => TendenciaRitmo.sube,
  'BAJA' => TendenciaRitmo.baja,
  'IGUAL' => TendenciaRitmo.igual,
  _ => null,
};

/// Un hábito en una de las dos secciones de Hoy, tal como lo manda `/hoy`.
class FilaHoy {
  final Habito habito;

  /// El «3» de «3/4»: en un diario, lo hecho el día que se mira; en un
  /// semanal, lo hecho en la semana.
  final int completados;

  final int meta;

  /// Si cuenta en el contador de su sección.
  final bool hecho;

  /// Si se marcó el día que se mira.
  final bool completadoEnFecha;

  /// El nivel de su ritmo, de 1 a 5. Siempre el de hoy, aunque se mire otro
  /// día.
  final int ritmoNivel;

  /// Las fechas ISO de la semana en que se hizo.
  final Set<String> fechasCompletadas;

  const FilaHoy({
    required this.habito,
    required this.completados,
    required this.meta,
    required this.hecho,
    required this.completadoEnFecha,
    required this.ritmoNivel,
    required this.fechasCompletadas,
  });

  factory FilaHoy.fromJson(Map<String, dynamic> json) => FilaHoy(
    habito: Habito.fromJson(json['habito'] as Map<String, dynamic>),
    completados: json['completados'] as int? ?? 0,
    meta: json['meta'] as int? ?? 1,
    hecho: json['hecho'] == true,
    completadoEnFecha: json['completadoEnFecha'] == true,
    ritmoNivel: json['ritmoNivel'] as int? ?? 1,
    fechasCompletadas:
        ((json['fechasCompletadas'] as List<dynamic>?) ?? const [])
            .cast<String>()
            .toSet(),
  );

  /// Lo que lleva respecto a su meta, de 0 a 1. Las sesiones de más de un
  /// semanal no pasan de 1.
  double get fraccion => meta <= 0 ? 0.0 : (completados / meta).clamp(0.0, 1.0);
}

/// Una sección de Hoy: cuántos de sus hábitos cuentan como hechos, y sus
/// filas en el orden en que se pintan.
class SeccionHoy {
  final int hechos;
  final int total;
  final List<FilaHoy> habitos;

  const SeccionHoy({
    required this.hechos,
    required this.total,
    required this.habitos,
  });

  static const SeccionHoy vacia = SeccionHoy(hechos: 0, total: 0, habitos: []);

  factory SeccionHoy.fromJson(Map<String, dynamic>? json) => json == null
      ? vacia
      : SeccionHoy(
          hechos: json['hechos'] as int? ?? 0,
          total: json['total'] as int? ?? 0,
          habitos: ((json['habitos'] as List<dynamic>?) ?? const [])
              .map((f) => FilaHoy.fromJson(f as Map<String, dynamic>))
              .toList(),
        );
}

/// Un día de la tira. [avance] va de 0 a 1, y es null si ese día no tocaba
/// nada o todavía no ha llegado.
class DiaTira {
  final String fecha;
  final double? avance;

  const DiaTira({required this.fecha, this.avance});
}

/// La respuesta de `/hoy` ya leída.
class HoyLeido {
  /// El día que se mira, `AAAA-MM-DD`.
  final String fecha;

  /// Hoy en la zona del usuario, según el servidor.
  final String hoy;

  /// Los siete días de la semana de [fecha], de lunes a domingo.
  final List<DiaTira> dias;

  /// El avance del día que se mira, de 0 a 1; null si no tocaba nada.
  final double? avance;

  /// El nivel del ritmo general, de 1 a 5; null sin hábitos activos.
  final int? ritmoNivel;

  final TendenciaRitmo? ritmoTendencia;
  final SeccionHoy delDia;
  final SeccionHoy deLaSemana;

  /// Códigos de los logros de ritmo ganados en esta lectura. Casi siempre
  /// vacío.
  final List<String> logrosOtorgados;

  const HoyLeido({
    required this.fecha,
    required this.hoy,
    required this.dias,
    required this.avance,
    required this.ritmoNivel,
    required this.ritmoTendencia,
    required this.delDia,
    required this.deLaSemana,
    required this.logrosOtorgados,
  });

  bool get viendoHoy => fecha == hoy;

  /// Posición de [fecha] en la tira, o -1 si no está.
  int get indiceFecha => dias.indexWhere((d) => d.fecha == fecha);

  /// Posición de [hoy] en la tira, o -1 si la semana que se mira no es la de
  /// hoy.
  int get indiceHoy => dias.indexWhere((d) => d.fecha == hoy);
}

/// Lee la respuesta de `/hoy`.
HoyLeido leerHoy(Map<String, dynamic> data) => HoyLeido(
  fecha: data['fecha'] as String,
  hoy: data['hoy'] as String,
  dias: ((data['dias'] as List<dynamic>?) ?? const []).map((d) {
    final dia = d as Map<String, dynamic>;
    return DiaTira(
      fecha: dia['fecha'] as String,
      avance: (dia['avance'] as num?)?.toDouble(),
    );
  }).toList(),
  avance: (data['avance'] as num?)?.toDouble(),
  ritmoNivel: data['ritmoNivel'] as int?,
  ritmoTendencia: tendenciaDe(data['ritmoTendencia']),
  delDia: SeccionHoy.fromJson(data['delDia'] as Map<String, dynamic>?),
  deLaSemana: SeccionHoy.fromJson(data['deLaSemana'] as Map<String, dynamic>?),
  logrosOtorgados: ((data['logrosOtorgados'] as List<dynamic>?) ?? const [])
      .cast<String>(),
);
