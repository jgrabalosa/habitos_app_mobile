import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/widgets/bienvenida.dart';

/// La bienvenida de una tarjeta: Nori en huevo, la promesa, el sonido y el
/// botón que lleva al primer hábito.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Un botón que abre la bienvenida, como lo abre el shell.
  Widget montar() => MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      NordayCoreLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => Bienvenida.mostrar(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(montar());
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('la bienvenida enseña a Nori, el sonido y el botón de crear', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    await abrir(tester);

    expect(find.text(l.bienvenidaTitulo), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, l.bienvenidaCrear),
      findsOneWidget,
    );
  });

  testWidgets('el botón cierra la bienvenida', (tester) async {
    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    await abrir(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, l.bienvenidaCrear));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(l.bienvenidaTitulo), findsNothing);
  });

  testWidgets('sin emojis en el título ni en el cuerpo', (tester) async {
    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    await abrir(tester);

    for (final texto in [l.bienvenidaTitulo, l.bienvenidaCuerpo]) {
      expect(texto.contains('🎉'), isFalse, reason: texto);
      expect(texto.contains('🐣'), isFalse, reason: texto);
    }
  });
}
