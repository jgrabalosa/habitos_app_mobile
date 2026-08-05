import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Disparadores: lo que se mide de los hábitos. Entrar y darse de alta son
/// eventos de cualquier app del ecosistema y los registra [AnalyticsCore],
/// dentro del paquete.
class AnalyticsHabitos {
  static Future<void> habitoCreado(String frecuencia) async {
    await AnalyticsCore.analytics.logEvent(
      name: 'habito_creado',
      parameters: {'frecuencia': frecuencia},
    );
  }

  static Future<void> habitoCompletado(String frecuencia) async {
    await AnalyticsCore.analytics.logEvent(
      name: 'habito_completado',
      parameters: {'frecuencia': frecuencia},
    );
  }
}
