import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/models/plantilla_habito.dart';
import 'package:habitos_app_mobile/screens/habito_screen.dart';
import 'package:habitos_app_mobile/screens/ideas_habito_screen.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final cargarCategoriasOriginal = HabitoScreen.cargarCategorias;
  final crearOriginal = HabitoScreen.crearHabito;

  final categorias = [
    {'categoriaId': 2, 'codigo': 'CAT_ESTUDIO', 'nombre': 'Estudio'},
    {'categoriaId': 5, 'codigo': 'CAT_SALUD', 'nombre': 'Salud'},
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

  Widget montar(Widget child, {String locale = 'es', double textScale = 1}) =>
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        locale: Locale(locale),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: child,
      );

  /// La lista es perezosa: baja hasta que la fila de [id] está construida y
  /// la lleva a la vista.
  Future<void> llevarALaVista(WidgetTester tester, String id) async {
    final fila = find.byKey(ValueKey('idea_$id'), skipOffstage: false);
    for (var i = 0; i < 20 && fila.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(fila);
    await tester.pumpAndSettle();
  }

  Future<AppLocalizations> cargarL(String codigo) =>
      AppLocalizations.delegate.load(Locale(codigo));

  IdeasHabitoScreen ideas({
    List<String> existentes = const [],
    bool primer = false,
  }) => IdeasHabitoScreen(
    usuarioId: 7,
    categoriasIniciales: categorias,
    nombresHabitosExistentes: existentes,
    esPrimerHabito: primer,
  );

  testWidgets('crear desde cero es la primera fila', (tester) async {
    final l = await cargarL('es');
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();

    final desdeCero = tester.getTopLeft(find.text(l.ideasDesdeCero)).dy;
    final primeraIdea = tester
        .getTopLeft(find.byKey(const ValueKey('idea_beberAgua')))
        .dy;
    expect(desdeCero, lessThan(primeraIdea));
  });

  testWidgets('hay una fila por plantilla disponible', (tester) async {
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();
    for (final id in plantillasHabito.map((p) => p.id)) {
      await llevarALaVista(tester, id);
      expect(find.byKey(ValueKey('idea_$id')), findsOneWidget, reason: id);
    }
  });

  testWidgets('la sugerencia solo sale en el primer hábito', (tester) async {
    final l = await cargarL('es');

    await tester.pumpWidget(montar(ideas(primer: false)));
    await tester.pumpAndSettle();
    expect(find.text(l.ideasSugerencia), findsNothing);

    await tester.pumpWidget(montar(ideas(primer: true)));
    await tester.pumpAndSettle();
    expect(find.text(l.ideasSugerencia), findsOneWidget);
  });

  testWidgets('tocar una idea abre el formulario relleno', (tester) async {
    final l = await cargarL('es');
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('idea_beberAgua')));
    await tester.pumpAndSettle();

    final nombre = tester.widget<TextField>(find.byType(TextField).first);
    expect(nombre.controller!.text, l.plantillaBeberAgua);
    expect(find.text('4 veces al día'), findsOneWidget);
    final frecuencia = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(frecuencia.initialValue, 'DIARIO');
  });

  testWidgets('Leer abre el formulario en minutos, 30 min cada día', (
    tester,
  ) async {
    final l = await cargarL('es');
    Map<String, Object?>? creado;
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
            'nombre': nombre,
            'frecuencia': frecuencia,
            'meta': meta,
            'unidad': unidad,
            'minutosObjetivo': minutosObjetivo,
          };
          return <String>[];
        };
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();
    // Leer va casi al final (la lista sigue la hora del aviso).
    await llevarALaVista(tester, 'leer');
    await tester.tap(find.byKey(const ValueKey('idea_leer')));
    await tester.pumpAndSettle();

    final nombre = tester.widget<TextField>(find.byType(TextField).first);
    expect(nombre.controller!.text, 'Leer');
    final unidad = tester.widget<SegmentedButton<UnidadHabito>>(
      find.byType(SegmentedButton<UnidadHabito>),
    );
    expect(unidad.selected, {UnidadHabito.minutos});
    await tester.ensureVisible(find.text('30 min cada día'));
    expect(find.text('30 min cada día'), findsOneWidget);

    // Sin recordatorio, para poder guardar sin elegir hora.
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    final crear = find.widgetWithText(ElevatedButton, l.habBotonCrear);
    await tester.ensureVisible(crear);
    await tester.tap(crear);
    await tester.pumpAndSettle();
    expect(creado, {
      'nombre': 'Leer',
      'frecuencia': 'DIARIO',
      'meta': 1,
      'unidad': 'MINUTOS',
      'minutosObjetivo': 30,
    });
  });

  testWidgets('Meditar abre el formulario en minutos, 15 min cada día', (
    tester,
  ) async {
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('idea_meditar')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('idea_meditar')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('15 min cada día'));
    expect(find.text('15 min cada día'), findsOneWidget);
  });

  testWidgets('Beber agua sigue abriendo el formulario en veces', (
    tester,
  ) async {
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('idea_beberAgua')));
    await tester.pumpAndSettle();
    final unidad = tester.widget<SegmentedButton<UnidadHabito>>(
      find.byType(SegmentedButton<UnidadHabito>),
    );
    expect(unidad.selected, {UnidadHabito.veces});
  });

  testWidgets('la categoría de la plantilla queda elegida', (tester) async {
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('idea_beberAgua')));
    await tester.pumpAndSettle();

    final categoria = tester.widget<DropdownButtonFormField<int?>>(
      find.byType(DropdownButtonFormField<int?>),
    );
    expect(categoria.initialValue, 5);
  });

  testWidgets('tocar crear desde cero abre el formulario vacío', (
    tester,
  ) async {
    final l = await cargarL('es');
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l.ideasDesdeCero));
    await tester.pumpAndSettle();

    final nombre = tester.widget<TextField>(find.byType(TextField).first);
    expect(nombre.controller!.text, isEmpty);
    final frecuencia = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(frecuencia.initialValue, 'DIARIO');
  });

  testWidgets('atrás desde el formulario vuelve a la lista de ideas', (
    tester,
  ) async {
    final l = await cargarL('es');
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('idea_meditar')));
    await tester.pumpAndSettle();
    expect(find.byType(HabitoScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(l.ideasDesdeCero), findsOneWidget);
    expect(find.byType(HabitoScreen), findsNothing);
  });

  testWidgets('con Dulce, pt y texto a 1,5 no desborda', (tester) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    await tester.pumpWidget(
      montar(ideas(primer: true), locale: 'pt', textScale: 1.5),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'la categoría que llega después se aplica si el usuario no eligió otra',
    (tester) async {
      final llegada = Completer<List<dynamic>>();
      HabitoScreen.cargarCategorias = (_) => llegada.future;

      await tester.pumpWidget(montar(ideas()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('idea_beberAgua')));
      await tester.pumpAndSettle();

      llegada.complete(categorias);
      await tester.pumpAndSettle();

      final categoria = tester.widget<DropdownButtonFormField<int?>>(
        find.byType(DropdownButtonFormField<int?>),
      );
      expect(categoria.initialValue, 5);
    },
  );

  testWidgets(
    'si el usuario ya eligió otra categoría, la que llega después no la pisa',
    (tester) async {
      final llegada = Completer<List<dynamic>>();
      HabitoScreen.cargarCategorias = (_) => llegada.future;

      // Sin la categoría de la plantilla entre las que ya hay.
      await tester.pumpWidget(
        montar(
          IdeasHabitoScreen(
            usuarioId: 7,
            categoriasIniciales: [categorias.first],
            nombresHabitosExistentes: const [],
            esPrimerHabito: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('idea_beberAgua')));
      await tester.pumpAndSettle();

      tester
          .widget<DropdownButtonFormField<int?>>(
            find.byType(DropdownButtonFormField<int?>),
          )
          .onChanged!(2);
      await tester.pump();

      llegada.complete(categorias);
      await tester.pumpAndSettle();

      final categoria = tester.widget<DropdownButtonFormField<int?>>(
        find.byType(DropdownButtonFormField<int?>),
      );
      expect(categoria.initialValue, 2);
    },
  );

  testWidgets(
    'sin plantillas disponibles, abrirAltaHabito va directo al formulario',
    (tester) async {
      final l = await cargarL('es');
      final todas = [
        for (final p in plantillasHabito) nombrePlantilla(l, p.id),
      ];
      await tester.pumpWidget(
        montar(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => abrirAltaHabito(
                context,
                usuarioId: 7,
                categoriasIniciales: categorias,
                nombresHabitosExistentes: todas,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(HabitoScreen), findsOneWidget);
      expect(find.byType(IdeasHabitoScreen), findsNothing);
    },
  );

  testWidgets('la última idea no queda debajo de la barra de navegación', (
    tester,
  ) async {
    // Android 15 dibuja la app de borde a borde: la barra de navegación del
    // sistema (aquí, 48 px abajo) va encima de lo que la pantalla no aparte.
    addTearDown(tester.view.reset);
    const barra = 48.0;
    final dpr = tester.view.devicePixelRatio;
    tester.view.padding = FakeViewPadding(bottom: barra * dpr);
    tester.view.viewPadding = FakeViewPadding(bottom: barra * dpr);
    await tester.pumpWidget(montar(ideas()));
    await tester.pumpAndSettle();

    // Hasta el final de la lista.
    for (var i = 0; i < 20; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    final ultima = plantillasHabito.last.id;
    final fila = find.byKey(ValueKey('idea_$ultima'));
    expect(fila, findsOneWidget);
    final alto = tester.view.physicalSize.height / dpr;
    expect(tester.getRect(fila).bottom, lessThanOrEqualTo(alto - barra));
  });
}
