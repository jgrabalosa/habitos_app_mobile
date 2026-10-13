import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/models/hoy.dart';

Map<String, dynamic> habito(
  int id,
  String nombre,
  String frecuencia, {
  int meta = 1,
  String? dias,
}) => {
  'habitoId': id,
  'nombre': nombre,
  'frecuencia': frecuencia,
  'meta': meta,
  'activo': true,
  'diasSemana': dias,
};

Map<String, dynamic> fila(
  Map<String, dynamic> h,
  int completados,
  int meta, {
  bool hecho = false,
  bool enFecha = false,
  int ritmo = 3,
  List<String> fechas = const [],
}) => {
  'habito': h,
  'completados': completados,
  'meta': meta,
  'hecho': hecho,
  'completadoEnFecha': enFecha,
  'ritmoNivel': ritmo,
  'fechasCompletadas': fechas,
};

/// La lámina aprobada de Hoy: sábado 10 de octubre de 2026.
Map<String, dynamic> lamina({String fecha = '2026-10-10'}) => {
  'fecha': fecha,
  'hoy': '2026-10-10',
  'dias': [
    {'fecha': '2026-10-05', 'avance': 1.0},
    {'fecha': '2026-10-06', 'avance': 1.0},
    {'fecha': '2026-10-07', 'avance': 0.5},
    {'fecha': '2026-10-08', 'avance': 0.75},
    {'fecha': '2026-10-09', 'avance': 1.0},
    {'fecha': '2026-10-10', 'avance': 0.4375},
    {'fecha': '2026-10-11', 'avance': null},
  ],
  'avance': 0.4375,
  'ritmoNivel': 3,
  'ritmoTendencia': 'SUBE',
  'delDia': {
    'hechos': 1,
    'total': 4,
    'habitos': [
      fila(
        habito(1, 'Beber agua', 'DIARIO', meta: 4),
        3,
        4,
        enFecha: true,
        ritmo: 4,
        fechas: ['2026-10-05', '2026-10-10'],
      ),
      fila(habito(2, 'Leer 20 minutos', 'DIARIO'), 0, 1),
      fila(
        habito(3, 'Yoga', 'SEMANAL', meta: 3, dias: '2,4,6'),
        1,
        3,
        ritmo: 2,
      ),
      fila(
        habito(4, 'Meditar', 'DIARIO'),
        1,
        1,
        hecho: true,
        enFecha: true,
        ritmo: 5,
      ),
    ],
  },
  'deLaSemana': {
    'hechos': 1,
    'total': 2,
    'habitos': [
      fila(habito(5, 'Gimnasio', 'SEMANAL', meta: 5), 2, 5),
      fila(habito(6, 'Llamar a casa', 'SEMANAL'), 1, 1, hecho: true, ritmo: 4),
    ],
  },
  'logrosOtorgados': <String>[],
};

void main() {
  test('lee la lámina de Hoy', () {
    final h = leerHoy(lamina());
    expect(h.fecha, '2026-10-10');
    expect(h.viendoHoy, isTrue);
    expect(h.dias.length, 7);
    expect(h.indiceHoy, 5);
    expect(h.indiceFecha, 5);
    expect(h.avance, 0.4375);
    expect(h.ritmoNivel, 3);
    expect(h.ritmoTendencia, TendenciaRitmo.sube);
    expect(h.delDia.hechos, 1);
    expect(h.delDia.total, 4);
    expect(h.delDia.habitos.map((f) => f.habito.nombre).toList(), [
      'Beber agua',
      'Leer 20 minutos',
      'Yoga',
      'Meditar',
    ]);
    expect(h.deLaSemana.hechos, 1);
    expect(h.deLaSemana.total, 2);
    expect(h.dias.last.avance, isNull);
    expect(h.logrosOtorgados, isEmpty);
  });

  test('una fila trae su avance, su ritmo y sus fechas', () {
    final agua = leerHoy(lamina()).delDia.habitos.first;
    expect(agua.completados, 3);
    expect(agua.meta, 4);
    expect(agua.hecho, isFalse);
    expect(agua.completadoEnFecha, isTrue);
    expect(agua.ritmoNivel, 4);
    expect(agua.fechasCompletadas, {'2026-10-05', '2026-10-10'});
    expect(agua.fraccion, 0.75);
  });

  test('la fracción de una fila se queda entre 0 y 1', () {
    final mas = FilaHoy.fromJson(
      fila(habito(7, 'Correr', 'SEMANAL', meta: 5), 6, 5),
    );
    expect(mas.fraccion, 1.0);
    final sinMeta = FilaHoy.fromJson(
      fila(habito(8, 'Raro', 'DIARIO', meta: 0), 0, 0),
    );
    expect(sinMeta.fraccion, 0.0);
  });

  test('la tendencia se traduce y lo desconocido es null', () {
    expect(tendenciaDe('SUBE'), TendenciaRitmo.sube);
    expect(tendenciaDe('BAJA'), TendenciaRitmo.baja);
    expect(tendenciaDe('IGUAL'), TendenciaRitmo.igual);
    expect(tendenciaDe('VUELA'), isNull);
    expect(tendenciaDe(null), isNull);
  });

  test('mirando otro día de la semana', () {
    final h = leerHoy(lamina(fecha: '2026-10-07'));
    expect(h.viendoHoy, isFalse);
    expect(h.indiceFecha, 2);
    expect(h.indiceHoy, 5);
  });

  test('sin hábitos activos', () {
    final h = leerHoy({
      'fecha': '2026-10-10',
      'hoy': '2026-10-10',
      'dias': [
        for (var d = 5; d <= 11; d++)
          {'fecha': '2026-10-${d.toString().padLeft(2, '0')}', 'avance': null},
      ],
      'avance': null,
      'ritmoNivel': null,
      'ritmoTendencia': null,
      'delDia': {'hechos': 0, 'total': 0, 'habitos': []},
      'deLaSemana': {'hechos': 0, 'total': 0, 'habitos': []},
      'logrosOtorgados': [],
    });
    expect(h.avance, isNull);
    expect(h.ritmoNivel, isNull);
    expect(h.ritmoTendencia, isNull);
    expect(h.delDia.habitos, isEmpty);
    expect(h.deLaSemana.total, 0);
  });
}
