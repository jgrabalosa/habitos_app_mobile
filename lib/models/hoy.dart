import 'habito.dart';
import 'minutos.dart';

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

  /// En qué se mide. En un hábito de minutos, [completados] y [meta] cuentan
  /// días (en un diario, 0 o 1) y [hecho] es que el día llegó a su objetivo.
  final UnidadHabito unidad;

  /// La suma de los minutos registrados el día que se mira. Cero en los de
  /// veces y si el backend no lo manda.
  final int minutosHechos;

  /// Los minutos que pide el día que se mira. Null en los de veces.
  final int? minutosObjetivo;

  const FilaHoy({
    required this.habito,
    required this.completados,
    required this.meta,
    required this.hecho,
    required this.completadoEnFecha,
    required this.ritmoNivel,
    required this.fechasCompletadas,
    this.unidad = UnidadHabito.veces,
    this.minutosHechos = 0,
    this.minutosObjetivo,
  });

  /// Los campos de minutos pueden faltar (backend anterior): sin `unidad` se
  /// usa la del hábito, que a su vez es `veces` si tampoco viene; sin
  /// `minutosObjetivo`, el del hábito.
  factory FilaHoy.fromJson(Map<String, dynamic> json) {
    final habito = Habito.fromJson(json['habito'] as Map<String, dynamic>);
    return FilaHoy(
      habito: habito,
      completados: json['completados'] as int? ?? 0,
      meta: json['meta'] as int? ?? 1,
      hecho: json['hecho'] == true,
      completadoEnFecha: json['completadoEnFecha'] == true,
      ritmoNivel: json['ritmoNivel'] as int? ?? 1,
      fechasCompletadas:
          ((json['fechasCompletadas'] as List<dynamic>?) ?? const [])
              .cast<String>()
              .toSet(),
      unidad: json.containsKey('unidad')
          ? unidadDe(json['unidad'])
          : habito.unidad,
      minutosHechos: (json['minutosHechos'] as num?)?.toInt() ?? 0,
      minutosObjetivo:
          (json['minutosObjetivo'] as num?)?.toInt() ?? habito.minutosObjetivo,
    );
  }

  /// Lo que lleva respecto a su meta, de 0 a 1. Las sesiones de más de un
  /// semanal no pasan de 1. En un diario de minutos, los minutos del día
  /// respecto a su objetivo.
  double get fraccion {
    if (esMinutos && !esSemanal) return fraccionDia;
    return meta <= 0 ? 0.0 : (completados / meta).clamp(0.0, 1.0);
  }

  bool get esSemanal => habito.frecuencia == 'SEMANAL';

  bool get esMinutos => unidad == UnidadHabito.minutos;

  /// En un hábito de minutos, lo que lleva el día que se mira respecto a su
  /// objetivo, de 0 a 1. Es lo que dibuja el anillo de la fila.
  double get fraccionDia => fraccionMinutos(minutosHechos, minutosObjetivo);

  /// En un hábito de minutos, si el día que se mira llegó a su objetivo.
  bool get diaHechoMinutos => diaHechoEnMinutos(minutosHechos, minutosObjetivo);

  /// La fila con [pasos] de más (o de menos, si es negativo) que la pantalla
  /// ya ha marcado en [fecha] y `/hoy` todavía no ha devuelto. Es una
  /// aproximación hasta la siguiente carga, para que el contador, el check y
  /// el mini-mapa cambien al momento; la verdad la trae la recarga.
  ///
  /// [delDia] dice en qué sección está: un semanal con día fijo en su día
  /// cuenta como hecho si se hizo ese día, y fuera de él, al llegar a su
  /// objetivo de la semana.
  FilaHoy conPasos(int pasos, {required bool delDia, required String fecha}) {
    if (pasos == 0) return this;
    final nuevos = completados + pasos < 0 ? 0 : completados + pasos;
    // En un diario, `completados` es lo de ese día: si queda algo, sigue
    // hecho ese día. En un semanal se apunta uno por día como mucho.
    final enFecha = pasos > 0 || (!esSemanal && nuevos > 0);
    final cuenta = !esSemanal
        ? nuevos >= meta
        : (delDia ? enFecha : nuevos >= meta);
    final fechas = {...fechasCompletadas};
    if (enFecha) {
      fechas.add(fecha);
    } else {
      fechas.remove(fecha);
    }
    return FilaHoy(
      habito: habito,
      completados: nuevos,
      meta: meta,
      hecho: cuenta,
      completadoEnFecha: enFecha,
      ritmoNivel: ritmoNivel,
      fechasCompletadas: fechas,
      unidad: unidad,
      minutosHechos: minutosHechos,
      minutosObjetivo: minutosObjetivo,
    );
  }

  /// Como [conPasos], para un hábito de minutos: la fila con [minutos] de más
  /// (o de menos, al deshacer) registrados en [fecha] que `/hoy` todavía no ha
  /// devuelto. El día pasa a hecho al llegar a su objetivo, y entonces cuenta
  /// un día más en [completados]; deshacer por debajo del objetivo lo quita.
  FilaHoy conMinutos(
    int minutos, {
    required bool delDia,
    required String fecha,
  }) {
    if (minutos == 0) return this;
    final nuevos = minutosHechos + minutos < 0 ? 0 : minutosHechos + minutos;
    final antes = diaHechoMinutos;
    final despues = diaHechoEnMinutos(nuevos, minutosObjetivo);
    var dias = completados;
    if (!antes && despues) dias++;
    if (antes && !despues && dias > 0) dias--;
    final cuenta = !esSemanal ? despues : (delDia ? despues : dias >= meta);
    final fechas = {...fechasCompletadas};
    if (despues) {
      fechas.add(fecha);
    } else {
      fechas.remove(fecha);
    }
    return FilaHoy(
      habito: habito,
      completados: dias,
      meta: meta,
      hecho: cuenta,
      completadoEnFecha: nuevos > 0,
      ritmoNivel: ritmoNivel,
      fechasCompletadas: fechas,
      unidad: unidad,
      minutosHechos: nuevos,
      minutosObjetivo: minutosObjetivo,
    );
  }
}

/// El avance de la sección del día, de 0 a 1, con la misma regla que el
/// backend: la media de lo que lleva cada fila, con lo hecho a medias; un
/// semanal con día fijo, en su día, cuenta todo o nada. Null si no hay
/// filas. Sirve para que el anillo y el fondo se muevan al marcar, antes de
/// que llegue la recarga.
///
/// Un hábito de minutos cuenta los minutos del día respecto a su objetivo,
/// también el semanal en su día: es el crédito parcial del diseño (sección
/// 3). Es una aproximación hasta la recarga, como todo aquí.
double? avanceDelDia(List<FilaHoy> filas) {
  if (filas.isEmpty) return null;
  var suma = 0.0;
  for (final f in filas) {
    suma += f.esMinutos
        ? f.fraccionDia
        : (f.esSemanal ? (f.hecho ? 1.0 : 0.0) : f.fraccion);
  }
  return suma / filas.length;
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
