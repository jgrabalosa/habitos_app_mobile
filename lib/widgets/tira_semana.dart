import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import 'identidad_ui.dart';

/// La tira de 7 días (lunes a domingo) encima de Hoy, para navegar a otro
/// día de la semana sin recargar red — los 7 días ya están en memoria.
///
/// La celda de cada día reutiliza [celdaHeatmap]: es la misma pieza que ya
/// pinta un día en el mini-heatmap de cada hábito, con el mismo criterio de
/// selección por identidad (`seleccionada`) y de "hoy" (`esHoy`) que ya
/// existía ahí — no hace falta inventar un segundo lenguaje visual para lo
/// mismo, sólo un lugar distinto donde usarlo.
class TiraSemana extends StatelessWidget {
  /// Un elemento por día, en orden lunes→domingo: `{'fecha': 'yyyy-MM-dd',
  /// 'habitos': [{'habito': Habito, 'completado': bool}, ...]}`.
  final List<Map<String, dynamic>> dias;

  final int diaSeleccionado;
  final int indiceHoy;
  final ValueChanged<int> onSeleccionar;

  const TiraSemana({
    super.key,
    required this.dias,
    required this.diaSeleccionado,
    required this.indiceHoy,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final sinAnimacion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Row(
      children: List.generate(dias.length, (i) {
        final fecha = DateTime.parse(dias[i]['fecha'] as String);
        final habitosDelDia = (dias[i]['habitos'] as List<Map<String, dynamic>>);
        // Vacío (nada programado ese día) no es "completado": no hay señal.
        final bool diaCompleto = habitosDelDia.isNotEmpty &&
            habitosDelDia.every((h) => h['completado'] == true);
        final bool esHoy = i == indiceHoy;
        final bool seleccionado = i == diaSeleccionado;
        final String nombreDia = DateFormat.E(locale).format(fecha);

        final Color colorCelda =
            seleccionado ? t.primary.withValues(alpha: 0.18) : t.inactivo;

        return Expanded(
          child: Semantics(
            button: true,
            selected: seleccionado,
            label: l.a11yDiaSemana(nombreDia,
                seleccionado ? l.a11yDiaSeleccionado : l.a11yDiaNoSeleccionado),
            child: GestureDetector(
              onTap: () => onSeleccionar(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Text(
                    nombreDia.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: t.textMuted),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: sinAnimacion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: celdaHeatmap(
                      id,
                      t,
                      color: colorCelda,
                      // La misma pieza que marca "hecho" en el heatmap marca
                      // aquí "es el día activo": incorpora el glow/relieve de
                      // la identidad al día que se está mirando.
                      llena: seleccionado,
                      esHoy: esHoy,
                      seleccionada: seleccionado,
                    ),
                    child: Text(
                      '${fecha.day}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: (seleccionado || esHoy)
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 6,
                    width: 6,
                    child: diaCompleto
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: t.success),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
