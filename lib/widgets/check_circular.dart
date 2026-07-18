import 'package:flutter/material.dart';

/// Checkbox circular animado — EL gesto de la app.
/// Genérico: recibe el estado [hecho] y un [onTap]; no conoce el dominio.
/// Al pasar de no-hecho a hecho: el círculo se rellena con pop elástico
/// y el check se dibuja trazándose.
class CheckCircular extends StatefulWidget {
  final bool hecho;
  final VoidCallback? onTap;
  final Color color;
  final Color colorVacio;
  final double tamano;

  const CheckCircular({
    super.key,
    required this.hecho,
    required this.onTap,
    required this.color,
    required this.colorVacio,
    this.tamano = 44,
  });

  @override
  State<CheckCircular> createState() => _CheckCircularState();
}

class _CheckCircularState extends State<CheckCircular>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _relleno; // 0-1: el círculo se llena
  late final Animation<double> _pop;     // escala con rebote
  late final Animation<double> _trazo;   // 0-1: el check se dibuja

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _relleno = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _pop = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.18, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.75),
    ));
    _trazo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    // Si ya nace hecho (recarga del Dashboard), mostrar el estado final sin animar
    if (widget.hecho) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(CheckCircular oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hecho && !oldWidget.hecho) {
      _controller.forward(from: 0); // acaba de completarse → animación completa
    } else if (!widget.hecho && oldWidget.hecho) {
      _controller.value = 0; // reset (p. ej. cambio de día)
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.hecho ? null : widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Amplía el área táctil sin agrandar el dibujo
        padding: const EdgeInsets.all(6),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Transform.scale(
              scale: _pop.value,
              child: CustomPaint(
                size: Size.square(widget.tamano),
                painter: _CheckPainter(
                  relleno: _relleno.value,
                  trazo: _trazo.value,
                  color: widget.color,
                  colorVacio: widget.colorVacio,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double relleno;
  final double trazo;
  final Color color;
  final Color colorVacio;

  _CheckPainter({
    required this.relleno,
    required this.trazo,
    required this.color,
    required this.colorVacio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2;

    // Aro exterior (estado vacío)
    final aro = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = colorVacio;
    canvas.drawCircle(centro, radio - 1.5, aro);

    // Relleno que crece desde el centro
    if (relleno > 0) {
      final fill = Paint()..color = color;
      canvas.drawCircle(centro, (radio - 1.5) * relleno, fill);
    }

    // Check dibujándose (dos segmentos: bajada corta + subida larga)
    if (trazo > 0) {
      final paintCheck = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.09
        ..strokeCap = StrokeCap.round
        ..color = Colors.white;

      final p1 = Offset(size.width * 0.28, size.height * 0.53);
      final p2 = Offset(size.width * 0.44, size.height * 0.68);
      final p3 = Offset(size.width * 0.73, size.height * 0.35);

      final path = Path()..moveTo(p1.dx, p1.dy);
      final primerTramo = (trazo * 2).clamp(0.0, 1.0);
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * primerTramo,
        p1.dy + (p2.dy - p1.dy) * primerTramo,
      );
      if (trazo > 0.5) {
        final segundoTramo = ((trazo - 0.5) * 2).clamp(0.0, 1.0);
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * segundoTramo,
          p2.dy + (p3.dy - p2.dy) * segundoTramo,
        );
      }
      canvas.drawPath(path, paintCheck);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.relleno != relleno || old.trazo != trazo || old.color != color;
}