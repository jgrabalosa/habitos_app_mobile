import 'package:flutter/material.dart';

/// Cuánto se amplifica la parte de la curva que sobrepasa 1 (el
/// rebote de `easeOutBack`, la curva de Dulce). El rango base de
/// escala es de sólo 0.04, así que sin amplificar, un overshoot
/// del 10% quedaba en un 0.4% de escala y no se veía.
const double _factorRebote = 0.30;

/// A qué lado del tránsito pertenece esta ranura: la posición que la fila
/// abandona (`origen`) o la que va a ocupar (`destino`). Las dos existen a la
/// vez mientras dura el gesto — es lo que hace posible que se crucen.
enum PapelTransito { origen, destino }

/// Una posición de la lista mientras una fila se traslada a otra, en dos
/// fases sobre el mismo `progreso` (0.0 a 1.0): primero se hunde en Z, luego
/// se desplaza a su sitio nuevo. Pensado para el hueco que deja una fila al
/// completarse y el que ocupa al llegar al fondo de la lista.
///
/// Cada ranura pinta un papel (`origen` o `destino`): el padre monta las dos
/// con el mismo `progreso` y dos `child` distintos, y esta clase decide cómo
/// se ve cada una en cada instante. No hay `AnimationController` aquí dentro
/// — el tránsito entero es una función pura de `progreso`, y quien la mueve
/// (típicamente un `AnimatedBuilder` o el propio dashboard) es quien decide
/// el ritmo real.
///
/// El `heightFactor` que sale de aquí SIEMPRE va `.clamp(0.0, 1.0)`, aunque
/// `curva` sea algo como `Curves.easeOutBack` —la de Dulce—, que pasa de
/// 1.0 a mitad de camino: sin el clamp, el complementario (`1 - t`) se
/// vuelve negativo y `Align` revienta un assert. El rebote de esa curva no
/// se pierde por el clamp: se conserva en la escala, que sí admite pasar de
/// 1.0, y es donde de verdad se lee el "bote" al aterrizar.
///
/// Por construcción, el `heightFactor` del `origen` y el del `destino` suman
/// siempre 1.0, para cualquier `progreso` y cualquier `curva`. Es lo que
/// impide que el resto de la lista dé un tirón: la altura que pierde una
/// ranura es exactamente la que gana la otra, así que la lista nunca crece
/// ni encoge de más mientras dura el gesto.
class RanuraTransito extends StatelessWidget {
  final Widget child;

  /// 0.0 al empezar el tránsito, 1.0 al terminar.
  final double progreso;

  final PapelTransito papel;

  /// La curva de la fase de traslado (fase 2). La fase de hundimiento (fase
  /// 1) es siempre lineal a propósito: hundirse con rebote no significa nada,
  /// el rebote es del aterrizaje, no de la caída.
  final Curve curva;

  const RanuraTransito({
    super.key,
    required this.child,
    required this.progreso,
    required this.papel,
    required this.curva,
  });

  (double heightFactor, double escala) _calcular() {
    // Fase 1 (0.0 → 0.5): el hundimiento. El origen se encoge un poco en Z
    // mientras sigue ocupando toda su fila; el destino todavía no existe.
    if (progreso <= 0.5) {
      final fase = (progreso / 0.5).clamp(0.0, 1.0);
      return switch (papel) {
        PapelTransito.origen => (1.0, 1.0 - 0.04 * fase),
        PapelTransito.destino => (0.0, 0.96),
      };
    }

    // Fase 2 (0.5 → 1.0): el traslado. `t` es el crudo de la curva —puede
    // pasar de 1.0 si `curva` hace overshoot— y sólo se clampa para la
    // altura; la escala del destino lo usa tal cual, overshoot incluido.
    final t = curva.transform(((progreso - 0.5) / 0.5).clamp(0.0, 1.0));
    final alturaDestino = t.clamp(0.0, 1.0);
    return switch (papel) {
      PapelTransito.origen => (1.0 - alturaDestino, 0.96),
      PapelTransito.destino => (
        alturaDestino,
        0.96 + 0.04 * alturaDestino + (t - alturaDestino) * _factorRebote,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (heightFactor, escala) = _calcular();

    // ClipRect evita que el contenido desborde hacia arriba/abajo mientras
    // Align lo encoge; Transform.scale es aparte porque una escala <1 no
    // reduce el hueco que ocupa el widget, sólo lo que se ve dentro de él.
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: heightFactor,
        child: Transform.scale(
          scale: escala,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
