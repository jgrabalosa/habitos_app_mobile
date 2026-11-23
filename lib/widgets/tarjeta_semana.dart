import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/hoy.dart';
import '../models/iconos_habito.dart';
import '../models/semana_pasada.dart';
import '../services/analytics_service.dart';
import '../services/api_service_habitos.dart';
import '../services/recorrido_onboarding.dart';
import 'identidad_ui.dart';
import 'panel_ritmo.dart';

/// «Así fue tu semana» (T-056): la tarjeta del primer día de la semana que se
/// abre la app. Nori, las fechas, lo que se hizo la semana pasada, los
/// semanales logrados y el ritmo.
///
/// **Solo cuenta lo hecho**: ni «fallaste», ni «te faltaron N», ni los días sin
/// hacer (D-70: las pausas no guardan fechas, así que lo que faltó no se sabe
/// con certeza). Por eso los días completos se pintan solo llenos, sin huecos.
///
/// Sale como mucho una vez por semana y usuario (`semana_vista_<usuarioId>`,
/// con el lunes de la semana del móvil): si la semana ya se vio, o no hubo
/// actividad, no sale. Con error de red no sale y **no se marca**, y si no
/// llega a enseñarse (alta nueva con la pista abierta) tampoco.
class TarjetaSemana {
  TarjetaSemana._();

  static String clave(int usuarioId) => 'semana_vista_$usuarioId';

  /// Seams de test. En producción, la red, las preferencias y la hora del móvil.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(int) obtener =
      ApiServiceHabitos.getSemanaPasada;

  @visibleForTesting
  static Future<SharedPreferences> Function() preferencias =
      SharedPreferences.getInstance;

  @visibleForTesting
  static DateTime Function() ahora = DateTime.now;

  @visibleForTesting
  static Future<void> Function() medir = AnalyticsHabitos.semanaVista;

  @visibleForTesting
  static void reiniciarParaTest() {
    obtener = ApiServiceHabitos.getSemanaPasada;
    preferencias = SharedPreferences.getInstance;
    ahora = DateTime.now;
    medir = AnalyticsHabitos.semanaVista;
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// El lunes de la semana de [d] (semana ISO), `AAAA-MM-DD`.
  static String lunesDe(DateTime d) =>
      _iso(DateTime(d.year, d.month, d.day - (d.weekday - 1)));

  static Future<void> _marcar(
    SharedPreferences prefs,
    int usuarioId,
    String lunes,
  ) async {
    try {
      await prefs.setString(clave(usuarioId), lunes);
    } catch (_) {
      // Sin marca, como mucho vuelve a intentarse en la siguiente apertura.
    }
  }

  /// Enseña la tarjeta si toca y devuelve si la enseñó; si no, o si algo falla,
  /// devuelve false. Se completa al cerrarse la tarjeta. `HomeShell` lo usa
  /// para no poner otra tarjeta en la misma apertura.
  static Future<bool> mostrarSiToca(
    BuildContext context, {
    required int usuarioId,
  }) async {
    if (usuarioId <= 0 || RecorridoOnboarding.instancia.activo) return false;

    final lunes = lunesDe(ahora());
    final SharedPreferences prefs;
    final SemanaPasada semana;
    try {
      prefs = await preferencias();
      if (prefs.getString(clave(usuarioId)) == lunes) return false;
      semana = SemanaPasada.fromJson(await obtener(usuarioId));
      // La zona del servidor puede ir un día por detrás del móvil: si lo que
      // llega no es una semana ya cerrada para el móvil, no es la que toca.
      if (semana.hasta.compareTo(lunes) >= 0) return false;
    } catch (_) {
      return false;
    }
    if (!semana.hayActividad) {
      // Una semana sin actividad no cambia: no hace falta preguntar otra vez.
      await _marcar(prefs, usuarioId, lunes);
      return false;
    }
    if (!context.mounted || RecorridoOnboarding.instancia.activo) return false;

    // Se abre antes de marcar para no usar el contexto tras una espera; la
    // marca se apunta enseguida, con la tarjeta ya en camino.
    final cierre = showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.semanaBoton,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => TarjetaSemanaContenido(semana),
      transitionBuilder: (context, anim, anim2, child) {
        final curva = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curva, child: child),
        );
      },
    );
    await _marcar(prefs, usuarioId, lunes);
    unawaited(medir());
    await cierre;
    return true;
  }
}

