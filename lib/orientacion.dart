import 'package:flutter/services.dart';

/// Fija la app en vertical. Se espera en `main()` antes de cualquier `runApp`,
/// también antes de la pantalla de entorno incorrecto.
Future<void> fijarOrientacionVertical() =>
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
