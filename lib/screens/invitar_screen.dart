import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';

/// El enlace que se dibuja en la tarjeta. Es el mismo en todos los idiomas, y
/// no lo resuelve la app sino Caddy, en el servidor.
const enlaceInvitacionVisible = 'norday.app/invitar';

/// El mismo enlace, completo, para el texto que acompaña a la imagen.
const enlaceInvitacion = 'https://$enlaceInvitacionVisible';

/// Cómo se llama el fichero que se comparte.
const nombreFicheroInvitacion = 'norday-invitacion.png';

/// Las fases de Nori que tienen imagen, con el nombre que pide
/// `assetMascota`.
const fasesNori = {'huevo', 'cria', 'adulto'};

/// La fase de Nori cuando no se puede saber la real: adulta.
const faseNoriPorDefecto = 'adulto';

/// La fase que manda el backend, llevada a una de [fasesNori]. Lo que no se
/// reconoce va a adulta: mejor Nori adulta que una tarjeta sin Nori.
String normalizarFaseNori(String? fase) {
  final f = (fase ?? '').trim().toLowerCase().replaceAll('í', 'i');
  return fasesNori.contains(f) ? f : faseNoriPorDefecto;
}

/// Lo que hace el menú nativo de compartir. Por defecto, el de `share_plus`;
/// los tests pasan uno falso.
typedef CompartirInvitacion = Future<ShareResult> Function(ShareParams params);

/// De dónde sale la fase de Nori. Por defecto, del backend.
typedef CargarFaseNori = Future<String?> Function(int usuarioId);

Future<ShareResult> _compartirConSharePlus(ShareParams params) =>
    SharePlus.instance.share(params);

Future<String?> _faseDelBackend(int usuarioId) async {
  final mascota = await ApiServiceCore.getMascota(usuarioId);
  return mascota['fase'] as String?;
}

/// El valor del parámetro `resultado` de `invitar_compartido`.
String resultadoCompartir(ShareResultStatus estado) => switch (estado) {
  ShareResultStatus.success => 'compartido',
  ShareResultStatus.dismissed => 'cancelado',
  ShareResultStatus.unavailable => 'no_disponible',
};

/// «Invitar a un amigo»: la tarjeta en grande y un botón que la comparte
/// como imagen, con un texto, por el menú nativo.
class InvitarScreen extends StatefulWidget {
  final int usuarioId;
  final CompartirInvitacion compartir;
  final CargarFaseNori cargarFase;

  const InvitarScreen({
    super.key,
    required this.usuarioId,
    this.compartir = _compartirConSharePlus,
    this.cargarFase = _faseDelBackend,
  });

  @override
  State<InvitarScreen> createState() => _InvitarScreenState();
}

class _InvitarScreenState extends State<InvitarScreen> {
  final _claveTarjeta = GlobalKey();
  String? _fase;
  bool _compartiendo = false;

  @override
  void initState() {
    super.initState();
    AnalyticsHabitos.invitarAbierto();
    _cargarFase();
  }

  Future<void> _cargarFase() async {
    String fase = faseNoriPorDefecto;
    try {
      fase = normalizarFaseNori(await widget.cargarFase(widget.usuarioId));
    } catch (e) {
      debugPrint('Invitar: sin fase de Nori, va adulta: $e');
    }
    if (mounted) setState(() => _fase = fase);
  }

  /// La tarjeta mide [TarjetaInvitacion.ancho] × [TarjetaInvitacion.alto]
  /// puntos sea cual sea la pantalla, así que este factor da siempre
  /// 1080 × 1920 px.
  Future<Uint8List> _capturar() async {
    final boundary =
        _claveTarjeta.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final imagen = await boundary.toImage(
      pixelRatio: TarjetaInvitacion.anchoPx / TarjetaInvitacion.ancho,
    );
    try {
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (datos == null) throw StateError('La captura no dio bytes');
      return datos.buffer.asUint8List();
    } finally {
      imagen.dispose();
    }
  }

