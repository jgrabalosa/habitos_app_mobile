import 'dart:math';
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
///
/// Vagabundeo (opcional, `vagabundeo: true`): mientras no se arrastra, da
/// pasos pequeños y aleatorios dentro de su área permitida cada pocos
/// segundos, y tiene un balanceo continuo de reposo — para que se sienta
/// "viva" en vez de completamente estática. Pensado para burbujas que
/// representen algo con vida propia (ej. una mascota); una burbuja
/// puramente funcional puede dejarlo en false (el valor por defecto).
class BurbujaFlotante extends StatefulWidget {
  final Widget child;
  final String storageKey; // clave única en SharedPreferences para la posición
  final Size areaSize; // tamaño real del área contenedora (el Stack padre)
  final double size;
  final VoidCallback? onTap;
  final double minTopFraction; // 0.0 = puede vivir en toda el área, 0.5 = solo mitad inferior
  final bool vagabundeo;
  final Duration pasoMin;
  final Duration pasoMax;
  final double pasoDistanciaFraccion; // tamaño de cada paso, en fracción del área (0-1)

  const BurbujaFlotante({
    super.key,
    required this.child,
    required this.storageKey,
    required this.areaSize,
    this.size = 64,
    this.onTap,
    this.minTopFraction = 0.0,
    this.vagabundeo = false,
    this.pasoMin = const Duration(seconds: 2),
    this.pasoMax = const Duration(seconds: 3),
    this.pasoDistanciaFraccion = 0.12,
  });

  @override
  State<BurbujaFlotante> createState() => _BurbujaFlotanteState();
}

class _BurbujaFlotanteState extends State<BurbujaFlotante>
    with TickerProviderStateMixin {
  double _dx = 1.0;
  double _dy = 0.75;
  bool _cargada = false;
  bool _arrastrando = false;

  late final AnimationController _snapController;
  Animation<double>? _dxAnim;
  Animation<double>? _dyAnim;

  // Balanceo continuo de reposo (vida en idle) — independiente de la
  // posición real, se superpone como un pequeño desplazamiento vertical.
  late final AnimationController _balanceoController;

  final _random = Random();
  bool _paseandoAhoraMismo = false;

  bool get _vivo => widget.vagabundeo;

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

    _balanceoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (_vivo) {
      _balanceoController.repeat(reverse: true);
    }

    _cargarPosicion();
  }

  @override
  void dispose() {
    _snapController.dispose();
    _balanceoController.dispose();
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
    if (_vivo) _programarProximoPaso();
  }

  Future<void> _guardarPosicion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${widget.storageKey}_dx', _dx);
    await prefs.setDouble('${widget.storageKey}_dy', _dy);
  }

  void _animarHasta(double dxDestino, double dyDestino, {Duration? duracion}) {
    if (duracion != null) _snapController.duration = duracion;
    _dxAnim = Tween(begin: _dx, end: dxDestino).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeInOut),
    );
    _dyAnim = Tween(begin: _dy, end: dyDestino).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeInOut),
    );
    _snapController.forward(from: 0);
    _dx = dxDestino;
    _dy = dyDestino;
  }

  // Da un paso pequeño y aleatorio dentro del área permitida, y programa
  // el siguiente. Se detiene solo mientras el usuario arrastra la burbuja.
  void _programarProximoPaso() {
    if (!mounted || !_vivo) return;
    final espera = widget.pasoMin +
        Duration(
          milliseconds: _random.nextInt(
            (widget.pasoMax - widget.pasoMin).inMilliseconds.clamp(1, 1 << 30),
          ),
        );
    Future.delayed(espera, () {
      if (!mounted || !_vivo) return;
      if (!_arrastrando) _darPaso();
      _programarProximoPaso();
    });
  }

  void _darPaso() {
    final paso = widget.pasoDistanciaFraccion;
    final nuevoDx = (_dx + (_random.nextDouble() * 2 - 1) * paso).clamp(0.0, 1.0);
    final nuevoDy = (_dy + (_random.nextDouble() * 2 - 1) * paso).clamp(0.0, 1.0);
    setState(() => _paseandoAhoraMismo = true);
    _animarHasta(nuevoDx, nuevoDy, duracion: const Duration(milliseconds: 700));
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _paseandoAhoraMismo = false);
    });
    _guardarPosicion();
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
          // Se queda donde se suelte (sin imán a los lados). Si tiene
          // vagabundeo, retoma sus paseos solos desde ahí.
          _guardarPosicion();
        },
        child: AnimatedBuilder(
          animation: _balanceoController,
          builder: (context, child) {
            // Balanceo de reposo: un pequeño vaivén vertical continuo (±3px).
            // Se pausa visualmente mientras da un paso, para no competir con
            // el movimiento del paso en sí.
            final balanceo = (_vivo && !_paseandoAhoraMismo && !_arrastrando)
                ? (sin(_balanceoController.value * pi) * 3.0 - 1.5)
                : 0.0;
            return Transform.translate(
              offset: Offset(0, balanceo),
              child: child,
            );
          },
          child: AnimatedScale(
            scale: _arrastrando ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}