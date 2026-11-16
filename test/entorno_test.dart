import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/entorno.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

const _staging = 'https://staging-api.norday.app/api';

void main() {
  test('produccion contra producción arranca', () {
    expect(errorDeEntorno(flavor: 'produccion', url: urlProduccion), isNull);
  });

  test('produccion contra staging no arranca', () {
    expect(errorDeEntorno(flavor: 'produccion', url: _staging), isNotNull);
  });

  test('prueba contra staging arranca', () {
    expect(errorDeEntorno(flavor: 'prueba', url: _staging), isNull);
  });

  test('prueba contra producción no arranca', () {
    expect(errorDeEntorno(flavor: 'prueba', url: urlProduccion), isNotNull);
  });

  test('sin flavor o con uno desconocido no arranca', () {
    expect(errorDeEntorno(flavor: null, url: urlProduccion), isNotNull);
    expect(errorDeEntorno(flavor: 'otro', url: _staging), isNotNull);
  });

  test('urlProduccion es el valor por defecto del core', () {
    expect(ApiServiceCore.baseUrl, urlProduccion);
  });

  group('cinta de entorno', () {
    Widget app(String? flavor) => MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          conCintaDeEntorno(flavor, child ?? const SizedBox.shrink()),
      home: const Scaffold(body: Text('pantalla')),
    );

    testWidgets('prueba: «PRUEBA» encima de la pantalla', (tester) async {
      await tester.pumpWidget(app('prueba'));
      final cinta = tester.widget<Banner>(find.byType(Banner));
      expect(cinta.message, 'PRUEBA');
      expect(find.text('pantalla'), findsOneWidget);
    });

    testWidgets('produccion y sin flavor: sin cinta', (tester) async {
      for (final flavor in ['produccion', null]) {
        await tester.pumpWidget(app(flavor));
        expect(find.byType(Banner), findsNothing);
        expect(find.text('pantalla'), findsOneWidget);
      }
    });

    testWidgets('la cinta no se queda con los toques', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => conCintaDeEntorno('prueba', child!),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 80,
                height: 80,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => toques++,
                ),
              ),
            ),
          ),
        ),
      );
      // Justo debajo de la cinta (esquina de arriba a la derecha).
      final esquina = tester.getTopRight(find.byType(GestureDetector));
      await tester.tapAt(esquina + const Offset(-20, 20));
      expect(toques, 1);
    });
  });
}
