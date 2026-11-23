import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';

/// T-048: los textos de los «?» cuentan lo que pasa de verdad (el ritmo se
/// pone al día al cerrar el periodo, la semana va de lunes a domingo, cuánto
/// crece Nori), y las claves de rachas que ya no se usan no vuelven.
void main() {
  const textos = {
    'es': (
      ritmo:
          'Tu ritmo junta el de todos tus hábitos. Se pone al día al acabar '
          'cada día, y en los semanales al acabar la semana: sube deprisa '
          'cuando cumples y baja despacio si fallas.',
      ritmoHabito:
          'Se pone al día al acabar cada día (cada semana, si es semanal). '
          'Sube deprisa cuando cumples y baja despacio si fallas.',
      flexibles:
          'Tus semanales fuera de su día. Hazlos cuando quieras antes del '
          'domingo: cuenta llegar al objetivo de la semana, y si llegas, '
          '+20 % de puntos. No hace falta para terminar el día.',
      xp:
          'La experiencia de Nori. Sube 5 por cada hábito que cumples y 15 '
          'por cada comida. Nori es cría en el nivel 3 y adulta en el 11.',
      frecuencia:
          'Diario: cada día. Semanal: unas veces por semana, de lunes a '
          'domingo, los días que mejor te vengan.',
    ),
    'en': (
      ritmo:
          'Your pace brings all your habits together. It updates when each '
          'day ends, and for weekly habits when the week ends: it rises fast '
          "when you follow through and dips slowly when you don't.",
      ritmoHabito:
          'It updates when each day ends (each week, if it\'s weekly). It '
          "rises fast when you follow through and dips slowly when you don't.",
      flexibles:
          'Your weekly habits on their off days. Do them whenever you like '
          "before Sunday: reaching the week's goal counts, and if you get "
          "there, +20% points. You don't need them to finish the day.",
      xp:
          "Nori's experience. It goes up 5 for each habit you complete and 15 "
          'for each meal. Nori is a hatchling at level 3 and an adult at '
          'level 11.',
      frecuencia:
          'Daily: every day. Weekly: a few times a week, Monday to Sunday, on '
          'whichever days suit you.',
    ),
    'pt': (
      ritmo:
          'O teu ritmo junta o de todos os teus hábitos. Atualiza-se no fim '
          'de cada dia e, nos semanais, no fim da semana: sobe depressa '
          'quando cumpres e desce devagar se falhares.',
      ritmoHabito:
          'Atualiza-se no fim de cada dia (de cada semana, se for semanal). '
          'Sobe depressa quando cumpres e desce devagar se falhares.',
      flexibles:
          'Os teus semanais fora do dia deles. Faz quando quiseres antes de '
          'domingo: conta chegar ao objetivo da semana e, se chegares, '
          '+20 % de pontos. Não é preciso para terminar o dia.',
      xp:
          'A experiência do Nori. Sobe 5 por cada hábito que cumpres e 15 por '
          'cada refeição. O Nori é cria no nível 3 e adulto no 11.',
      frecuencia:
          'Diário: todos os dias. Semanal: algumas vezes por semana, de '
          'segunda a domingo, nos dias que te derem mais jeito.',
    ),
  };

  test(
    'los textos de las ayudas cuentan lo que pasa, en los tres idiomas',
    () async {
      for (final MapEntry(key: idioma, value: t) in textos.entries) {
        final l = await AppLocalizations.delegate.load(Locale(idioma));
        expect(l.ritmoExplicacion, t.ritmo, reason: idioma);
        expect(l.ritmoExplicacionHabito, t.ritmoHabito, reason: idioma);
        expect(l.dashAyudaFlexibles, t.flexibles, reason: idioma);
        expect(l.mascotaAyudaXp, t.xp, reason: idioma);
        expect(l.habAyudaFrecuencia, t.frecuencia, reason: idioma);
      }
    },
  );

  test('las claves de rachas sin uso ya no están en ningún ARB', () {
    const quitadas = [
      'detAyudaRacha',
      'detAyudaRachaEtiqueta',
      'detRachaActual',
      'detMejorRacha',
    ];
    for (final idioma in textos.keys) {
      final arb =
          jsonDecode(File('lib/l10n/app_$idioma.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final clave in quitadas) {
        expect(arb.containsKey(clave), isFalse, reason: '$clave en $idioma');
      }
      // No se toca: la usa registrarTextosHabits como `eliminarCuenta`.
      expect(arb.containsKey('eliminarCuentaCuerpo'), isTrue, reason: idioma);
    }
  });
}
