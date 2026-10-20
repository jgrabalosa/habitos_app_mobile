import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:habitos_app_mobile/widgets/estrellas_registro.dart';

void main() {
  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Future<void> montar(WidgetTester tester, int valoracion) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EstrellasRegistro(valoracion: valoracion)),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<bool> marcadas(WidgetTester tester) => tester
      .widgetList<EstrellaValoracion>(find.byType(EstrellaValoracion))
      .map((e) => e.marcada)
      .toList();

  testWidgets('con valoración 3 marca las tres primeras y deja vacías dos', (
    tester,
  ) async {
    await montar(tester, 3);
    expect(find.byType(EstrellaValoracion), findsNWidgets(5));
    expect(marcadas(tester), [true, true, true, false, false]);
  });

  testWidgets('con 0 quedan 5 vacías y con 5 quedan 5 llenas', (tester) async {
    await montar(tester, 0);
    expect(marcadas(tester), [false, false, false, false, false]);

    await montar(tester, 5);
    expect(marcadas(tester), [true, true, true, true, true]);
  });

  testWidgets('un valor fuera de rango no revienta: 9 es 5 y -2 es 0', (
    tester,
  ) async {
    await montar(tester, 9);
    expect(marcadas(tester), [true, true, true, true, true]);

    await montar(tester, -2);
    expect(marcadas(tester), [false, false, false, false, false]);
  });

  testWidgets('cada estrella mide 14 por defecto en Dulce y en Profundidad', (
    tester,
  ) async {
    for (final codigo in ['TEMA_DULCE', 'TEMA_PROFUNDIDAD']) {
      aplicarIdentidadEquipada(codigo);
      await montar(tester, 2);
      for (var i = 0; i < 5; i++) {
        expect(
          tester.getSize(find.byType(EstrellaValoracion).at(i)),
          const Size(14, 14),
          reason: '$codigo estrella $i',
        );
      }
    }
  });
}
