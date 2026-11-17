import 'package:intl/intl.dart';

import '../models/habito.dart';
import '../models/minutos.dart';
import '../models/objetivo_programado.dart';
import '../models/registro.dart';
import 'app_localizations.dart';

/// Los textos de los hábitos de minutos que se componen con varias claves.
/// Viven aquí, fuera de las pantallas, para poder probarlos en los tres
/// idiomas.

/// [minutos] en horas y minutos: «45 min», «3 h», «12 h 35 min».
String duracionLegible(AppLocalizations l, int minutos) {
  final total = minutos < 0 ? 0 : minutos;
  final horas = total ~/ 60;
  final resto = total % 60;
  if (horas == 0) return l.durMinutos(resto);
  if (resto == 0) return l.durHoras(horas);
  return l.durHorasMinutos(horas, resto);
}

/// Un par hecho/objetivo con la regla de todos los pares: si las dos cifras
/// son menores de 60, la primera va sola y la segunda con «min» («20» y «30
/// min»: «20 / 30 min»); si alguna llega a 60, cada una con su unidad («45
/// min» y «1 h 30 min»).
({String hechos, String objetivo}) parMinutos(
  AppLocalizations l,
  int hechos,
  int objetivo,
) {
  final h = hechos < 0 ? 0 : hechos;
  if (h < 60 && objetivo < 60) {
    return (hechos: '$h', objetivo: l.durMinutos(objetivo));
  }
  return (
    hechos: duracionLegible(l, h),
    objetivo: duracionLegible(l, objetivo),
  );
}

/// Lo hecho respecto al objetivo: «20 / 30 min», «45 min / 1 h 30 min».
String progresoMinutos(AppLocalizations l, int hechos, int objetivo) {
  final par = parMinutos(l, hechos, objetivo);
  return l.minDeObjetivo(par.hechos, par.objetivo);
}

/// La cifra que decide el singular de lo que falta: 1 solo si es justo
/// «1 min» o «1 h». «1 h 30 min» es un sujeto compuesto y va en plural: «Te
/// faltan 1 h 30 min».
int _cifraPlural(int minutos) => minutos == 60 ? 1 : minutos;

/// La línea bajo el progreso del panel: «Te faltan 10 min», «Meta cumplida»
/// o «Meta cumplida · +13 min de más».
String textoEstadoPanel(
  AppLocalizations l, {
  required int hechos,
  required int? objetivo,
}) {
  final faltan = minutosParaCompletar(hechos, objetivo);
  if (faltan != null) {
    return l.minPanelFaltan(_cifraPlural(faltan), duracionLegible(l, faltan));
  }
  final exceso = hechos - (objetivo ?? 0);
  if (objetivo == null || objetivo <= 0 || exceso <= 0) return l.minPanelHecho;
  return l.minPanelHechoExceso(duracionLegible(l, exceso));
}

/// El botón principal del panel: «Completar · +10 min».
String textoCompletar(AppLocalizations l, int minutos) =>
    l.minCompletar(duracionLegible(l, minutos));

/// La etiqueta de Deshacer: «Deshacer +20 min (14:05)», con la hora local en
/// que se sumó y en el formato del idioma. Sin hora, «Deshacer la última
/// entrada (20 min)»; sin la entrada (no ha llegado), sin cifra.
String etiquetaDeshacer(
  AppLocalizations l,
  Registro? ultima, {
  required String locale,
}) {
  if (ultima == null) return l.minDeshacerUltima;
  final duracion = duracionLegible(l, ultima.cantidad);
  final creado = ultima.creadoEn;
  if (creado == null) return l.minDeshacerUltimaN(duracion);
  return l.minDeshacerConHora(
    duracion,
    DateFormat.jm(locale).format(creado.toLocal()),
  );
}

/// La etiqueta de la cifra propia en el formulario, con la unidad y los
/// límites: «Otra cifra, en minutos (1–600)». Las cifras salen de
/// [minutosMinimo] y [minutosMaximo].
String textoMinutosOtra(AppLocalizations l) =>
    l.habMinutosOtra(minutosMinimo, minutosMaximo);

/// El error del formulario con una cifra fuera de los límites: «Elige entre
/// 1 y 600 minutos (10 h) por día.».
String textoMinutosRango(AppLocalizations l) => l.habMinutosRango(
  minutosMinimo,
  minutosMaximo,
  duracionLegible(l, minutosMaximo),
);

/// El error del panel con una cifra fuera de los límites: «Entre 1 y 600
/// minutos (10 h) cada vez.».
String textoErrorRangoMinutos(AppLocalizations l) => l.minErrorRango(
  minutosMinimo,
  minutosMaximo,
  duracionLegible(l, minutosMaximo),
);

/// La frase del objetivo en el formulario: «30 min cada día», «1 h 30 min
/// cada día que lo hagas».
String etiquetaObjetivoMinutos(
  AppLocalizations l,
  int minutos, {
  required bool diario,
}) {
  final duracion = duracionLegible(l, minutos);
  return diario
      ? l.habMinutosEtiquetaDiario(duracion)
      : l.habMinutosEtiquetaSemanal(duracion);
}

