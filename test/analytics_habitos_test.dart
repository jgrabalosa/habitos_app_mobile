import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/services/analytics_service.dart';

/// En los tests Firebase no está inicializado, así que cualquier llamada real
/// a Analytics falla. Es justo el caso que estos métodos no pueden dejar
/// escapar: habito_screen espera a habitoCreado dentro del try de guardar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('habitoCreado no lanza aunque Firebase falle', () async {
    await expectLater(AnalyticsHabitos.habitoCreado('DIARIO'), completes);
  });

  test('habitoCompletado no lanza aunque Firebase falle', () async {
    await expectLater(AnalyticsHabitos.habitoCompletado('DIARIO'), completes);
  });
}
