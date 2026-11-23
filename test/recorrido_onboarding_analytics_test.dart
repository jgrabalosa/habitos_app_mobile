import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/services/analytics_service.dart';
import 'package:habitos_app_mobile/services/recorrido_onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T-048: al cerrarse la pista del alta se registra `pista_cerrada`, una vez,
/// con `completa` = true si se pasó el último paso y false si se abandonó.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final enviados = <(String, Map<String, Object>)>[];
  late Future<void> Function(String, Map<String, Object>) original;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    enviados.clear();
    original = AnalyticsHabitos.enviarEvento;
    AnalyticsHabitos.enviarEvento = (n, p) async => enviados.add((n, p));
  });
  tearDown(() => AnalyticsHabitos.enviarEvento = original);

  Future<void> abrir(WidgetTester tester) async {
    late BuildContext contexto;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            contexto = c;
            return const Scaffold();
          },
        ),
      ),
    );
    RecorridoOnboarding.instancia.iniciar(
      contexto,
      pasos: const [
        PasoRecorrido(titulo: 'Uno', cuerpo: 'a', textoBoton: 'Siguiente'),
        PasoRecorrido(titulo: 'Dos', cuerpo: 'b', textoBoton: 'Entendido'),
      ],
      textoSaltar: 'Saltar',
    );
    await tester.pump();
  }

  testWidgets('pasar el último paso registra pista_cerrada completa=true', (
    tester,
  ) async {
    await abrir(tester);
    RecorridoOnboarding.instancia.avanzar();
    expect(enviados, isEmpty);
    RecorridoOnboarding.instancia.avanzar();
    await tester.pump();
    expect(enviados, hasLength(1));
    expect(enviados.single.$1, 'pista_cerrada');
    expect(enviados.single.$2, {'completa': 'true'});
  });

  testWidgets('abandonar la pista registra pista_cerrada completa=false', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.text('Saltar'));
    await tester.pump();
    expect(enviados, hasLength(1));
    expect(enviados.single.$1, 'pista_cerrada');
    expect(enviados.single.$2, {'completa': 'false'});
  });

  testWidgets('cerrar dos veces solo registra una', (tester) async {
    await abrir(tester);
    RecorridoOnboarding.instancia.terminar();
    RecorridoOnboarding.instancia.terminar();
    await tester.pump();
    expect(enviados, hasLength(1));
  });

  test('pistaCerrada no lanza aunque Firebase falle', () async {
    AnalyticsHabitos.enviarEvento = original;
    await expectLater(AnalyticsHabitos.pistaCerrada(completa: true), completes);
  });
}
