import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton.dart';
import 'tienda_screen.dart';

class MascotaScreen extends StatefulWidget {
  final int usuarioId;
  const MascotaScreen({super.key, required this.usuarioId});

  @override
  State<MascotaScreen> createState() => _MascotaScreenState();
}

class _MascotaScreenState extends State<MascotaScreen> {
  bool _loading = true;
  String _nombre = '';
  int _nivel = 1;
  int _xpEnNivelActual = 0;
  int _xpParaSiguienteNivel = 20;
  String _fase = 'Huevo';
  String _estado = 'neutral';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final data = await ApiService.getMascota(widget.usuarioId);
      setState(() {
        _nombre = data['nombre'] ?? '';
        _nivel = data['nivel'] ?? 1;
        _xpEnNivelActual = data['xpEnNivelActual'] ?? 0;
        _xpParaSiguienteNivel = data['xpParaSiguienteNivel'] ?? 20;
        _fase = data['fase'] ?? 'Huevo';
        _estado = data['estado'] ?? 'neutral';
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  String get _icono {
    switch (_estado) {
      case 'feliz':
        return '🐣';
      case 'dormida':
        return '💤';
      default:
        return '🐤';
    }
  }

  String get _estadoLegible {
    switch (_estado) {
      case 'feliz':
        return 'Feliz';
      case 'dormida':
        return 'Necesita atención';
      default:
        return 'Tranquila';
    }
  }

  Future<void> _editarNombre() async {
    final controller = TextEditingController(text: _nombre);
    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ponle nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Nombre de tu mascota'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoNombre != null && nuevoNombre.isNotEmpty && nuevoNombre != _nombre) {
      final anterior = _nombre;
      setState(() => _nombre = nuevoNombre);
      try {
        await ApiService.actualizarNombreMascota(widget.usuarioId, nuevoNombre);
      } catch (e) {
        if (mounted) {
          setState(() => _nombre = anterior);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar el nombre. Inténtalo de nuevo.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final pct = _xpParaSiguienteNivel > 0 ? _xpEnNivelActual / _xpParaSiguienteNivel : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Tu mascota')),
      body: _loading
          ? _skeletonMascota()
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      child: Column(
                        children: [
                          Text(_icono, style: const TextStyle(fontSize: 96)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _editarNombre,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_nombre,
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: t.text)),
                                const SizedBox(width: 6),
                                Icon(LucideIcons.pencil, size: 16, color: t.textMuted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('$_fase · $_estadoLegible',
                              style: TextStyle(color: t.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Nivel $_nivel',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                              Text('$_xpEnNivelActual/$_xpParaSiguienteNivel XP',
                                  style: TextStyle(color: t.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: t.surface2,
                              valueColor: AlwaysStoppedAnimation(t.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TiendaScreen(usuarioId: widget.usuarioId),
                        ),
                      ).then((_) => _cargarDatos());
                    },
                    icon: const Icon(LucideIcons.utensils),
                    label: const Text('Ir a la tienda a alimentarla'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _skeletonMascota() {
    return SkeletonPulso(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: const [
                  SkeletonBox(width: 96, height: 96, radius: 48),
                  SizedBox(height: 16),
                  SkeletonBox(width: 120, height: 22),
                  SizedBox(height: 8),
                  SkeletonBox(width: 90, height: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14),
                  SizedBox(height: 12),
                  SkeletonBox(height: 10, radius: 999),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}