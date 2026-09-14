import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/widgets/transito_fila.dart';

/// `RanuraTransito` no tiene ticker propio (es un `StatelessWidget` puro en
/// función de `progreso`), así que no hace falta `pumpAndSettle` en ningún
/// test de este fichero: un `pumpWidget` basta para que el árbol quede
/// asentado en ese instante.

/// Altura real que ocupa la ranura para un `progreso`/`papel`/`curva` dados,
/// midiendo el árbol ya construido en vez de leer el cálculo interno: es lo
/// que demuestra que `Align`+`ClipRect` hacen lo que dice la clase, no sólo
/// que la fórmula esté bien.
Future<double> alturaDe(
  WidgetTester tester, {
  required double progreso,
  required PapelTransito papel,
  required Curve curva,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          RanuraTransito(
            progreso: progreso,
            papel: papel,
            curva: curva,
            child: const SizedBox(height: 100, width: 50),
          ),
        ],
      ),
    ),
  ));
  return tester.getSize(find.byType(RanuraTransito)).height;
}

void main() {
  const curvas = [
    Curves.easeOutCubic,
    Curves.easeOutExpo,
    Curves.easeInOutSine,
    Curves.easeOutBack,
  ];

  testWidgets('con progreso 0.0 el origen ocupa su altura íntegra y el destino 0',
      (tester) async {
    final alturaOrigen = await alturaDe(tester,
        progreso: 0.0, papel: PapelTransito.origen, curva: Curves.easeOutCubic);
    final alturaDestino = await alturaDe(tester,
        progreso: 0.0, papel: PapelTransito.destino, curva: Curves.easeOutCubic);

    expect(alturaOrigen, 100.0);
    expect(alturaDestino, 0.0);
  });

  testWidgets('con progreso 1.0 el origen ocupa 0 y el destino su altura íntegra',
      (tester) async {
    final alturaOrigen = await alturaDe(tester,
        progreso: 1.0, papel: PapelTransito.origen, curva: Curves.easeOutCubic);
    final alturaDestino = await alturaDe(tester,
        progreso: 1.0, papel: PapelTransito.destino, curva: Curves.easeOutCubic);

    expect(alturaOrigen, 0.0);
    expect(alturaDestino, 100.0);
  });

  testWidgets(
      'la suma de las dos alturas se mantiene constante en todo el recorrido, '
      'para las cuatro curvas del catálogo', (tester) async {
    const progresos = [0.0, 0.25, 0.5, 0.75, 1.0];

    for (final curva in curvas) {
      for (final progreso in progresos) {
        final alturaOrigen = await alturaDe(tester,
            progreso: progreso, papel: PapelTransito.origen, curva: curva);
        final alturaDestino = await alturaDe(tester,
            progreso: progreso, papel: PapelTransito.destino, curva: curva);

        expect(alturaOrigen + alturaDestino, closeTo(100.0, 0.001),
            reason: 'curva=$curva progreso=$progreso');
      }
    }
  });

  testWidgets(
      'con Curves.easeOutBack no salta ningún assert en ningún punto del recorrido',
      (tester) async {
    for (int i = 0; i <= 20; i++) {
      final progreso = i * 0.05;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RanuraTransito(
                progreso: progreso,
                papel: PapelTransito.origen,
                curva: Curves.easeOutBack,
                child: const SizedBox(height: 100, width: 50),
              ),
              RanuraTransito(
                progreso: progreso,
                papel: PapelTransito.destino,
                curva: Curves.easeOutBack,
                child: const SizedBox(height: 100, width: 50),
              ),
            ],
          ),
        ),
      ));

      expect(tester.takeException(), isNull, reason: 'progreso=$progreso');
    }
  });
}
