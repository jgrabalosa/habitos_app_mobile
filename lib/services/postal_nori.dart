import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:norday_flutter_core/services/arte_prendas_service.dart';
import 'package:norday_flutter_core/services/manifiesto_compartido.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../screens/invitar_screen.dart' show enlaceInvitacion;
import 'analytics_service.dart';

/// Cómo se llama el fichero que se comparte.
const nombreFicheroNori = 'norday-nori.png';

/// Ancho en píxeles de la postal: 1080 × 1350 (la tarjeta mide 360 × 450).
const _anchoPx = 1080.0;

/// Lo más que se espera a que lleguen las imágenes. Pasado el plazo se
/// captura con lo que haya: mejor la postal sin una prenda que ninguna.
const _plazoImagenes = Duration(seconds: 6);

/// La postal de Nori: se pinta fuera de pantalla, se captura a 1080 × 1350 y
/// se abre el menú de compartir con ella y un texto. Es la misma mecánica que
/// `PostalCierre`.
class PostalNori {
  const PostalNori._();

  /// Seam de test: lo que hace el menú nativo de compartir.
  @visibleForTesting
  static Future<ShareResult> Function(ShareParams params) menu = _conSharePlus;

  /// Seam de test: cómo se mide. Por defecto, Analytics.
  @visibleForTesting
  static Future<void> Function({
    required String identidad,
    required String fase,
  })
  medir = AnalyticsHabitos.noriCompartido;

  static Future<ShareResult> _conSharePlus(ShareParams params) =>
      SharePlus.instance.share(params);

  /// Genera la postal de Nori y abre el menú de compartir. Con el menú
  /// cancelado no mide nada. Si algo falla, no lanza ni enseña nada.
  static Future<void> compartir(BuildContext context, DatosNori datos) async {
    final l = AppLocalizations.of(context)!;
    final overlay = Overlay.of(context, rootOverlay: true);
    final identidad = identidadEquipadaNotifier.value.codigo;
    try {
      final png = await _pintarYCapturar(overlay, datos);
      final resultado = await menu(
        ShareParams(
          text: l.noriTextoCompartir(enlaceInvitacion),
          files: [
            XFile.fromData(png, mimeType: 'image/png', name: nombreFicheroNori),
          ],
          fileNameOverrides: const [nombreFicheroNori],
        ),
      );
      if (resultado.status != ShareResultStatus.dismissed) {
        await medir(identidad: identidad, fase: datos.fase);
      }
    } catch (e) {
      debugPrint('Nori: no se pudo compartir la postal: $e');
    }
  }

  /// Los sitios de prenda que `NoriVestida` va a pintar para [fase], con su
  /// fichero ya bajado. Pedirlos aquí, antes de montar la tarjeta, deja la
  /// caché llena: al montarla, `NoriVestida` los recibe en un instante.
  /// Mismas reglas que `NoriVestida._actualizar`.
  static Future<Set<String>> _prendasEsperadas(String fase) async {
    final puestas = prendasEquipadasNotifier.value;
    if (puestas.isEmpty) return const {};
    await asegurarManifiesto();
    final f = faseYSufijoMascota(fase: fase, estado: 'feliz');
    final manifiesto = manifiestoArteNotifier.value;
    final servicio = ArtePrendasService();
    final esperadas = <String>{};
    for (final sitio in ordenCapasPrenda) {
      final codigo = puestas[sitio];
      if (codigo == null) continue;
      final prenda = manifiesto.prendas[codigo];
      if (prenda == null || !prenda.fases.contains(f.fase)) continue;
      final ruta = prenda.imagenPara(f.fase, f.sufijo);
      if (ruta == null) continue;
      final File? fichero = await servicio.imagen(ruta);
      if (fichero != null) esperadas.add(sitio);
    }
    return esperadas;
  }

  /// Monta la postal fuera de la vista, espera a que Nori y sus prendas estén
  /// cargadas y la captura.
  static Future<Uint8List> _pintarYCapturar(
    OverlayState overlay,
    DatosNori datos,
  ) async {
    final esperadas = await _prendasEsperadas(datos.fase);
    final nieve = manifiestoArteNotifier.value.nieveActiva(DateTime.now());
    final clave = GlobalKey();
    final entrada = OverlayEntry(
      builder: (_) => Positioned(
        // Fuera de la pantalla, pero pintada: `Offstage` u `Opacity(0)` no
        // pintarían y no habría imagen que capturar.
        left: -TarjetaNori.ancho * 3,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: clave,
            child: TarjetaNori.de(datos, nieve: nieve, marca: 'Norday Habits'),
          ),
        ),
      ),
    );
    overlay.insert(entrada);
    try {
      await _esperarImagenes(clave, esperadas);
      return await capturarPostal(clave);
    } finally {
      entrada.remove();
      entrada.dispose();
    }
  }

  /// Espera, fotograma a fotograma, a que estén las capas de [esperadas] y
  /// a que toda imagen de la tarjeta tenga ya su dibujo decodificado (una
  /// `RenderImage` sin `image` es una imagen que aún no ha llegado). Con el
  /// plazo cumplido, sigue.
  static Future<void> _esperarImagenes(
    GlobalKey clave,
    Set<String> esperadas,
  ) async {
    final limite = DateTime.now().add(_plazoImagenes);
    while (true) {
      await WidgetsBinding.instance.endOfFrame;
      if (_imagenesListas(clave, esperadas)) return;
      if (DateTime.now().isAfter(limite)) {
        debugPrint('Nori: la postal se captura sin esperar más imágenes');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  static bool _imagenesListas(GlobalKey clave, Set<String> esperadas) {
    final raiz = clave.currentContext;
    if (raiz == null) return false;
    final capas = <String>{};
    var pendientes = 0;
    void visitar(Element e) {
      final w = e.widget;
      if (w is Image && w.key is ValueKey<String>) {
        final k = (w.key! as ValueKey<String>).value;
        if (k.startsWith('prenda_')) capas.add(k.substring('prenda_'.length));
      }
      if (e is RenderObjectElement) {
        final r = e.renderObject;
        if (r is RenderImage && r.image == null) pendientes++;
      }
      e.visitChildren(visitar);
    }

    (raiz as Element).visitChildren(visitar);
    return pendientes == 0 && capas.containsAll(esperadas);
  }

  /// La captura de la tarjeta de [clave]: mide [TarjetaNori.ancho] ×
  /// [TarjetaNori.alto] puntos sea cual sea la pantalla, así que este factor
  /// da siempre 1080 × 1350 px.
  @visibleForTesting
  static Future<Uint8List> capturarPostal(GlobalKey clave) async {
    final boundary =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await boundary.toImage(
      pixelRatio: _anchoPx / TarjetaNori.ancho,
    );
    try {
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (datos == null) throw StateError('La captura no dio bytes');
      return datos.buffer.asUint8List();
    } finally {
      imagen.dispose();
    }
  }
}
