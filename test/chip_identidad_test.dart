import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:habitos_app_mobile/widgets/identidad_ui.dart';

/// Lo semanal se marca con el tercer color de la identidad; lo diario sigue
/// con el acento principal.
void main() {
  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Color colorDelTexto(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text)).style!.color!;

  testWidgets('el chip de un semanal escribe en streakText', (tester) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      final t = temaEquipadoNotifier.value;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChipIdentidad(texto: 'Semanal', semanal: true)),
        ),
      );
      expect(colorDelTexto(tester), t.streakText, reason: codigo);
    }
  });

  testWidgets('el chip de un diario no cambia', (tester) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      final id = identidadEquipadaNotifier.value;
      final t = id.tokens;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChipIdentidad(texto: 'Diario')),
        ),
      );
      final esperado = id.forma == FormaIdentidad.pill
          ? t.successText
          : t.primary;
      expect(colorDelTexto(tester), esperado, reason: codigo);
    }
  });
}
