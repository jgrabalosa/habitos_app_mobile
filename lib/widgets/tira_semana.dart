import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../models/hoy.dart';
import 'identidad_ui.dart';

/// La tira de 7 días (lunes a domingo) encima de Hoy, para moverse a otro
/// día de la semana.
///
/// La celda de cada día reutiliza [celdaHeatmap]: es la misma pieza que ya
/// pinta un día en el mini-mapa de cada hábito, con el mismo criterio de
/// selección por identidad (`seleccionada`) y de "hoy" (`esHoy`).
///
/// Debajo de cada día va su avance (`DiaTira.avance`, de 0 a 1) como una
/// barrita que se llena con lo hecho, también a medias. Un día sin nada que
/// hacer, o que todavía no ha llegado, lleva un punto: ahí no se espera nada.
/// Nunca se pinta un fallo.
class TiraSemana extends StatelessWidget {
  /// Los siete días, en orden lunes→domingo.
  final List<DiaTira> dias;

  final int diaSeleccionado;

  /// Posición de hoy en [dias], o -1 si la semana que se mira no es la de hoy.
  final int indiceHoy;

  final ValueChanged<int> onSeleccionar;

  /// Las flechas de los extremos: cambian de semana, no de día.
  final VoidCallback onSemanaAnterior;
  final VoidCallback onSemanaSiguiente;

  const TiraSemana({
    super.key,
    required this.dias,
    required this.diaSeleccionado,
    required this.indiceHoy,
    required this.onSeleccionar,
    required this.onSemanaAnterior,
    required this.onSemanaSiguiente,
  });

  /// Ancho de la barrita del avance, el de la maqueta.
  static const double _anchoBarra = 14;

  /// Lado del cuadro de cada día. Con las dos flechas (48 cada una) y el
  /// relleno lateral de Hoy, a 360 de ancho cada columna mide unos 33: 32 cabe
  /// con holgura en las tres identidades.
  static const double _ladoCelda = 32;

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final sinAnimacion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          iconSize: 20,
          color: t.textMuted,
          tooltip: l.a11ySemanaAnterior,
          onPressed: onSemanaAnterior,
        ),
        ...List.generate(dias.length, (i) {
          final fecha = DateTime.parse(dias[i].fecha);
          final double? avance = dias[i].avance;
          final bool esHoy = i == indiceHoy;
          final bool seleccionado = i == diaSeleccionado;
          final String nombreDia = DateFormat.E(locale).format(fecha);

          final Color colorCelda = seleccionado
              ? t.primary.withValues(alpha: 0.18)
              : t.inactivo;

          return Expanded(
            child: Semantics(
              button: true,
              selected: seleccionado,
              label: l.a11yDiaSemana(
                nombreDia,
                seleccionado ? l.a11yDiaSeleccionado : l.a11yDiaNoSeleccionado,
              ),
              child: GestureDetector(
                onTap: () => onSeleccionar(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    Text(
                      nombreDia.toUpperCase(),
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: sinAnimacion
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      width: _ladoCelda,
                      height: _ladoCelda,
                      alignment: Alignment.center,
                      decoration: celdaHeatmap(
                        id,
                        t,
                        color: colorCelda,
                        // La misma pieza que marca "hecho" en el mini-mapa marca
                        // aquí "es el día activo": incorpora el glow/relieve de
                        // la identidad al día que se está mirando.
                        llena: seleccionado,
                        esHoy: esHoy,
                        seleccionada: seleccionado,
                      ),
                      child: Text(
                        '${fecha.day}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: (seleccionado || esHoy)
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: t.text,
                            ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 4,
                      width: _anchoBarra,
                      child: avance == null
                          ? Center(
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: t.inactivo,
                                ),
                              ),
                            )
                          : _BarraAvance(
                              avance: avance,
                              pista: t.aroVacio,
                              relleno: t.success,
                              forma: id.forma,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        IconButton(
          icon: const Icon(LucideIcons.chevronRight),
          iconSize: 20,
          color: t.textMuted,
          tooltip: l.a11ySemanaSiguiente,
          onPressed: onSemanaSiguiente,
        ),
      ],
    );
  }
}

/// La barrita del avance de un día: la pista apagada y, encima, lo hecho. En
/// Dulce, las dos a lápiz; en las demás, barras redondeadas.
class _BarraAvance extends StatelessWidget {
  final double avance;
  final Color pista;
  final Color relleno;
  final FormaIdentidad forma;

  const _BarraAvance({
    required this.avance,
    required this.pista,
    required this.relleno,
    required this.forma,
  });

  @override
  Widget build(BuildContext context) {
    if (forma == FormaIdentidad.pill) {
      return CustomPaint(
        size: Size.infinite,
        painter: _BarraLapiz(avance: avance, pista: pista, relleno: relleno),
      );
    }
    final radio = BorderRadius.circular(2);
    return Align(
      alignment: Alignment.center,
      child: Container(
        height: 3,
        decoration: BoxDecoration(color: pista, borderRadius: radio),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: avance.clamp(0.0, 1.0),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: relleno, borderRadius: radio),
          ),
        ),
      ),
    );
  }
}

/// La barrita del avance en Dulce: la pista entera y, encima, lo hecho, los dos
/// trazos a lápiz sobre la misma línea, con la misma mano.
class _BarraLapiz extends CustomPainter {
  _BarraLapiz({
    required this.avance,
    required this.pista,
    required this.relleno,
  });

  final double avance;
  final Color pista;
  final Color relleno;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final semilla = semillaDe(size);
    pintarTrazoLapiz(
      canvas,
      Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y),
      color: pista,
      grosor: 1.6,
      semilla: semilla,
    );
    pintarTrazoLapiz(
      canvas,
      Path()
        ..moveTo(0, y)
        ..lineTo(size.width * avance.clamp(0.0, 1.0), y),
      color: relleno,
      grosor: 2.4,
      semilla: semilla,
    );
  }

  @override
  bool shouldRepaint(_BarraLapiz viejo) =>
      viejo.avance != avance ||
      viejo.pista != pista ||
      viejo.relleno != relleno;
}
