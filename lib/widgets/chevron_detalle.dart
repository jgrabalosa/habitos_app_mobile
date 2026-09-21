import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// El chevron que anuncia que una tarjeta de hábito abre su detalle.
///
/// Con [empujar], cada poco se desplaza unos píxeles a la derecha y vuelve.
/// Es un empujón y no un parpadeo a propósito: un parpadeo dice «mírame»;
/// un empujón dice «por aquí», que es lo que el chevron quiere decir.
///
/// Con «reducir movimiento» activado en el sistema se queda quieto, como el
/// resto de animaciones de la app.
class ChevronDetalle extends StatefulWidget {
  final Color color;
  final bool empujar;

  const ChevronDetalle({
    super.key,
    required this.color,
    this.empujar = false,
  });

  @override
  State<ChevronDetalle> createState() => _ChevronDetalleState();
}

class _ChevronDetalleState extends State<ChevronDetalle>
    with SingleTickerProviderStateMixin {
  /// Un ciclo entero: ida, vuelta y una pausa larga. El movimiento ocupa la
  /// cuarta parte y el resto es quietud, para que se note sin molestar.
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  late final Animation<double> _dx = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 3.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 12,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 3.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeIn)),
      weight: 13,
    ),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 75),
  ]).animate(_anim);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizar();
  }

  @override
  void didUpdateWidget(covariant ChevronDetalle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizar();
  }

  /// Arranca o para el empujón según lo que toque ahora. Se llama al montar,
  /// al cambiar el ajuste de movimiento y al cambiar [ChevronDetalle.empujar].
  void _sincronizar() {
    final reducir = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final mover = widget.empujar && !reducir;
    if (mover && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!mover && _anim.isAnimating) {
      _anim.reset();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dx,
      builder: (context, child) => Transform.translate(
        offset: Offset(_dx.value, 0),
        child: child,
      ),
      child: Icon(LucideIcons.chevronRight, size: 16, color: widget.color),
    );
  }
}
