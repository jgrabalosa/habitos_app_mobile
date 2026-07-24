import 'package:flutter/material.dart';

/// Widget genérico y exportable: muestra "+X" flotando hacia arriba
/// con fade out, al estilo de los juegos. No conoce el dominio de la app;
/// solo recibe una cantidad. Se muestra vía [AnimacionPuntos.mostrar].
class AnimacionPuntos {
  /// Muestra "+[cantidad]" animado como overlay sobre la pantalla actual.
  /// [simbolo] permite personalizar el texto (p. ej. "pts", "⭐").
  static void mostrar(
    BuildContext context,
    int cantidad, {
    String simbolo = 'pts',
  }) {
    if (cantidad <= 0) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _PuntosFlotantes(
        texto: '+$cantidad $simbolo',
        alTerminar: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _PuntosFlotantes extends StatefulWidget {
  final String texto;
  final VoidCallback alTerminar;

  const _PuntosFlotantes({required this.texto, required this.alTerminar});

  @override
  State<_PuntosFlotantes> createState() => _PuntosFlotantesState();
}

class _PuntosFlotantesState extends State<_PuntosFlotantes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _subida;
  late final Animation<double> _opacidad;
  late final Animation<double> _escala;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Sube desde el centro hacia arriba
    _subida = Tween<double>(begin: 0, end: -120).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Pop de entrada (crece con rebote) y se mantiene
    _escala = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    ]).animate(_controller);

    // Visible al principio, se desvanece al final
    _opacidad = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    _controller.forward().whenComplete(widget.alTerminar);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Center(
            child: Transform.translate(
              offset: Offset(0, _subida.value),
              child: Transform.scale(
                scale: _escala.value,
                child: Opacity(
                  opacity: _opacidad.value,
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      widget.texto,
                      style: TextStyle(
                        color: Colors.amber.shade600,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}