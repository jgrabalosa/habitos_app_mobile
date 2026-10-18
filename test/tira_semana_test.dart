import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/models/hoy.dart';
import 'package:habitos_app_mobile/widgets/tira_semana.dart';

/// La tira de siete días, con sus flechas de semana en los extremos. A 360 de
/// ancho, con el mismo relleno lateral de Hoy, no puede desbordar en ninguna
/// identidad.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  final dias = [
    for (var i = 0; i < 7; i++)
      DiaTira(fecha: '2026-10-${12 + i}', avance: i.isEven ? 0.5 : null),
  ];

  TiraSemana tira({VoidCallback? anterior, VoidCallback? siguiente}) =>
      TiraSemana(
        dias: dias,
        diaSeleccionado: 2,
        indiceHoy: 2,
        onSeleccionar: (_) {},
        onSemanaAnterior: anterior ?? () {},
        onSemanaSiguiente: siguiente ?? () {},
      );

  Widget montar(Widget child) => MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    ),
  );

  testWidgets('hay una flecha a cada lado, y cada una llama a su callback', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    var anterior = 0;
    var siguiente = 0;

    await tester.pumpWidget(
      montar(tira(anterior: () => anterior++, siguiente: () => siguiente++)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Semana anterior'));
    expect(anterior, 1);
    expect(siguiente, 0);

    await tester.tap(find.byTooltip('Semana siguiente'));
    expect(siguiente, 1);
    expect(anterior, 1);
  });

  testWidgets('a 360 de ancho no desborda en ninguna identidad', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(montar(tira()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: codigo);

      // Un texto que no cabe se parte o se recorta sin dar error: se mide.
      // La columna de cada día mide (360 - 32 de relleno - 96 de flechas) / 7.
      const columna = (360 - 32 - 96) / 7;
      final textos = find.descendant(
        of: find.byType(TiraSemana),
        matching: find.byType(Text),
      );
      for (var i = 0; i < textos.evaluate().length; i++) {
        expect(
          tester.getSize(textos.at(i)).width,
          lessThanOrEqualTo(columna + 0.5),
          reason: '$codigo, texto $i',
        );
      }
    }
  });
}
