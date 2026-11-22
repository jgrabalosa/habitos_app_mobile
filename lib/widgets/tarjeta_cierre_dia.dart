import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:norday_flutter_core/widgets/constelaciones.dart'
    show nombreConstelacion;

import '../l10n/app_localizations.dart';

/// El nombre de la figura del día de la identidad equipada: la constelación
/// en Profundidad, el ramo en Dulce y el letrero en Neotokyo+. Es el mismo
/// que dice la ceremonia del cierre.
String nombreFiguraDelDia(
  NordayCoreLocalizations l,
  FondoIdentidadTipo fondo,
  int total,
) => switch (fondo) {
  FondoIdentidadTipo.cielo => nombreConstelacion(l, total),
  FondoIdentidadTipo.acumulacion => nombreRamo(l, total),
  FondoIdentidadTipo.ciudad => nombreLetrero(l, total),
};

/// La postal del cierre del día, en 4:5: el fondo de la identidad a sangre,
/// sin panel; arriba, el nombre de la figura del día y la fecha; en medio, la
/// figura grande ([FiguraDelDia]); debajo, «N hábitos hechos»; abajo, el
/// wordmark. **Nunca lleva los nombres de los hábitos.**
///
/// No pide nada a la red: todo sale del número de hábitos, la fecha y la
/// identidad equipada. Los colores y las letras son los de esa identidad.
class TarjetaCierreDia extends StatelessWidget {
  /// Tamaño lógico fijo: 4:5.
  static const double ancho = 360;
  static const double alto = 450;

  /// Tamaño de la imagen compartida.
  static const double anchoPx = 1080;
  static const double altoPx = 1350;

  /// Lado del cuadrado de la figura: el 53 % del alto, entre el nombre y el
  /// número.
  static const double ladoFigura = 240;

  /// Cuántos hábitos hay en el día (los que se han hecho: el día está cerrado).
  final int total;

  /// El día que se cierra.
  final DateTime fecha;

  const TarjetaCierreDia({super.key, required this.total, required this.fecha});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final core = NordayCoreLocalizations.of(context)!;
    final t = tokens(context);
    final tema = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();

    return SizedBox(
      width: ancho,
      height: alto,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // El fondo de la identidad, a sangre y sin panel encima, como el de
          // la postal de invitar: sin huecos transparentes.
          ColoredBox(color: t.bg),
          const Positioned.fill(child: FondoIdentidad()),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Los textos se encogen antes que partirse: la postal mide
                // siempre lo mismo y un nombre largo no la desborda.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ValueListenableBuilder<IdentidadPaleta>(
                    valueListenable: identidadEquipadaNotifier,
                    builder: (context, id, _) => Text(
                      nombreFiguraDelDia(core, id.fondo, total),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: tema.headlineSmall?.copyWith(color: t.text),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    DateFormat.MMMMEEEEd(locale).format(fecha),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: tema.bodyLarge?.copyWith(color: t.text),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FiguraDelDia(total: total, tamano: ladoFigura),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l.cierrePostalHabitos(total),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: tema.titleLarge?.copyWith(color: t.text),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                WordmarkIdentidad(
                  texto: l.appNombre,
                  color: t.text,
                  // El wordmark va pequeño: un rol de la escala, no un número.
                  tamano: tema.titleMedium?.fontSize ?? 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
