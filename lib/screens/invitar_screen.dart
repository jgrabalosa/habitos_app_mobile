import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';

/// El enlace de la invitación, para el texto que acompaña a la postal (en la
/// postal no se dibuja: en el texto se puede pulsar). Es el mismo en todos
/// los idiomas, y no lo resuelve la app sino Caddy, en el servidor.
const enlaceInvitacion = 'https://norday.app/invitar';

/// Cómo se llama el fichero que se comparte.
const nombreFicheroInvitacion = 'norday-invitacion.png';

/// Las fases de Nori que tienen imagen, con el nombre que pide
/// `assetMascota`.
const fasesNori = {'huevo', 'cria', 'adulto'};

/// La fase de Nori cuando no se puede saber la real: adulta.
const faseNoriPorDefecto = 'adulto';

/// La fase que manda el backend, llevada a una de [fasesNori]. Lo que no se
/// reconoce va a adulta: mejor Nori adulta que una postal sin Nori.
String normalizarFaseNori(String? fase) {
  final f = (fase ?? '').trim().toLowerCase().replaceAll('í', 'i');
  return fasesNori.contains(f) ? f : faseNoriPorDefecto;
}

/// Lo que la postal cuenta de quien invita: la fase de su Nori y, si los
/// hay, el nombre que le puso y su nivel. Sale de `getMascota`.
@immutable
class DatoNori {
  /// Una de [fasesNori].
  final String fase;

  /// El nombre que el usuario le puso a Nori, o `null` si no le puso.
  final String? nombre;

  /// El nivel de Nori, o `null` si el backend no lo mandó.
  final int? nivel;

  const DatoNori({this.fase = faseNoriPorDefecto, this.nombre, this.nivel});

  factory DatoNori.desdeMascota(Map<String, dynamic> mascota) {
    final nombre = (mascota['nombre'] as String?)?.trim();
    final nivel = mascota['nivel'];
    return DatoNori(
      fase: normalizarFaseNori(mascota['fase'] as String?),
      nombre: nombre == null || nombre.isEmpty ? null : nombre,
      nivel: nivel is num ? nivel.toInt() : null,
    );
  }

  /// Sin nivel no hay frase que decir: la postal sale sin dato.
  bool get tieneDato => nivel != null;
}

/// La frase del dato: «Pipo ya es cría · nivel 7», o «Mi Nori …» sin nombre.
String textoDatoNori(AppLocalizations l, DatoNori dato) =>
    l.invitarDato(dato.nombre ?? l.invitarMiNori, dato.fase, dato.nivel ?? 0);

/// Lo que hace el menú nativo de compartir. Por defecto, el de `share_plus`;
/// los tests pasan uno falso.
typedef CompartirInvitacion = Future<ShareResult> Function(ShareParams params);

/// De dónde sale el dato de Nori (fase, nombre y nivel). Por defecto, del
/// backend.
typedef CargarDatoNori = Future<DatoNori?> Function(int usuarioId);

/// Cómo se mide lo que devolvió el menú. Por defecto, Analytics.
typedef MedirCompartido =
    Future<void> Function(String resultado, {required bool conDato});

Future<ShareResult> _compartirConSharePlus(ShareParams params) =>
    SharePlus.instance.share(params);

Future<DatoNori?> _datoDelBackend(int usuarioId) async =>
    DatoNori.desdeMascota(await ApiServiceCore.getMascota(usuarioId));

/// El valor del parámetro `resultado` de `invitar_compartido`.
String resultadoCompartir(ShareResultStatus estado) => switch (estado) {
  ShareResultStatus.success => 'compartido',
  ShareResultStatus.dismissed => 'cancelado',
  ShareResultStatus.unavailable => 'no_disponible',
};

/// «Invitar a un amigo»: la postal en grande, un interruptor para quitarle
/// el dato y un botón que la comparte como imagen, con un texto, por el menú
/// nativo.
class InvitarScreen extends StatefulWidget {
  final int usuarioId;
  final CompartirInvitacion compartir;
  final CargarDatoNori cargarDato;
  final MedirCompartido medirCompartido;

  const InvitarScreen({
    super.key,
    required this.usuarioId,
    this.compartir = _compartirConSharePlus,
    this.cargarDato = _datoDelBackend,
    this.medirCompartido = AnalyticsHabitos.invitarCompartido,
  });

  @override
  State<InvitarScreen> createState() => _InvitarScreenState();
}

