import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/mensajes_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/mascota_assets.dart';
import '../widgets/animacion_puntos.dart';
import '../widgets/mascota_animada_viva.dart';
import '../widgets/skeleton.dart';
import 'tienda_screen.dart';

class MascotaScreen extends StatefulWidget {
  final int usuarioId;

  /// Dentro del shell la cabecera ya la pone el shell: un Scaffold propio aquí
  /// pintaría el título dos veces. Abierta como ruta (mini-mascota) sí necesita
  /// la suya, con su botón de volver.
  final bool embebida;

  /// Si la pantalla está a la vista. Dentro del PageView del shell el estado se
  /// mantiene vivo, así que `initState` sólo corre una vez: sin esto, una fase
  /// que cambia mientras el usuario está en otra pestaña no se vería hasta
  /// reiniciar. Abierta como ruta siempre está activa.
  final bool activa;

  const MascotaScreen({
    super.key,
    required this.usuarioId,
    this.embebida = false,
    this.activa = true,
  });

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

  /// Comida disponible. El id del producto sale del propio inventario: el
  /// cliente no cablea ningún identificador de la BD, sólo el código.
  static const _codigoComida = 'COMIDA_BASICA';
  int? _comidaProductoId;
  int _comidaCantidad = 0;
  bool _alimentando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void didUpdateWidget(covariant MascotaScreen anterior) {
    super.didUpdateWidget(anterior);
    // Al volver a la pestaña, no al salir de ella.
    if (!anterior.activa && widget.activa) _cargarDatos();
  }

  Future<void> _cargarDatos() =>
      Future.wait([_cargarMascota(), _cargarInventario()]);

  Future<void> _cargarMascota() async {
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

  /// El inventario es accesorio: si falla, la mascota se sigue viendo y el
  /// botón de alimentar se queda deshabilitado. No se avisa por separado
  /// porque un fallo de red ya lo canta la carga de la mascota.
  Future<void> _cargarInventario() async {
    try {
      final inventario = await ApiService.getInventarioProductos(widget.usuarioId);
      int? productoId;
      int cantidad = 0;
      for (final up in inventario) {
        if (up['producto']?['codigo'] == _codigoComida) {
          productoId = up['producto']['productoId'] as int?;
          cantidad = up['cantidad'] ?? 0;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _comidaProductoId = productoId;
        _comidaCantidad = cantidad;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _comidaCantidad = 0);
    }
  }

  Future<void> _alimentar() async {
    final productoId = _comidaProductoId;
    if (productoId == null || _comidaCantidad <= 0 || _alimentando) return;

    setState(() => _alimentando = true);
    try {
      final resultado = await ApiService.usarProducto(widget.usuarioId, productoId);
      if (!mounted) return;
      // Consumir la comida siempre da XP; subir de nivel es el caso vistoso.
      if (resultado['subioNivel'] == true || resultado['codigoConsumido'] != null) {
        AnimacionPuntos.mostrar(context, 10, simbolo: 'XP');
      }
      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: AppLocalizations.of(context)!.mascotaErrorAlimentar)),
        ),
      );
    } finally {
      if (mounted) setState(() => _alimentando = false);
    }
  }

  String get _imagenMascota => assetMascota(fase: _fase, estado: _estado);

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

  /// Nori manda en la pantalla: ocupa casi tres cuartos del ancho. Los topes
  /// suben con el factor, pero el de arriba se queda algo por debajo de la
  /// proporción exacta (serían 372): en tablet el ancho crece mucho más que el
  /// alto, y pasado ese punto Nori empuja los botones fuera de la pantalla.
  double _tamanoMascota(BuildContext context) =>
      (MediaQuery.sizeOf(context).width * 0.72).clamp(185.0, 360.0);

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final pct = _xpParaSiguienteNivel > 0 ? _xpEnNivelActual / _xpParaSiguienteNivel : 0.0;

    final contenido = _loading
          ? _skeletonMascota(context)
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              // El scroll se conserva aunque el contenido quepa de sobra: es lo
              // que da el gesto de tirar para refrescar. Lo que añade el
              // LayoutBuilder es el `minHeight` del viewport, para que la
              // Column pueda centrarse verticalmente en ese hueco en vez de
              // apelotonarse arriba. Restamos el padding vertical (8 + 24)
              // porque el mínimo se aplica al contenido ya despadeado: sin eso
              // la pantalla scrollearía siempre 32px de más.
              child: LayoutBuilder(
                builder: (context, restricciones) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // El clamp cubre el viewport más bajo que el propio
                      // padding: un mínimo negativo revienta BoxConstraints.
                      minHeight: (restricciones.maxHeight - 32).clamp(0.0, double.infinity),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // Como hacía el ListView: los hijos ocupan todo el ancho,
                      // que es de lo que tiran la barra de XP y la fila de
                      // nivel.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child:
                                  ScaleTransition(scale: animation, child: child),
                            ),
                            child: MascotaAnimadaViva(
                              // La clave es la ilustración, no el estado: el
                              // AnimatedSwitcher tiene que cruzar cuando
                              // cambia lo que se ve.
                              key: ValueKey(_imagenMascota),
                              fase: _fase,
                              estado: _estado,
                              tamano: _tamanoMascota(context),
                              permiteToque: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: GestureDetector(
                            onTap: _editarNombre,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_nombreVisible(l),
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: t.text)),
                                const SizedBox(width: 6),
                                Icon(LucideIcons.pencil,
                                    size: 16, color: t.textMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                              '${_faseLegible(l)} · ${_estadoLegible(l)}',
                              style: TextStyle(color: t.textMuted)),
                        ),
                        const SizedBox(height: 20),
                        // Progreso desnudo, sin tarjeta: acompaña a Nori en vez
                        // de competir con ella por la atención.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.mascotaNivel(_nivel),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, color: t.text)),
                            Text(
                                l.mascotaXp(
                                    _xpEnNivelActual, _xpParaSiguienteNivel),
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              // Sin comida el botón sigue a la vista, apagado:
                              // es la pista de que hay algo que comprar en la
                              // tienda.
                              onPressed: _comidaCantidad > 0 && !_alimentando
                                  ? _alimentar
                                  : null,
                              icon: _alimentando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(LucideIcons.drumstick, size: 18),
                              label: Text(
                                  '${l.mascotaAlimentar} ($_comidaCantidad)'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TiendaScreen(
                                        usuarioId: widget.usuarioId),
                                  ),
                                ).then((_) => _cargarDatos());
                              },
                              icon: const Icon(LucideIcons.store, size: 18),
                              label: Text(l.tiendaTitulo),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

    if (widget.embebida) return contenido;

    return Scaffold(
      appBar: AppBar(title: Text(l.mascotaTitulo)),
      body: contenido,
    );
  }

  Widget _skeletonMascota(BuildContext context) {
    final lado = _tamanoMascota(context);
    return SkeletonPulso(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Center(child: SkeletonBox(width: lado, height: lado, radius: lado / 2)),
          const SizedBox(height: 16),
          const Center(child: SkeletonBox(width: 160, height: 26)),
          const SizedBox(height: 10),
          const Center(child: SkeletonBox(width: 110, height: 14)),
          const SizedBox(height: 24),
          const SkeletonBox(height: 14),
          const SizedBox(height: 12),
          const SkeletonBox(height: 10, radius: 999),
          const SizedBox(height: 28),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBox(width: 130, height: 40, radius: 20),
              SizedBox(width: 12),
              SkeletonBox(width: 110, height: 40, radius: 20),
            ],
          ),
        ],
      ),
    );
  }
}
