import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Anillo de progreso animado — genérico y exportable.
/// Recibe [actual]/[total] y anima el arco entre valores al cambiar.
/// No conoce el dominio: quien lo usa decide qué cuenta.
class AnilloProgreso extends StatelessWidget {
  final int actual;
  final int total;
  final Color color;
  final Color colorPista;
  final Color colorTexto;
  final double tamano;

  const AnilloProgreso({
    super.key,
    required this.actual,
    required this.total,
    required this.color,
    required this.colorPista,
    required this.colorTexto,
    this.tamano = 64,
  });

  @override
  Widget build(BuildContext context) {
    final objetivo = total <= 0 ? 0.0 : (actual / total).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: objetivo),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, progreso, _) {
        return SizedBox(
          width: tamano,
          height: tamano,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(tamano),
                painter: _AnilloPainter(
                  progreso: progreso,
                  color: color,
                  colorPista: colorPista,
                  grosor: tamano * 0.11,
                ),
              ),
              Text(
                '$actual/$total',
                style: TextStyle(
                  fontSize: tamano * 0.24,
                  fontWeight: FontWeight.w600, // Números = SemiBold (identidad)
                  color: colorTexto,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnilloPainter extends CustomPainter {
  final double progreso;
  final Color color;
  final Color colorPista;
  final double grosor;

  _AnilloPainter({
    required this.progreso,
    required this.color,
    required this.colorPista,
    required this.grosor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = (size.width - grosor) / 2;

    final pista = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..color = colorPista;
    canvas.drawCircle(centro, radio, pista);

    if (progreso > 0) {
      final arco = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: radio),
        -math.pi / 2, // empieza arriba (las 12)
        2 * math.pi * progreso,
        false,
        arco,
      );
    }
  }

  @override
  bool shouldRepaint(_AnilloPainter old) =>
      old.progreso != progreso || old.color != color;
}