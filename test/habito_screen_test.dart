import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/habito_screen.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final cargarCategoriasOriginal = HabitoScreen.cargarCategorias;
  final crearOriginal = HabitoScreen.crearHabito;

  final categorias = [
    {'categoriaId': 2, 'codigo': 'CAT_ESTUDIO', 'nombre': 'Estudio'},
  ];

  setUp(() {
    // Sin red: las categorías son las del test.
    HabitoScreen.cargarCategorias = (_) async => categorias;
  });

  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    HabitoScreen.cargarCategorias = cargarCategoriasOriginal;
    HabitoScreen.crearHabito = crearOriginal;
  });

  Widget montar(Widget child) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: const Locale('es'),
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      ...NordayCoreLocalizations.localizationsDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  /// Abre el formulario como lo abre la lista: un push que espera un bool.
  /// [resultado] recibe lo que devuelve el push cuando la pantalla se cierra.
  Future<void> abrirFormulario(
    WidgetTester tester,
    List<bool?> resultado,
  ) async {
    await tester.pumpWidget(
      montar(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado.add(
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HabitoScreen(usuarioId: 7),
                      ),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  /// Escribe el nombre y apaga el recordatorio: con recordatorio activo y sin
  /// hora el formulario da error antes de llamar a nada.
  Future<void> rellenar(WidgetTester tester, String nombre) async {
    await tester.enterText(find.byType(TextField).first, nombre);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
  }

  Future<void> guardar(WidgetTester tester, AppLocalizations l) async {
    final boton = find.widgetWithText(ElevatedButton, l.habBotonCrear);
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  testWidgets('guardar un hábito nuevo devuelve true y cierra la pantalla', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    var llamadas = 0;
    HabitoScreen.crearHabito =
        (
          String nombre,
          String descripcion,
          String frecuencia,
          int meta,
          int usuarioId,
          int? categoriaId, {
          String? diasSemana,
          bool recordatorioActivo = true,
          String? recordatorioHora,
        }) async {
          llamadas++;
          return <String>[];
        };

    final resultado = <bool?>[];
    await abrirFormulario(tester, resultado);
    await rellenar(tester, 'Meditar');
    await guardar(tester, l);

    expect(llamadas, 1);
    expect(resultado, [true]);
    expect(find.byType(HabitoScreen), findsNothing);
  });

  testWidgets(
    'si el servidor falla, no se cierra, muestra el error y no devuelve true',
    (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      HabitoScreen.crearHabito =
          (
            String nombre,
            String descripcion,
            String frecuencia,
            int meta,
            int usuarioId,
            int? categoriaId, {
            String? diasSemana,
            bool recordatorioActivo = true,
            String? recordatorioHora,
          }) async {
            throw Exception('fallo de prueba');
          };

      final resultado = <bool?>[];
      await abrirFormulario(tester, resultado);
      await rellenar(tester, 'Meditar');
      await guardar(tester, l);

      expect(resultado, isEmpty);
      expect(find.byType(HabitoScreen), findsOneWidget);
      expect(find.text(l.habErrorCrear), findsOneWidget);
    },
  );

  testWidgets('nombre vacío: no llama a la red y avisa del nombre', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    var llamadas = 0;
    HabitoScreen.crearHabito =
        (
          String nombre,
          String descripcion,
          String frecuencia,
          int meta,
          int usuarioId,
          int? categoriaId, {
          String? diasSemana,
          bool recordatorioActivo = true,
          String? recordatorioHora,
        }) async {
          llamadas++;
          return <String>[];
        };

    final resultado = <bool?>[];
    await abrirFormulario(tester, resultado);
    await rellenar(tester, '');
    await guardar(tester, l);

    expect(llamadas, 0);
    expect(resultado, isEmpty);
    expect(find.text(l.habNombreObligatorio), findsOneWidget);
  });
}
