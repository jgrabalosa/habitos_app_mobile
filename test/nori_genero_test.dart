import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nori es chico (M-2): «he» y «him» en inglés, «o Nori» y «do Nori» en
/// portugués, como en el core desde la 0.56.0. En español no hay nada que
/// marque el género. Nori es el único personaje de la app, así que en inglés
/// ningún texto dice «she» ni «her».
Map<String, String> _textos(String idioma) {
  final arb =
      jsonDecode(File('lib/l10n/app_$idioma.arb').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final e in arb.entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };
}

List<String> _casan(Map<String, String> textos, RegExp patron) => [
  for (final e in textos.entries)
    if (patron.hasMatch(e.value)) '${e.key}: ${e.value}',
];

void main() {
  test('en inglés, ningún texto trata a Nori de «she» o «her»', () {
    final femenino = RegExp(
      r'\b(she|her|hers|herself)\b',
      caseSensitive: false,
    );
    expect(_casan(_textos('en'), femenino), isEmpty);
  });

  test('en portugués, ningún texto dice «a Nori» ni «da Nori»', () {
    final femenino = RegExp(
      r'(^|[^\p{L}])(a|da|na|pela|à)\s+Nori\b',
      caseSensitive: false,
      unicode: true,
    );
    expect(_casan(_textos('pt'), femenino), isEmpty);
  });
}
