import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/widgets/resumen_detalle.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Future<void> montar(WidgetTester tester, {required bool mesActual}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ResumenDetalle(
            totalCompletados: 7,
            diasMes: 3,
            mesActual: mesActual,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra las dos cifras y sus etiquetas', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    await montar(tester, mesActual: true);

    expect(find.text('7'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text(l.detLoQueLlevas), findsOneWidget);
    expect(find.text(l.detDiasEsteMes), findsOneWidget);
  });

  testWidgets('con un mes pasado usa la etiqueta de mes del pasado', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    await montar(tester, mesActual: false);

    expect(find.text(l.detDiasDelMes), findsOneWidget);
    expect(find.text(l.detDiasEsteMes), findsNothing);
  });

  testWidgets('hay dos ayudas, ambas en superíndice', (tester) async {
    await montar(tester, mesActual: true);

    final ayudas = tester.widgetList<AyudaCampo>(find.byType(AyudaCampo));
    expect(ayudas.length, 2);
    for (final ayuda in ayudas) {
      expect(ayuda.superindice, isTrue);
    }
  });

  testWidgets('cada ayuda lleva su texto y su etiqueta de lector', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    await montar(tester, mesActual: true);

    final ayudas = tester
        .widgetList<AyudaCampo>(find.byType(AyudaCampo))
        .toList();
    expect(ayudas[0].texto, l.detAyudaLoQueLlevas);
    expect(ayudas[0].etiquetaSemantica, l.detAyudaLoQueLlevasEtiqueta);
    expect(ayudas[1].texto, l.detAyudaDiasMes);
    expect(ayudas[1].etiquetaSemantica, l.detAyudaDiasMesEtiqueta);
  });

  test(
    'los textos de ayuda existen, no están vacíos y son distintos en es, en y pt',
    () async {
      for (final codigo in ['es', 'en', 'pt']) {
        final l = await AppLocalizations.delegate.load(Locale(codigo));
        final textos = [
          l.detAyudaLoQueLlevasEtiqueta,
          l.detAyudaLoQueLlevas,
          l.detAyudaDiasMesEtiqueta,
          l.detAyudaDiasMes,
        ];
        for (final texto in textos) {
          expect(texto.trim(), isNotEmpty, reason: codigo);
        }
        expect(textos.toSet().length, 4, reason: codigo);
      }
    },
  );
}
