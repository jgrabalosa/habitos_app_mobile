/// Las reglas de los hábitos de minutos que no dependen de widgets ni de red,
/// para poder probarlas. Las pantallas las llaman tal cual.
library;

import 'habito.dart';

/// Lo mínimo y lo máximo que admite un registro, y también el objetivo de un
/// día. El backend aplica los mismos límites: aquí es para no dejar escribir
/// algo que va a rechazar.
const int minutosMinimo = 1;
const int minutosMaximo = 600;

/// Las metas de un toque al crear o editar un hábito de minutos.
const List<int> metasRapidasMinutos = [10, 15, 30, 60, 120];

/// Las horas que ofrece la rueda de la meta: de 0 a 10 (10 h = 600 min).
const int horasMaximasRueda = minutosMaximo ~/ 60;

/// El paso de la rueda de minutos de la meta.
const int pasoMinutosRueda = 5;

/// Lo que ofrece la rueda de minutos de la meta con [horas] elegidas, en orden.
///
/// De 5 en 5, con estos límites (los de [minutosMinimo] y [minutosMaximo]):
/// con 10 h solo el 0, y con 0 h no hay 0 (nunca 0 h 0 min). Si [existente] —la
/// meta que ya tenía el hábito— cae en esas [horas] y no es múltiplo de 5 (o
/// es menor de 5), se incluye tal cual, para no redondearla sin que el
/// usuario toque nada.
List<int> minutosDeRueda(int horas, {int? existente}) {
  if (horas >= horasMaximasRueda) return const [0];
  final lista = <int>[
    for (var m = 0; m < 60; m += pasoMinutosRueda)
      if (horas > 0 || m > 0) m,
  ];
  if (existente != null &&
      existente ~/ 60 == horas &&
      !lista.contains(existente % 60) &&
      objetivoMinutosValido(existente)) {
    lista
      ..add(existente % 60)
      ..sort();
  }
  return lista;
}

/// El minuto de [opciones] más cercano a [minuto] (el menor si empatan): lo
/// que queda elegido en la rueda de minutos al cambiar de horas.
int minutoMasCercano(List<int> opciones, int minuto) {
  var mejor = opciones.first;
  for (final o in opciones) {
    if ((o - minuto).abs() < (mejor - minuto).abs()) mejor = o;
  }
  return mejor;
}

/// Los botones de suma rápida del panel de minutos.
const List<int> sumasRapidasMinutos = [5, 15, 30];

/// Lo que lleva un día respecto a su objetivo, de 0 a 1. Pasarse no sube de
/// 1: los minutos de más se guardan, pero no hacen el día «más hecho». Sin
/// objetivo (no debería pasar en un hábito de minutos) cuenta hecho en cuanto
/// hay algo.
double fraccionMinutos(int hechos, int? objetivo) {
  if (hechos <= 0) return 0.0;
  if (objetivo == null || objetivo <= 0) return 1.0;
  return (hechos / objetivo).clamp(0.0, 1.0);
}

/// Si con [hechos] minutos el día llega a su [objetivo].
bool diaHechoEnMinutos(int hechos, int? objetivo) =>
    fraccionMinutos(hechos, objetivo) >= 1.0;

/// Lo que envía «Completar»: exactamente lo que falta para el [objetivo], o
/// null si no falta nada (meta cumplida, o sin objetivo).
int? minutosParaCompletar(int hechos, int? objetivo) {
  if (objetivo == null || objetivo <= 0) return null;
  final faltan = objetivo - hechos;
  return faltan > 0 ? faltan : null;
}

/// Los botones rápidos que se enseñan, en su orden fijo. Mientras falte algo,
/// solo los menores estrictos que lo que falta: para llegar justo está
/// «Completar». Con la meta cumplida (o sin objetivo), todos, para sumar de
/// más.
List<int> sumasRapidasVisibles(int hechos, int? objetivo) {
  final faltan = minutosParaCompletar(hechos, objetivo);
  if (faltan == null) return sumasRapidasMinutos;
  return [
    for (final n in sumasRapidasMinutos)
      if (n < faltan) n,
  ];
}

/// Por qué no vale la cifra libre.
enum ErrorMinutos {
  /// No hay número.
  vacio,

  /// La cifra no cae entre [minutosMinimo] y [minutosMaximo].
  fueraDeRango,
}

