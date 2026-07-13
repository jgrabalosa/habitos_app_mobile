import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> registro(int usuarioId) async {
    await _analytics.setUserId(id: usuarioId.toString());
    await _analytics.logEvent(name: 'registro_completado');
  }

  static Future<void> login(int usuarioId) async {
    await _analytics.setUserId(id: usuarioId.toString());
    await _analytics.logEvent(name: 'login');
  }

  static Future<void> habitoCreado(String frecuencia) async {
    await _analytics.logEvent(
      name: 'habito_creado',
      parameters: {'frecuencia': frecuencia},
    );
  }

  static Future<void> habitoCompletado(String frecuencia) async {
    await _analytics.logEvent(
      name: 'habito_completado',
      parameters: {'frecuencia': frecuencia},
    );
  }
}