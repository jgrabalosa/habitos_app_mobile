import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:habitos_app_mobile/main.dart';

/// El grano de papel encima de toda la app: lo pone el `builder` del
/// MaterialApp, así que cubre pantallas, diálogos y hojas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  int pulsado = 0;

  Widget montar() => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    builder: envolverConGrano,
    home: Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => pulsado++,
          child: const Text('pulsa'),
        ),
      ),
    ),
  );

  testWidgets(
    'en Dulce, el grano va encima del contenido, en un RepaintBoundary',
    (tester) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      await tester.pumpWidget(montar());
      await tester.pump();

      expect(find.byType(GranoPapel), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(GranoPapel),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
      // Encima del botón: en el árbol, el grano va después, en la misma pila.
      final pila = find.ancestor(
        of: find.byType(GranoPapel),
        matching: find.byType(Stack),
      );
      expect(pila, findsWidgets);
      expect(
        find.descendant(of: pila.first, matching: find.text('pulsa')),
        findsOneWidget,
      );
    },
  );

  testWidgets('un botón del contenido sigue recibiendo el toque', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    pulsado = 0;
    await tester.pumpWidget(montar());
    await tester.pump();

    await tester.tap(find.text('pulsa'));
    expect(pulsado, 1);
  });

  testWidgets('al cambiar de Dulce a Profundidad, el grano deja de pintar', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    await tester.pumpWidget(montar());
    await tester.pump();
    expect(find.byKey(const ValueKey('TEMA_DULCE')), findsOneWidget);

    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    await tester.pumpWidget(montar());
    await tester.pump();

    expect(find.byKey(const ValueKey('TEMA_PROFUNDIDAD')), findsOneWidget);
    expect(find.byKey(const ValueKey('TEMA_DULCE')), findsNothing);
    expect(
      find.descendant(
        of: find.byType(GranoPapel),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });
}
