import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/services/crashlytics_service.dart';

/// En los tests Firebase no está inicializado, así que Crashlytics falla con
/// `[core/no-app]`. Identificar al usuario no puede dejar escapar ese fallo:
/// se llama sin esperar desde HomeShell.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('identificarUsuario no lanza aunque Firebase falle', () async {
    await expectLater(CrashlyticsService.identificarUsuario(7), completes);
  });
}
