import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../screens/mascota_screen.dart';
import 'burbuja_flotante.dart';
import 'mascota_animada_viva.dart';

/// Versión flotante y pequeña de la mascota. La ilustración y su animación
/// de reposo salen de `MascotaAnimadaViva`, el mismo widget que usa la
/// pantalla grande: aquí no se decide nada sobre fases ni estados.
class MiniMascota extends StatefulWidget {
  final int usuarioId;
  final Size areaSize;

  const MiniMascota({super.key, required this.usuarioId, required this.areaSize});

  @override
  State<MiniMascota> createState() => _MiniMascotaState();
}

class _MiniMascotaState extends State<MiniMascota> {
  /// Tamaño habitual de la burbuja. En cualquier móvil normal manda este
  /// valor: el tope de abajo solo entra en juego en pantallas diminutas.
  static const double _tamanoNominal = 84;

  /// La burbuja no puede pasar del 40% del alto de pantalla. Es una
  /// salvaguarda, no un tamaño: si se llega a aplicar es que la pantalla es
  /// tan baja que 84px ya tapaban media lista.
  static const double _fraccionMaximaAlto = 0.4;

  /// La ilustración deja aire alrededor dentro de la caja de la burbuja
  /// (63 sobre 84). Ese aire es el margen del que tira el arrastre, no un
  /// adorno: la caja es lo que la burbuja usa para calcular sus límites.
  static const double _proporcionIlustracion = 0.75;

  String? _estado;
  String? _fase;
  bool _oculta = false;
  bool _cargando = true;
  bool _rebotando = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    final oculta = prefs.getBool('mini_mascota_oculta') ?? false;
    String? estado;
    String? fase;
    try {
      final data = await ApiService.getMascota(widget.usuarioId);
      estado = data['estado'];
      fase = data['fase'];
    } catch (_) {
      // Si falla, se muestra igualmente con fase y estado por defecto
    }
    if (!mounted) return;
    setState(() {
      _estado = estado;
      _fase = fase;
      _oculta = oculta;
      _cargando = false;
    });
  }

  void _onTap() {
    setState(() => _rebotando = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _rebotando = false);
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MascotaScreen(usuarioId: widget.usuarioId)),
    ).then((_) => _inicializar()); // al volver, refresca el estado (pudo alimentarla)
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _oculta) return const SizedBox.shrink();

    final topeAlto =
        MediaQuery.of(context).size.height * _fraccionMaximaAlto;
    final tamano = min(_tamanoNominal, topeAlto);

    return BurbujaFlotante(
      storageKey: 'mini_mascota',
      areaSize: widget.areaSize,
      // La burbuja calcula sus límites con este tamaño: si no coincide con el
      // del contenido, la mascota se sale del área por abajo.
      size: tamano,
      onTap: _onTap,
      minTopFraction: 0.5,
      vagabundeo: true,
      child: AnimatedScale(
        scale: _rebotando ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        // Sin círculo, sin sombra y sin superficie detrás: Nori se ve
        // directamente sobre el fondo de la pantalla. La caja sigue midiendo
        // `tamano` porque es la que le hemos declarado a la burbuja para que
        // calcule sus límites; simplemente ya no pinta nada.
        child: SizedBox(
          width: tamano,
          height: tamano,
          child: Center(
            // El toque lo gestiona la burbuja (que además arrastra), así que
            // aquí va sin él: dos GestureDetector encajados se pelearían.
            child: MascotaAnimadaViva(
              fase: _fase,
              estado: _estado,
              tamano: tamano * _proporcionIlustracion,
            ),
          ),
        ),
      ),
    );
  }
}