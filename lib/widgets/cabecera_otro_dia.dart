import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';

/// Encima de la tira, solo cuando el día que se mira no es hoy: el mes de ese
/// día y el botón para volver a hoy. Viendo hoy no ocupa nada.
class CabeceraOtroDia extends StatelessWidget {
  final DateTime fecha;
  final bool viendoHoy;
  final VoidCallback onHoy;

  const CabeceraOtroDia({
    super.key,
    required this.fecha,
    required this.viendoHoy,
    required this.onHoy,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final sinAnimacion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // Con el mes en mayúscula inicial, como el resto de cabeceras.
    final mes = DateFormat.yMMMM(locale).format(fecha);
    final mesMayuscula = mes.isEmpty
        ? mes
        : mes[0].toUpperCase() + mes.substring(1);

    return AnimatedSize(
      duration: sinAnimacion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: viendoHoy
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      mesMayuscula,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: t.textMuted),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    // El mismo botón de la cabecera de antes: 48 de zona táctil
                    // (Android) y el texto en tinta, 4.61 sobre el rosa en Dulce.
                    child: FilledButton(
                      onPressed: onHoy,
                      style: FilledButton.styleFrom(
                        backgroundColor: t.primary,
                        foregroundColor: t.tinta,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        textStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                      child: Text(l.navHoy),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
