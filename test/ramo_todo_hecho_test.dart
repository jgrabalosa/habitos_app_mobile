import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/widgets/estados_hoy.dart';

/// En Dulce, con el día cerrado, el ramo ocupa el sitio de «¡Todo hecho!».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Widget montar(Widget child) => MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      NordayCoreLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: Scaffold(body: child),
  );

  testWidgets('RamoTodoHecho pinta el ramo y se lee con su nombre', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    await tester.pumpWidget(montar(const RamoTodoHecho(total: 3)));
    await tester.pumpAndSettle();

    expect(find.byType(RamoDulce), findsOneWidget);
    expect(tester.getSize(find.byType(RamoDulce)).height, 220);
    final etiqueta = tester
        .widget<Semantics>(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label ?? '').contains('Ramillete'),
          ),
        )
        .properties
        .label!;
    expect(etiqueta, contains(l.dashTodoHecho));
    expect(etiqueta, contains('Ramillete'));
  });

  testWidgets('con más de 8 hábitos, Gran ramo', (tester) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    await tester.pumpWidget(montar(const RamoTodoHecho(total: 12)));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics && (w.properties.label ?? '').contains('Gran ramo'),
      ),
      findsOneWidget,
    );
  });
}
