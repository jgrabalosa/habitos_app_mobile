import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/mensajes_error.dart';
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
  String _fase = 'HUEVO'; // código, no texto: se traduce al pintar
  String _estado = 'triste';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final data = await ApiService.getMascota(widget.usuarioId);
      if (!mounted) return;
      setState(() {
        _nombre = data['nombre'] ?? '';
        _nivel = data['nivel'] ?? 1;
        _xpEnNivelActual = data['xpEnNivelActual'] ?? 0;
        _xpParaSiguienteNivel = data['xpParaSiguienteNivel'] ?? 20;
        _fase = data['fase'] ?? 'HUEVO';
        _estado = data['estado'] ?? 'triste';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MensajesError.de(context, e))),
      );
    }
  }

  /// Respaldo: solo se pinta si la imagen de la fase actual no existe todavia.
  String get _icono {
    switch (_estado) {
      case 'feliz':
        return '🐣';
      case 'dormida':
        return '💤';
      case 'triste':
        return '😢';
      default:
        return '😢';
    }
  }

  String get _sufijoEstado {
    switch (_estado) {
      case 'feliz':
        return 'sonriente';
      case 'dormida':
        return 'dormido';
      case 'triste':
        return 'triste';
      default:
        return 'triste';
    }
  }

  String get _imagenMascota =>
      'assets/mascota/Nori_${_fase.toLowerCase()}_$_sufijoEstado.png';

  /// Fase traducida. Caída al código crudo si llega uno desconocido, igual
  /// que hace Catalogos: nunca se deja al usuario sin texto.
  String _faseLegible(AppLocalizations l) => switch (_fase) {
        'HUEVO' => l.mascotaFaseHuevo,
        'CRIA' => l.mascotaFaseCria,
        'ADULTO' => l.mascotaFaseAdulto,
        _ => _fase,
      };

  /// Los tres que manda el backend, explicitos. La caida solo cubre un
  /// estado futuro que este cliente aun no conozca: mejor "Tranquila" que
  /// un codigo crudo o una alarma que no toca.
  String _estadoLegible(AppLocalizations l) => switch (_estado) {
        'feliz' => l.mascotaEstadoFeliz,
        'dormida' => l.mascotaEstadoAtencion,
        'triste' => l.mascotaEstadoTriste,
        _ => l.mascotaEstadoTranquila,
      };

  /// Sin nombre puesto, se muestra la fase localizada. Así el valor por
  /// defecto está traducido sin haber guardado nada en la BD.
  String _nombreVisible(AppLocalizations l) =>
      _nombre.isEmpty ? _faseLegible(l) : _nombre;

  Future<void> _editarNombre() async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _nombre);
    // El controller es local al dialogo: se destruye al cerrarse, pase lo que
    // pase. Si no, cada vez que se abre el dialogo se queda uno vivo.
    String? nuevoNombre;
    try {
      nuevoNombre = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.mascotaPonleNombre),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            decoration: InputDecoration(hintText: l.mascotaHintNombre),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancelar),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l.guardar),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }

    final elegido = nuevoNombre;
    if (elegido != null && elegido.isNotEmpty && elegido != _nombre) {
      final anterior = _nombre;
      setState(() => _nombre = elegido);
      try {
        await ApiService.actualizarNombreMascota(widget.usuarioId, elegido);
      } catch (e) {
        if (mounted) {
          setState(() => _nombre = anterior);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(MensajesError.de(context, e,
                  generico: l.mascotaErrorNombre)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final pct = _xpParaSiguienteNivel > 0 ? _xpEnNivelActual / _xpParaSiguienteNivel : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(l.mascotaTitulo)),
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(scale: animation, child: child),
                            ),
                            child: Image.asset(
                              _imagenMascota,
                              key: ValueKey(_imagenMascota),
                              width: 140,
                              height: 140,
                              // Solo existen imagenes de la fase HUEVO: para
                              // CRIA y ADULTO cae al emoji de siempre.
                              errorBuilder: (context, error, stackTrace) => Text(_icono,
                                  key: ValueKey('icono_$_estado'),
                                  style: const TextStyle(fontSize: 96)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _editarNombre,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_nombreVisible(l),
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
                          Text('${_faseLegible(l)} · ${_estadoLegible(l)}',
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
                              Text(l.mascotaNivel(_nivel),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                              Text(l.mascotaXp(_xpEnNivelActual, _xpParaSiguienteNivel),
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
                    label: Text(l.mascotaIrTienda),
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