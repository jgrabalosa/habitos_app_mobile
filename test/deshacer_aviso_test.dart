import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';

/// El aviso de «solo el último» debe existir en los tres idiomas y no ser el
/// mismo texto que el genérico de fallo, o el usuario no sabría por qué no se
/// pudo deshacer.
void main() {
  test(
    'el aviso de solo el último existe en es, en y pt, y no es el genérico',
    () async {
      for (final codigo in ['es', 'en', 'pt']) {
        final l = await AppLocalizations.delegate.load(Locale(codigo));
        expect(l.dashDeshacerSoloUltimo.trim(), isNotEmpty, reason: codigo);
        expect(
          l.dashDeshacerSoloUltimo,
          isNot(l.dashDeshacerError),
          reason: codigo,
        );
      }
    },
  );
}
