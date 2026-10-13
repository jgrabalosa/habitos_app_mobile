import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/services/pausa.dart';

void main() {
  test('cuenta las pausas del inventario', () {
    expect(
      pausasEn([
        {
          'cantidad': 2,
          'producto': {'codigo': 'COMIDA_BASICA'},
        },
        {
          'cantidad': 3,
          'producto': {'codigo': 'PAUSA_HABITO'},
        },
      ]),
      3,
    );
  });

  test('sin pausas en el inventario, cero', () {
    expect(pausasEn([]), 0);
    expect(
      pausasEn([
        {
          'cantidad': 2,
          'producto': {'codigo': 'COMIDA_BASICA'},
        },
      ]),
      0,
    );
  });

  test('un inventario raro no rompe y cuenta cero', () {
    expect(
      pausasEn([
        'no es un mapa',
        {'producto': null},
        {
          'cantidad': null,
          'producto': {'codigo': 'PAUSA_HABITO'},
        },
      ]),
      0,
    );
  });
}
