import 'dart:async';

import 'package:flutter/material.dart';
import 'package:norday_flutter_core/models/precio_tienda.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/recorrido_onboarding.dart';

/// La tarjeta que regala el gorro de Papá Noel al entrar en la app: Nori con
/// el gorro puesto y un solo botón que se lo da.
///
/// Sale mientras dure la oferta a 0 y sólo a quien aún no lo tiene. No guarda
/// nada en el móvil: deja de salir sola cuando acaba la oferta o cuando ya lo
/// tiene. Como la bienvenida, no se cierra tocando fuera ni con atrás; y
/// tampoco deja atrapado a nadie: si la compra falla, se cierra igual y vuelve
/// a salir en la siguiente apertura.
class RegaloGorro {
  static const codigoGorro = 'PRENDA_GORRO_NOEL';
  static const _sitio = 'Cabeza';

  /// Seams de test, como los de `TiendaScreen`. En producción, el core.
  @visibleForTesting
  static Future<List<dynamic>> Function() obtenerCatalogo =
      ApiServiceCore.getCatalogoProductos;

  @visibleForTesting
  static Future<List<dynamic>> Function(int) obtenerInventario =
      ApiServiceCore.getInventarioProductos;

  @visibleForTesting
  static Future<List<String>> Function(int, int) comprar =
      ApiServiceCore.comprarProducto;

  @visibleForTesting
  static Future<List<String>> Function(int, int, String, String) equipar =
      Equipamiento.equiparPrenda;

  /// La fecha del móvil, con la que se elige la oferta vigente.
  @visibleForTesting
  static DateTime Function() ahora = DateTime.now;

  @visibleForTesting
  static void reiniciarParaTest() {
    obtenerCatalogo = ApiServiceCore.getCatalogoProductos;
    obtenerInventario = ApiServiceCore.getInventarioProductos;
    comprar = ApiServiceCore.comprarProducto;
    equipar = Equipamiento.equiparPrenda;
    ahora = DateTime.now;
  }

  /// Enseña la tarjeta si toca; si no, o si algo falla, no pasa nada.
  ///
  /// [altaNueva]: quien se acaba de registrar la ve en la siguiente apertura.
  /// Se completa al cerrarse la tarjeta (o enseguida si no sale).
  static Future<void> mostrarSiToca(
    BuildContext context, {
    required int usuarioId,
    required bool altaNueva,
  }) async {
    if (altaNueva || RecorridoOnboarding.instancia.activo) return;

    final int productoId;
    final bool llevaCabeza;
    try {
      final catalogo = await obtenerCatalogo();
      final inventario = await obtenerInventario(usuarioId);

      final gorro = catalogo.whereType<Map>().where(
        (p) => p['codigo'] == codigoGorro,
      );
      if (gorro.isEmpty) return;
      final precio = precioEnTienda(gorro.first, ahora());
      if (precio == null || !precio.gratis) return;
      final id = gorro.first['productoId'];
      if (id is! int) return;

      var loTiene = false;
      var cabeza = false;
      for (final up in inventario) {
        if (up is! Map) continue;
        final producto = up['producto'];
        if (producto is! Map) continue;
        if (producto['productoId'] == id) loTiene = true;
        if (up['equipado'] == true && producto['categoria'] == _sitio) {
          cabeza = true;
        }
      }
      if (loTiene) return;
      productoId = id;
      llevaCabeza = cabeza;
    } catch (_) {
      return;
    }
    if (!context.mounted) return;

    unawaited(AnalyticsHabitos.regaloGorroVisto());
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _RegaloGorroContenido(
        usuarioId: usuarioId,
        productoId: productoId,
        llevaCabeza: llevaCabeza,
      ),
      transitionBuilder: (context, anim, anim2, child) {
        final curva = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curva, child: child),
        );
      },
    );
  }
}

class _RegaloGorroContenido extends StatefulWidget {
  final int usuarioId;
  final int productoId;
  final bool llevaCabeza;

  const _RegaloGorroContenido({
    required this.usuarioId,
    required this.productoId,
    required this.llevaCabeza,
  });

  @override
  State<_RegaloGorroContenido> createState() => _RegaloGorroContenidoState();
}

class _RegaloGorroContenidoState extends State<_RegaloGorroContenido> {
  bool _procesando = false;

  /// Lo que lleva Nori más el gorro. Fijo mientras la tarjeta está abierta,
  /// como en la hoja «Probar» de la tienda.
  late final ValueNotifier<Map<String, String>> _puesta = ValueNotifier(
    Map.unmodifiable({
      ...prendasEquipadasNotifier.value,
      RegaloGorro._sitio: RegaloGorro.codigoGorro,
    }),
  );

  @override
  void dispose() {
    _puesta.dispose();
    super.dispose();
  }

  Future<void> _coger() async {
    setState(() => _procesando = true);
    final navegador = Navigator.of(context);
    var logros = <String>[];
    String resultado;
    try {
      logros = await RegaloGorro.comprar(widget.usuarioId, widget.productoId);
      resultado = 'ok';
    } on ApiException catch (e) {
      // Ya era suyo: otro móvil o un doble toque. Cuenta como hecho.
      resultado = e.codigoEstado == 409 ? 'ya_lo_tenia' : 'fallo';
    } catch (_) {
      resultado = 'fallo';
    }
    unawaited(AnalyticsHabitos.regaloGorroCogido(resultado));

    if (resultado != 'fallo' && !widget.llevaCabeza) {
      try {
        logros = [
          ...logros,
          ...await RegaloGorro.equipar(
            widget.usuarioId,
            widget.productoId,
            RegaloGorro.codigoGorro,
            RegaloGorro._sitio,
          ),
        ];
      } catch (_) {
        // El gorro ya es suyo: se podrá equipar desde la tienda.
      }
    }

    navegador.pop();
    if (logros.isNotEmpty) await CelebracionService.mostrar(logros);
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final tema = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: SuperficieIdentidad(
                    protagonista: true,
                    relleno: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 128,
                          height: 128,
                          child: NoriVestida(
                            fase: 'CRIA',
                            estado: 'feliz',
                            tamano: 128,
                            prendas: _puesta,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.regaloGorroTitulo,
                          textAlign: TextAlign.center,
                          style: tema.headlineMedium?.copyWith(color: t.text),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.regaloGorroCuerpo,
                          textAlign: TextAlign.center,
                          style: tema.bodyMedium?.copyWith(color: t.textMuted),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _procesando ? null : _coger,
                            child: _procesando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l.regaloGorroBoton),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
