import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/l10n/textos_objetivo.dart';

/// Las cifras que se enseñan solas dicen de qué son.
void main() {
  late AppLocalizations es;
  late AppLocalizations en;
  late AppLocalizations pt;

  setUpAll(() async {
    es = await AppLocalizations.delegate.load(const Locale('es'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
    pt = await AppLocalizations.delegate.load(const Locale('pt'));
  });

  group('el extra de la semana dice que son puntos', () {
    test('en español', () {
      expect(es.dashExtraSemana(20), '+20 puntos por completar la semana');
      expect(es.dashExtraSemana(1), '+1 punto por completar la semana');
    });

    test('en inglés', () {
      expect(en.dashExtraSemana(20), '+20 points for completing the week');
      expect(en.dashExtraSemana(1), '+1 point for completing the week');
    });

    test('en portugués', () {
      expect(pt.dashExtraSemana(20), '+20 pontos por completares a semana');
      expect(pt.dashExtraSemana(1), '+1 ponto por completares a semana');
    });
  });
  group('el selector de objetivo dice la unidad', () {
    test('en español', () {
      expect(textoMetaFormulario(es, diario: true, meta: 3), '3 veces al día');
      expect(textoMetaFormulario(es, diario: true, meta: 1), '1 vez al día');
      expect(
        textoMetaFormulario(es, diario: false, meta: 3),
        '3 días por semana',
      );
      expect(
        textoMetaFormulario(es, diario: false, meta: 1),
        '1 día por semana',
      );
    });

    test('en inglés', () {
      expect(textoMetaFormulario(en, diario: true, meta: 3), '3 times a day');
      expect(textoMetaFormulario(en, diario: true, meta: 1), 'once a day');
      expect(textoMetaFormulario(en, diario: false, meta: 3), '3 days a week');
      expect(textoMetaFormulario(en, diario: false, meta: 1), '1 day a week');
    });

    test('en portugués', () {
      expect(textoMetaFormulario(pt, diario: true, meta: 3), '3 vezes por dia');
      expect(textoMetaFormulario(pt, diario: true, meta: 1), '1 vez por dia');
      expect(
        textoMetaFormulario(pt, diario: false, meta: 3),
        '3 dias por semana',
      );
      expect(
        textoMetaFormulario(pt, diario: false, meta: 1),
        '1 dia por semana',
      );
    });
  });

  group('la frecuencia del detalle dice la unidad', () {
    test('en español', () {
      expect(textoFrecuenciaVeces(es, diario: true, meta: 1), 'Diario');
      expect(
        textoFrecuenciaVeces(es, diario: true, meta: 3),
        'Diario · 3 veces al día',
      );
      expect(
        textoFrecuenciaVeces(es, diario: false, meta: 3),
        'Semanal · 3 días por semana',
      );
      expect(
        textoFrecuenciaVeces(es, diario: false, meta: 1),
        'Semanal · 1 día por semana',
      );
    });

    test('en inglés', () {
      expect(
        textoFrecuenciaVeces(en, diario: true, meta: 3),
        'Daily · 3 times a day',
      );
      expect(
        textoFrecuenciaVeces(en, diario: false, meta: 3),
        'Weekly · 3 days a week',
      );
      expect(
        textoFrecuenciaVeces(en, diario: false, meta: 1),
        'Weekly · 1 day a week',
      );
    });

    test('en portugués', () {
      expect(
        textoFrecuenciaVeces(pt, diario: true, meta: 3),
        'Diário · 3 vezes por dia',
      );
      expect(
        textoFrecuenciaVeces(pt, diario: false, meta: 3),
        'Semanal · 3 dias por semana',
      );
      expect(
        textoFrecuenciaVeces(pt, diario: false, meta: 1),
        'Semanal · 1 dia por semana',
      );
    });
  });
}
