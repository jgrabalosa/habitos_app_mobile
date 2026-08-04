import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/app_localizations.dart';
import '../l10n/catalogos.dart';
import '../l10n/mensajes_error.dart';
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
  final IconData icono;
  /// Clave de traduccion resuelta al pintar. Las categorias que llegan del
  /// backend y no conocemos caen a su propio texto crudo.
  final String Function(AppLocalizations)? _titulo;
  const SeccionColeccion(this.categoriasBackend, this.icono, [this._titulo]);

  String titulo(AppLocalizations l) => _titulo?.call(l) ?? categoriasBackend.first;
}

// Orden fijo de esta app — el motor (categoria en backend) sigue siendo generico.
final seccionesConocidas = [
  SeccionColeccion(['Avatar'], LucideIcons.userRound, (l) => l.colSeccionAvatares),
  SeccionColeccion(['Protección', 'Consumible'], LucideIcons.shield, (l) => l.colSeccionConsumibles),
  SeccionColeccion(['Tema'], LucideIcons.palette, (l) => l.colSeccionTemas),
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
      (SeccionColeccion([categoria], LucideIcons.package), agrupado[categoria]!),
  ];
}

/// Matriz de luminancia (Rec. 709): apaga el color de lo que aun no se tiene
/// sin tocar el alfa, para que el candado siga leyendose encima.
const _filtroGrises = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

