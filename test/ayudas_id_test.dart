import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Recorre `lib/` y saca el cuerpo (entre paréntesis) de cada `AyudaCampo(`.
List<({String fichero, String cuerpo})> _ayudas() {
  final salida = <({String fichero, String cuerpo})>[];
  final ficheros = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final f in ficheros) {
    final src = f.readAsStringSync();
    for (final m in RegExp(r'\bAyudaCampo\(').allMatches(src)) {
      var profundidad = 1;
      var i = m.end;
      while (i < src.length && profundidad > 0) {
        final c = src[i++];
        if (c == '(') profundidad++;
        if (c == ')') profundidad--;
      }
      salida.add((fichero: f.path, cuerpo: src.substring(m.end, i - 1)));
    }
  }
  return salida;
}

String? _id(String cuerpo) =>
    RegExp(r"\bid:\s*'([a-z0-9_]+)'").firstMatch(cuerpo)?.group(1);

void main() {
  final ayudas = _ayudas();

  test('se encuentran los «?» de lib/', () {
    // Si el recorrido dejara de verlos, los demás tests pasarían en vacío.
    expect(ayudas.length, greaterThanOrEqualTo(12));
  });

  test('todo AyudaCampo de lib/ lleva su id, en minúsculas y con guiones', () {
    final sinId = [
      for (final a in ayudas)
        if (_id(a.cuerpo) == null) a.fichero,
    ];
    expect(sinId, isEmpty, reason: 'AyudaCampo sin id (ayuda_abierta)');
  });

  test(
    '«Saber más» enlaza con el apartado que toca, y los demás no lo llevan',
    () {
      const apartados = {
        'frecuencia': 'diarios',
        'meta': 'diarios',
        'esta_semana': 'diarios',
        'ritmo_habito': 'ritmo',
        'animo': 'nori',
        'xp': 'nori',
      };
      for (final a in ayudas) {
        final id = _id(a.cuerpo);
        final enlace = RegExp(
          r'ApartadoComoFunciona\.(\w+)',
        ).firstMatch(a.cuerpo)?.group(1);
        expect(
          enlace,
          apartados[id],
          reason: 'Saber más de «$id» (${a.fichero})',
        );
      }
    },
  );
}