/// La frecuencia de un hábito de minutos en el detalle: «Diario · 1 h cada
/// día» o, con [semanal] (los días o los días por semana ya escritos),
/// «Semanal · lun · mié · 1 h 30 min cada día que lo hagas».
String etiquetaMinutosDetalle(
  AppLocalizations l,
  int minutos, {
  String? semanal,
}) {
  final duracion = duracionLegible(l, minutos);
  return semanal == null
      ? l.detMinutosDiario(duracion)
      : l.detMinutosSemanal(semanal, duracion);
}

/// Lo que sumó un registro, en el detalle: «+20 min», «+1 h 15 min».
String textoRegistroMinutos(AppLocalizations l, int cantidad) =>
    l.detRegistroMinutos(duracionLegible(l, cantidad));

/// El aviso tras guardar un cambio que no vale hasta otro día, o null si ya
/// vale ([aplicaDesde] es hoy, anterior o no viene).
///
/// Con [minutosNuevos] —el cambio toca los minutos por día— y efecto mañana,
/// se dice la cifra: «El objetivo de 1 h 30 min se aplica desde mañana…».
String? avisoAplicaDesde(
  AppLocalizations l, {
  required DateTime? aplicaDesde,
  required DateTime hoy,
  required String locale,
  int? minutosNuevos,
}) {
  if (aplicaDesde == null) return null;
  return switch (cuandoAplica(aplicaDesde, hoy)) {
    CuandoAplica.hoy => null,
    // Un cambio de días o de frecuencia se aplica por semanas: si mañana es
    // lunes (guardado en domingo), lo que se dice es «desde el lunes», no
    // «hoy ya tienes registros». El de minutos se aplica por días.
    CuandoAplica.manana =>
      minutosNuevos != null
          ? l.habAplicaMinutosManana(duracionLegible(l, minutosNuevos))
          : (aplicaDesde.weekday == DateTime.monday
                ? l.habAplicaLunes
                : l.habAplicaManana),
    CuandoAplica.lunes => l.habAplicaLunes,
    CuandoAplica.otraFecha => l.habAplicaFecha(
      DateFormat.MMMMd(locale).format(aplicaDesde),
    ),
  };
}

/// Los días fijos con su abreviatura en el idioma activo: «lun · mié · vie».
String diasFijosLegibles(List<int> dias, String locale) {
  final formato = DateFormat.E(locale);
  // El 6 de enero de 2025 fue lunes: de ahí sale el día ISO 1..7.
  return (List<int>.of(
    dias,
  )..sort()).map((d) => formato.format(DateTime(2025, 1, 5 + d))).join(' · ');
}

/// Qué pedirá [p] respecto a [actual], solo en lo que cambia: «40 min»,
/// «4 días por semana», «40 min · 3 días por semana». Si no cambia nada que
/// se sepa decir, el objetivo entero.
String describirObjetivo(
  AppLocalizations l,
  ObjetivoProgramado p, {
  required Habito actual,
  required String locale,
}) {
  final cambiaUnidad = p.unidad != actual.unidad;
  final cambiaMinutos =
      p.unidad == UnidadHabito.minutos &&
      (cambiaUnidad || p.minutosObjetivo != actual.minutosObjetivo);
  final cambiaFrecuencia =
      p.frecuencia != actual.frecuencia ||
      p.meta != actual.meta ||
      (p.diasSemana ?? '') != (actual.diasSemana ?? '');

  String minutos() => duracionLegible(l, p.minutosObjetivo ?? 0);
  String frecuencia() {
    if (p.frecuencia == 'SEMANAL') {
      final dias = p.diasPlanificados;
      return dias.isNotEmpty
          ? diasFijosLegibles(dias, locale)
          : l.objDiasSemana(p.meta);
    }
    return p.unidad == UnidadHabito.minutos
        ? l.frecDiario
        : l.objVecesDia(p.meta);
  }

  final partes = <String>[
    if (cambiaMinutos) minutos(),
    if (cambiaFrecuencia) frecuencia(),
  ];
  if (partes.isEmpty) {
    partes.addAll([
      if (p.unidad == UnidadHabito.minutos) minutos(),
      frecuencia(),
    ]);
  }
  return partes.join(' · ');
}

/// La línea de un cambio programado: «Desde el lunes: 4 días por semana»,
/// «Desde mañana: 40 min», «Desde el 23 de noviembre: …».
String textoObjetivoProgramado(
  AppLocalizations l,
  ObjetivoProgramado p, {
  required Habito actual,
  required DateTime hoy,
  required String locale,
}) {
  final objetivo = describirObjetivo(l, p, actual: actual, locale: locale);
  return switch (cuandoAplica(p.desde, hoy)) {
    CuandoAplica.manana => l.progDesdeManana(objetivo),
    CuandoAplica.lunes => l.progDesdeLunes(objetivo),
    CuandoAplica.hoy || CuandoAplica.otraFecha => l.progDesdeFecha(
      DateFormat.MMMMd(locale).format(p.desde),
      objetivo,
    ),
  };
}
