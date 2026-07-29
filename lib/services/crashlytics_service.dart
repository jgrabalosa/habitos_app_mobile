import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Motor: captura de errores no controlados. No conoce nada del dominio.
class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Engancha los dos canales por los que un error puede escaparse:
  /// los del framework (FlutterError) y los asincronos que no atrapa nadie
  /// (PlatformDispatcher). Llamar despues de Firebase.initializeApp().
  ///
  /// [recogerEnDebug] a true envia tambien los crashes de las compilaciones
  /// de debug, para poder probar la integracion antes de publicar.
  static Future<void> inicializar({bool recogerEnDebug = true}) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(recogerEnDebug);

    // recordFlutterFatalError sigue llamando a FlutterError.presentError,
    // asi que la consola roja de debug no se pierde.
    FlutterError.onError = _crashlytics.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Identifica la sesion en el panel de Crashlytics. Sin datos personales:
  /// solo el id que ya usa Analytics.
  static Future<void> identificarUsuario(int usuarioId) async {
    await _crashlytics.setUserIdentifier(usuarioId.toString());
  }

  /// Error no fatal: la app sigue viva pero queda registrado.
  static Future<void> registrarError(Object error, StackTrace? stack) async {
    await _crashlytics.recordError(error, stack, fatal: false);
  }

  /// Crash provocado, solo para comprobar que los informes llegan al panel.
  /// Mata el proceso: el informe se sube al siguiente arranque de la app.
  static void crashDePrueba() => _crashlytics.crash();
}
