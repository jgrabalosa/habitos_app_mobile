import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Arrastre libre que gana el pulso a un pager horizontal que la contenga.
///
/// Un [PanGestureRecognizer] normal no reclama el gesto hasta los 36px
/// (`kPanSlop`), pero el deslizamiento entre pestañas lo reclama a los 18
/// (`kTouchSlop`): sin esto, arrastrar la burbuja de lado cambiaba de pestaña
/// en vez de mover la burbuja. Con el mismo umbral gana el hijo, que se
/// resuelve antes que el ancestro.
class _ArrastreLibre extends PanGestureRecognizer {
  @override
  bool hasSufficientGlobalDistanceToAccept(
      PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) {
    return globalDistanceMoved.abs() >
        computeHitSlop(pointerDeviceKind, gestureSettings);
  }
}

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
/// segundos. Pensado para burbujas que representen algo con vida propia
/// (ej. una mascota); una burbuja puramente funcional puede dejarlo en
/// false (el valor por defecto).
///
/// La burbuja mueve la burbuja: la vida de reposo del contenido (respirar,
/// balancearse) es cosa del contenido, que es quien sabe si respira y a qué
/// ritmo. Por eso aquí no hay ningún vaivén propio.
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

  final _random = Random();

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
    if (!mounted) return;
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
    _animarHasta(nuevoDx, nuevoDy, duracion: const Duration(milliseconds: 700));
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
      child: RawGestureDetector(
        gestures: {
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            TapGestureRecognizer.new,
            (r) => r.onTap = () {
              HapticFeedback.lightImpact();
              widget.onTap?.call();
            },
          ),
          _ArrastreLibre: GestureRecognizerFactoryWithHandlers<_ArrastreLibre>(
            _ArrastreLibre.new,
            (r) {
              r.onStart = (_) => setState(() => _arrastrando = true);
              r.onUpdate = (details) {
                setState(() {
                  final nuevoLeft = (left + details.delta.dx)
                      .clamp(margen, tamano.width - widget.size - margen);
                  final nuevoTop = (top + details.delta.dy).clamp(minY, maxY);
                  _dx = (nuevoLeft - margen) /
                      (tamano.width - widget.size - margen * 2);
                  _dy = (nuevoTop - minY) / (maxY - minY);
                });
              };
              r.onEnd = (_) {
                setState(() => _arrastrando = false);
                // Se queda donde se suelte (sin imán a los lados). Si tiene
                // vagabundeo, retoma sus paseos solos desde ahí.
                _guardarPosicion();
              };
            },
          ),
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