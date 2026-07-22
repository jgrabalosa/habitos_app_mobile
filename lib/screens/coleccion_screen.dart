import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/paletas_premium.dart';
import '../theme/avatares.dart';
import 'tienda_screen.dart';
import '../widgets/skeleton.dart';

class _Seccion {
  final String categoriaBackend;
  final String titulo;
  final String emoji;
  const _Seccion(this.categoriaBackend, this.titulo, this.emoji);
}

// Orden y nombres fijos de esta app — el motor (categoria en backend) sigue siendo genérico.
const _seccionesConocidas = [
  _Seccion('Avatar', 'Avatares', '🧑'),
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

  // categoria: para saber qué caché de equipado actualizar (Tema/Avatar) sin
  // pisar la de la otra — antes esto llamaba siempre a guardarTemaEquipado,
  // lo que borraba el tema premium equipado al elegir un avatar.
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

  // Regla puente: elegir el primer avatar gratis (una sola vez, hasta que
  // exista la pantalla de Bienvenida de Fase 4, que reutilizará esta lógica).
  Future<void> _elegirAvatarGratis(int productoId, String? codigo) async {
    setState(() => _procesando = productoId);
    try {
      await ApiService.otorgarProducto(widget.usuarioId, productoId);
      await ApiService.equiparProducto(widget.usuarioId, productoId);
      await guardarAvatarEquipado(codigo);
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
      return SkeletonPulso(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: 6,
          itemBuilder: (context, i) => const SkeletonBox(height: double.infinity, radius: AppRadius.lg),
        ),
      );
    }
    final agrupado = _agruparPorCategoria();
    final categoriasConocidas = _seccionesConocidas.map((s) => s.categoriaBackend).toSet();
    final categoriasExtra = agrupado.keys.where((c) => !categoriasConocidas.contains(c));

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final seccion in _seccionesConocidas)
            if (agrupado.containsKey(seccion.categoriaBackend))
              _seccionWidget(seccion, agrupado[seccion.categoriaBackend]!, t),
          for (final categoria in categoriasExtra)
            _seccionWidget(_Seccion(categoria, categoria, '📦'), agrupado[categoria]!, t),
        ],
      ),
    );
  }

  Widget _seccionWidget(_Seccion seccion, List<dynamic> productos, TokensContextuales t) {
    final algunoPoseido = productos.any((p) => _inventario.containsKey(p['productoId']));
    final esAvatarSinElegir = seccion.categoriaBackend == 'Avatar' && !algunoPoseido;
    final itemCount = productos.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${seccion.emoji} ${seccion.titulo}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
          const SizedBox(height: 8),
          if (esAvatarSinElegir)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Elige tu primer avatar gratis 👇',
                  style: TextStyle(color: t.primary, fontWeight: FontWeight.w600)),
            )
          else if (!algunoPoseido)
            _ganchoTienda(seccion.titulo, t),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: itemCount,
            itemBuilder: (context, i) {
              return esAvatarSinElegir
                  ? _tarjetaAvatarGratis(productos[i], t)
                  : _tarjetaProducto(productos[i], t);
            },
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

  // Tarjeta especial mientras el usuario no tiene ningún avatar: tap = elegir
  // ese como el gratis (no hay candado ni enlace a tienda todavía).
  Widget _tarjetaAvatarGratis(dynamic producto, TokensContextuales t) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final info = codigo != null ? catalogoAvatares[codigo] : null;
    final procesandoEste = _procesando == productoId;

    return GestureDetector(
      onTap: procesandoEste ? null : () => _elegirAvatarGratis(productoId, codigo),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (info != null)
                CircleAvatar(radius: 28, backgroundColor: info.color.withOpacity(0.25),
                    child: Text(info.emoji, style: const TextStyle(fontSize: 28)))
              else
                CircleAvatar(radius: 28, backgroundColor: t.surface2),
              const SizedBox(height: 8),
              Text(producto['nombre'], maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
              const SizedBox(height: 4),
              if (procesandoEste)
                const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                Text('Elegir gratis', style: TextStyle(color: t.primary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaProducto(dynamic producto, TokensContextuales t) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final tipo = producto['tipo'] as String;
    final categoria = producto['categoria'] as String;
    final info = _inventario[productoId];
    final poseido = info != null;
    final equipado = info?['equipado'] == true;
    final cantidad = info?['cantidad'] ?? 0;
    final procesandoEste = _procesando == productoId;
    final paleta = categoria == 'Tema' && codigo != null ? catalogoPaletas[codigo] : null;
    final avatarInfo = categoria == 'Avatar' && codigo != null ? catalogoAvatares[codigo] : null;

    if (!poseido) {
      return _tarjetaBloqueada(producto, paleta, avatarInfo, t);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (avatarInfo != null) ...[
                  CircleAvatar(radius: 14, backgroundColor: avatarInfo.color.withOpacity(0.25),
                      child: Text(avatarInfo.emoji, style: const TextStyle(fontSize: 14))),
                  const SizedBox(width: 6),
                ],
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
                  : _accionPoseido(productoId, tipo, equipado, cantidad, codigo, categoria, t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accionPoseido(int productoId, String tipo, bool equipado, int cantidad,
      String? codigo, String categoria, TokensContextuales t) {
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
        onPressed: () => _equipar(productoId, codigo, categoria),
        child: const Text('Equipar'),
      );
    }

    // CONSUMIBLE
    return ElevatedButton(
      onPressed: cantidad > 0 ? () => _usar(productoId) : null,
      child: Text('Usar (x$cantidad)'),
    );
  }

  Widget _tarjetaBloqueada(dynamic producto, Paleta? paleta, AvatarInfo? avatarInfo, TokensContextuales t) {
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
                    if (avatarInfo != null) ...[
                      CircleAvatar(radius: 14, backgroundColor: avatarInfo.color.withOpacity(0.2),
                          child: Opacity(opacity: 0.5,
                              child: Text(avatarInfo.emoji, style: const TextStyle(fontSize: 14)))),
                      const SizedBox(height: 6),
                    ],
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