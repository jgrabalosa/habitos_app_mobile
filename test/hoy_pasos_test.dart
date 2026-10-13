import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/models/hoy.dart';

FilaHoy fila(
  String frecuencia,
  int completados,
  int meta, {
  bool hecho = false,
  bool enFecha = false,
  String? dias,
  Set<String> fechas = const {},
}) => FilaHoy.fromJson({
  'habito': {
    'habitoId': 1,
    'nombre': 'Prueba',
    'frecuencia': frecuencia,
    'meta': meta,
    'activo': true,
    'diasSemana': dias,
  },
  'completados': completados,
  'meta': meta,
  'hecho': hecho,
  'completadoEnFecha': enFecha,
  'ritmoNivel': 3,
  'fechasCompletadas': fechas.toList(),
});

const hoy = '2026-10-10';

void main() {
  test('un paso en un diario de cuatro: de 3/4 a 4/4, hecho', () {
    final f = fila(
      'DIARIO',
      3,
      4,
      enFecha: true,
      fechas: {hoy},
    ).conPasos(1, delDia: true, fecha: hoy);
    expect(f.completados, 4);
    expect(f.hecho, isTrue);
    expect(f.completadoEnFecha, isTrue);
    expect(f.fechasCompletadas, {hoy});
  });

  test('deshacer un paso en un diario de cuatro: sigue hecho ese día', () {
    final f = fila(
      'DIARIO',
      4,
      4,
      hecho: true,
      enFecha: true,
      fechas: {hoy},
    ).conPasos(-1, delDia: true, fecha: hoy);
    expect(f.completados, 3);
    expect(f.hecho, isFalse);
    expect(f.completadoEnFecha, isTrue);
    expect(f.fechasCompletadas, {hoy});
  });

  test('un semanal con día fijo en su día cuenta al hacerse ese día', () {
    final f = fila(
      'SEMANAL',
      1,
      3,
      dias: '2,4,6',
    ).conPasos(1, delDia: true, fecha: hoy);
    expect(f.completados, 2);
    expect(f.hecho, isTrue);
  });

  test(
    'un semanal en la sección de la semana cuenta al llegar al objetivo',
    () {
      final dos = fila('SEMANAL', 2, 5).conPasos(1, delDia: false, fecha: hoy);
      expect(dos.hecho, isFalse);
      expect(dos.completadoEnFecha, isTrue);
      final cinco = fila(
        'SEMANAL',
        4,
        5,
      ).conPasos(1, delDia: false, fecha: hoy);
      expect(cinco.hecho, isTrue);
    },
  );

  test('deshacer un semanal lo deja sin hacer ese día', () {
    final f = fila(
      'SEMANAL',
      2,
      5,
      enFecha: true,
      fechas: {'2026-10-05', hoy},
    ).conPasos(-1, delDia: false, fecha: hoy);
    expect(f.completados, 1);
    expect(f.completadoEnFecha, isFalse);
    expect(f.fechasCompletadas, {'2026-10-05'});
  });

  test('el avance del día de la lámina es 0,4375', () {
    // Agua 3/4, leer 0/1, yoga en su día sin hacer, meditar hecho.
    final filas = [
      fila('DIARIO', 3, 4, enFecha: true),
      fila('DIARIO', 0, 1),
      fila('SEMANAL', 1, 3, dias: '2,4,6'),
      fila('DIARIO', 1, 1, hecho: true, enFecha: true),
    ];
    expect(avanceDelDia(filas), 0.4375);
    expect(avanceDelDia([]), isNull);
  });
}
