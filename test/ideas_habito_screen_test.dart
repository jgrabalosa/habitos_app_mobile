import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/habito_screen.dart';
import 'package:habitos_app_mobile/screens/ideas_habito_screen.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final cargarCategoriasOriginal = HabitoScreen.cargarCategorias;

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
    for (final id in [
      'beberAgua',
      'leer20Min',
      'ejercicio',
      'meditar',
      'dormir8h',
      'caminar',
      'escribirDiario',
    ]) {
      // La lista es perezosa: las filas de abajo hay que llevarlas a la vista.
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('idea_$id')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
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
    expect(find.text('4'), findsOneWidget);
    final frecuencia = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(frecuencia.initialValue, 'DIARIO');
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
        l.plantillaBeberAgua,
        l.plantillaLeer20Min,
        l.plantillaEjercicio,
        l.plantillaMeditar,
        l.plantillaDormir8h,
        l.plantillaCaminar,
        l.plantillaEscribirDiario,
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
}
