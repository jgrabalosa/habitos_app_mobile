import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/mascota_screen.dart';
import 'burbuja_flotante.dart';

/// Traductor de dominio: convierte el estado genérico de la mascota
/// (feliz/neutral/dormida) en una representación visual. Hoy es un
/// placeholder emoji/Lottie de prueba — cuando lleguen los assets
/// definitivos, solo se sustituye `_iconoPara` / el Lottie.asset.
class MiniMascota extends StatefulWidget {
  final int usuarioId;
  final Size areaSize;

  const MiniMascota({super.key, required this.usuarioId, required this.areaSize});

  @override
  State<MiniMascota> createState() => _MiniMascotaState();
}

class _MiniMascotaState extends State<MiniMascota> {
  String? _estado;
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
    try {
      final data = await ApiService.getMascota(widget.usuarioId);
      estado = data['estado'];
    } catch (_) {
      // Si falla, se muestra igualmente con el estado por defecto
    }
    if (!mounted) return;
    setState(() {
      _estado = estado;
      _oculta = oculta;
      _cargando = false;
    });
  }

  String _iconoPara(String? estado) {
    switch (estado) {
      case 'feliz':
        return '🐣';
      case 'neutral':
        return '🐤';
      case 'dormida':
        return '💤';
      default:
        return '🐣';
    }
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
            child: _estado == 'feliz'
                ? Lottie.asset('assets/animations/mascota_placeholder.json', width: 48, height: 48)
                : Text(_iconoPara(_estado), style: const TextStyle(fontSize: 32)),
          ),
        ),
      ),
    );
  }
}