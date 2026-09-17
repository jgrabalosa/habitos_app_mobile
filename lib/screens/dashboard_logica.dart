import '../models/habito.dart';

/// Decisiones de la pantalla de Hoy que no dependen de widgets ni de red,
/// sacadas de `_DashboardScreenState` para poder probarlas. La pantalla las
/// llama tal cual: aquí no hay estado.

/// Qué frase de progreso toca. La pantalla la traduce.
enum FraseProgreso { primero, perfecto, casi, buenRitmo }

FraseProgreso fraseProgreso(int hechos, int total) {
  if (hechos == 0) return FraseProgreso.primero;
  if (hechos == total) return FraseProgreso.perfecto;
  if (hechos / total >= 0.5) return FraseProgreso.casi;
  return FraseProgreso.buenRitmo;
}

/// Si [habito] cuenta como hecho hoy, según su [progreso] del dashboard
/// (`completadoHoy`, `completadosPeriodo`, `meta`). Sin progreso, no.
/// Semanal: si ya se completó hoy, está hecho por hoy (Hoy es el resumen
/// del día). Si no, cuenta llegar a la meta del periodo.
bool estaHecho(Habito habito, Map<String, dynamic>? progreso) {
  if (progreso == null) return false;
  if (habito.frecuencia == 'SEMANAL' && progreso['completadoHoy'] == true) {
    return true;
  }
  return (progreso['completadosPeriodo'] ?? 0) >= (progreso['meta'] ?? 1);
}

/// Índice de [hoyIso] dentro de [fechas], o -1 si hoy no está en esta
/// semana o aún no se conoce. -1 hay que distinguirlo de "hoy es el lunes":
/// con un 0, el lunes de otra semana se comportaba como hoy.
int indiceDeHoy(List<String> fechas, String? hoyIso) =>
    hoyIso == null ? -1 : fechas.indexOf(hoyIso);

/// Qué día dejar seleccionado al llegar una semana nueva. Se decide por
/// fecha y no por índice: completar o deshacer un día pasado recarga la
/// semana, y reposicionar en hoy hacía saltar la tira bajo el dedo.
/// Si el día que se miraba sigue en la semana nueva, se respeta. Si no
/// —arranque, o cambio de semana con las flechas—, hoy; y si hoy tampoco
/// está en esta semana, el lunes. En el arranque [fechasAnteriores] está
/// vacía, de ahí la guarda de rango.
int diaASeleccionar({
  required List<String> fechasAnteriores,
  required int seleccionAnterior,
  required List<String> fechasNuevas,
  required int indiceHoy,
}) {
  final String? fechaQueSeMiraba =
      (seleccionAnterior >= 0 && seleccionAnterior < fechasAnteriores.length)
          ? fechasAnteriores[seleccionAnterior]
          : null;
  final int conservado = fechaQueSeMiraba == null
      ? -1
      : fechasNuevas.indexOf(fechaQueSeMiraba);
  if (conservado >= 0) return conservado;
  return indiceHoy >= 0 ? indiceHoy : 0;
}

/// La respuesta de `/semana` ya leída.
class SemanaLeida {
  final List<Map<String, dynamic>> dias;
  final List<Map<String, dynamic>> flexibles;
  final String? hoyIso;

  const SemanaLeida({
    required this.dias,
    required this.flexibles,
    required this.hoyIso,
  });

  List<String> get fechas => dias.map((d) => d['fecha'] as String).toList();
}

/// Lee la respuesta de `/semana`. Hoy lo declara el servidor; si no
/// viniera, se conserva [hoyAnterior] antes que caer al reloj del
/// dispositivo: una fecha equivocada aquí marca el día que no es.
SemanaLeida leerSemana(Map<String, dynamic> data, {String? hoyAnterior}) {
  final List<Map<String, dynamic>> dias =
      (data['dias'] as List<dynamic>).map<Map<String, dynamic>>((dia) {
    final List<Map<String, dynamic>> habitosDia =
        (dia['habitos'] as List<dynamic>).map<Map<String, dynamic>>((item) => {
              'habito': Habito.fromJson(item['habito']),
              'completado': item['completado'] == true,
            }).toList();
    return {
      'fecha': dia['fecha'] as String,
      'habitos': habitosDia,
    };
  }).toList();

  final List<Map<String, dynamic>> flexibles =
      (data['flexibles'] as List<dynamic>).map<Map<String, dynamic>>((item) => {
            'habito': Habito.fromJson(item['habito']),
            'completadosSemana': item['completadosSemana'] ?? 0,
            'meta': item['meta'] ?? 1,
          }).toList();

  return SemanaLeida(
    dias: dias,
    flexibles: flexibles,
    hoyIso: (data['hoy'] as String?) ?? hoyAnterior,
  );
}
