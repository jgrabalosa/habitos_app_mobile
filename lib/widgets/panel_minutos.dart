import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../l10n/textos_minutos.dart';
import '../models/hoy.dart';
import '../models/minutos.dart';
import '../models/registro.dart';
import '../screens/dashboard_logica.dart';
import '../services/abrir_enfoque.dart';
import '../services/api_service_habitos.dart';
import '../services/clave_envio.dart';

/// Las llamadas de red del panel de minutos. En producción van al backend; en
/// los tests se cambian por un falso, igual que en `PausaHabito`.
class PanelMinutos {
  PanelMinutos._();

  /// El botón «Empezar sesión», que abre Norday Focus con este hábito como
  /// destino, o su ficha de Google Play si no está; apagado hasta que Norday
  /// Focus esté en Producción (la salida B), porque la ficha de una app en
  /// prueba cerrada no la ve nadie fuera de los testers. Para encenderlo,
  /// cambiar false por true.
  @visibleForTesting
  static bool enfoqueDisponible = false;

  /// Quién abre Enfoque o su ficha. En los tests, un falso.
  @visibleForTesting
  static LanzadorEnlaces lanzadorEnlaces = const LanzadorEnlacesAndroid();

  /// El flavor con el que corre la app, para abrir la Enfoque que le toca.
  @visibleForTesting
  static String? Function() flavor = () => appFlavor;

  @visibleForTesting
  static Future<Map<String, dynamic>> Function(
    int habitoId, {
    String? fecha,
    int? minutos,
    String? clave,
    String? origen,
  })
  completar = ApiServiceHabitos.completarHabito;

  @visibleForTesting
  static Future<List<Registro>> Function(int habitoId) registros =
      ApiServiceHabitos.getRegistros;

  @visibleForTesting
  static Future<void> Function(int registroId) deshacer =
      ApiServiceHabitos.deshacerRegistro;

  /// De dónde sale la `clave` de cada envío. Un UUID v4 nuevo cada vez.
  @visibleForTesting
  static String Function() nuevaClaveEnvio = nuevaClave;
}

/// Qué ha pasado en el panel.
enum TipoResultadoMinutos {
  /// Se sumaron minutos y el servidor lo confirmó.
  sumado,

  /// Se deshizo la última entrada y el servidor lo confirmó.
  deshecho,

  /// El panel se cerró después de un envío sin respuesta clara (timeout, sin
  /// conexión, 5xx): puede que se registrara. Hoy recarga para saberlo.
  desconocido,
}

/// Lo que ha pasado en el panel, para que Hoy lo pinte y lo celebre.
class ResultadoMinutos {
  final TipoResultadoMinutos tipo;

  /// Los minutos que han cambiado el día: positivos al sumar, negativos al
  /// deshacer, cero si no se sabe.
  final int minutos;

  /// La respuesta de completar, tal como la lee `ApiServiceHabitos`. Solo al
  /// sumar.
  final Map<String, dynamic>? completado;

  const ResultadoMinutos.sumado(this.minutos, Map<String, dynamic> respuesta)
    : tipo = TipoResultadoMinutos.sumado,
      completado = respuesta;

  const ResultadoMinutos.deshecho(this.minutos)
    : tipo = TipoResultadoMinutos.deshecho,
      completado = null;

  const ResultadoMinutos.desconocido()
    : tipo = TipoResultadoMinutos.desconocido,
      minutos = 0,
      completado = null;
}

/// La clave del último envío que no tuvo respuesta clara, con lo que llevaba.
/// Si se repite el mismo envío (mismos minutos, mismo día), va con la misma
/// clave: si el primero sí llegó, el backend lo reconoce y no registra otro.
typedef EnvioPendiente = ({String clave, int minutos, String? fecha});

/// La clave para enviar [minutos] en [fecha]: la de [pendiente] si es el mismo
/// envío repetido, o una nueva.
String claveParaEnvio(
  EnvioPendiente? pendiente, {
  required int minutos,
  required String? fecha,
  required String Function() nueva,
}) =>
    (pendiente != null &&
        pendiente.minutos == minutos &&
        pendiente.fecha == fecha)
    ? pendiente.clave
    : nueva();

