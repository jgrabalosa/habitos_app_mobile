import 'dart:async';

import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';

/// Desde dónde se ofrece la tarjeta: es el valor de `origen` del evento
/// `permiso_avisos_ofrecido`.
enum OrigenPermisoAvisos { alta, apertura }

/// La tarjeta que pide el permiso de notificaciones en contexto: Nori lo
/// explica antes de que salga el diálogo del sistema.
///
/// Sale a quien no tiene permiso, no lo tiene bloqueado en los ajustes y no ha
/// visto ya esta pregunta en este móvil (`permiso_avisos_ofrecido`): al acabar
/// el alta nueva, o una sola vez en una apertura normal de quien ya usaba la
/// app. Se marca al enseñarla, así que «Ahora no» (o atrás) no vuelve.
/// También se marca cuando el formulario de un hábito pregunta el permiso
/// ([marcarOfrecido]): ya se le ha preguntado.
class PermisoAvisos {
  static const claveOfrecido = 'permiso_avisos_ofrecido';

  /// Seams de test. En producción, el core y las preferencias del móvil.
  @visibleForTesting
  static Future<bool> Function() concedido = NotificacionesService.concedido;

  @visibleForTesting
  static Future<bool> Function() bloqueadoEnAjustes =
      NotificacionesService.bloqueadoEnAjustes;

  @visibleForTesting
  static Future<bool> Function(int) pedirYRegistrar =
      NotificacionesService.pedirYRegistrar;

  @visibleForTesting
  static Future<SharedPreferences> Function() preferencias =
      SharedPreferences.getInstance;

  @visibleForTesting
  static void reiniciarParaTest() {
    concedido = NotificacionesService.concedido;
    bloqueadoEnAjustes = NotificacionesService.bloqueadoEnAjustes;
    pedirYRegistrar = NotificacionesService.pedirYRegistrar;
    preferencias = SharedPreferences.getInstance;
  }

  /// Deja anotado que a este móvil ya se le ha preguntado por los avisos. Nunca
  /// lanza.
  static Future<void> marcarOfrecido() async {
    try {
      final prefs = await preferencias();
      await prefs.setBool(claveOfrecido, true);
    } catch (_) {
      // Sin marca, como mucho vuelve a salir una vez más.
    }
  }

  /// Enseña la tarjeta si toca y devuelve si la enseñó; si no, o si algo falla,
  /// devuelve false. Se completa al cerrarse la tarjeta.
  static Future<bool> mostrarSiToca(
    BuildContext context, {
    required int usuarioId,
    required OrigenPermisoAvisos origen,
  }) async {
    try {
      final prefs = await preferencias();
      if (prefs.getBool(claveOfrecido) ?? false) return false;
      if (await concedido()) return false;
      if (await bloqueadoEnAjustes()) return false;
    } catch (_) {
      return false;
    }
    if (!context.mounted) return false;

    await marcarOfrecido();
    unawaited(AnalyticsHabitos.permisoAvisosOfrecido(origen.name));
    if (!context.mounted) return true;
    await showGeneralDialog<void>(
      context: context,
      // Aquí sí se puede salir: tocar fuera o atrás cuenta como «Ahora no».
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.permisoAvisosAhoraNo,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) =>
          _PermisoAvisosContenido(usuarioId: usuarioId),
      transitionBuilder: (context, anim, anim2, child) {
        final curva = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curva, child: child),
        );
      },
    );
    return true;
  }
}

class _PermisoAvisosContenido extends StatefulWidget {
  final int usuarioId;
  const _PermisoAvisosContenido({required this.usuarioId});

  @override
  State<_PermisoAvisosContenido> createState() =>
      _PermisoAvisosContenidoState();
}

class _PermisoAvisosContenidoState extends State<_PermisoAvisosContenido> {
  bool _procesando = false;

  Future<void> _activar() async {
    setState(() => _procesando = true);
    final navegador = Navigator.of(context);
    try {
      final concedido = await PermisoAvisos.pedirYRegistrar(widget.usuarioId);
      await AnalyticsHabitos.permisoAvisos(concedido);
    } catch (_) {
      // Sin permiso o sin red: la tarjeta se cierra igual.
    }
    if (navegador.mounted) navegador.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final tema = Theme.of(context).textTheme;

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
                          prendas: prendasEquipadasNotifier,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.permisoAvisosTitulo,
                        textAlign: TextAlign.center,
                        style: tema.headlineMedium?.copyWith(color: t.text),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.permisoAvisosCuerpo,
                        textAlign: TextAlign.center,
                        style: tema.bodyMedium?.copyWith(color: t.textMuted),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _procesando ? null : _activar,
                          child: _procesando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l.permisoAvisosActivar),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _procesando
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(l.permisoAvisosAhoraNo),
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
