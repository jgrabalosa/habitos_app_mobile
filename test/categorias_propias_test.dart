import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/habitos_screen.dart';
import 'package:habitos_app_mobile/services/api_service_habitos.dart';
import 'package:habitos_app_mobile/widgets/hoja_categoria.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final resumenOriginal = HabitosScreen.cargarResumen;
  final categoriasOriginal = HabitosScreen.cargarCategorias;
  final crearOriginal = HabitosScreen.crearCategoria;
  final actualizarOriginal = HabitosScreen.actualizarCategoria;
  final borrarOriginal = HabitosScreen.borrarCategoria;

  const global = {
    'categoriaId': 1,
    'codigo': 'CAT_SALUD',
    'nombre': 'Salud',
    'icono': '💪',
    'esGlobal': true,
  };
  const propia = {
    'categoriaId': 5,
    'codigo': null,
    'nombre': 'Casa',
    'icono': '🏠',
    'esGlobal': false,
  };

  late AppLocalizations l;
  late List<dynamic> categorias;

  setUp(() async {
    l = await AppLocalizations.delegate.load(const Locale('es'));
    categorias = [global, propia];
    HabitosScreen.cargarResumen = (_) async => <Map<String, dynamic>>[];
    HabitosScreen.cargarCategorias = (_) async => categorias;
  });

  tearDown(() {
    HabitosScreen.cargarResumen = resumenOriginal;
    HabitosScreen.cargarCategorias = categoriasOriginal;
    HabitosScreen.crearCategoria = crearOriginal;
    HabitosScreen.actualizarCategoria = actualizarOriginal;
    HabitosScreen.borrarCategoria = borrarOriginal;
  });

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        locale: const Locale('es'),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HabitosScreen(usuarioId: 7),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> mantener(WidgetTester tester, String texto) async {
    await tester.longPress(find.text(texto));
    await tester.pumpAndSettle();
  }

  bool todasElegida(WidgetTester tester) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, l.habitosTodas))
      .selected;

  group('Mis hábitos: categorías propias', () {
    testWidgets('mantener pulsada una propia abre la hoja', (tester) async {
      await montar(tester);
      await mantener(tester, '🏠 Casa');

      expect(find.text(l.catCambiar), findsOneWidget);
      expect(find.text(l.catBorrar), findsOneWidget);
    });

    testWidgets('una global no responde al mantener pulsado', (tester) async {
      await montar(tester);
      await mantener(tester, '💪 Salud');

      expect(find.text(l.catCambiar), findsNothing);
      expect(find.text(l.catBorrar), findsNothing);
    });

    testWidgets('el chip «+» abre la hoja de categoría nueva', (tester) async {
      HabitosScreen.crearCategoria = (nombre, icono) async => {
        'categoriaId': 6,
        'codigo': null,
        'nombre': nombre,
        'icono': icono,
        'esGlobal': false,
      };
      await montar(tester);
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();

      expect(find.text(l.catNuevaEtiqueta), findsOneWidget);
      expect(find.text(l.catGuardar), findsOneWidget);
    });

    testWidgets('el chip propio anuncia la pista de mantener pulsado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(tester);

      expect(
        tester.getSemantics(find.text('🏠 Casa')),
        isSemantics(
          hasLongPressAction: true,
          onLongPressHint: l.catPistaMantener,
        ),
      );
      // Una global no lo anuncia.
      expect(
        tester.getSemantics(find.text('💪 Salud')),
        isNot(isSemantics(hasLongPressAction: true)),
      );
      semantica.dispose();
    });

    testWidgets('borrar pide confirmación, llama a borrar y el filtro vuelve '
        'a «Todas»', (tester) async {
      final borradas = <int>[];
      HabitosScreen.borrarCategoria = (id) async {
        borradas.add(id);
        categorias = [global];
      };
      await montar(tester);
      await tester.tap(find.text('🏠 Casa'));
      await tester.pumpAndSettle();
      expect(todasElegida(tester), false);

      await mantener(tester, '🏠 Casa');
      await tester.tap(find.text(l.catBorrar));
      await tester.pumpAndSettle();

      // Pide confirmación y todavía no ha borrado nada.
      expect(find.text(l.catBorrarCuerpo), findsOneWidget);
      expect(borradas, isEmpty);

      await tester.tap(find.widgetWithText(TextButton, l.catBorrar));
      await tester.pumpAndSettle();

      expect(borradas, [5]);
      expect(find.text('🏠 Casa'), findsNothing);
      expect(todasElegida(tester), true);
    });

    testWidgets('cancelar la confirmación no borra', (tester) async {
      var llamadas = 0;
      HabitosScreen.borrarCategoria = (id) async => llamadas++;
      await montar(tester);
      await mantener(tester, '🏠 Casa');
      await tester.tap(find.text(l.catBorrar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.cancelar));
      await tester.pumpAndSettle();

      expect(llamadas, 0);
      expect(find.text('🏠 Casa'), findsOneWidget);
    });

    testWidgets('cambiar nombre o emoji manda el id y los datos nuevos', (
      tester,
    ) async {
      final cambios = <(int, String, String?)>[];
      HabitosScreen.actualizarCategoria = (id, nombre, icono) async {
        cambios.add((id, nombre, icono));
        return {...propia, 'nombre': nombre, 'icono': icono};
      };
      await montar(tester);
      await mantener(tester, '🏠 Casa');
      await tester.tap(find.text(l.catCambiar));
      await tester.pumpAndSettle();

      // La hoja llega con el nombre de la categoría.
      final campo = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(campo).controller!.text, 'Casa');
      await tester.enterText(campo, 'Hogar');
      await tester.tap(find.text('🎯'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, l.catGuardar));
      await tester.pumpAndSettle();

      expect(cambios, [(5, 'Hogar', '🎯')]);
    });
  });

  group('Emojis de categoría', () {
    test('son 16 y no se repiten', () {
      expect(emojisCategoria, hasLength(16));
      expect(emojisCategoria.toSet(), hasLength(16));
    });
  });

  group('Pista del lector de pantalla', () {
    // TalkBack ya antepone «Toca dos veces y mantén pulsado para…»: la pista
    // es solo la acción, o se leería «…para Mantén pulsado para…».
    for (final (idioma, gesto) in [
      ('es', 'pulsad'),
      ('en', 'hold'),
      ('pt', 'premid'),
    ]) {
      test('en $idioma no repite el gesto', () {
        final pista = lookupAppLocalizations(Locale(idioma)).catPistaMantener;
        expect(pista.toLowerCase(), isNot(contains(gesto)));
      });
    }
  });

  group('Longitud del nombre', () {
    // Como el servidor (CategoriaService): en code points, no en unidades
    // UTF-16. «👪» mide 2 en Dart y 1 en el servidor.
    test('un solo emoji astral es demasiado corto, como en el servidor', () {
      expect(nombreCategoriaValido('👪'), isFalse);
    });

    test('30 code points con un emoji astral valen', () {
      final nombre = '👪${'a' * 29}';
      expect(nombre.length, 31);
      expect(nombreCategoriaValido(nombre), isTrue);
    });

    test('31 code points no valen', () {
      expect(nombreCategoriaValido('a' * 31), isFalse);
    });
  });

  group('Mensaje del servidor', () {
    ApiException e(int codigo, String? cuerpo) => ApiException(
      TipoErrorApi.peticionInvalida,
      codigoEstado: codigo,
      cuerpo: cuerpo,
    );

    test('lee el texto de un 409 en JSON o plano', () {
      expect(
        ApiServiceHabitos.mensajeDelServidor(e(409, '{"message":"Repetida"}')),
        'Repetida',
      );
      expect(
        ApiServiceHabitos.mensajeDelServidor(e(409, 'Tope de 20')),
        'Tope de 20',
      );
    });

    test('otros códigos o sin texto, null', () {
      expect(ApiServiceHabitos.mensajeDelServidor(e(400, 'x')), isNull);
      expect(ApiServiceHabitos.mensajeDelServidor(e(409, '')), isNull);
      expect(ApiServiceHabitos.mensajeDelServidor(Exception('x')), isNull);
    });

    test('el body de crear lleva nombre e icono', () {
      expect(
        ApiServiceHabitos.cuerpoCategoria('Casa', '🏠'),
        '{"nombre":"Casa","icono":"🏠"}',
      );
      expect(
        ApiServiceHabitos.cuerpoCategoria('Casa', null),
        '{"nombre":"Casa","icono":null}',
      );
    });
  });
}
