import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/services/abrir_enfoque.dart';
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

  test('habitoCreado con plantilla y unidad no lanza', () async {
    await expectLater(
      AnalyticsHabitos.habitoCreado(
        'DIARIO',
        plantilla: 'leer',
        unidad: 'minutos',
      ),
      completes,
    );
  });

  test('permisoAvisos no lanza aunque Firebase falle', () async {
    await expectLater(AnalyticsHabitos.permisoAvisos(true), completes);
    await expectLater(AnalyticsHabitos.permisoAvisos(false), completes);
  });

  test('enfoqueAbierto no lanza aunque Firebase falle', () async {
    for (final a in AperturaEnfoque.values) {
      await expectLater(AnalyticsHabitos.enfoqueAbierto(a), completes);
    }
  });

  test('resultadoEnfoque queda dentro de los cuatro valores', () {
    expect(AnalyticsHabitos.resultadoEnfoque(AperturaEnfoque.app), 'app');
    expect(
      AnalyticsHabitos.resultadoEnfoque(AperturaEnfoque.fichaPlay),
      'ficha_play',
    );
    expect(
      AnalyticsHabitos.resultadoEnfoque(AperturaEnfoque.fichaWeb),
      'ficha_web',
    );
    expect(AnalyticsHabitos.resultadoEnfoque(AperturaEnfoque.nada), 'nada');
    expect(
      AnalyticsHabitos.resultadoEnfoque(AperturaEnfoque.faltaPrueba),
      'nada',
    );
  });

  test('identidadElegida no lanza aunque Firebase falle', () async {
    await expectLater(
      AnalyticsHabitos.identidadElegida('TEMA_PROFUNDIDAD'),
      completes,
    );
  });

  test('invitarAbierto no lanza aunque Firebase falle', () async {
    await expectLater(AnalyticsHabitos.invitarAbierto(), completes);
  });

  test('invitarCompartido no lanza aunque Firebase falle', () async {
    await expectLater(
      AnalyticsHabitos.invitarCompartido('compartido'),
      completes,
    );
  });
}
