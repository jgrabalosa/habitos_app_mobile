import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/catalogos.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/paletas_premium.dart';
import '../theme/avatares.dart';
import 'tienda_screen.dart';
import '../widgets/skeleton.dart';
import '../widgets/selector_avatar_gratis.dart';

class SeccionColeccion {
  /// Una seccion puede recoger varias categorias del backend: alli
  /// 'Protección' y 'Consumible' son etiquetas distintas, pero de cara al
  /// usuario son lo mismo y van juntas.
  final List<String> categoriasBackend;
  final String emoji;
  /// Clave de traduccion resuelta al pintar. Las categorias que llegan del
  /// backend y no conocemos caen a su propio texto crudo.
  final String Function(AppLocalizations)? _titulo;
  const SeccionColeccion(this.categoriasBackend, this.emoji, [this._titulo]);

  String titulo(AppLocalizations l) => _titulo?.call(l) ?? categoriasBackend.first;
}

// Orden fijo de esta app — el motor (categoria en backend) sigue siendo generico.
final seccionesConocidas = [
  SeccionColeccion(['Avatar'], '🧑', (l) => l.colSeccionAvatares),
  SeccionColeccion(['Protección', 'Consumible'], '🛡️', (l) => l.colSeccionConsumibles),
  SeccionColeccion(['Tema'], '🎨', (l) => l.colSeccionTemas),
];

/// Reparte los productos ya agrupados por categoria de backend en las
/// secciones de la pantalla, en el orden declarado arriba. Las categorias que
/// no conoce ninguna seccion caen cada una en la suya, con su texto crudo.
///
/// Vive fuera del State para poder probarlo sin montar el widget.
List<(SeccionColeccion, List<dynamic>)> repartirEnSecciones(
    Map<String, List<dynamic>> agrupado) {
  final conocidas = seccionesConocidas.expand((s) => s.categoriasBackend).toSet();

  // Los productos de una seccion son la union de sus categorias, en el orden
  // en que estan declaradas.
  List<dynamic> productosDe(SeccionColeccion s) =>
      [for (final c in s.categoriasBackend) ...?agrupado[c]];

  return [
    for (final seccion in seccionesConocidas)
      if (productosDe(seccion).isNotEmpty) (seccion, productosDe(seccion)),
    for (final categoria in agrupado.keys.where((c) => !conocidas.contains(c)))
      (SeccionColeccion([categoria], '📦'), agrupado[categoria]!),
  ];
}

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

  void _mostrarError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.colError)),
      );
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
    final l = AppLocalizations.of(context)!;

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
    final seccionesConProductos = repartirEnSecciones(_agruparPorCategoria());

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (seccion, productos) in seccionesConProductos)
            _seccionWidget(l, seccion, productos, t),
        ],
      ),
    );
  }

  Widget _seccionWidget(AppLocalizations l, SeccionColeccion seccion, List<dynamic> productos,
      TokensContextuales t) {
    final algunoPoseido = productos.any((p) => _inventario.containsKey(p['productoId']));
    final esAvatarSinElegir =
        seccion.categoriasBackend.contains('Avatar') && !algunoPoseido;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${seccion.emoji} ${seccion.titulo(l)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
          const SizedBox(height: 8),
          if (esAvatarSinElegir) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.colEligeAvatar,
                  style: TextStyle(color: t.primary, fontWeight: FontWeight.w600)),
            ),
            SelectorAvatarGratis(
              usuarioId: widget.usuarioId,
              onElegido: (_) => _cargarDatos(),
            ),
          ] else ...[
            if (!algunoPoseido) _ganchoTienda(l, seccion.titulo(l), t),
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
              itemBuilder: (context, i) => _tarjetaProducto(l, productos[i], t),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ganchoTienda(AppLocalizations l, String titulo, TokensContextuales t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _irATienda,
        child: Text(l.colDescubre(titulo),
            style: TextStyle(color: t.primary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _tarjetaProducto(AppLocalizations l, dynamic producto, TokensContextuales t) {
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
                  CircleAvatar(radius: 14, backgroundColor: avatarInfo.color.withValues(alpha: 0.25),
                      child: Text(avatarInfo.emoji, style: const TextStyle(fontSize: 14))),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(Catalogos.producto(context, producto['codigo'], producto['nombre']),
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
                  : _accionPoseido(l, productoId, tipo, equipado, cantidad, codigo, categoria, t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accionPoseido(AppLocalizations l, int productoId, String tipo, bool equipado, int cantidad,
      String? codigo, String categoria, TokensContextuales t) {
    if (tipo == 'EQUIPABLE') {
      if (equipado) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: t.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(l.tiendaEquipado,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.primary, fontSize: 12, fontWeight: FontWeight.bold)),
        );
      }
      return OutlinedButton(
        onPressed: () => _equipar(productoId, codigo, categoria),
        child: Text(l.tiendaEquipar),
      );
    }

    // CONSUMIBLE
    return ElevatedButton(
      onPressed: cantidad > 0 ? () => _usar(productoId) : null,
      child: Text(l.tiendaUsar(cantidad)),
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
                      CircleAvatar(radius: 14, backgroundColor: avatarInfo.color.withValues(alpha: 0.2),
                          child: Opacity(opacity: 0.5,
                              child: Text(avatarInfo.emoji, style: const TextStyle(fontSize: 14)))),
                      const SizedBox(height: 6),
                    ],
                    Text(Catalogos.producto(context, producto['codigo'], producto['nombre']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, color: t.textMuted)),
                    if (paleta != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _swatch(paleta.primary.withValues(alpha: 0.5)),
                          _swatch(paleta.success.withValues(alpha: 0.5)),
                          _swatch(paleta.points.withValues(alpha: 0.5)),
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