  Future<void> _compartir() async {
    if (_compartiendo) return;
    final l = AppLocalizations.of(context)!;
    final mensajero = ScaffoldMessenger.of(context);
    setState(() => _compartiendo = true);
    try {
      final png = await _capturar();
      final resultado = await widget.compartir(
        ShareParams(
          text: l.invitarTextoCompartir(enlaceInvitacion),
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: nombreFicheroInvitacion,
            ),
          ],
          fileNameOverrides: const [nombreFicheroInvitacion],
        ),
      );
      AnalyticsHabitos.invitarCompartido(resultadoCompartir(resultado.status));
    } catch (e) {
      debugPrint('Invitar: no se pudo compartir: $e');
      mensajero.showSnackBar(SnackBar(content: Text(l.invitarError)));
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final fase = _fase;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.invitarMenu)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: FondoIdentidad()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      // La tarjeta se compone siempre al mismo tamaño y aquí
                      // sólo se escala: así la captura sale igual en todos
                      // los móviles y igual a lo que se ve.
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _claveTarjeta,
                          child: TarjetaInvitacion(
                            fase: fase ?? faseNoriPorDefecto,
                            cargando: fase == null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: fase == null || _compartiendo
                          ? null
                          : _compartir,
                      icon: _compartiendo
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: t.text,
                              ),
                            )
                          : const Icon(LucideIcons.share2),
                      label: Text(l.invitarCompartir),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La tarjeta de invitación, en 9:16, con los colores, letras y radios de la
/// identidad activa. No lleva nada personal: ni nombre, ni email, ni el
/// nombre que el usuario le haya puesto a Nori.
class TarjetaInvitacion extends StatelessWidget {
  /// Tamaño lógico fijo: 9:16.
  static const double ancho = 360;
  static const double alto = 640;

  /// Tamaño de la imagen compartida.
  static const double anchoPx = 1080;
  static const double altoPx = 1920;

  /// La fase de Nori, una de [fasesNori].
  final String fase;

  /// Mientras llega la fase, no se pinta Nori: así no sale una y luego otra.
  final bool cargando;

  const TarjetaInvitacion({
    super.key,
    required this.fase,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final tema = Theme.of(context).textTheme;
    const tamanoNori = 200.0;

    return SizedBox(
      width: ancho,
      height: alto,
      // La superficie de la identidad, no una pintada a mano: así sale a
      // lápiz en Dulce, achaflanada en Neotokyo+ y de cristal en Profundidad,
      // como la bienvenida (CLAUDE.md del core, «Equipamiento»).
      child: SuperficieIdentidad(
        protagonista: true,
        relleno: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          children: [
            WordmarkIdentidad(
              texto: l.appNombre,
              color: t.text,
              // El tamaño sale de un rol de la escala, no de un número.
              tamano: tema.headlineSmall?.fontSize ?? 24,
            ),
            const Spacer(),
            SizedBox(
              width: tamanoNori,
              height: tamanoNori,
              child: cargando
                  ? null
                  : Image.asset(
                      assetMascota(fase: fase, estado: 'exultante'),
                      package: 'norday_flutter_core',
                      width: tamanoNori,
                      height: tamanoNori,
                      // Si la fase no tuviera imagen, mejor un hueco que
                      // una tarjeta rota.
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.invitarTitular,
              textAlign: TextAlign.center,
              style: tema.headlineSmall?.copyWith(color: t.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.invitarFrase,
              textAlign: TextAlign.center,
              style: tema.bodyLarge?.copyWith(color: t.textMuted),
            ),
            const Spacer(),
            Text(
              enlaceInvitacionVisible,
              textAlign: TextAlign.center,
              style: tema.headlineMedium?.copyWith(
                color: t.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.invitarPie,
              textAlign: TextAlign.center,
              style: tema.labelSmall?.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