/// Abre el panel de minutos de [fila] para el día [fechaDia] (`AAAA-MM-DD`),
/// que es el que se mira en Hoy. Con [esHoy], el completado se manda sin
/// fecha y la decide el servidor en la zona del usuario, como hace el check.
///
/// Cada envío sale de aquí con su `clave` y, si va bien, el panel se cierra
/// y devuelve lo que ha pasado: la celebración la hace Hoy, igual que al
/// marcar un hábito de veces, para no apilar hojas. Si falla, el panel se
/// queda abierto con el error.
///
/// Mientras envía no se puede cerrar (ni con atrás ni tocando fuera), y no se
/// arrastra para cerrar: el arrastre de la hoja hace `pop` sin preguntar a
/// `PopScope`. Si se cierra después de un envío sin respuesta clara, devuelve
/// [TipoResultadoMinutos.desconocido] para que Hoy recargue. Null si se
/// cierra sin haber enviado nada.
Future<ResultadoMinutos?> mostrarPanelMinutos(
  BuildContext context, {
  required FilaHoy fila,
  required String fechaDia,
  required bool esHoy,
}) async {
  final id = identidad(context);
  final t = tokens(context);
  var incierto = false;
  final resultado = await showModalBottomSheet<ResultadoMinutos>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    backgroundColor: t.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(id.radioHero)),
    ),
    builder: (context) => _PanelMinutosVista(
      fila: fila,
      fechaDia: fechaDia,
      esHoy: esHoy,
      alQuedarIncierto: () => incierto = true,
    ),
  );
  if (resultado == null && incierto) {
    return const ResultadoMinutos.desconocido();
  }
  return resultado;
}

class _PanelMinutosVista extends StatefulWidget {
  final FilaHoy fila;
  final String fechaDia;
  final bool esHoy;

  /// Un envío ha fallado sin respuesta clara: puede que se registrara.
  final VoidCallback alQuedarIncierto;

  const _PanelMinutosVista({
    required this.fila,
    required this.fechaDia,
    required this.esHoy,
    required this.alQuedarIncierto,
  });

  @override
  State<_PanelMinutosVista> createState() => _PanelMinutosVistaState();
}

class _PanelMinutosVistaState extends State<_PanelMinutosVista> {
  final _campo = TextEditingController();
  bool _enviando = false;

  /// Abriendo Enfoque: el botón no se puede pulsar dos veces, y nada suma
  /// ni deshace mientras tanto (si Enfoque se abre, el panel se cierra y el
  /// resultado de ese envío se perdería).
  bool _abriendo = false;

  /// El error del campo libre, ya traducido. Se borra al escribir.
  String? _errorCampo;

  /// El error de red de un envío o de deshacer, ya traducido.
  String? _error;

  /// La última entrada del día, para decir cuánto se deshace. Null mientras
  /// carga, o si no hay ninguna.
  Registro? _ultima;

  /// El último envío sin respuesta clara, para repetirlo con su clave.
  EnvioPendiente? _pendiente;

  FilaHoy get _fila => widget.fila;

  @override
  void initState() {
    super.initState();
    if (_fila.minutosHechos > 0) _cargarUltima();
  }

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  /// Solo para la etiqueta del botón (cantidad y hora): si no llega, el botón
  /// dice lo mismo sin la cifra.
  Future<void> _cargarUltima() async {
    try {
      final registros = await PanelMinutos.registros(_fila.habito.habitoId);
      if (!mounted) return;
      setState(() => _ultima = ultimoRegistroDe(registros, widget.fechaDia));
    } catch (_) {
      // Sin la cifra, el botón sigue funcionando.
    }
  }

