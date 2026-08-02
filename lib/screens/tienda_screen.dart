import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/catalogos.dart';
import '../l10n/mensajes_error.dart';
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

      if (!mounted) return;
      setState(() {
        _saldo = saldo;
        _catalogo = catalogo;
        _inventario = mapaInventario;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarError(e);
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: AppLocalizations.of(context)!.tiendaError)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.tiendaTitulo)),
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
                          Text(l.puntos, style: TextStyle(color: t.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l.tiendaCatalogo,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
                  const SizedBox(height: 8),
                  ..._catalogo.map((producto) => _productoCard(l, producto, t)),
                ],
              ),
            ),
    );
  }

  Widget _productoCard(AppLocalizations l, dynamic producto, TokensContextuales t) {
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
      // El ripple de la previsualización tiene que respetar las esquinas.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Sólo los temas se pueden previsualizar: del resto no hay nada que
        // enseñar que no esté ya en la propia tarjeta.
        onTap: paleta != null
            ? () => _abrirPrevisualizacion(l, producto, paleta)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconoProducto(categoria, codigo, icono),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(Catalogos.producto(context, producto['codigo'], producto['nombre']),
                        style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                  ),
                  if (equipado)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(l.tiendaEquipado,
                          style: TextStyle(
                              color: t.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                  Catalogos.productoDescripcion(
                      context, producto['codigo'], producto['descripcion']),
                  style: TextStyle(color: t.textMuted)),
              if (paleta != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _swatch(paleta.bg),
                    _swatch(paleta.primary),
                    _swatch(paleta.success),
                    _swatch(paleta.points),
                    const Spacer(),
                    // Pista de que la tarjeta se puede tocar para verlo.
                    Icon(LucideIcons.eye, size: 16, color: t.textMuted),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.tiendaPrecio(producto['precio'] as int),
                      style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w600)),
                  _botonAccion(l, productoId, tipo, poseido, equipado, cantidad, codigo, categoria, procesandoEste),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Los avatares se ven, no se describen: si el código está en el catálogo se
  /// pinta el PNG real. Cualquier otra cosa —incluido un avatar que este
  /// cliente aún no conozca— cae al emoji de su categoría.
  Widget _iconoProducto(String categoria, String? codigo, String emoji) {
    final avatar = categoria == 'Avatar' && codigo != null
        ? catalogoAvatares[codigo]
        : null;
    if (avatar == null) {
      return Text(emoji, style: const TextStyle(fontSize: 24));
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: fondoAvatar,
      // El PNG cuadrado no llena el círculo: se deja aire alrededor, igual
      // que en AvatarUsuario.
      child: Image.asset(avatar.asset, width: 24, height: 24),
    );
  }

  Widget _swatch(Color color) => Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      );

  /// Enseña el tema antes de pagarlo. Las acciones cierran la hoja y delegan
  /// en los mismos métodos de la tarjeta: la hoja no duplica nada del estado
  /// de compra, sólo evita el viaje de vuelta.
  void _abrirPrevisualizacion(AppLocalizations l, dynamic producto, Paleta paleta) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final categoria = producto['categoria'] as String;
    final info = _inventario[productoId];
    final poseido = info != null;
    final equipado = info?['equipado'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Catalogos.producto(context, codigo, producto['nombre']),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _maquetaTema(l, paleta),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(hoja),
                      child: Text(l.comunCerrar),
                    ),
                  ),
                  // Ya equipado no hay nada que ofrecer: sólo mirarlo.
                  if (!equipado) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(hoja);
                          if (poseido) {
                            _equipar(productoId, codigo, categoria);
                          } else {
                            _comprar(productoId);
                          }
                        },
                        child: Text(poseido ? l.tiendaEquipar : l.tiendaComprar),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Maqueta aislada: una pantalla de mentira pintada con los nueve colores de
  /// [p]. Ni un color sale del tema activo, así que lo que se ve aquí es el
  /// tema que se está mirando, no el que se lleva puesto.
  Widget _maquetaTema(AppLocalizations l, Paleta p) {
    // Sobre el primary puede ir texto claro u oscuro según lo vivo que sea:
    // hay paletas con primary casi blanco y otras con primary casi negro.
    final sobrePrimary =
        p.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.navHoy,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: p.text)),
              ),
              _pastilla(icono: LucideIcons.coins, texto: '120', color: p.points),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: p.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.circleCheckBig, size: 20, color: p.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.plantillaBeberAgua,
                          style: TextStyle(fontWeight: FontWeight.w600, color: p.text)),
                    ),
                    _pastilla(icono: LucideIcons.flame, texto: '5', color: p.streak),
                  ],
                ),
                const SizedBox(height: 10),
                Text(l.dashCompletados,
                    style: TextStyle(fontSize: 11, letterSpacing: 0.5, color: p.textMuted)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.7,
                    minHeight: 8,
                    backgroundColor: p.surface2,
                    valueColor: AlwaysStoppedAnimation(p.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: p.primary, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(l.comunContinuar,
                  style: TextStyle(fontWeight: FontWeight.w700, color: sobrePrimary)),
            ),
          ),
        ],
      ),
    );
  }

  /// Pastilla de color de la maqueta (racha, puntos): fondo tenue del mismo
  /// color que el contenido, que es como se pintan en la app de verdad.
  Widget _pastilla({
    required IconData icono,
    required String texto,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 4),
            Text(texto,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _botonAccion(AppLocalizations l, int productoId, String tipo, bool poseido, bool equipado,
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
          child: Text(l.tiendaComprar),
        );
      }
      if (equipado) {
        return const SizedBox.shrink();
      }
      return OutlinedButton(
        onPressed: () => _equipar(productoId, codigo, categoria),
        child: Text(l.tiendaEquipar),
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
            child: Text(l.tiendaUsar(cantidad)),
          ),
        ],
      );
    }
    return ElevatedButton(
      onPressed: () => _comprar(productoId),
      child: Text(l.tiendaComprar),
    );
  }
}