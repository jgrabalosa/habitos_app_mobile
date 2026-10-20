import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/widgets/pausa_habito.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final inventarioOriginal = PausaHabito.inventario;
  final desactivarOriginal = PausaHabito.desactivar;
  tearDown(() {
    PausaHabito.inventario = inventarioOriginal;
    PausaHabito.desactivar = desactivarOriginal;
  });

  List<dynamic> conPausas(int cantidad) => [
    {
      'producto': {'codigo': 'PAUSA_HABITO'},
      'cantidad': cantidad,
    },
  ];

  Future<AppLocalizations> cargarL() =>
      AppLocalizations.delegate.load(const Locale('es'));

  /// Abre la ventana de pausa desde un botón y deja el resultado en [resultado].
  Future<void> abrir(WidgetTester tester, List<bool?> resultado) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resultado.add(
                  await pausarHabito(
                    context,
                    usuarioId: 7,
                    habitoId: 3,
                    nombre: 'Leer',
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'con pausas ofrece «Pausar (usa 1)»; al aceptar desactiva y devuelve true',
    (tester) async {
      final l = await cargarL();
      PausaHabito.inventario = (_) async => conPausas(1);
      final desactivados = <int>[];
      PausaHabito.desactivar = (id) async {
        desactivados.add(id);
      };
      final resultado = <bool?>[];

      await abrir(tester, resultado);
      expect(find.text(l.pausaBotonPausar), findsOneWidget);

      await tester.tap(find.text(l.pausaBotonPausar));
      await tester.pumpAndSettle();

      expect(desactivados, [3]);
      expect(resultado, [true]);
    },
  );

  testWidgets('sin pausas ofrece «Ir a la tienda» y no desactiva', (
    tester,
  ) async {
    final l = await cargarL();
    PausaHabito.inventario = (_) async => [];
    final desactivados = <int>[];
    PausaHabito.desactivar = (id) async {
      desactivados.add(id);
    };
    final resultado = <bool?>[];

    await abrir(tester, resultado);
    expect(find.text(l.pausaBotonTienda), findsOneWidget);
    expect(find.text(l.pausaBotonPausar), findsNothing);

    await tester.tap(find.text(l.cancelar));
    await tester.pumpAndSettle();
    expect(desactivados, isEmpty);
  });

  testWidgets('cancelar devuelve false y no desactiva', (tester) async {
    final l = await cargarL();
    PausaHabito.inventario = (_) async => conPausas(2);
    final desactivados = <int>[];
    PausaHabito.desactivar = (id) async {
      desactivados.add(id);
    };
    final resultado = <bool?>[];

    await abrir(tester, resultado);
    await tester.tap(find.text(l.cancelar));
    await tester.pumpAndSettle();

    expect(desactivados, isEmpty);
    expect(resultado, [false]);
  });
}