/// Lo que hay que enviar por la cifra libre [texto], o por qué no se puede.
/// La cifra siempre se suma a lo que hay.
({int? minutos, ErrorMinutos? error}) minutosAEnviar(String texto) {
  final cifra = int.tryParse(texto.trim());
  if (cifra == null) return (minutos: null, error: ErrorMinutos.vacio);
  if (cifra < minutosMinimo || cifra > minutosMaximo) {
    return (minutos: null, error: ErrorMinutos.fueraDeRango);
  }
  return (minutos: cifra, error: null);
}

/// Si una cifra vale como objetivo de minutos por día.
bool objetivoMinutosValido(int? minutos) =>
    minutos != null && minutos >= minutosMinimo && minutos <= minutosMaximo;

/// Cuándo empieza a valer un cambio de objetivo, visto desde [hoy].
enum CuandoAplica {
  /// Ya vale: no hay que avisar de nada.
  hoy,

  /// Mañana. Gana a [lunes] si mañana es lunes.
  manana,

  /// El lunes que viene, dentro de los próximos siete días.
  lunes,

  /// Cualquier otra fecha futura: se dice la fecha.
  otraFecha,
}

/// Cuándo vale un cambio que empieza en [desde], visto desde [hoy]. Las dos se
/// comparan como fechas sin hora, construidas con el constructor de
/// `DateTime` y no con `Duration`, por el cambio de hora.
CuandoAplica cuandoAplica(DateTime desde, DateTime hoy) {
  final d = DateTime(desde.year, desde.month, desde.day);
  final h = DateTime(hoy.year, hoy.month, hoy.day);
  if (!d.isAfter(h)) return CuandoAplica.hoy;
  if (d == DateTime(h.year, h.month, h.day + 1)) return CuandoAplica.manana;
  if (d.weekday == DateTime.monday &&
      d.isBefore(DateTime(h.year, h.month, h.day + 8))) {
    return CuandoAplica.lunes;
  }
  return CuandoAplica.otraFecha;
}

/// «AAAA-MM-DD» a fecha sin hora; cualquier otra cosa es null.
DateTime? fechaSinHoraDe(Object? valor) {
  if (valor is! String) return null;
  final fecha = DateTime.tryParse(valor);
  return fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);
}

/// Días por semana de un semanal de minutos: entre 1 y 7. Cada día cuenta
/// una vez, así que no se puede pedir más de siete.
const int diasMinimosSemana = 1;
const int diasMaximosSemana = 7;

/// La meta recortada a lo que admite [unidad]. En minutos, entre 1 y 7 días
/// por semana (y en un diario el servidor la fuerza a 1 de todos modos). En
/// veces no se toca: un diario de veces puede pedir 8 al día.
int metaParaUnidad(int meta, UnidadHabito unidad) => switch (unidad) {
  UnidadHabito.veces => meta,
  UnidadHabito.minutos => meta.clamp(diasMinimosSemana, diasMaximosSemana),
};

/// Cómo se pinta un día de un hábito de minutos en el calendario del
/// detalle: sin nada, a medias o hecho.
enum NivelDiaMinutos { vacio, parcial, hecho }

/// El nivel de un día de minutos del calendario. Manda el servidor:
/// [completado] dice si el día llegó al objetivo que valía ESE día. A medias
/// es tener minutos sin estar completado. Pasarse no lo hace «más hecho».
NivelDiaMinutos nivelDiaCalendario({
  required bool completado,
  required int minutos,
}) {
  if (completado) return NivelDiaMinutos.hecho;
  return minutos > 0 ? NivelDiaMinutos.parcial : NivelDiaMinutos.vacio;
}

/// Un día de minutos del calendario del detalle, ya leído.
class DiaCalendarioMinutos {
  final NivelDiaMinutos nivel;
  final int minutos;

  /// El objetivo que valía ese día, o el de hoy si el backend no lo manda.
  final int? objetivo;

  const DiaCalendarioMinutos({
    required this.nivel,
    required this.minutos,
    required this.objetivo,
  });
}

/// Lee un día del calendario de un hábito de minutos. Null si el día no trae
/// `minutos` (ese día el hábito era de veces, o el backend es anterior): se
/// pinta como un día de veces.
DiaCalendarioMinutos? leerDiaCalendarioMinutos(
  Map<String, dynamic> dia, {
  required int? objetivoActual,
}) {
  final minutos = (dia['minutos'] as num?)?.toInt();
  if (minutos == null) return null;
  return DiaCalendarioMinutos(
    nivel: nivelDiaCalendario(
      completado: dia['completado'] == true,
      minutos: minutos,
    ),
    minutos: minutos,
    objetivo: (dia['minutosObjetivo'] as num?)?.toInt() ?? objetivoActual,
  );
}
