import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/services/identidad_al_volver.dart';

void main() {
  test('sin usuario no pide nada', () async {
    var llamadas = 0;
    await recargarIdentidadAlVolver(
      0,
      cargar: (_) async {
        llamadas++;
        return null;
      },
    );
    expect(llamadas, 0);
  });

  test('con usuario pide la identidad una vez, con su id', () async {
    final pedidos = <int>[];
    await recargarIdentidadAlVolver(
      7,
      cargar: (id) async {
        pedidos.add(id);
        return true;
      },
    );
    expect(pedidos, [7]);
  });

  test('si la carga lanza, no se propaga', () async {
    await expectLater(
      recargarIdentidadAlVolver(
        7,
        cargar: (_) async => throw Exception('sin red'),
      ),
      completes,
    );
  });

  test('una llamada mientras otra sigue en curso no pide otra vez', () async {
    final completer = Completer<bool?>();
    var llamadas = 0;
    Future<bool?> cargar(int _) {
      llamadas++;
      return completer.future;
    }

    final primera = recargarIdentidadAlVolver(7, cargar: cargar);
    final segunda = recargarIdentidadAlVolver(7, cargar: cargar);
    await segunda;
    expect(llamadas, 1);

    completer.complete(true);
    await primera;

    // Terminada la primera, una nueva sí vuelve a pedir.
    await recargarIdentidadAlVolver(
      7,
      cargar: (_) {
        llamadas++;
        return Future.value(true);
      },
    );
    expect(llamadas, 2);
  });
}
