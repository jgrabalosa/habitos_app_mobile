import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/widgets/cabecera_otro_dia.dart';

/// La línea de encima de la tira: solo cuando el día que se mira no es hoy.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() => initializeDateFormatting('es'));

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Widget montar(Widget child) => MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: Scaffold(body: child),
  );

  testWidgets('viendo hoy no ocupa nada: ni mes ni botón', (tester) async {
    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    await tester.pumpWidget(
      montar(
        CabeceraOtroDia(
          fecha: DateTime(2026, 10, 18),
          viendoHoy: true,
          onHoy: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets(
    'en otro día sale el mes con mayúscula y el botón Hoy, que llama a onHoy',
    (tester) async {
      aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
      var pulsado = 0;
      await tester.pumpWidget(
        montar(
          CabeceraOtroDia(
            fecha: DateTime(2026, 10, 14),
            viendoHoy: false,
            onHoy: () => pulsado++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Octubre de 2026'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Hoy'));
      expect(pulsado, 1);
    },
  );
}
