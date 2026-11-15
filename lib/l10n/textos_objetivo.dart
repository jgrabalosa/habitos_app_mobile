import 'app_localizations.dart';

/// Las cifras del objetivo de un hábito con su unidad, fuera de las
/// pantallas para poder probarlas en los tres idiomas.
///
/// Un semanal de veces cuenta días: el backend admite como mucho un
/// completado por día (`RegistroService`), así que su meta son días por
/// semana, igual que la de un semanal de minutos.

/// La cifra del selector de objetivo del formulario: «3 veces al día» en un
/// diario de veces y «3 días por semana» en un semanal (de veces o de
/// minutos). Un diario de minutos no tiene este selector.
String textoMetaFormulario(
  AppLocalizations l, {
  required bool diario,
  required int meta,
}) => diario ? l.objVecesDia(meta) : l.objDiasSemana(meta);

/// La frecuencia de un hábito de veces en el detalle, sin días fijos:
/// «Diario», «Diario · 3 veces al día», «Semanal · 1 día por semana».
String textoFrecuenciaVeces(
  AppLocalizations l, {
  required bool diario,
  required int meta,
}) {
  if (diario) return meta > 1 ? l.detDiarioMeta(meta) : l.frecDiario;
  return l.detSemanalMeta(meta);
}
