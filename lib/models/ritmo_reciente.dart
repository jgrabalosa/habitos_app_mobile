import 'habito.dart';

/// Si un hábito acaba de empezar: lleva menos de siete días desde su alta, así
/// que no hay semana anterior con la que compararlo. El día siete ya se
/// compara con normalidad.
///
/// Todo se mide en fechas sin hora, para que el cambio de hora no cambie la
/// cuenta de días.
bool esRecienEmpezado(DateTime? fechaInicio, DateTime hoy) {
  if (fechaInicio == null) return false;
  final alta = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
  final hace7 = DateTime(hoy.year, hoy.month, hoy.day - 7);
  return alta.isAfter(hace7);
}

/// Si la lista entera está recién empezada. Manda el hábito más antiguo: si él
/// ya no es reciente, ninguno lo es. Si alguno no trae fecha de alta, no se
/// puede afirmar y devuelve false.
bool recienEmpezadoEnLista(List<Habito> habitos, DateTime hoy) {
  if (habitos.isEmpty) return false;
  DateTime? masAntiguo;
  for (final habito in habitos) {
    final alta = habito.fechaInicio;
    if (alta == null) return false;
    if (masAntiguo == null || alta.isBefore(masAntiguo)) masAntiguo = alta;
  }
  return esRecienEmpezado(masAntiguo, hoy);
}
