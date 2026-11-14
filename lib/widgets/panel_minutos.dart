import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../l10n/app_localizations.dart';
import '../models/hoy.dart';
import '../models/minutos.dart';
import '../models/registro.dart';
import '../screens/dashboard_logica.dart';
import '../services/api_service_habitos.dart';
import '../services/clave_envio.dart';

/// Las llamadas de red del panel de minutos. En producción van al backend; en
/// los tests se cambian por un falso, igual que en `PausaHabito`.
class PanelMinutos {
  PanelMinutos._();

  /// El hueco de «Empezar sesión» (Norday Enfoque). Apagado: Enfoque no existe
  /// todavía, y hasta entonces el panel no enseña nada en su sitio.
  static const bool enfoqueDisponible = false;

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

/// Lo que ha pasado en el panel, para que Hoy lo pinte y lo celebre.
class ResultadoMinutos {
  /// Los minutos que han cambiado el día: positivos al sumar, negativos al
  /// deshacer.
  final int minutos;

  /// La respuesta de completar, tal como la lee `ApiServiceHabitos`. Null al
  /// deshacer.
  final Map<String, dynamic>? completado;

  const ResultadoMinutos({required this.minutos, this.completado});

  bool get esDeshacer => completado == null;
}

/// Abre el panel de minutos de [fila] para el día [fechaDia] (`AAAA-MM-DD`),
/// que es el que se mira en Hoy. Con [esHoy], el completado se manda sin
/// fecha y la decide el servidor en la zona del usuario, como hace el check.
///
/// Cada envío sale de aquí con su `clave` nueva y, si va bien, el panel se
/// cierra y devuelve lo que ha pasado: la celebración la hace Hoy, igual que
/// al marcar un hábito de veces, para no apilar hojas. Si falla, el panel se
/// queda abierto con el error. Null si se cierra sin hacer nada.
Future<ResultadoMinutos?> mostrarPanelMinutos(
  BuildContext context, {
  required FilaHoy fila,
  required String fechaDia,
  required bool esHoy,
}) {
  final id = identidad(context);
  final t = tokens(context);
  return showModalBottomSheet<ResultadoMinutos>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: t.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(id.radioHero)),
    ),
    builder: (context) =>
        _PanelMinutosVista(fila: fila, fechaDia: fechaDia, esHoy: esHoy),
  );
}

class _PanelMinutosVista extends StatefulWidget {
  final FilaHoy fila;
  final String fechaDia;
  final bool esHoy;

  const _PanelMinutosVista({
    required this.fila,
    required this.fechaDia,
    required this.esHoy,
  });

  @override
  State<_PanelMinutosVista> createState() => _PanelMinutosVistaState();
}

class _PanelMinutosVistaState extends State<_PanelMinutosVista> {
  final _campo = TextEditingController();
  ModoMinutos _modo = ModoMinutos.sumar;
  bool _enviando = false;

  /// El error del campo libre, ya traducido. Se borra al escribir.
  String? _errorCampo;

  /// El error de red de un envío o de deshacer, ya traducido.
  String? _error;

  /// La última entrada del día, para decir cuánto se deshace. Null mientras
  /// carga, o si no hay ninguna.
  Registro? _ultima;

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

  /// Solo para la etiqueta del botón: si no llega, el botón dice lo mismo
  /// sin la cifra.
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
    if (_enviando) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final resultado = await PanelMinutos.completar(
        _fila.habito.habitoId,
        fecha: widget.esHoy ? null : widget.fechaDia,
        minutos: minutos,
        clave: PanelMinutos.nuevaClaveEnvio(),
        origen: origenManual,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        ResultadoMinutos(minutos: minutos, completado: resultado),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = MensajesError.de(context, e, generico: l.minErrorEnviar);
      });
    }
  }

  void _enviarCampo() {
    final l = AppLocalizations.of(context)!;
    final r = minutosAEnviar(_modo, _campo.text, _fila.minutosHechos);
    final minutos = r.minutos;
    if (minutos == null) {
      setState(() {
        _errorCampo = switch (r.error!) {
          ErrorMinutos.vacio => l.minErrorVacio,
          ErrorMinutos.fueraDeRango => l.minErrorRango,
          ErrorMinutos.noSube => l.minErrorNoSube(_fila.minutosHechos),
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
    if (_enviando) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final registros = await PanelMinutos.registros(_fila.habito.habitoId);
      final ultima = ultimoRegistroDe(registros, widget.fechaDia);
      if (ultima == null) throw StateError('No hay registros ese día');
      await PanelMinutos.deshacer(ultima.registroId);
      if (!mounted) return;
      Navigator.pop(context, ResultadoMinutos(minutos: -ultima.cantidad));
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final texto = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hechos = _fila.minutosHechos;
    final objetivo = _fila.minutosObjetivo ?? 0;
    final faltan = objetivo - hechos;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
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
                      l.minDeObjetivo(hechos, objetivo),
                      style: texto.titleLarge?.copyWith(color: t.text),
                    ),
                    Text(
                      faltan > 0 ? l.minPanelFaltan(faltan) : l.minPanelHecho,
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final (i, n) in sumasRapidasMinutos.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _enviando ? null : () => _enviar(n),
                    child: Text(l.minSumaRapida(n)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<ModoMinutos>(
            segments: [
              ButtonSegment(
                value: ModoMinutos.sumar,
                label: Text(l.minModoSumar),
              ),
              ButtonSegment(
                value: ModoMinutos.establecer,
                label: Text(l.minModoEstablecer),
              ),
            ],
            selected: {_modo},
            onSelectionChanged: _enviando
                ? null
                : (nuevo) => setState(() {
                    _modo = nuevo.first;
                    _errorCampo = null;
                  }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _campo,
                  enabled: !_enviando,
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
                    labelText: _modo == ModoMinutos.sumar
                        ? l.minCampoSumar
                        : l.minCampoEstablecer,
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
                  onPressed: _enviando ? null : _enviarCampo,
                  child: Text(
                    _modo == ModoMinutos.sumar
                        ? l.minBotonSumar
                        : l.minBotonEstablecer,
                  ),
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
                onPressed: _enviando ? null : _deshacer,
                icon: const Icon(LucideIcons.undo2, size: 18),
                label: Text(
                  _ultima == null
                      ? l.minDeshacerUltima
                      : l.minDeshacerUltimaN(_ultima!.cantidad),
                ),
              ),
            ),
          ],
          // Aquí irá «Empezar sesión» de Norday Enfoque. Mientras
          // `enfoqueDisponible` sea false no se pinta nada: no se implementa
          // Enfoque hasta que exista.
          if (PanelMinutos.enfoqueDisponible)
            const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
