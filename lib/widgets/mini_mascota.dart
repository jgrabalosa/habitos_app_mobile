import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'burbuja_flotante.dart';

/// Traductor de dominio: convierte el estado genérico de la mascota
/// (feliz/neutral/dormida) en una representación visual. Hoy es un
/// placeholder emoji — cuando lleguen los assets de Rive, solo se
/// sustituye `_iconoPara` por la animación real.
class MiniMascota extends StatefulWidget {
  final int usuarioId;

  const MiniMascota({super.key, required this.usuarioId});

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
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _oculta) return const SizedBox.shrink();

    final t = tokens(context);

    return BurbujaFlotante(
      storageKey: 'mini_mascota',
      onTap: _onTap,
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
            child: Text(_iconoPara(_estado), style: const TextStyle(fontSize: 32)),
          ),
        ),
      ),
    );
  }
}