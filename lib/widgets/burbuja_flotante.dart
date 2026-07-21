import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget flotante genérico y exportable: una "burbuja" arrastrable que se
/// imanta al borde lateral más cercano (izquierda/derecha) al soltarla,
/// con su posición persistida en SharedPreferences (estilo burbujas Messenger).
/// No conoce el contenido que envuelve ni su significado — solo la mecánica.
///
/// Importante: necesita el tamaño real del área donde vive (normalmente el
/// tamaño del Stack que la contiene, NO el de toda la pantalla), porque un
/// Stack casi siempre es más pequeño que la pantalla (AppBar, barra de
/// navegación inferior, etc. quedan fuera de su `body`).
class BurbujaFlotante extends StatefulWidget {
  final Widget child;
  final String storageKey; // clave única en SharedPreferences para la posición
  final Size areaSize; // tamaño real del área contenedora (el Stack padre)
  final double size;
  final VoidCallback? onTap;
  final double minTopFraction; // 0.0 = puede vivir en toda el área, 0.5 = solo mitad inferior

  const BurbujaFlotante({
    super.key,
    required this.child,
    required this.storageKey,
    required this.areaSize,
    this.size = 64,
    this.onTap,
    this.minTopFraction = 0.0,
  });

  @override
  State<BurbujaFlotante> createState() => _BurbujaFlotanteState();
}

class _BurbujaFlotanteState extends State<BurbujaFlotante>
    with SingleTickerProviderStateMixin {
  double _dx = 1.0;
  double _dy = 0.75;
  bool _cargada = false;
  bool _arrastrando = false;

  late final AnimationController _snapController;
  Animation<double>? _dxAnim;
  Animation<double>? _dyAnim;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_dxAnim != null && _dyAnim != null) {
          setState(() {
            _dx = _dxAnim!.value;
            _dy = _dyAnim!.value;
          });
        }
      });
    _cargarPosicion();
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  Future<void> _cargarPosicion() async {
    final prefs = await SharedPreferences.getInstance();
    final dx = prefs.getDouble('${widget.storageKey}_dx');
    final dy = prefs.getDouble('${widget.storageKey}_dy');
    setState(() {
      if (dx != null) _dx = dx;
      if (dy != null) _dy = dy;
      _cargada = true;
    });
  }

  Future<void> _guardarPosicion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${widget.storageKey}_dx', _dx);
    await prefs.setDouble('${widget.storageKey}_dy', _dy);
  }

  void _animarHasta(double dxDestino, double dyDestino) {
    _dxAnim = Tween(begin: _dx, end: dxDestino).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
    );
    _dyAnim = Tween(begin: _dy, end: dyDestino).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
    );
    _snapController.forward(from: 0);
    _dx = dxDestino;
  }

  @override
  Widget build(BuildContext context) {
    if (!_cargada) return const SizedBox.shrink();

    final tamano = widget.areaSize;
    const margen = 12.0;
    final minY = (tamano.height * widget.minTopFraction) + margen;
    final maxY = tamano.height - widget.size - margen;

    final left = _dx * (tamano.width - widget.size - margen * 2) + margen;
    final top = _dy.clamp(0.0, 1.0) * (maxY - minY) + minY;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        onPanStart: (_) => setState(() => _arrastrando = true),
        onPanUpdate: (details) {
          setState(() {
            final nuevoLeft = (left + details.delta.dx)
                .clamp(margen, tamano.width - widget.size - margen);
            final nuevoTop = (top + details.delta.dy).clamp(minY, maxY);
            _dx = (nuevoLeft - margen) / (tamano.width - widget.size - margen * 2);
            _dy = (nuevoTop - minY) / (maxY - minY);
          });
        },
        onPanEnd: (_) {
          setState(() => _arrastrando = false);
          final destino = _dx < 0.5 ? 0.0 : 1.0;
          _animarHasta(destino, _dy);
          _guardarPosicion();
        },
        child: AnimatedScale(
          scale: _arrastrando ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    );
  }
}