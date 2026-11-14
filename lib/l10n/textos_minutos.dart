import 'package:intl/intl.dart';

import '../models/habito.dart';
import '../models/minutos.dart';
import '../models/objetivo_programado.dart';
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

/// El aviso tras guardar un cambio que no vale hasta otro día, o null si ya
/// vale ([aplicaDesde] es hoy, anterior o no viene).
///
/// Con [minutosNuevos] —el cambio toca los minutos por día— y efecto mañana,
/// se dice la cifra: «Los 40 min se aplican desde mañana…».
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
    CuandoAplica.manana =>
      minutosNuevos != null
          ? l.habAplicaMinutosManana(minutosNuevos)
          : l.habAplicaManana,
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

  String minutos() => l.minCifra(p.minutosObjetivo ?? 0);
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