const _opacidadBloqueado = 0.45;

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
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    _cargarNombre();
    _cargarDatos();
  }

  /// Sale de `shared_preferences`, no de la red: la tarjeta de arriba lo
  /// necesita para la inicial de caida cuando no hay avatar equipado.
  Future<void> _cargarNombre() async {
    final usuario = await ApiService.getUsuarioLocal();
    if (!mounted || usuario == null) return;
    setState(() => _nombre = usuario['nombre'] ?? '');
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

      if (!mounted) return;
      setState(() {
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
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: AppLocalizations.of(context)!.colError)),
        ),
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

  /// El producto equipado de una categoria, o null si no hay ninguno — que es
  /// lo normal antes del primer avatar o con el tema de serie.
  dynamic _productoEquipado(String categoria) {
    for (final p in _catalogo) {
      if (p['categoria'] == categoria &&
          _inventario[p['productoId']]?['equipado'] == true) {
        return p;
      }
    }
    return null;
  }

  bool _poseido(dynamic producto) => _inventario.containsKey(producto['productoId']);

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;

    // Ya no es pestaña del shell: se abre como ruta desde el icono de arriba,
    // asi que trae su propia cabecera y su boton de volver.
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navColeccion,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _loading ? _skeletonColeccion() : _contenido(l, t),
    );
  }

  Widget _skeletonColeccion() {
    return const SkeletonPulso(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 130, radius: AppRadius.lg),
            SizedBox(height: 24),
            SkeletonBox(width: 140, height: 16),
            SizedBox(height: 12),
            SkeletonBox(height: 52, radius: AppRadius.lg),
            SizedBox(height: 24),
            SkeletonBox(width: 140, height: 16),
            SizedBox(height: 12),
            SkeletonBox(height: 68, radius: AppRadius.lg),
            SizedBox(height: 8),
            SkeletonBox(height: 68, radius: AppRadius.lg),
          ],
        ),
      ),
    );
  }

  Widget _contenido(AppLocalizations l, TokensContextuales t) {
    final seccionesConProductos = repartirEnSecciones(_agruparPorCategoria());

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardSeleccionActual(l, t),
          const SizedBox(height: 24),
          for (final (seccion, productos) in seccionesConProductos)
            _seccionWidget(l, seccion, productos, t),
        ],
      ),
    );
  }

  /// Resumen de lo que el usuario lleva puesto ahora mismo: avatar (o inicial
  /// de caida) y la paleta del tema equipado.
  Widget _cardSeleccionActual(AppLocalizations l, TokensContextuales t) {
    final codigoTema = _productoEquipado('Tema')?['codigo'] as String?;
    final paleta = codigoTema != null ? catalogoPaletas[codigoTema] : null;
    // Sin tema equipado (o con uno que este cliente aun no conozca) lo que se
    // lleva puesto es el tema de serie: sus colores son los tokens activos.
    final colores = paleta != null
        ? [paleta.primary, paleta.success, paleta.points]
        : [t.primary, t.success, t.points];

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: t.successText, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.colSeleccionActual,
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                    color: t.textMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                AvatarUsuario(nombre: _nombre, radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: t.text)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _tiraPaleta(colores, alto: 14),
          ],
        ),
      ),
    );
  }

  /// Los colores de un tema, uno al lado del otro. Es la representacion del
  /// tema en toda la pantalla: aqui y en su tarjeta.
  Widget _tiraPaleta(List<Color> colores, {required double alto, double radio = 999}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: SizedBox(
        height: alto,
        child: Row(
          children: [for (final c in colores) Expanded(child: ColoredBox(color: c))],
        ),
      ),
    );
  }

  Widget _seccionWidget(AppLocalizations l, SeccionColeccion seccion, List<dynamic> productos,
      TokensContextuales t) {
    final algunoPoseido = productos.any(_poseido);
    final esAvatarSinElegir =
        seccion.categoriasBackend.contains('Avatar') && !algunoPoseido;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabeceraSeccion(l, seccion, productos, t),
          const SizedBox(height: 12),
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
            _cuerpoSeccion(l, seccion, productos, t),
          ],
        ],
      ),
    );
  }

  /// Icono + titulo + cuantos se tienen de cuantos hay, con la misma cuenta
  /// pintada como barra debajo.
  Widget _cabeceraSeccion(AppLocalizations l, SeccionColeccion seccion,
      List<dynamic> productos, TokensContextuales t) {
    final poseidos = productos.where(_poseido).length;
    final total = productos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(seccion.icono, size: 18, color: t.successText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(seccion.titulo(l),
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
            ),
            Text(l.colContador(poseidos, total),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: t.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : poseidos / total,
            minHeight: 4,
            backgroundColor: t.surface2,
            valueColor: AlwaysStoppedAnimation(t.successText),
          ),
        ),
      ],
    );
  }

  Widget _cuerpoSeccion(AppLocalizations l, SeccionColeccion seccion,
      List<dynamic> productos, TokensContextuales t) {
    if (seccion.categoriasBackend.contains('Avatar')) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final p in productos) _chipAvatar(p, t)],
      );
    }
    if (seccion.categoriasBackend.contains('Tema')) {
      return Column(
        children: [for (final p in productos) _tarjetaTema(l, p, t)],
      );
    }
    // Consumibles y cualquier categoria que este cliente aun no conozca: la
    // tarjeta de fila con icono sirve para las dos.
    return Column(
      children: [for (final p in productos) _tarjetaConsumible(l, p, t)],
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

  // ── Avatares ──

  Widget _chipAvatar(dynamic producto, TokensContextuales t) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final info = codigo != null ? catalogoAvatares[codigo] : null;
    final poseido = _poseido(producto);
    final equipado = _inventario[productoId]?['equipado'] == true;
    final procesandoEste = _procesando == productoId;

    // Un avatar que este cliente aun no conozca no rompe la tira: cae al
    // icono generico, como el nombre cae al que manda el backend.
    final Widget imagen = info != null
        ? Image.asset(info.asset, width: 34, height: 34)
        : Icon(LucideIcons.userRound, size: 24, color: t.textMuted);

    return Tooltip(
      message: Catalogos.producto(context, codigo, producto['nombre']),
      child: GestureDetector(
        onTap: procesandoEste
            ? null
            : poseido
                ? (equipado ? null : () => _equipar(productoId, codigo, 'Avatar'))
                : _irATienda,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fondoAvatar,
                  border: equipado
                      ? Border.all(color: t.successText, width: 2.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: poseido
                    ? imagen
                    : Opacity(
                        opacity: _opacidadBloqueado,
                        child: ColorFiltered(colorFilter: _filtroGrises, child: imagen),
                      ),
              ),
              // El candado va fuera del filtro y la opacidad: es lo unico que
              // tiene que seguir leyendose a plena vista.
              if (!poseido) Icon(LucideIcons.lock, size: 18, color: t.text),
              if (procesandoEste)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Temas ──

  Widget _tarjetaTema(AppLocalizations l, dynamic producto, TokensContextuales t) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final paleta = codigo != null ? catalogoPaletas[codigo] : null;
    final poseido = _poseido(producto);
    final equipado = _inventario[productoId]?['equipado'] == true;
    final procesandoEste = _procesando == productoId;

    // Un tema que este cliente aun no conozca no tiene colores que enseñar:
    // la tira se queda neutra y la tarjeta sigue siendo legible.
    final colores = paleta != null
        ? [paleta.primary, paleta.success, paleta.points]
        : [t.surface2, t.surface2, t.surface2];

    final contenido = _cajaTarjeta(
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: _tiraPaleta(colores, alto: 40, radio: AppRadius.sm),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(Catalogos.producto(context, codigo, producto['nombre']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
          ),
          if (poseido) ...[
            const SizedBox(width: 8),
            if (procesandoEste)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (equipado)
              _pastillaEquipado(l, t)
            else
              OutlinedButton(
                onPressed: () => _equipar(productoId, codigo, 'Tema'),
                child: Text(l.tiendaEquipar),
              ),
          ],
        ],
      ),
    );

    if (!poseido) return _envolverBloqueado(contenido, t);
    return contenido;
  }

  Widget _pastillaEquipado(AppLocalizations l, TokensContextuales t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.successText.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(l.tiendaEquipado,
          style: TextStyle(
              color: t.successText, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // ── Consumibles ──

  Widget _tarjetaConsumible(AppLocalizations l, dynamic producto, TokensContextuales t) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final categoria = producto['categoria'] as String;
    final poseido = _poseido(producto);
    final cantidad = (_inventario[productoId]?['cantidad'] ?? 0) as int;
    final procesandoEste = _procesando == productoId;
    // 'Protección' es justo la categoria de lo que se gasta solo cuando hace
    // falta (el escudo salta al romperse la racha); lo demas se usa a mano.
    final automatico = categoria == 'Protección';

    final contenido = _cajaTarjeta(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.successText.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_iconoConsumible(codigo, categoria), size: 22, color: t.successText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Catalogos.producto(context, codigo, producto['nombre']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                if (automatico) ...[
                  const SizedBox(height: 2),
                  Text(l.colSeActivaSolo,
                      style: TextStyle(fontSize: 12, color: t.textMuted)),
                ],
              ],
            ),
          ),
          if (poseido) ...[
            const SizedBox(width: 8),
            Text(l.colCantidad(cantidad),
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
            if (!automatico) ...[
              const SizedBox(width: 10),
              if (procesandoEste)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                ElevatedButton(
                  onPressed: cantidad > 0 ? () => _usar(productoId) : null,
                  child: Text(l.colUsar),
                ),
            ],
          ],
        ],
      ),
    );

    if (!poseido) return _envolverBloqueado(contenido, t);
    return contenido;
  }

  /// Por codigo cuando lo conocemos; si no, por categoria, para que un
  /// consumible nuevo del backend siga saliendo con un icono que dice algo.
  IconData _iconoConsumible(String? codigo, String categoria) => switch (codigo) {
        'ESCUDO_RACHA' => LucideIcons.shield,
        'COMIDA_BASICA' => LucideIcons.drumstick,
        _ => categoria == 'Protección' ? LucideIcons.shield : LucideIcons.package,
      };

  // ── Piezas comunes ──

  /// La caja comun de temas y consumibles: misma Card que el resto de la app,
  /// para que lo unico que cambie entre secciones sea el contenido.
  Widget _cajaTarjeta({required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  /// Lo que aun no se tiene: la misma tarjeta apagada y con candado. Tocarla
  /// lleva a la tienda, que es donde se consigue.
  Widget _envolverBloqueado(Widget tarjeta, TokensContextuales t) {
    return GestureDetector(
      onTap: _irATienda,
      child: Stack(
        children: [
          // El candado se queda fuera del filtro: es lo unico que tiene que
          // seguir leyendose a plena opacidad.
          Opacity(
            opacity: _opacidadBloqueado,
            child: ColorFiltered(
              colorFilter: _filtroGrises,
              child: IgnorePointer(child: tarjeta),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Icon(LucideIcons.lock, size: 16, color: t.text),
          ),
        ],
      ),
    );
  }
}
