import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// Dependencia del core, no de la app: sólo se usa para simular el token.
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/home_shell.dart';
import 'package:habitos_app_mobile/services/recorrido_onboarding.dart';
import 'package:habitos_app_mobile/widgets/permiso_avisos.dart';
import 'package:habitos_app_mobile/widgets/regalo_gorro.dart';
import 'package:habitos_app_mobile/widgets/tarjeta_semana.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «Así fue tu semana» (T-056): cuándo sale la tarjeta del lunes, qué cuenta y
/// qué no cuenta nunca.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final comprobarOriginal = HomeShell.comprobarActualizacion;

  // Lunes 23-nov-2026. La semana pasada: del 16 al 22.
  final lunes = DateTime(2026, 11, 23);

  Map<String, dynamic> semana({
    bool hayActividad = true,
    int hechos = 9,
    int diasCompletos = 3,
    String desde = '2026-11-16',
    String hasta = '2026-11-22',
  }) => {
    'desde': desde,
    'hasta': hasta,
    'hayActividad': hayActividad,
    'hechos': hechos,
    'total': 12,
    'diasCompletos': diasCompletos,
    'semanales': [
      {
        'habitoId': 1,
        'nombre': 'Correr',
        'icono': 'dumbbell',
        'hechos': 3,
        'meta': 3,
        'completo': true,
      },
      {
        'habitoId': 2,
        'nombre': 'Leer',
        'icono': 'book-open',
        'hechos': 1,
        'meta': 4,
        'completo': false,
      },
    ],
    'ritmoNivel': 4,
    'ritmoTendencia': 'SUBE',
    'masSube': {
      'habitoId': 1,
      'nombre': 'Correr',
      'nivelAntes': 2,
      'nivelAhora': 4,
    },
  };

  late int peticiones;
  late int medidas;
  late Map<String, dynamic> respuesta;
  late bool hayRed;

  setUp(() {
    peticiones = 0;
    medidas = 0;
    respuesta = semana();
    hayRed = true;
    SharedPreferences.setMockInitialValues({'usuarioId': 7});
    FlutterSecureStorage.setMockInitialValues({'token': 'token-de-prueba'});
    TarjetaSemana.ahora = () => lunes;
    TarjetaSemana.obtener = (_) async {
      peticiones++;
      if (!hayRed) throw const SocketException('sin red');
      return respuesta;
    };
    TarjetaSemana.medir = () async {
      medidas++;
    };
    HomeShell.comprobarActualizacion = (_) async {};
    PermisoAvisos.concedido = () async => true;
    PermisoAvisos.bloqueadoEnAjustes = () async => false;
    RegaloGorro.obtenerCatalogo = () async => [];
    RegaloGorro.obtenerInventario = (_) async => [];
  });

  tearDown(() {
    RecorridoOnboarding.instancia.terminar();
    TarjetaSemana.reiniciarParaTest();
    PermisoAvisos.reiniciarParaTest();
    RegaloGorro.reiniciarParaTest();
    HomeShell.comprobarActualizacion = comprobarOriginal;
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  Future<AppLocalizations> textos() =>
      AppLocalizations.delegate.load(const Locale('es'));

  Future<void> asentar(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Widget app(Widget home, {Locale locale = const Locale('es')}) => MaterialApp(
    locale: locale,
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      NordayCoreLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: home,
  );

  /// Una apertura de la app: se monta `HomeShell` y se deja pasar lo que sale
  /// al entrar.
  Future<void> abrirApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const HomeShell()));
    await asentar(tester);
    await asentar(tester);
  }

  /// Desmonta y deja pasar los timers de la burbuja flotante del core.
  Future<void> cerrarApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  Future<String?> vista() async =>
      (await SharedPreferences.getInstance()).getString('semana_vista_7');

  group('al abrir la app', () {
    testWidgets('sale el primer día con actividad y no el segundo', (
      tester,
    ) async {
      final l = await textos();
      await abrirApp(tester);
      expect(find.text(l.semanaTitulo), findsOneWidget);
      expect(find.text(l.semanaHiciste(9, 12)), findsOneWidget);
      expect(find.text(l.semanaDiasCompletos(3)), findsOneWidget);
      expect(find.text('Correr'), findsOneWidget);
      // Lo que no llegó a su objetivo no se nombra.
      expect(find.text('Leer'), findsNothing);
      expect(find.text(l.semanaSube), findsOneWidget);
      expect(find.text(l.semanaBoton), findsOneWidget);
      expect(medidas, 1);
      expect(await vista(), '2026-11-23');

      await tester.tap(find.text(l.semanaBoton));
      await asentar(tester);
      expect(find.text(l.semanaTitulo), findsNothing);
      await cerrarApp(tester);

      // Martes, otra apertura: la semana ya se vio y ni se pregunta.
      TarjetaSemana.ahora = () => DateTime(2026, 11, 24);
      await abrirApp(tester);
      expect(find.text(l.semanaTitulo), findsNothing);
      expect(peticiones, 1);
      expect(medidas, 1);
      await cerrarApp(tester);
    });

    testWidgets('la semana siguiente vuelve a salir', (tester) async {
      final l = await textos();
      SharedPreferences.setMockInitialValues({
        'usuarioId': 7,
        'semana_vista_7': '2026-11-16',
      });
      await abrirApp(tester);
      expect(find.text(l.semanaTitulo), findsOneWidget);
      await cerrarApp(tester);
    });

    testWidgets('sin actividad no sale', (tester) async {
      final l = await textos();
      respuesta = semana(hayActividad: false, hechos: 0, diasCompletos: 0);
      await abrirApp(tester);
      expect(find.text(l.semanaTitulo), findsNothing);
      expect(medidas, 0);
      await cerrarApp(tester);
    });

    testWidgets('sin red no sale y no se marca como vista', (tester) async {
      final l = await textos();
      hayRed = false;
      await abrirApp(tester);
      expect(find.text(l.semanaTitulo), findsNothing);
      expect(await vista(), isNull);
      expect(medidas, 0);
      await cerrarApp(tester);

      // Vuelve la red y, en la siguiente apertura de esa semana, sale.
      hayRed = true;
      await abrirApp(tester);
      expect(find.text(l.semanaTitulo), findsOneWidget);
      await cerrarApp(tester);
    });

    testWidgets('si el móvil va por delante del servidor, no sale', (
      tester,
    ) async {
      final l = await textos();
      // El servidor aún cuenta la semana anterior a la pasada.
      respuesta = semana(desde: '2026-11-16', hasta: '2026-11-29');
      await abrirApp(tester);
      expect(find.text(l.semanaTitulo), findsNothing);
      expect(await vista(), isNull);
      await cerrarApp(tester);
    });

    testWidgets('con la pista del alta abierta no sale ni se marca', (
      tester,
    ) async {
      final l = await textos();
      late BuildContext raiz;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (c) {
              raiz = c;
              return const Scaffold();
            },
          ),
        ),
      );
      RecorridoOnboarding.instancia.iniciar(
        raiz,
        pasos: const [
          PasoRecorrido(titulo: 'Uno', cuerpo: 'a', textoBoton: 'Vale'),
        ],
      );
      await tester.pump();
      expect(RecorridoOnboarding.instancia.activo, isTrue);
      final salio = await tester.runAsync(
        () => TarjetaSemana.mostrarSiToca(raiz, usuarioId: 7),
      );
      expect(salio, isFalse);
      expect(peticiones, 0);
      expect(await vista(), isNull);
      expect(find.text(l.semanaTitulo), findsNothing);
    });

    testWidgets('no sale en la misma apertura que otra tarjeta', (
      tester,
    ) async {
      final l = await textos();
      // El permiso de avisos sí sale (sin permiso ni marca).
      PermisoAvisos.concedido = () async => false;
      await abrirApp(tester);
      expect(find.text(l.permisoAvisosTitulo), findsOneWidget);
      await tester.tap(find.text(l.permisoAvisosAhoraNo));
      await asentar(tester);
      await asentar(tester);
      expect(find.text(l.semanaTitulo), findsNothing);
      // Ni se ha pedido ni se ha marcado: se intenta en la siguiente apertura.
      expect(peticiones, 0);
      expect(await vista(), isNull);
      await cerrarApp(tester);

      await abrirApp(tester);
      expect(find.text(l.semanaTitulo), findsOneWidget);
      await cerrarApp(tester);
    });
  });

  group('en cada identidad', () {
    for (final codigo in [
      'TEMA_PROFUNDIDAD',
      'TEMA_NEOTOKYO_PLUS',
      'TEMA_DULCE',
    ]) {
      testWidgets('$codigo: se pinta entera y se cierra con el botón', (
        tester,
      ) async {
        final l = await textos();
        aplicarIdentidadEquipada(codigo);
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        late BuildContext raiz;
        await tester.pumpWidget(
          app(
            Scaffold(
              body: Builder(
                builder: (c) {
                  raiz = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final futuro = TarjetaSemana.mostrarSiToca(raiz, usuarioId: 7);
        await asentar(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(SuperficieIdentidad), findsOneWidget);
        expect(find.text(l.semanaTitulo), findsOneWidget);
        expect(find.text(l.semanaFechas('16 nov', '22 nov')), findsOneWidget);
        expect(find.text(l.semanaRitmo(l.ritmoNivel4)), findsOneWidget);
        await tester.tap(find.text(l.semanaBoton));
        await tester.pumpAndSettle();
        expect(await futuro, isTrue);
        expect(find.text(l.semanaTitulo), findsNothing);
      });
    }
  });

  group('nunca lo que faltó', () {
    test('ningún texto de la tarjeta, en ningún idioma, nombra una falta', () {
      // Claves de la tarjeta; el ritmo reutiliza `ritmoNivel*`, que no hablan
      // de faltas.
      final prohibidas = RegExp(
        r'falt|fall|sin hacer|no hiciste|perdi|miss|fail|didn.t|without|'
        r'não fez|sem fazer|perdeu',
        caseSensitive: false,
      );
      for (final idioma in ['es', 'en', 'pt']) {
        final arb =
            jsonDecode(File('lib/l10n/app_$idioma.arb').readAsStringSync())
                as Map<String, dynamic>;
        final claves = arb.keys.where(
          (k) => k.startsWith('semana') && !k.startsWith('@'),
        );
        expect(claves, isNotEmpty);
        for (final k in claves) {
          expect(
            prohibidas.hasMatch(arb[k] as String),
            isFalse,
            reason: '$idioma/$k: «${arb[k]}» habla de lo que faltó',
          );
        }
      }
    });

    testWidgets('con días completos, solo se pintan los llenos', (
      tester,
    ) async {
      final l = await textos();
      respuesta = semana(hechos: 2, diasCompletos: 1);
      await abrirApp(tester);
      expect(find.text(l.semanaDiasCompletos(1)), findsOneWidget);
      // Sin «de 7», sin «te faltaron»: del total de días no se dice nada.
      expect(find.textContaining('7'), findsNothing);
      await cerrarApp(tester);
    });
  });
}
