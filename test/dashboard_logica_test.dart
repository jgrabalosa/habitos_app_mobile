import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/screens/dashboard_logica.dart';

Habito habito(String frecuencia, {int meta = 1}) => Habito(
      habitoId: 1,
      nombre: 'Leer',
      frecuencia: frecuencia,
      meta: meta,
      activo: true,
    );

Map<String, dynamic> habitoJson(int id) => {
      'habitoId': id,
      'nombre': 'Hábito $id',
      'frecuencia': 'DIARIO',
      'meta': 1,
      'activo': true,
    };

const semana = [
  '2026-09-14',
  '2026-09-15',
  '2026-09-16',
  '2026-09-17',
  '2026-09-18',
  '2026-09-19',
  '2026-09-20',
];

const semanaAnterior = [
  '2026-09-07',
  '2026-09-08',
  '2026-09-09',
  '2026-09-10',
  '2026-09-11',
  '2026-09-12',
  '2026-09-13',
];

void main() {
  group('fraseProgreso', () {
    test('sin nada hecho es la del primero, también con cero hábitos', () {
      expect(fraseProgreso(0, 4), FraseProgreso.primero);
      expect(fraseProgreso(0, 0), FraseProgreso.primero);
    });

    test('todo hecho es perfecto', () {
      expect(fraseProgreso(4, 4), FraseProgreso.perfecto);
    });

    test('la mitad justa ya es casi', () {
      expect(fraseProgreso(2, 4), FraseProgreso.casi);
      expect(fraseProgreso(3, 4), FraseProgreso.casi);
    });

    test('por debajo de la mitad es buen ritmo', () {
      expect(fraseProgreso(1, 3), FraseProgreso.buenRitmo);
    });
  });

  group('estaHecho', () {
    test('sin progreso no está hecho', () {
      expect(estaHecho(habito('DIARIO'), null), isFalse);
    });

    test('un diario por debajo de la meta no está hecho', () {
      expect(
        estaHecho(habito('DIARIO', meta: 2),
            {'completadoHoy': true, 'completadosPeriodo': 1, 'meta': 2}),
        isFalse,
      );
    });

    test('un diario que llega a la meta está hecho', () {
      expect(
        estaHecho(habito('DIARIO', meta: 2),
            {'completadoHoy': true, 'completadosPeriodo': 2, 'meta': 2}),
        isTrue,
      );
    });

    test('un semanal completado hoy está hecho aunque no llegue a la meta', () {
      expect(
        estaHecho(habito('SEMANAL', meta: 3),
            {'completadoHoy': true, 'completadosPeriodo': 1, 'meta': 3}),
        isTrue,
      );
    });

    test('un semanal no completado hoy y bajo la meta no está hecho', () {
      expect(
        estaHecho(habito('SEMANAL', meta: 3),
            {'completadoHoy': false, 'completadosPeriodo': 2, 'meta': 3}),
        isFalse,
      );
    });

    test('sin datos de periodo ni meta, cuenta 0 sobre 1', () {
      expect(estaHecho(habito('DIARIO'), {'completadoHoy': false}), isFalse);
      expect(
        estaHecho(habito('DIARIO'), {'completadosPeriodo': 1}),
        isTrue,
      );
    });
  });

  group('indiceDeHoy', () {
    test('hoy en la semana da su posición', () {
      expect(indiceDeHoy(semana, '2026-09-17'), 3);
    });

    test('hoy fuera de la semana o desconocido da -1, no el lunes', () {
      expect(indiceDeHoy(semanaAnterior, '2026-09-17'), -1);
      expect(indiceDeHoy(semana, null), -1);
    });
  });

  group('diaASeleccionar', () {
    test('en el arranque, sin semana anterior, va a hoy', () {
      expect(
        diaASeleccionar(
          fechasAnteriores: const [],
          seleccionAnterior: 0,
          fechasNuevas: semana,
          indiceHoy: 3,
        ),
        3,
      );
    });

    test('al recargar la misma semana conserva el día que se miraba', () {
      expect(
        diaASeleccionar(
          fechasAnteriores: semana,
          seleccionAnterior: 1,
          fechasNuevas: semana,
          indiceHoy: 3,
        ),
        1,
      );
    });

    test('al volver a la semana de hoy, el día viejo no está y va a hoy', () {
      expect(
        diaASeleccionar(
          fechasAnteriores: semanaAnterior,
          seleccionAnterior: 2,
          fechasNuevas: semana,
          indiceHoy: 3,
        ),
        3,
      );
    });

    test('en otra semana sin hoy, va al lunes', () {
      expect(
        diaASeleccionar(
          fechasAnteriores: semana,
          seleccionAnterior: 3,
          fechasNuevas: semanaAnterior,
          indiceHoy: -1,
        ),
        0,
      );
    });

    test('una selección fuera de rango se ignora y va a hoy', () {
      expect(
        diaASeleccionar(
          fechasAnteriores: semana,
          seleccionAnterior: 9,
          fechasNuevas: semana,
          indiceHoy: 3,
        ),
        3,
      );
    });
  });

  group('leerSemana', () {
    test('lee los días, sus hábitos y el hoy del servidor', () {
      final leida = leerSemana({
        'hoy': '2026-09-17',
        'dias': [
          {
            'fecha': '2026-09-17',
            'habitos': [
              {'habito': habitoJson(1), 'completado': true},
              {'habito': habitoJson(2), 'completado': false},
            ],
          },
        ],
        'flexibles': [],
      });

      expect(leida.hoyIso, '2026-09-17');
      expect(leida.fechas, ['2026-09-17']);
      final habitos = leida.dias.first['habitos'] as List<Map<String, dynamic>>;
      expect((habitos[0]['habito'] as Habito).habitoId, 1);
      expect(habitos[0]['completado'], isTrue);
      expect(habitos[1]['completado'], isFalse);
    });

    test('completado sólo es true si llega exactamente true', () {
      final leida = leerSemana({
        'dias': [
          {
            'fecha': '2026-09-17',
            'habitos': [
              {'habito': habitoJson(1), 'completado': null},
              {'habito': habitoJson(2)},
            ],
          },
        ],
        'flexibles': [],
      });

      final habitos = leida.dias.first['habitos'] as List<Map<String, dynamic>>;
      expect(habitos[0]['completado'], isFalse);
      expect(habitos[1]['completado'], isFalse);
    });

    test('los flexibles sin datos cuentan 0 completados y meta 1', () {
      final leida = leerSemana({
        'dias': [],
        'flexibles': [
          {'habito': habitoJson(5)},
          {'habito': habitoJson(6), 'completadosSemana': 2, 'meta': 3},
        ],
      });

      expect(leida.flexibles[0]['completadosSemana'], 0);
      expect(leida.flexibles[0]['meta'], 1);
      expect(leida.flexibles[1]['completadosSemana'], 2);
      expect(leida.flexibles[1]['meta'], 3);
    });

    test('sin hoy en la respuesta conserva el anterior', () {
      final leida = leerSemana(
        {'dias': [], 'flexibles': []},
        hoyAnterior: '2026-09-16',
      );
      expect(leida.hoyIso, '2026-09-16');
    });
  });
}
