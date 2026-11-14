import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/models/objetivo_programado.dart';
import 'package:habitos_app_mobile/screens/habito_screen.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final cargarCategoriasOriginal = HabitoScreen.cargarCategorias;
  final crearOriginal = HabitoScreen.crearHabito;
  final actualizarOriginal = HabitoScreen.actualizarHabito;
  final cargarProgramadoOriginal = HabitoScreen.cargarObjetivoProgramado;
  final anularOriginal = HabitoScreen.anularObjetivoProgramado;

  final categorias = [
    {'categoriaId': 2, 'codigo': 'CAT_ESTUDIO', 'nombre': 'Estudio'},
  ];

  setUp(() {
    // Sin red: las categorías son las del test.
    HabitoScreen.cargarCategorias = (_) async => categorias;
    HabitoScreen.cargarObjetivoProgramado = (_) async => null;
  });

  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    HabitoScreen.cargarCategorias = cargarCategoriasOriginal;
    HabitoScreen.crearHabito = crearOriginal;
    HabitoScreen.actualizarHabito = actualizarOriginal;
    HabitoScreen.cargarObjetivoProgramado = cargarProgramadoOriginal;
    HabitoScreen.anularObjetivoProgramado = anularOriginal;
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
    List<bool?> resultado, {
    Habito? habito,
    ObjetivoProgramado? programado,
  }) async {
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
                        builder: (_) => HabitoScreen(
                          usuarioId: 7,
                          habito: habito,
                          objetivoProgramado: programado,
                        ),
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
          String? unidad,
          int? minutosObjetivo,
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
            String? unidad,
            int? minutosObjetivo,
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
          String? unidad,
          int? minutosObjetivo,
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

  group('hábitos de minutos', () {
    /// Lo que recibe el falso de crear: el body que iría a la red.
    late Map<String, Object?> creado;

    setUp(() {
      creado = {};
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
            String? unidad,
            int? minutosObjetivo,
          }) async {
            creado = {
              'frecuencia': frecuencia,
              'meta': meta,
              'unidad': unidad,
              'minutosObjetivo': minutosObjetivo,
            };
            return <String>[];
          };
    });

    Habito habitoMinutos({int minutos = 30}) => Habito(
      habitoId: 3,
      nombre: 'Leer',
      frecuencia: 'DIARIO',
      meta: 1,
      activo: true,
      recordatorioActivo: false,
      unidad: UnidadHabito.minutos,
      minutosObjetivo: minutos,
    );

    testWidgets('uno de veces se crea sin campos de minutos, como siempre', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirFormulario(tester, []);
      await rellenar(tester, 'Beber agua');
      await guardar(tester, l);
      expect(creado['unidad'], isNull);
      expect(creado['minutosObjetivo'], isNull);
    });

    testWidgets('Minutos con la meta rápida de 15: diario, 1 día, 15 min', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirFormulario(tester, []);
      await rellenar(tester, 'Leer');
      await tester.ensureVisible(find.text(l.habUnidadMinutos));
      await tester.tap(find.text(l.habUnidadMinutos));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l.minCifra(15)));
      await tester.tap(find.text(l.minCifra(15)));
      await tester.pumpAndSettle();
      expect(find.text(l.habMinutosEtiquetaDiario(15)), findsOneWidget);
      await guardar(tester, l);

      expect(creado, {
        'frecuencia': 'DIARIO',
        'meta': 1,
        'unidad': 'MINUTOS',
        'minutosObjetivo': 15,
      });
    });

    testWidgets('una cifra propia fuera de 1-600 no se guarda', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      final resultado = <bool?>[];
      await abrirFormulario(tester, resultado);
      await rellenar(tester, 'Leer');
      await tester.ensureVisible(find.text(l.habUnidadMinutos));
      await tester.tap(find.text(l.habUnidadMinutos));
      await tester.pumpAndSettle();
      final otra = find.widgetWithText(ChoiceChip, l.habMinutosOtra);
      await tester.ensureVisible(otra);
      await tester.tap(otra);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, l.habMinutosOtra),
        '700',
      );
      await guardar(tester, l);

      expect(creado, isEmpty);
      expect(resultado, isEmpty);
      expect(find.text(l.habMinutosRango), findsOneWidget);
    });

    testWidgets('editando uno de minutos, «Veces» no se ofrece', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirFormulario(tester, [], habito: habitoMinutos());
      final segmento = tester.widget<SegmentedButton<UnidadHabito>>(
        find.byType(SegmentedButton<UnidadHabito>),
      );
      expect(
        segmento.segments
            .firstWhere((s) => s.value == UnidadHabito.veces)
            .enabled,
        isFalse,
      );
      expect(find.text(l.habUnidadSinVuelta), findsOneWidget);
    });

    testWidgets('si el cambio vale desde mañana, se avisa con los minutos', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      final hoy = DateTime.now();
      HabitoScreen.actualizarHabito =
          (
            int habitoId,
            String nombre,
            String descripcion,
            String frecuencia,
            int meta,
            int usuarioId,
            int? categoriaId, {
            String? diasSemana,
            bool recordatorioActivo = true,
            String? recordatorioHora,
            String? unidad,
            int? minutosObjetivo,
          }) async => DateTime(hoy.year, hoy.month, hoy.day + 1);

      final resultado = <bool?>[];
      await abrirFormulario(tester, resultado, habito: habitoMinutos());
      await tester.ensureVisible(find.text(l.minCifra(60)));
      await tester.tap(find.text(l.minCifra(60)));
      await tester.pumpAndSettle();
      final boton = find.widgetWithText(ElevatedButton, l.habBotonActualizar);
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(resultado, [true]);
      expect(find.text(l.habAplicaMinutosManana(60)), findsOneWidget);
    });

    testWidgets('el cambio programado se ve y se puede anular', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      final anulados = <int>[];
      HabitoScreen.anularObjetivoProgramado = (id) async => anulados.add(id);
      final hoy = DateTime.now();
      final programado = ObjetivoProgramado(
        desde: DateTime(hoy.year, hoy.month, hoy.day + 1),
        unidad: UnidadHabito.minutos,
        frecuencia: 'DIARIO',
        meta: 1,
        minutosObjetivo: 40,
      );

      final resultado = <bool?>[];
      await abrirFormulario(
        tester,
        resultado,
        habito: habitoMinutos(),
        programado: programado,
      );
      expect(find.text(l.habProgramadoTitulo), findsOneWidget);
      expect(find.text(l.progDesdeManana(l.minCifra(40))), findsOneWidget);

      await tester.tap(find.text(l.habProgramadoAnular));
      await tester.pumpAndSettle();
      expect(anulados, [3]);
      expect(find.text(l.habProgramadoTitulo), findsNothing);

      // Salir sin guardar avisa igual de que algo ha cambiado.
      final NavigatorState nav = tester.state(find.byType(Navigator));
      nav.maybePop();
      await tester.pumpAndSettle();
      expect(resultado, [true]);
    });
  });
}
