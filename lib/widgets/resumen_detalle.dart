import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../l10n/textos_minutos.dart';
import 'identidad_ui.dart';

/// Las dos cifras de lo que lleva un hábito: las veces marcadas desde que se
/// creó y los días del mes en que se marcó. En uno de minutos, la primera es
/// el tiempo total, en horas y minutos.
class ResumenDetalle extends StatelessWidget {
  final int totalCompletados;
  final int diasMes;
  final bool mesActual;

  /// Los minutos de todos los registros, en un hábito de minutos. Con él, la
  /// primera tarjeta dice el tiempo total en vez de las veces.
  final int? totalMinutos;

  const ResumenDetalle({
    super.key,
    required this.totalCompletados,
    required this.diasMes,
    required this.mesActual,
    this.totalMinutos,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final minutos = totalMinutos;
    return Row(
      children: [
        if (minutos != null)
          _statCard(
            context,
            LucideIcons.timer,
            duracionLegible(l, minutos),
            l.detTiempoTotal,
            t.successText,
            ayuda: AyudaCampo(
              texto: l.detAyudaTiempoTotal,
              etiquetaSemantica: l.detAyudaTiempoTotalEtiqueta,
              superindice: true,
              id: 'tiempo_total',
            ),
          )
        else
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
              id: 'lo_que_llevas',
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
            id: 'dias_mes',
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