/// El contenido de la tarjeta. Público para poder pintarlo sin red en tests.
class TarjetaSemanaContenido extends StatelessWidget {
  final SemanaPasada semana;
  const TarjetaSemanaContenido(this.semana, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final id = identidad(context);
    final l = AppLocalizations.of(context)!;
    final tema = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formato = DateFormat.MMMd(locale);
    final desde = DateTime.tryParse(semana.desde);
    final hasta = DateTime.tryParse(semana.hasta);
    final logrados = semana.semanalesLogrados;
    final nivel = semana.ritmoNivel;
    final dias = semana.diasCompletos.clamp(0, 7);

    final (IconData, String)? tendencia = switch (semana.ritmoTendencia) {
      TendenciaRitmo.sube => (LucideIcons.arrowUp, l.semanaSube),
      TendenciaRitmo.igual => (LucideIcons.arrowRight, l.semanaIgual),
      TendenciaRitmo.baja => (LucideIcons.arrowDown, l.semanaBaja),
      null => null,
    };

    return Material(
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
                  relleno: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: NoriVestida(
                          fase: 'CRIA',
                          estado: 'feliz',
                          tamano: 96,
                          prendas: prendasEquipadasNotifier,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.semanaTitulo,
                        textAlign: TextAlign.center,
                        style: tema.headlineMedium?.copyWith(color: t.text),
                      ),
                      if (desde != null && hasta != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l.semanaFechas(
                            formato.format(desde),
                            formato.format(hasta),
                          ),
                          textAlign: TextAlign.center,
                          style: tema.bodyMedium?.copyWith(color: t.textMuted),
                        ),
                      ],
                      if (semana.hechos > 0) ...[
                        const SizedBox(height: 24),
                        Text(
                          l.semanaHiciste(semana.hechos, semana.total),
                          textAlign: TextAlign.center,
                          style: tema.headlineSmall?.copyWith(
                            color: t.points,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (dias > 0) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          label: l.semanaDiasCompletos(dias),
                          child: ExcludeSemantics(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: [
                                for (var i = 0; i < dias; i++)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: celdaHeatmap(
                                      id,
                                      t,
                                      color: t.success,
                                      llena: true,
                                      esHoy: false,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.semanaDiasCompletos(dias),
                          textAlign: TextAlign.center,
                          style: tema.bodyMedium?.copyWith(color: t.textMuted),
                        ),
                      ],
                      if (logrados.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          l.semanaSemanalesTitulo,
                          textAlign: TextAlign.center,
                          style: tema.titleSmall?.copyWith(color: t.textMuted),
                        ),
                        const SizedBox(height: 8),
                        for (final s in logrados)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  iconoDeHabito(s.icono),
                                  size: 20,
                                  color: t.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    s.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tema.titleSmall?.copyWith(
                                      color: t.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (nivel != null) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                l.semanaRitmo(palabraRitmo(l, nivel)),
                                style: tema.titleMedium?.copyWith(
                                  color: t.points,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IndicadorNivel(nivel: nivel, tamano: 20),
                          ],
                        ),
                        if (tendencia != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(tendencia.$1, size: 18, color: t.text),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  tendencia.$2,
                                  style: tema.bodyMedium?.copyWith(
                                    color: t.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      if (semana.masSube case final mas?) ...[
                        const SizedBox(height: 12),
                        Text(
                          l.semanaMasSube(
                            mas.nombre,
                            palabraRitmo(l, mas.nivelAntes),
                            palabraRitmo(l, mas.nivelAhora),
                          ),
                          textAlign: TextAlign.center,
                          style: tema.bodyMedium?.copyWith(color: t.textMuted),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l.semanaBoton),
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
    );
  }
}
