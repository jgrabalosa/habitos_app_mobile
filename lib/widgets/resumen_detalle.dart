import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import 'identidad_ui.dart';

/// Las dos cifras de lo que lleva un hábito: las veces marcadas desde que se
/// creó y los días del mes en que se marcó.
class ResumenDetalle extends StatelessWidget {
  final int totalCompletados;
  final int diasMes;
  final bool mesActual;

  const ResumenDetalle({
    super.key,
    required this.totalCompletados,
    required this.diasMes,
    required this.mesActual,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    return Row(
      children: [
        _statCard(
          context,
          LucideIcons.chartColumn,
          totalCompletados.toString(),
          l.detLoQueLlevas,
          t.successText,
          ayuda: AyudaCampo(
            texto: l.detAyudaLoQueLlevas,
            etiquetaSemantica: l.detAyudaLoQueLlevasEtiqueta,
            superindice: true,
          ),
        ),
        const SizedBox(width: 8),
        _statCard(
          context,
          LucideIcons.calendarDays,
          diasMes.toString(),
          mesActual ? l.detDiasEsteMes : l.detDiasDelMes,
          t.successText,
          ayuda: AyudaCampo(
            texto: l.detAyudaDiasMes,
            etiquetaSemantica: l.detAyudaDiasMesEtiqueta,
            superindice: true,
          ),
        ),
      ],
    );
  }

  /// El `color` es el de la cifra, y llega ya resuelto para texto: quien
  /// llama pasa `successText`, no `success`.
  Widget _statCard(
    BuildContext context,
    IconData icono,
    String valor,
    String label,
    Color color, {
    Widget? ayuda,
  }) {
    final t = tokens(context);
    return Expanded(
      child: TarjetaIdentidad(
        margen: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                valor,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: color),
              ),
              // La etiqueta puede partirse en dos líneas: la tarjeta es un
              // cuarto de pantalla y, con ayuda, comparte fila con el
              // interrogante.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: t.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ?ayuda,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
