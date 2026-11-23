import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// La nota de una pista de Nori (T-054): un `BurbujaContexto` que se cierra
/// tocándola. Va **en la lista, junto a lo que explica**, empujando lo de
/// debajo en vez de flotar encima: así no tapa nada.
///
/// Entra con un fundido corto y un leve deslizamiento; con «reducir
/// movimiento» aparece de golpe, sin ningún controlador.
class NotaPista extends StatefulWidget {
  final String texto;
  final VoidCallback onCerrar;

  /// Lo que lee el lector de pantalla para el gesto de cerrar.
  final String? etiquetaCerrar;

  const NotaPista({
    super.key,
    required this.texto,
    required this.onCerrar,
    this.etiquetaCerrar,
  });

  @override
  State<NotaPista> createState() => _NotaPistaState();
}

class _NotaPistaState extends State<NotaPista>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget nota = Semantics(
      container: true,
      button: true,
      label: widget.texto,
      onTapHint: widget.etiquetaCerrar,
      onTap: widget.onCerrar,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onCerrar,
        child: ExcludeSemantics(child: BurbujaContexto(texto: widget.texto)),
      ),
    );
    final ctrl = _ctrl;
    if (ctrl == null) return nota;
    final curva = CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curva,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(curva),
        child: nota,
      ),
    );
  }
}
