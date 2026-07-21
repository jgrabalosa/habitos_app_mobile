import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Skeleton loader genérico y exportable al ecosistema: siluetas en gris
/// pulsante con los colores/radios del sistema de tokens Norday. Cada
/// pantalla compone su propio layout de skeleton combinando estas piezas
/// según la forma real de su contenido.

/// Envuelve piezas de skeleton con la animación de pulso compartida (todas
/// laten a la vez, más barato que animar cada pieza por separado).
class SkeletonPulso extends StatefulWidget {
  final Widget child;
  const SkeletonPulso({super.key, required this.child});

  @override
  State<SkeletonPulso> createState() => _SkeletonPulsoState();
}

class _SkeletonPulsoState extends State<SkeletonPulso>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacidad;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacidad = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacidad, child: widget.child);
  }
}

/// Pieza básica: un bloque gris con el radio que le pidas (por defecto
/// AppRadius.sm, para líneas de texto).
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Silueta lista para usar: imita una tarjeta genérica (título + línea
/// corta), con el radio de card (20px) del sistema.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 88});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      height: height,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonBox(width: 160, height: 16),
          SizedBox(height: 10),
          SkeletonBox(width: 100, height: 12),
        ],
      ),
    );
  }
}

/// Lista lista para usar: N tarjetas skeleton con el pulso ya aplicado.
/// Uso típico: `if (_loading) return const SkeletonLista(); else ...`
class SkeletonLista extends StatelessWidget {
  final int cantidad;
  final EdgeInsetsGeometry padding;
  const SkeletonLista({
    super.key,
    this.cantidad = 4,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonPulso(
      child: ListView(
        padding: padding,
        children: List.generate(cantidad, (_) => const SkeletonCard()),
      ),
    );
  }
}