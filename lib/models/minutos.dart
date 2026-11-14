/// Las reglas de los hábitos de minutos que no dependen de widgets ni de red,
/// para poder probarlas. Las pantallas las llaman tal cual.
library;

/// Lo mínimo y lo máximo que admite un registro, y también el objetivo de un
/// día. El backend aplica los mismos límites: aquí es para no dejar escribir
/// algo que va a rechazar.
const int minutosMinimo = 1;
const int minutosMaximo = 600;

/// Las metas de un toque al crear o editar un hábito de minutos.
const List<int> metasRapidasMinutos = [10, 15, 30, 60];

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

/// Cómo se lee la cifra libre del panel: se suma a lo que hay, o es el total
/// que se quiere tener ese día.
enum ModoMinutos { sumar, establecer }

/// Por qué no vale la cifra libre.
enum ErrorMinutos {
  /// No hay número.
  vacio,

  /// Lo que se enviaría no cae entre [minutosMinimo] y [minutosMaximo].
  fueraDeRango,

  /// En «Establecer», un total que no sube del que ya hay: el total solo puede
  /// subir, porque bajar sería borrar registros, y para eso está «Deshacer».
  noSube,
}

/// Lo que hay que enviar por la cifra libre [texto], o por qué no se puede.
///
/// En [ModoMinutos.sumar] se envía la cifra tal cual. En
/// [ModoMinutos.establecer] la cifra es el total del día y se envía la
/// diferencia con [totalActual]; si no sube, [ErrorMinutos.noSube].
({int? minutos, ErrorMinutos? error}) minutosAEnviar(
  ModoMinutos modo,
  String texto,
  int totalActual,
) {
  final cifra = int.tryParse(texto.trim());
  if (cifra == null) return (minutos: null, error: ErrorMinutos.vacio);
  final enviar = switch (modo) {
    ModoMinutos.sumar => cifra,
    ModoMinutos.establecer => cifra - totalActual,
  };
  if (modo == ModoMinutos.establecer && enviar <= 0) {
    return (minutos: null, error: ErrorMinutos.noSube);
  }
  if (enviar < minutosMinimo || enviar > minutosMaximo) {
    return (minutos: null, error: ErrorMinutos.fueraDeRango);
  }
  return (minutos: enviar, error: null);
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

/// Cómo se pinta un día de un hábito de minutos en el calendario del
/// detalle: sin nada, a medias (algo, sin llegar a su objetivo) o hecho.
enum NivelDiaMinutos { vacio, parcial, hecho }

NivelDiaMinutos nivelDiaMinutos(int minutos, int? objetivo) {
  if (minutos <= 0) return NivelDiaMinutos.vacio;
  return diaHechoEnMinutos(minutos, objetivo)
      ? NivelDiaMinutos.hecho
      : NivelDiaMinutos.parcial;
}
