import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String texto;

  setUpAll(() {
    texto = File('CLAUDE.md').readAsStringSync();
  });

  test('el CLAUDE.md tiene menos de 200 líneas', () {
    final lineas = texto.split('\n');
    // Un salto de línea final no cuenta como línea (como `wc -l`).
    final cuenta = texto.endsWith('\n') ? lineas.length - 1 : lineas.length;
    expect(cuenta, lessThan(200));
  });

  test('cada docs/….md que nombra existe', () {
    final rutas = RegExp(
      r'docs/[^\s`)»]+\.md',
    ).allMatches(texto).map((m) => m.group(0)!).toSet();
    expect(rutas, isNotEmpty);
    for (final ruta in rutas) {
      expect(File(ruta).existsSync(), isTrue, reason: '$ruta no existe');
    }
  });
}
