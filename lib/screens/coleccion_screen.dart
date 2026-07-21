import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/paletas_premium.dart';
import 'tienda_screen.dart';

class _Seccion {
  final String categoriaBackend;
  final String titulo;
  final String emoji;
  const _Seccion(this.categoriaBackend, this.titulo, this.emoji);
}

// Orden y nombres fijos de esta app — el motor (categoria en backend) sigue siendo genérico.
const _seccionesConocidas = [
  _Seccion('Protección', 'Consumibles', '🛡️'),
  _Seccion('Tema', 'Temas', '🎨'),
];

class ColeccionScreen extends StatefulWidget {
  final int usuarioId;
  const ColeccionScreen({super.key, required this.usuarioId});

  @override
  State<ColeccionScreen> createState() => _ColeccionScreenState();
}

class _ColeccionScreenState extends State<ColeccionScreen> {
  bool _loading = true;
  List<dynamic> _catalogo = [];
  Map<int, Map<String, dynamic>> _inventario = {};
  int? _procesando;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
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
        _catalogo = catalogo;
        _inventario = mapaInventario;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _equipar(int productoId, String? codigo) async {
    setState(() => _procesando = productoId);
    try {
      await ApiService.equiparProducto(widget.usuarioId, productoId);
      await guardarTemaPremiumEquipado(codigo);
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

  void _irATienda() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TiendaScreen(usuarioId: widget.usuarioId)),
    );
  }

  Map<String, List<dynamic>> _agruparPorCategoria() {
    final mapa = <String, List<dynamic>>{};
    for (final p in _catalogo) {
      mapa.putIfAbsent(p['categoria'] as String, () => []).add(p);
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final agrupado = _agruparPorCategoria();
    final categoriasConocidas = _seccionesConocidas.map((s) => s.categoriaBackend).toSet();
    final categoriasExtra = agrupado.keys.where((c) => !categoriasConocidas.contains(c));

    return Scaffold(
      appBar: AppBar(title: const Text('Colección')),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final seccion in _seccionesConocidas)
              if (agrupado.containsKey(seccion.categoriaBackend))
                _seccionWidget(seccion.titulo, seccion.emoji, agrupado[seccion.categoriaBackend]!, t),
            for (final categoria in categoriasExtra)
              _seccionWidget(categoria, '📦', agrupado[categoria]!, t),
          ],
        ),
      ),
    );
  }

  Widget _seccionWidget(String titulo, String emoji, List<dynamic> productos, TokensContextuales t) {
    final algunoPoseido = productos.any((p) => _inventario.containsKey(p['productoId']));

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $titulo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
          const SizedBox(height: 8),
          if (!algunoPoseido) _ganchoTienda(titulo, t),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: productos.length,
            itemBuilder: (context, i) => _tarjetaProducto(productos[i], t),
          ),
        ],
      ),
    );
  }

  Widget _ganchoTienda(String titulo, TokensContextuales t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _irATienda,
        child: Text('Descubre $titulo en la tienda →',
            style: TextStyle(color: t.primary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _tarjetaProducto(dynamic producto, TokensContextuales t) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final tipo = producto['tipo'] as String;
    final info = _inventario[productoId];
    final poseido = info != null;
    final equipado = info?['equipado'] == true;
    final cantidad = info?['cantidad'] ?? 0;
    final procesandoEste = _procesando == productoId;
    final paleta = codigo != null ? catalogoPaletas[codigo] : null;

    if (!poseido) {
      return _tarjetaBloqueada(producto, paleta, t);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(producto['nombre'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                ),
              ],
            ),
            if (paleta != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  _swatch(paleta.primary),
                  _swatch(paleta.success),
                  _swatch(paleta.points),
                ],
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: procesandoEste
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _accionPoseido(productoId, tipo, equipado, cantidad, codigo, t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accionPoseido(int productoId, String tipo, bool equipado, int cantidad,
      String? codigo, TokensContextuales t) {
    if (tipo == 'EQUIPABLE') {
      if (equipado) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: t.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Equipado',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.primary, fontSize: 12, fontWeight: FontWeight.bold)),
        );
      }
      return OutlinedButton(
        onPressed: () => _equipar(productoId, codigo),
        child: const Text('Equipar'),
      );
    }

    // CONSUMIBLE
    return ElevatedButton(
      onPressed: cantidad > 0 ? () => _usar(productoId) : null,
      child: Text('Usar (x$cantidad)'),
    );
  }

  Widget _tarjetaBloqueada(dynamic producto, Paleta? paleta, TokensContextuales t) {
    return Opacity(
      opacity: 0.55,
      child: GestureDetector(
        onTap: _irATienda,
        child: Card(
          color: t.surface2,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(producto['nombre'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, color: t.textMuted)),
                    if (paleta != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _swatch(paleta.primary.withOpacity(0.5)),
                          _swatch(paleta.success.withOpacity(0.5)),
                          _swatch(paleta.points.withOpacity(0.5)),
                        ],
                      ),
                    ],
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Text('🔒', style: TextStyle(fontSize: 18, color: t.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swatch(Color color) => Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      );
}