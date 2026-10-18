import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:habitos_app_mobile/widgets/identidad_ui.dart';

/// Dulce a lápiz de color en las piezas de la app: el chip, las celdas de
/// heatmap y la pestaña de la barra de navegación. Profundidad y Neotokyo+ no
/// cambian en nada.
void main() {
  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  final dulce = catalogoIdentidades['TEMA_DULCE']!;

  ShapeDecoration celdaDulce({
    required bool llena,
    bool esHoy = false,
    bool vacia = false,
  }) =>
      celdaHeatmap(
            dulce,
            dulce.tokens,
            color: dulce.tokens.primary,
            llena: llena,
            esHoy: esHoy,
            vacia: vacia,
          )
          as ShapeDecoration;

  test(
    'en Dulce, la celda llena va a rayas; la vacía y la de hoy, a lápiz',
    () {
      final t = dulce.tokens;

      final llena = celdaDulce(llena: true).shape as BordeLapiz;
      expect(llena.rayas, isNotNull);

      final vacia = celdaDulce(llena: false, vacia: true).shape as BordeLapiz;
      expect(vacia.rayas, isNull);
      expect(vacia.side.color, t.aroVacio);

      final hoy = celdaDulce(llena: false, esHoy: true).shape as BordeLapiz;
      expect(hoy.side.color, t.primaryTrazo);
    },
  );

  test('en Profundidad y Neotokyo+, la celda sigue siendo BoxDecoration', () {
    for (final codigo in ['TEMA_PROFUNDIDAD', 'TEMA_NEOTOKYO_PLUS']) {
      final id = catalogoIdentidades[codigo]!;
      final t = id.tokens;

      final llena = celdaHeatmap(
        id,
        t,
        color: t.primary,
        llena: true,
        esHoy: false,
      );
      expect(llena, isA<BoxDecoration>(), reason: codigo);
      expect((llena as BoxDecoration).boxShadow, isNotEmpty, reason: codigo);

      final hoy =
          celdaHeatmap(id, t, color: t.inactivo, llena: false, esHoy: true)
              as BoxDecoration;
      expect((hoy.border! as Border).top.color, t.primaryTrazo, reason: codigo);
    }
  });

  testWidgets('en Dulce, el chip no tiene relleno y su forma es BordeLapiz', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    final t = temaEquipadoNotifier.value;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChipIdentidad(texto: 'Diario')),
      ),
    );

    final caja = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ChipIdentidad),
            matching: find.byType(Container),
          )
          .first,
    );
    final deco = caja.decoration! as ShapeDecoration;
    expect(deco.color, isNull);
    expect(deco.shape, isA<BordeLapiz>());
    expect((deco.shape as OutlinedBorder).side.color, t.primaryTrazo);
  });

  test(
    'en Dulce, la pestaña elegida va a rayas, con indicador transparente',
    () {
      final barra = barraNavegacionIdentidad(dulce, dulce.tokens, null);

      expect(barra.indicatorColor, Colors.transparent);
      final forma = barra.indicatorShape as BordeLapiz;
      expect(forma.rayas, isNotNull);
      expect(forma.side.color, dulce.tokens.primaryTrazo);
    },
  );
}