  Future<void> _enviar(int minutos) async {
    if (_enviando || _abriendo) return;
    final l = AppLocalizations.of(context)!;
    final fecha = widget.esHoy ? null : widget.fechaDia;
    final clave = claveParaEnvio(
      _pendiente,
      minutos: minutos,
      fecha: fecha,
      nueva: PanelMinutos.nuevaClaveEnvio,
    );
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      // Si la clave ya se usó y llegó, el backend responde 200 con el
      // resultado del original (sin premios nuevos): se trata como éxito, y
      // Hoy recarga igualmente después de cualquier completado.
      final resultado = await PanelMinutos.completar(
        _fila.habito.habitoId,
        fecha: fecha,
        minutos: minutos,
        clave: clave,
        origen: origenManual,
      );
      if (!mounted) return;
      _pendiente = null;
      Navigator.pop(context, ResultadoMinutos.sumado(minutos, resultado));
    } catch (e) {
      if (!mounted) return;
      final incierto = esResultadoIncierto(e);
      if (incierto) widget.alQuedarIncierto();
      setState(() {
        _enviando = false;
        // Sin respuesta clara se guarda la clave para repetir el mismo envío;
        // con un 4xx no se registró nada y el siguiente lleva clave nueva.
        _pendiente = incierto
            ? (clave: clave, minutos: minutos, fecha: fecha)
            : null;
        _error = MensajesError.de(context, e, generico: l.minErrorEnviar);
      });
    }
  }

  void _enviarCampo() {
    final l = AppLocalizations.of(context)!;
    final r = minutosAEnviar(_campo.text);
    final minutos = r.minutos;
    if (minutos == null) {
      setState(() {
        _errorCampo = switch (r.error!) {
          ErrorMinutos.vacio => l.minErrorVacio,
          ErrorMinutos.fueraDeRango => textoErrorRangoMinutos(l),
        };
      });
      return;
    }
    _enviar(minutos);
  }

  /// Deshace la última entrada del día que se mira. El id se busca en el
  /// momento, como hace Hoy con el check: así no se queda rancio si se sumó
  /// desde otro sitio. El backend solo deja deshacer el último registro del
  /// hábito; si no lo es, 409.
  Future<void> _deshacer() async {
    if (_enviando || _abriendo) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final registros = await PanelMinutos.registros(_fila.habito.habitoId);
      final ultima = ultimoRegistroDe(registros, widget.fechaDia);
      if (ultima == null) throw StateError('No hay registros ese día');
      try {
        await PanelMinutos.deshacer(ultima.registroId);
      } catch (e) {
        if (esResultadoIncierto(e)) widget.alQuedarIncierto();
        rethrow;
      }
      if (!mounted) return;
      Navigator.pop(context, ResultadoMinutos.deshecho(-ultima.cantidad));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = esSoloDeshacerElUltimo(e)
            ? l.dashDeshacerSoloUltimo
            : MensajesError.de(context, e, generico: l.dashDeshacerError);
      });
    }
  }

  /// Abre Enfoque con este hábito (o su ficha de Google Play) y cierra el
  /// panel: los minutos de la sesión llegan desde Enfoque, y al volver a la
  /// app Hoy recarga. Si no se ha podido abrir nada, el panel se queda
  /// abierto con el error.
  Future<void> _empezarSesion() async {
    if (_enviando || _abriendo) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _abriendo = true;
      _error = null;
    });
    final apertura = await abrirEnfoque(
      habitoId: _fila.habito.habitoId,
      flavor: PanelMinutos.flavor(),
      lanzador: PanelMinutos.lanzadorEnlaces,
    );
    if (!mounted) return;
    if (apertura == AperturaEnfoque.nada) {
      setState(() {
        _abriendo = false;
        _error = l.minErrorAbrirEnfoque;
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final texto = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hechos = _fila.minutosHechos;
    final objetivo = _fila.minutosObjetivo ?? 0;
    // «Completar» suma justo lo que falta; null con la meta cumplida.
    final completar = minutosParaCompletar(hechos, _fila.minutosObjetivo);
    final rapidas = sumasRapidasVisibles(hechos, _fila.minutosObjetivo);

    // Mientras sale un envío, el panel no se cierra: atrás y tocar fuera
    // preguntan a PopScope. Si se cerrara, no se sabría qué ha pasado.
    return PopScope(
      canPop: !_enviando,
      child: SingleChildScrollView(
        // `useSafeArea` no aparta de abajo: se suma la barra del sistema, o el
        // teclado si está abierto (que ya la tapa), lo que sea mayor. Igual
        // que en el panel del ritmo.
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md +
              math.max(
                MediaQuery.viewInsetsOf(context).bottom,
                MediaQuery.viewPaddingOf(context).bottom,
              ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mientras sale un envío, una línea fina arriba: los botones ya se
            // apagan, y esto dice que está pasando algo.
            SizedBox(
              height: AppSpacing.xs,
              child: _enviando ? const LinearProgressIndicator() : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnilloIdentidad(
                        tamano: 56,
                        pct: _fila.fraccionDia,
                        color: t.success,
                      ),
                      Icon(LucideIcons.timer, size: 22, color: t.successText),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fila.habito.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: texto.titleMedium?.copyWith(color: t.text),
                      ),
                      Text(
                        progresoMinutos(l, hechos, objetivo),
                        style: texto.titleLarge?.copyWith(color: t.text),
                      ),
                      Text(
                        textoEstadoPanel(
                          l,
                          hechos: hechos,
                          objetivo: _fila.minutosObjetivo,
                        ),
                        style: texto.bodySmall?.copyWith(color: t.textMuted),
                      ),
                      if (!widget.esHoy)
                        Text(
                          l.minPanelOtroDia(
                            DateFormat.MMMMEEEEd(
                              locale,
                            ).format(DateTime.parse(widget.fechaDia)),
                          ),
                          style: texto.bodySmall?.copyWith(color: t.streakText),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Lo principal, arriba y a todo lo ancho: llegar justo a la meta.
            // Es una suma normal, con su clave y MANUAL, como cualquier otra.
            if (completar != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _enviando || _abriendo
                    ? null
                    : () => _enviar(completar),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(LucideIcons.check, size: 18),
                label: Semantics(
                  label: l.minCompletarA11y(duracionLegible(l, completar)),
                  excludeSemantics: true,
                  child: Text(textoCompletar(l, completar)),
                ),
              ),
            ],
            // Los botones rápidos, siempre en su orden y en su casilla: los
            // que no salen dejan la suya vacía, para que los demás no se
            // muevan ni cambien de tamaño.
            if (rapidas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (final (i, n) in sumasRapidasMinutos.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: rapidas.contains(n)
                          ? OutlinedButton(
                              onPressed: _enviando || _abriendo
                                  ? null
                                  : () => _enviar(n),
                              child: Text(l.minSumaRapida(n)),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _campo,
                    enabled: !_enviando && !_abriendo,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (_) {
                      if (_errorCampo != null) {
                        setState(() => _errorCampo = null);
                      }
                    },
                    onSubmitted: (_) => _enviarCampo(),
                    decoration: InputDecoration(
                      labelText: l.minCampoSumar,
                      errorText: _errorCampo,
                      errorMaxLines: 3,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: ElevatedButton(
                    onPressed: _enviando || _abriendo ? null : _enviarCampo,
                    child: Text(l.minBotonSumar),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: tonoError(context).texto)),
            ],
            if (hechos > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _enviando || _abriendo ? null : _deshacer,
                  icon: const Icon(LucideIcons.undo2, size: 18),
                  label: Text(etiquetaDeshacer(l, _ultima, locale: locale)),
                ),
              ),
            ],
            // «Empezar sesión» de Norday Focus (la app Enfoque). Solo para
            // hoy: una sesión cuenta en el día en que empieza, así que desde
            // otro día de la semana sumaría a hoy y no al que se mira.
            if (PanelMinutos.enfoqueDisponible && widget.esHoy) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _enviando || _abriendo ? null : _empezarSesion,
                icon: const Icon(LucideIcons.play, size: 18),
                label: Text(l.minEmpezarSesion),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
