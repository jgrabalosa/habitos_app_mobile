import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/catalogos.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/avatares.dart';

/// Grid para elegir el primer avatar gratis (una sola vez). Motor genérico:
/// solo conoce "avatares", no si se usa desde la Colección o el onboarding.
/// Al tocar uno, lo otorga y equipa, y avisa al padre vía [onElegido].
class SelectorAvatarGratis extends StatefulWidget {
  final int usuarioId;
  final void Function(String codigoAvatar) onElegido;

  const SelectorAvatarGratis({
    super.key,
    required this.usuarioId,
    required this.onElegido,
  });

  /// Reutilizable por quien necesite saber si el usuario ya tiene algún
  /// avatar (p. ej. para decidir si mostrar el onboarding).
  static Future<bool> tieneAlgunAvatar(int usuarioId) async {
    final inventario = await ApiService.getInventarioProductos(usuarioId);
    return inventario.any((up) => up['producto']['categoria'] == 'Avatar');
  }

  @override
  State<SelectorAvatarGratis> createState() => _SelectorAvatarGratisState();
}

class _SelectorAvatarGratisState extends State<SelectorAvatarGratis> {
  bool _loading = true;
  List<dynamic> _avatares = [];
  int? _procesando;

  @override
  void initState() {
    super.initState();
    _cargarAvatares();
  }

  Future<void> _cargarAvatares() async {
    try {
      final catalogo = await ApiService.getCatalogoProductos();
      setState(() {
        _avatares = catalogo.where((p) => p['categoria'] == 'Avatar').toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _elegir(int productoId, String? codigo) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _procesando = productoId);
    try {
      await ApiService.otorgarProducto(widget.usuarioId, productoId);
      await ApiService.equiparProducto(widget.usuarioId, productoId);
      await guardarAvatarEquipado(codigo);
      if (codigo != null) widget.onElegido(codigo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.selError)),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _avatares.length,
      itemBuilder: (context, i) {
        final producto = _avatares[i];
        final productoId = producto['productoId'] as int;
        final codigo = producto['codigo'] as String?;
        final info = codigo != null ? catalogoAvatares[codigo] : null;
        final procesandoEste = _procesando == productoId;

        return GestureDetector(
          onTap: procesandoEste ? null : () => _elegir(productoId, codigo),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (info != null)
                    CircleAvatar(
                        radius: 28,
                        backgroundColor: fondoAvatar,
                        child: Image.asset(info.asset, width: 42, height: 42))
                  else
                    CircleAvatar(radius: 28, backgroundColor: t.surface2),
                  const SizedBox(height: 8),
                  Text(Catalogos.producto(context, producto['codigo'], producto['nombre']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                  const SizedBox(height: 4),
                  if (procesandoEste)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Text(l.selElegirGratis,
                        style: TextStyle(color: t.primary, fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
