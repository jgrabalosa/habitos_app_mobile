import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../screens/invitar_screen.dart' show enlaceInvitacion;
import '../widgets/tarjeta_cierre_dia.dart';
import 'analytics_service.dart';

/// Cómo se llama el fichero que se comparte.
const nombreFicheroCierre = 'norday-cierre.png';

/// La postal del cierre del día: se pinta fuera de pantalla, se captura a
/// 1080 × 1350 y se abre el menú de compartir con ella y un texto.
class PostalCierre {
  const PostalCierre._();

  /// Seam de test: lo que hace el menú nativo de compartir. Por defecto, el de
  /// `share_plus`.
  @visibleForTesting
  static Future<ShareResult> Function(ShareParams params) menu = _conSharePlus;

  /// Seam de test: cómo se mide. Por defecto, Analytics.
  @visibleForTesting
  static Future<void> Function({required String identidad, required int total})
  medir = AnalyticsHabitos.cierreCompartido;

  static Future<ShareResult> _conSharePlus(ShareParams params) =>
      SharePlus.instance.share(params);

  /// Genera la postal de un día de [total] hábitos y abre el menú de
  /// compartir. Con el menú cancelado no mide nada. Si algo falla, no lanza:
  /// la ceremonia ya acabó y no hay nada que enseñar.
  static Future<void> compartir(
    BuildContext context, {
    required int total,
    required DateTime fecha,
  }) async {
    final l = AppLocalizations.of(context)!;
    final overlay = Overlay.of(context, rootOverlay: true);
    final identidad = identidadEquipadaNotifier.value.codigo;
    try {
      final png = await _pintarYCapturar(overlay, total, fecha);
      final resultado = await menu(
        ShareParams(
          text: l.cierreTextoCompartir(enlaceInvitacion),
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: nombreFicheroCierre,
            ),
          ],
          fileNameOverrides: const [nombreFicheroCierre],
        ),
      );
      if (resultado.status != ShareResultStatus.dismissed) {
        await medir(identidad: identidad, total: total);
      }
    } catch (e) {
      debugPrint('Cierre: no se pudo compartir la postal: $e');
    }
  }

  /// Monta la postal fuera de la vista, espera a que se pinte y la captura.
  static Future<Uint8List> _pintarYCapturar(
    OverlayState overlay,
    int total,
    DateTime fecha,
  ) async {
    final clave = GlobalKey();
    final entrada = OverlayEntry(
      builder: (_) => Positioned(
        // Fuera de la pantalla, pero pintada: `Offstage` u `Opacity(0)` no
        // pintarían y no habría imagen que capturar.
        left: -TarjetaCierreDia.ancho * 3,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: clave,
            child: TarjetaCierreDia(total: total, fecha: fecha),
          ),
        ),
      ),
    );
    overlay.insert(entrada);
    try {
      await WidgetsBinding.instance.endOfFrame;
      return await capturarPostal(clave);
    } finally {
      entrada.remove();
      entrada.dispose();
    }
  }

  /// La captura de la tarjeta de [clave]: la tarjeta mide
  /// [TarjetaCierreDia.ancho] × [TarjetaCierreDia.alto] puntos sea cual sea la
  /// pantalla, así que este factor da siempre 1080 × 1350 px.
  @visibleForTesting
  static Future<Uint8List> capturarPostal(GlobalKey clave) async {
    final boundary =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await boundary.toImage(
      pixelRatio: TarjetaCierreDia.anchoPx / TarjetaCierreDia.ancho,
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
