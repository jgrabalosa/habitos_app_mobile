import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/screens/dashboard_logica.dart';

void main() {
  test('sin nada hecho ni empezado', () {
    expect(fraseHoy(hechos: 0, total: 4, avance: 0), FraseHoy.nada);
  });

  test('algo a medias, ninguno entero', () {
    expect(fraseHoy(hechos: 0, total: 4, avance: 0.1875), FraseHoy.empezado);
  });

  test('uno o más hechos, y faltan varios', () {
    expect(fraseHoy(hechos: 1, total: 4, avance: 0.4375), FraseHoy.llevas);
    expect(fraseHoy(hechos: 2, total: 5, avance: 0.4), FraseHoy.llevas);
  });

  test('falta uno', () {
    expect(fraseHoy(hechos: 3, total: 4, avance: 0.8), FraseHoy.quedaUno);
    expect(fraseHoy(hechos: 1, total: 2, avance: 0.5), FraseHoy.quedaUno);
  });

  test('todo hecho', () {
    expect(fraseHoy(hechos: 4, total: 4, avance: 1), FraseHoy.todo);
    expect(fraseHoy(hechos: 1, total: 1, avance: 1), FraseHoy.todo);
  });
}
