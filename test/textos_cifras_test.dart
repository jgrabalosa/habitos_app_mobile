import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';

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
}
