import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/mascota_assets.dart';
import '../screens/mascota_screen.dart';
import 'burbuja_flotante.dart';

/// Versión flotante y pequeña de la mascota. La ilustración sale de
/// `assetMascota`, el mismo mapeo que usa la pantalla grande: aquí no se
/// decide nada sobre fases ni estados.
class MiniMascota extends StatefulWidget {
  final int usuarioId;
  final Size areaSize;

  const MiniMascota({super.key, required this.usuarioId, required this.areaSize});

  @override
  State<MiniMascota> createState() => _MiniMascotaState();
}

class _MiniMascotaState extends State<MiniMascota> {
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

    final t = tokens(context);

    return BurbujaFlotante(
      storageKey: 'mini_mascota',
      areaSize: widget.areaSize,
      onTap: _onTap,
      minTopFraction: 0.5,
      vagabundeo: true,
      child: AnimatedScale(
        scale: _rebotando ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.surface,
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Center(
            child: Image.asset(
              assetMascota(fase: _fase, estado: _estado),
              width: 48,
              height: 48,
            ),
          ),
        ),
      ),
    );
  }
}