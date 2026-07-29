import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mascota_assets.dart';

/// Motor: da vida a la ilustración de la mascota sin assets nuevos, sólo con
/// animación nativa. Tres capas continuas superpuestas —respiración (escala),
/// vaivén (traslación vertical) y balanceo (rotación)— cada una con su propio
/// controlador y su propia duración: si compartieran periodo el conjunto se
/// leería como un único movimiento mecánico en vez de como algo que respira.
///
/// La amplitud y la velocidad de las tres salen del estado, que es lo único
/// de dominio que entra aquí — y "estado de la mascota" es motor, igual que
/// `assetMascota`: este widget no sabe qué es un hábito ni por qué la mascota
/// está como está.
class MascotaAnimadaViva extends StatefulWidget {
  /// Fase y estado tal y como los manda el backend. La ruta se resuelve
  /// dentro con `assetMascota`, que ya garantiza un asset existente para
  /// cualquier combinación, incluida la desconocida.
  final String? fase;
  final String? estado;

  /// Lado del cuadrado donde se pinta la ilustración.
  final double tamano;

  /// Si acepta el toque directo. En falso el widget no instala ningún
  /// `GestureDetector`, para no competir con el de quien lo envuelva
  /// (la burbuja flotante, sin ir más lejos, ya gestiona toque y arrastre).
  final bool permiteToque;

  /// Aviso opcional de que la han tocado, por si quien la usa quiere añadir
  /// háptica o sonido. El widget no decide nada de eso.
  final VoidCallback? onToque;

  const MascotaAnimadaViva({
    super.key,
    this.fase,
    this.estado,
    required this.tamano,
    this.permiteToque = false,
    this.onToque,
  });

  @override
  State<MascotaAnimadaViva> createState() => _MascotaAnimadaVivaState();
}

/// Cuánto y cómo de rápido se mueve cada capa. Un estado, un perfil.
class _PerfilVida {
  final Duration respiracion;
  final Duration vaiven;
  final Duration balanceo;

  /// Desviación máxima de la escala respecto a 1 (0.04 → 0.96–1.04).
  final double amplitudEscala;

  /// Desplazamiento vertical máximo, en píxeles lógicos.
  final double amplitudY;

  /// Giro máximo, en grados.
  final double amplitudGiro;

  const _PerfilVida({
    required this.respiracion,
    required this.vaiven,
    required this.balanceo,
    required this.amplitudEscala,
    required this.amplitudY,
    required this.amplitudGiro,
  });
}

/// Las tres duraciones de cada perfil son distintas entre sí a propósito.
const _PerfilVida _perfilFeliz = _PerfilVida(
  respiracion: Duration(milliseconds: 1100),
  vaiven: Duration(milliseconds: 1400),
  balanceo: Duration(milliseconds: 1900),
  amplitudEscala: 0.04,
  amplitudY: 5.0,
  amplitudGiro: 2.0,
);

const _PerfilVida _perfilTriste = _PerfilVida(
  respiracion: Duration(milliseconds: 2100),
  vaiven: Duration(milliseconds: 2600),
  balanceo: Duration(milliseconds: 3300),
  amplitudEscala: 0.018,
  amplitudY: 2.0,
  amplitudGiro: 0.8,
);

/// Casi quieta: lo justo para que no parezca una imagen congelada.
const _PerfilVida _perfilDormida = _PerfilVida(
  respiracion: Duration(milliseconds: 3400),
  vaiven: Duration(milliseconds: 4300),
  balanceo: Duration(milliseconds: 5700),
  amplitudEscala: 0.012,
  amplitudY: 1.2,
  amplitudGiro: 0.3,
);

/// Un estado que este cliente aún no conozca cae al perfil sereno, mismo
/// criterio que `assetMascota`: ante la duda, no darla por contenta.
_PerfilVida _perfilDe(String? estado) => switch (estado) {
      'feliz' => _perfilFeliz,
      'dormida' => _perfilDormida,
      _ => _perfilTriste,
    };

