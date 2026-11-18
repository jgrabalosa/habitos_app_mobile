import 'package:flutter/foundation.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Disparadores: lo que se mide de los hábitos. Entrar y darse de alta son
/// eventos de cualquier app del ecosistema y los registra [AnalyticsCore],
/// dentro del paquete.
///
/// Igual que [AnalyticsCore], ningún método de aquí lanza: medir nunca puede
/// romper lo que se mide. `habito_screen` espera a [habitoCreado] dentro del
/// try de guardar, con el hábito ya creado en el servidor; si esto lanzara,
/// la pantalla diría que no se pudo crear y un reintento lo duplicaría.
///
/// La captura vive aquí y no en un ayudante del core a propósito: esta app
/// depende del core por tag, y no debe hacer falta publicar uno para que
/// medir sea seguro.
class AnalyticsHabitos {
  static Future<void> habitoCreado(String frecuencia) async {
    try {
      await AnalyticsCore.analytics.logEvent(
        name: 'habito_creado',
        parameters: {'frecuencia': frecuencia},
      );
    } catch (e) {
      debugPrint('Analytics: no se registró habito_creado: $e');
    }
  }

  static Future<void> habitoCompletado(String frecuencia) async {
    try {
      await AnalyticsCore.analytics.logEvent(
        name: 'habito_completado',
        parameters: {'frecuencia': frecuencia},
      );
    } catch (e) {
      debugPrint('Analytics: no se registró habito_completado: $e');
    }
  }

  /// Se abre «Invitar a un amigo».
  static Future<void> invitarAbierto() async {
    try {
      await AnalyticsCore.analytics.logEvent(name: 'invitar_abierto');
    } catch (e) {
      debugPrint('Analytics: no se registró invitar_abierto: $e');
    }
  }

  /// Lo que devolvió el menú de compartir: `compartido`, `cancelado` o
  /// `no_disponible`.
  static Future<void> invitarCompartido(String resultado) async {
    try {
      await AnalyticsCore.analytics.logEvent(
        name: 'invitar_compartido',
        parameters: {'resultado': resultado},
      );
    } catch (e) {
      debugPrint('Analytics: no se registró invitar_compartido: $e');
    }
  }
}
