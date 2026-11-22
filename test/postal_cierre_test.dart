import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/dashboard_screen.dart';
import 'package:habitos_app_mobile/services/analytics_service.dart';
import 'package:habitos_app_mobile/services/postal_cierre.dart';
import 'package:habitos_app_mobile/widgets/panel_minutos.dart';
import 'package:habitos_app_mobile/widgets/tarjeta_cierre_dia.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `/hoy` con un solo hábito del día, de minutos, a 20 de 30: «Completar»
/// deja el día hecho y lo cierra.
Map<String, dynamic> hoyConUnHabito() => {
  'fecha': '2026-11-15',
  'hoy': '2026-11-15',
  'dias': [
    for (var d = 9; d <= 15; d++)
      {'fecha': '2026-11-${d.toString().padLeft(2, '0')}', 'avance': 0.0},
  ],
  'avance': 0.66,
  'ritmoNivel': null,
  'delDia': {
    'hechos': 0,
    'total': 1,
    'habitos': [
      {
        'habito': {
          'habitoId': 1,
          'nombre': 'Leer',
          'frecuencia': 'DIARIO',
          'meta': 1,
          'activo': true,
          'unidad': 'MINUTOS',
          'minutosObjetivo': 30,
        },
        'completados': 0,
        'meta': 1,
        'hecho': false,
        'completadoEnFecha': true,
        'ritmoNivel': 2,
        'fechasCompletadas': <String>[],
        'unidad': 'MINUTOS',
        'minutosHechos': 20,
        'minutosObjetivo': 30,
      },
    ],
  },
  'deLaSemana': {'hechos': 0, 'total': 0, 'habitos': <dynamic>[]},
  'logrosOtorgados': <String>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final usuarioOriginal = DashboardScreen.cargarUsuario;
  final hoyOriginal = DashboardScreen.cargarHoy;
  final resenaOriginal = DashboardScreen.solicitarResena;
  final completarOriginal = PanelMinutos.completar;
  final registrosOriginal = PanelMinutos.registros;
  final menuOriginal = PostalCierre.menu;
  final medirOriginal = PostalCierre.medir;

  late int minutosEnviados;
  late int peticionesResena;
  late List<ShareParams> enviados;
  late List<(String, int)> medidos;
  late ShareResultStatus estadoMenu;

  setUpAll(() async {
    await initializeDateFormatting();
    // El sonido de completar usa un plugin que en test no existe: con
    // `runAsync` su fallo llegaría al test.
    SonidoService.activado = false;
  });

  tearDownAll(() => SonidoService.activado = true);

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'mini_mascota_oculta': true,
      'detalle_habito_descubierto': true,
      'resena_dias_uso': 5,
      'resena_ultima_fecha': '2000-01-01',
      'resena_pendiente': true,
    });
    minutosEnviados = 0;
    peticionesResena = 0;
    enviados = [];
    medidos = [];
    estadoMenu = ShareResultStatus.success;
    DashboardScreen.cargarUsuario = () async => {'usuarioId': 7};
    DashboardScreen.cargarHoy = (int usuarioId, {String? fecha}) async {
      final hoy = hoyConUnHabito();
      final fila =
          (hoy['delDia'] as Map<String, dynamic>)['habitos'][0]
              as Map<String, dynamic>;
      final hechos = 20 + minutosEnviados;
      fila['minutosHechos'] = hechos;
      if (hechos >= 30) {
        fila['completados'] = 1;
        fila['hecho'] = true;
        (hoy['delDia'] as Map<String, dynamic>)['hechos'] = 1;
      }
      return hoy;
    };
    DashboardScreen.solicitarResena = () async => peticionesResena++;
    PanelMinutos.registros = (_) async => const [];
    PanelMinutos.completar =
        (
          int habitoId, {
          String? fecha,
          int? minutos,
          String? clave,
          String? origen,
        }) async {
          minutosEnviados += minutos ?? 0;
          return {'logros': <String>[], 'puntosGanados': 0};
        };
    PostalCierre.menu = (p) async {
      enviados.add(p);
      return ShareResult('', estadoMenu);
    };
    PostalCierre.medir = ({required identidad, required total}) async =>
        medidos.add((identidad, total));
  });

  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    DashboardScreen.cargarUsuario = usuarioOriginal;
    DashboardScreen.cargarHoy = hoyOriginal;
    DashboardScreen.solicitarResena = resenaOriginal;
    PanelMinutos.completar = completarOriginal;
    PanelMinutos.registros = registrosOriginal;
    PostalCierre.menu = menuOriginal;
    PostalCierre.medir = medirOriginal;
  });

  MaterialApp app(Widget home, {String idioma = 'es', bool conCapa = false}) =>
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        locale: Locale(idioma),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: conCapa
            ? (context, child) => Stack(
                children: [
                  child!,
                  const Positioned.fill(child: CapaCierreDelDia()),
                ],
              )
            : null,
        home: home,
      );

  final fecha = DateTime(2026, 11, 15);

  Finder enTarjeta(Finder f) =>
      find.descendant(of: find.byType(TarjetaCierreDia), matching: f);

  group('la postal', () {
    Future<void> montarTarjeta(
      WidgetTester tester, {
      String idioma = 'es',
      int total = 3,
      GlobalKey? clave,
    }) async {
      await tester.pumpWidget(
        app(
          Center(
            child: RepaintBoundary(
              key: clave,
              child: TarjetaCierreDia(total: total, fecha: fecha),
            ),
          ),
          idioma: idioma,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('el PNG mide 1080 × 1350', (tester) async {
      final clave = GlobalKey();
      await montarTarjeta(tester, clave: clave);
      final bytes = (await tester.runAsync(
        () => PostalCierre.capturarPostal(clave),
      ))!;
      expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
      int entero(int i) =>
          (bytes[i] << 24) |
          (bytes[i + 1] << 16) |
          (bytes[i + 2] << 8) |
          bytes[i + 3];
      expect(entero(16), 1080);
      expect(entero(20), 1350);
    });

    for (final codigo in [
      'TEMA_PROFUNDIDAD',
      'TEMA_NEOTOKYO_PLUS',
      'TEMA_DULCE',
    ]) {
      testWidgets('en $codigo lleva la figura, el nombre, la fecha y el número '
          'y ningún nombre de hábito', (tester) async {
        aplicarIdentidadEquipada(codigo);
        await montarTarjeta(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final figura = tester.widget<FiguraDelDia>(
          enTarjeta(find.byType(FiguraDelDia)),
        );
        expect(figura.total, 3);
        expect(figura.tamano, TarjetaCierreDia.ladoFigura);

        final core = await NordayCoreLocalizations.delegate.load(
          const Locale('es'),
        );
        final nombreEsperado = nombreFiguraDelDia(
          core,
          identidadEquipadaNotifier.value.fondo,
          3,
        );
        expect(nombreEsperado, isNotEmpty);
        expect(enTarjeta(find.text(nombreEsperado)), findsOneWidget);
        expect(
          enTarjeta(find.text('domingo, 15 de noviembre')),
          findsOneWidget,
        );
        expect(enTarjeta(find.text('3 hábitos hechos')), findsOneWidget);
        expect(enTarjeta(find.byType(WordmarkIdentidad)), findsOneWidget);
        expect(enTarjeta(find.text('Leer')), findsNothing);
      });
    }

    testWidgets('un solo hábito, en singular', (tester) async {
      await montarTarjeta(tester, total: 1);
      expect(enTarjeta(find.text('1 hábito hecho')), findsOneWidget);
    });

    testWidgets('en inglés y en portugués, también', (tester) async {
      await montarTarjeta(tester, idioma: 'en');
      expect(enTarjeta(find.text('3 habits done')), findsOneWidget);
      await montarTarjeta(tester, idioma: 'pt');
      expect(enTarjeta(find.text('3 hábitos feitos')), findsOneWidget);
    });
  });

  test('el texto que acompaña, en los tres idiomas, con el enlace aparte', () {
    const enlace = 'https://norday.app/invitar';
    expect(
      lookupAppLocalizations(const Locale('es')).cierreTextoCompartir(enlace),
      'Hoy he cerrado el día con Norday Habits.\n$enlace',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).cierreTextoCompartir(enlace),
      'Today I closed the day with Norday Habits.\n$enlace',
    );
    expect(
      lookupAppLocalizations(const Locale('pt')).cierreTextoCompartir(enlace),
      'Hoje fechei o dia com o Norday Habits.\n$enlace',
    );
  });

  test('los parámetros de cierre_compartido: identidad y total', () {
    expect(
      AnalyticsHabitos.parametrosCierreCompartido(
        identidad: 'TEMA_DULCE',
        total: 4,
      ),
      {'identidad': 'TEMA_DULCE', 'total_habitos': 4},
    );
  });

  group('al cerrar el día', () {
    Future<void> montar(WidgetTester tester, {String idioma = 'es'}) async {
      await tester.pumpWidget(
        app(
          const Scaffold(body: DashboardScreen()),
          idioma: idioma,
          conCapa: true,
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> avanzar(WidgetTester tester, [int pasos = 40]) async {
      for (var i = 0; i < pasos; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    /// Deja el día hecho y corre la secuencia hasta que sale la ceremonia.
    Future<void> completarElDia(WidgetTester tester) async {
      // El aro de minutos, cuya etiqueta cambia con el idioma: «… Leer. …».
      await tester.tap(find.bySemanticsLabel(RegExp(r'Leer\. \S')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(' · +'));
      await avanzar(tester);
    }

    /// La captura y el PNG son trabajo real del motor, no del reloj falso.
    Future<void> esperarMenu(WidgetTester tester) async {
      for (var i = 0; i < 100 && enviados.isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    for (final (idioma, boton, texto) in [
      (
        'es',
        'Compartir',
        'Hoy he cerrado el día con Norday Habits.\nhttps://norday.app/invitar',
      ),
      (
        'en',
        'Share',
        'Today I closed the day with Norday Habits.\nhttps://norday.app/invitar',
      ),
      (
        'pt',
        'Partilhar',
        'Hoje fechei o dia com o Norday Habits.\nhttps://norday.app/invitar',
      ),
    ]) {
      testWidgets('«$boton» abre el menú con la postal y el texto en $idioma, '
          'y no pide la reseña', (tester) async {
        aplicarIdentidadEquipada('TEMA_DULCE');
        await montar(tester, idioma: idioma);
        await completarElDia(tester);

        await tester.tap(find.text(boton));
        await tester.pump();
        await esperarMenu(tester);

        expect(enviados, hasLength(1));
        expect(enviados.single.text, texto);
        expect(enviados.single.fileNameOverrides, ['norday-cierre.png']);
        expect(enviados.single.files, hasLength(1));
        expect(enviados.single.files!.single.mimeType, 'image/png');
        expect(medidos, [('TEMA_DULCE', 1)]);

        // La reseña se queda para el siguiente cierre.
        final sp = await SharedPreferences.getInstance();
        expect(peticionesResena, 0);
        expect(sp.getBool('resena_pendiente'), isTrue);
      });
    }

    testWidgets('con el menú cancelado, Analytics no mide nada', (
      tester,
    ) async {
      estadoMenu = ShareResultStatus.dismissed;
      await montar(tester);
      await completarElDia(tester);
      await tester.tap(find.text('Compartir'));
      await tester.pump();
      await esperarMenu(tester);

      expect(enviados, hasLength(1));
      expect(medidos, isEmpty);
    });

    testWidgets('sin pulsar «Compartir», no se genera nada y la reseña sale', (
      tester,
    ) async {
      await montar(tester);
      await completarElDia(tester);
      expect(find.text('Compartir'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await avanzar(tester, 6);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );

      expect(enviados, isEmpty);
      expect(medidos, isEmpty);
      expect(peticionesResena, 1);
    });
  });
}
