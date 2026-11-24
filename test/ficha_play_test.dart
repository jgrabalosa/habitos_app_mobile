import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Vigila la ficha de Google Play (`store/ficha-play/`): los límites de
/// caracteres de Play y que los tres idiomas tengan los mismos campos.
const _limites = <String, int>{
  'Nombre': 30,
  'Descripción breve': 80,
  'Descripción completa': 4000,
};

const _ficheros = ['es.md', 'en-US.md', 'pt-PT.md'];

/// Campos `## Título` → texto (sin espacios sobrantes). Play cuenta
/// caracteres, no unidades UTF-16: se mide con `runes`.
Map<String, String> _campos(String fichero) {
  final lineas = File('store/ficha-play/$fichero').readAsLinesSync();
  final campos = <String, List<String>>{};
  String? actual;
  for (final linea in lineas) {
    if (linea.startsWith('## ')) {
      actual = linea.substring(3).trim();
      campos[actual] = [];
    } else if (actual != null) {
      campos[actual]!.add(linea);
    }
  }
  return {for (final e in campos.entries) e.key: e.value.join('\n').trim()};
}

void main() {
  for (final fichero in _ficheros) {
    group(fichero, () {
      final campos = _campos(fichero);

      test('tiene los mismos campos que los demás idiomas', () {
        expect(campos.keys.toList(), _limites.keys.toList());
      });

      for (final e in _limites.entries) {
        test('«${e.key}» no está vacío y cabe en ${e.value} caracteres', () {
          final texto = campos[e.key] ?? '';
          expect(texto, isNotEmpty);
          expect(texto.runes.length, lessThanOrEqualTo(e.value));
        });
      }

      test('el nombre lleva «Norday Habits» sin traducir', () {
        expect(campos['Nombre'], startsWith('Norday Habits'));
      });
    });
  }
}