class _InvitarScreenState extends State<InvitarScreen> {
  final _claveTarjeta = GlobalKey();
  DatoNori? _dato;
  bool _cargando = true;
  bool _incluirDato = true;
  bool _compartiendo = false;

  @override
  void initState() {
    super.initState();
    AnalyticsHabitos.invitarAbierto();
    _cargarDato();
  }

  Future<void> _cargarDato() async {
    DatoNori? dato;
    try {
      dato = await widget.cargarDato(widget.usuarioId);
    } catch (e) {
      debugPrint('Invitar: sin dato de Nori, va adulta y sin dato: $e');
    }
    if (mounted) {
      setState(() {
        _dato = dato;
        _cargando = false;
      });
    }
  }

  bool get _conDato => _incluirDato && (_dato?.tieneDato ?? false);

  /// La tarjeta mide [TarjetaInvitacion.ancho] × [TarjetaInvitacion.alto]
  /// puntos sea cual sea la pantalla, así que este factor da siempre
  /// 1080 × 1350 px.
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
    final conDato = _conDato;
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
      await widget.medirCompartido(
        resultadoCompartir(resultado.status),
        conDato: conDato,
      );
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
    final dato = _dato;

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
                      // La postal se compone siempre al mismo tamaño y aquí
                      // sólo se escala: así la captura sale igual en todos
                      // los móviles y igual a lo que se ve.
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _claveTarjeta,
                          child: TarjetaInvitacion(
                            fase: dato?.fase ?? faseNoriPorDefecto,
                            dato: _conDato ? dato : null,
                            cargando: _cargando,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Sin dato (sin red, o sin nivel) no hay nada que quitar.
                  if (dato != null && dato.tieneDato) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.invitarIncluirDato),
                      value: _incluirDato,
                      onChanged: _compartiendo
                          ? null
                          : (v) => setState(() => _incluirDato = v),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargando || _compartiendo ? null : _compartir,
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

/// La postal de invitación, en 4:5: el fondo de la identidad a sangre, sin
/// panel; arriba, si lo hay, el dato de quien invita; en medio, su Nori en
/// grande, en su fase y con lo que lleva puesto; abajo, el wordmark. Los
/// colores y las letras son los de la identidad equipada.
class TarjetaInvitacion extends StatelessWidget {
  /// Tamaño lógico fijo: 4:5.
  static const double ancho = 360;
  static const double alto = 450;

  /// Tamaño de la imagen compartida.
  static const double anchoPx = 1080;
  static const double altoPx = 1350;

  /// Nori ocupa el 58 % del alto (el encargo pide entre el 55 y el 60 %).
  static const double tamanoNori = 261;

  /// La fase de Nori, una de [fasesNori].
  final String fase;

  /// El dato de quien invita, o `null` para una postal sin dato.
  final DatoNori? dato;

  /// Mientras llega el dato, no se pinta Nori: así no sale una y luego otra.
  final bool cargando;

  const TarjetaInvitacion({
    super.key,
    required this.fase,
    this.dato,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final tema = Theme.of(context).textTheme;
    final dato = this.dato;

    return SizedBox(
      width: ancho,
      height: alto,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // El fondo de la identidad, a sangre y sin panel encima: la imagen
          // no tiene huecos transparentes, que en una historia saldrían
          // negros o blancos. Debajo, el color de fondo de las pantallas
          // (`bg`), sobre el que se pinta el dibujo de la identidad.
          ColoredBox(color: t.bg),
          const Positioned.fill(child: FondoIdentidad()),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // El dato y el wordmark se reparten lo que deja Nori, a
                // partes iguales: así Nori queda en el centro con y sin dato.
                Expanded(
                  child: Center(
                    child: dato == null || cargando
                        ? null
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: ancho - 2 * AppSpacing.lg,
                              ),
                              child: Text(
                                textoDatoNori(l, dato),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: tema.titleLarge?.copyWith(color: t.text),
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox.square(
                  dimension: tamanoNori,
                  child: cargando
                      ? null
                      : NoriVestida(
                          fase: fase,
                          estado: 'exultante',
                          tamano: tamanoNori,
                          prendas: prendasEquipadasNotifier,
                        ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: WordmarkIdentidad(
                      texto: l.appNombre,
                      color: t.text,
                      // El tamaño sale de un rol de la escala, no de un
                      // número: el wordmark va pequeño.
                      tamano: tema.titleMedium?.fontSize ?? 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