class _MascotaAnimadaVivaState extends State<MascotaAnimadaViva>
    with TickerProviderStateMixin {
  late final AnimationController _respiracion;
  late final AnimationController _vaiven;
  late final AnimationController _balanceo;

  /// Reacción al toque, independiente de las tres capas de reposo: va de 1
  /// (aplastada) a 0 (en reposo) con rebote elástico, así que en reposo vale
  /// 0 y no deforma nada.
  late final AnimationController _squishController;
  late final Animation<double> _squish;

  /// Última lectura de la preferencia del sistema de reducir animaciones.
  bool _animacionesDesactivadas = false;

  _PerfilVida get _perfil => _perfilDe(widget.estado);

  @override
  void initState() {
    super.initState();
    final p = _perfil;
    _respiracion = AnimationController(vsync: this, duration: p.respiracion);
    _vaiven = AnimationController(vsync: this, duration: p.vaiven);
    _balanceo = AnimationController(vsync: this, duration: p.balanceo);

    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1.0, // 1 en el controlador = 0 de deformación
    );
    _squish = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _squishController, curve: Curves.elasticOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respetar "reducir movimiento" del sistema: una animación en bucle
    // permanente es justo lo que esa preferencia quiere apagar.
    _animacionesDesactivadas =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _sincronizarBucles();
  }

  @override
  void didUpdateWidget(covariant MascotaAnimadaViva anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.estado != widget.estado) _sincronizarBucles();
  }

  /// Deja los tres bucles en marcha con las duraciones del perfil actual, o
  /// parados y en su punto medio (sin deformación) si no toca animar.
  void _sincronizarBucles() {
    final p = _perfil;
    _respiracion.duration = p.respiracion;
    _vaiven.duration = p.vaiven;
    _balanceo.duration = p.balanceo;

    for (final c in [_respiracion, _vaiven, _balanceo]) {
      if (_animacionesDesactivadas) {
        c.stop();
        c.value = 0.5; // centro del recorrido: reposo exacto
      } else {
        c.repeat(reverse: true);
      }
    }
    if (_animacionesDesactivadas) _squishController.value = 1.0;
  }

  @override
  void dispose() {
    _respiracion.dispose();
    _vaiven.dispose();
    _balanceo.dispose();
    _squishController.dispose();
    super.dispose();
  }

  void _alTocar() {
    if (!_animacionesDesactivadas) _squishController.forward(from: 0);
    widget.onToque?.call();
  }

  /// De [0,1] a [-1,1] con entrada y salida suaves, que es lo que convierte
  /// un vaivén lineal en algo que parece vivo.
  double _oscilacion(AnimationController c) =>
      Curves.easeInOut.transform(c.value) * 2 - 1;

  @override
  Widget build(BuildContext context) {
    final p = _perfil;
    final imagen = assetMascota(fase: widget.fase, estado: widget.estado);

    final cuerpo = AnimatedBuilder(
      animation: Listenable.merge([_respiracion, _vaiven, _balanceo, _squish]),
      builder: (context, child) {
        final escala = 1 + _oscilacion(_respiracion) * p.amplitudEscala;
        final desplazamientoY = _oscilacion(_vaiven) * p.amplitudY;
        final giro = _oscilacion(_balanceo) * p.amplitudGiro * math.pi / 180;

        // El squish aplasta en Y y ensancha en X (y al rebotar, al revés).
        final squish = _squish.value;
        final escalaX = escala * (1 + squish * 0.18);
        final escalaY = escala * (1 - squish * 0.18);

        return Transform.translate(
          offset: Offset(0, desplazamientoY),
          child: Transform.rotate(
            angle: giro,
            child: Transform(
              // Desde la base: aplastarse contra el suelo se lee como peso,
              // hacerlo desde el centro parece que flota.
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(escalaX, escalaY, 1),
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(imagen, width: widget.tamano, height: widget.tamano),
    );

    if (!widget.permiteToque) return cuerpo;

    return GestureDetector(
      onTap: _alTocar,
      behavior: HitTestBehavior.opaque,
      child: cuerpo,
    );
  }
}
