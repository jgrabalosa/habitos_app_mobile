import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/paletas_premium.dart';
import '../theme/avatares.dart';

class TiendaScreen extends StatefulWidget {
  final int usuarioId;
  const TiendaScreen({super.key, required this.usuarioId});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  bool _loading = true;
  int _saldo = 0;
  List<dynamic> _catalogo = [];
  // productoId -> {cantidad, equipado}
  Map<int, Map<String, dynamic>> _inventario = {};
  int? _procesando;

  static const iconosCategoria = {
    'Tema': '🎨',
    'Protección': '🛡️',
    'Avatar': '🧑',
  };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final saldo = await ApiService.getSaldoPuntos(widget.usuarioId);
      final catalogo = await ApiService.getCatalogoProductos();
      final inventario = await ApiService.getInventarioProductos(widget.usuarioId);

      final mapaInventario = <int, Map<String, dynamic>>{};
      for (final up in inventario) {
        final productoId = up['producto']['productoId'] as int;
        mapaInventario[productoId] = {
          'cantidad': up['cantidad'],
          'equipado': up['equipado'],
        };
      }

      setState(() {
        _saldo = saldo;
        _catalogo = catalogo;
        _inventario = mapaInventario;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _comprar(int productoId) async {
    setState(() => _procesando = productoId);
    try {
      await ApiService.comprarProducto(widget.usuarioId, productoId);
      await _cargarDatos();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  Future<void> _equipar(int productoId, String? codigo, String categoria) async {
    setState(() => _procesando = productoId);
    try {
      await ApiService.equiparProducto(widget.usuarioId, productoId);
      if (categoria == 'Tema') {
        await guardarTemaEquipado(codigo);
      } else if (categoria == 'Avatar') {
        await guardarAvatarEquipado(codigo);
      }
      await _cargarDatos();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  Future<void> _usar(int productoId) async {
    setState(() => _procesando = productoId);
    try {
      await ApiService.usarProducto(widget.usuarioId, productoId);
      await _cargarDatos();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  void _mostrarError(Object e) {
    final mensaje = e.toString().replaceFirst('Exception: ', '');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tienda')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(LucideIcons.coins, color: t.points, size: 40),
                          const SizedBox(height: 8),
                          Text('$_saldo',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800, color: t.text)),
                          Text('puntos', style: TextStyle(color: t.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Catálogo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
                  const SizedBox(height: 8),
                  ..._catalogo.map((producto) => _productoCard(producto, t)),
                ],
              ),
            ),
    );
  }

  Widget _productoCard(dynamic producto, TokensContextuales t) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final tipo = producto['tipo'] as String;
    final categoria = producto['categoria'] as String;
    final icono = iconosCategoria[categoria] ?? '📦';
    final info = _inventario[productoId];
    final poseido = info != null;
    final equipado = info?['equipado'] == true;
    final cantidad = info?['cantidad'] ?? 0;
    final procesandoEste = _procesando == productoId;
    final paleta = codigo != null ? catalogoPaletas[codigo] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icono, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(producto['nombre'],
                      style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                ),
                if (equipado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Equipado',
                        style: TextStyle(
                            color: t.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(producto['descripcion'], style: TextStyle(color: t.textMuted)),
            if (paleta != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _swatch(paleta.bg),
                  _swatch(paleta.primary),
                  _swatch(paleta.success),
                  _swatch(paleta.points),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${producto['precio']} pts',
                    style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w600)),
                _botonAccion(productoId, tipo, poseido, equipado, cantidad, codigo, categoria, procesandoEste),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color) => Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      );

  Widget _botonAccion(int productoId, String tipo, bool poseido, bool equipado,
      int cantidad, String? codigo, String categoria, bool procesando) {
    if (procesando) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (tipo == 'EQUIPABLE') {
      if (!poseido) {
        return ElevatedButton(
          onPressed: () => _comprar(productoId),
          child: const Text('Comprar'),
        );
      }
      if (equipado) {
        return const SizedBox.shrink();
      }
      return OutlinedButton(
        onPressed: () => _equipar(productoId, codigo, categoria),
        child: const Text('Equipar'),
      );
    }

    // CONSUMIBLE
    if (cantidad > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _comprar(productoId),
            child: const Text('+1'),
          ),
          ElevatedButton(
            onPressed: () => _usar(productoId),
            child: Text('Usar (x$cantidad)'),
          ),
        ],
      );
    }
    return ElevatedButton(
      onPressed: () => _comprar(productoId),
      child: const Text('Comprar'),
    );
  }
}