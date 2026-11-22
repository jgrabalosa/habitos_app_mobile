import 'package:flutter/material.dart';
// Dependencia del core, no de la app: sólo se usa para simular el token.
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/habito_screen.dart';
import 'package:habitos_app_mobile/screens/home_shell.dart';
import 'package:habitos_app_mobile/services/recorrido_onboarding.dart';
import 'package:habitos_app_mobile/widgets/permiso_avisos.dart';
import 'package:habitos_app_mobile/widgets/regalo_gorro.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cuándo ofrece `HomeShell` la tarjeta del permiso de avisos (T-060): tras la
/// pista del primer hábito en el alta nueva, una vez en una apertura normal y
/// nunca junto a la tarjeta del gorro.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final llamadaOriginal = HomeShell.comprobarActualizacion;
  final categoriasOriginal = HabitoScreen.cargarCategorias;
  final crearOriginal = HabitoScreen.crearHabito;
  final identidadInicial = identidadEquipadaNotifier.value;

  late int pedidos;
  late int comprobaciones;

  setUp(() {
    pedidos = 0;
    comprobaciones = 0;
    SharedPreferences.setMockInitialValues({'usuarioId': 7});
    FlutterSecureStorage.setMockInitialValues({'token': 'token-de-prueba'});
    HomeShell.comprobarActualizacion = (_) async {
      comprobaciones++;
    };
    PermisoAvisos.concedido = () async => false;
    PermisoAvisos.bloqueadoEnAjustes = () async => false;
    PermisoAvisos.pedirYRegistrar = (_) async {
      pedidos++;
      return true;
    };
    // Sin red ni gorro por defecto.
    RegaloGorro.obtenerCatalogo = () async => [];
    RegaloGorro.obtenerInventario = (_) async => [];
    HabitoScreen.cargarCategorias = (_) async => [
      {'categoriaId': 2, 'codigo': 'CAT_ESTUDIO', 'nombre': 'Estudio'},
    ];
    HabitoScreen.crearHabito =
        (
          nombre,
          descripcion,
          frecuencia,
          meta,
          usuarioId,
          categoriaId, {
          diasSemana,
          recordatorioActivo = false,
          recordatorioHora,
          unidad,
          minutosObjetivo,
          icono,
        }) async {
          return <String>[];
        };
  });

  tearDown(() {
    RecorridoOnboarding.instancia.terminar();
    HomeShell.comprobarActualizacion = llamadaOriginal;
    HabitoScreen.cargarCategorias = categoriasOriginal;
    HabitoScreen.crearHabito = crearOriginal;
    PermisoAvisos.reiniciarParaTest();
    RegaloGorro.reiniciarParaTest();
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  Future<void> asentar(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> montar(WidgetTester tester, {required bool onboarding}) async {
    // Alta y formulario caben sin desplazarse.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          NordayCoreLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: HomeShell(mostrarOnboarding: onboarding),
      ),
    );
    await asentar(tester);
    await asentar(tester);
  }

  /// Del alta nueva: la bienvenida, «Crear uno desde cero» y el formulario con
  /// el recordatorio apagado (así el formulario no pregunta el permiso).
  Future<void> guardarPrimerHabito(
    WidgetTester tester,
    AppLocalizations l,
  ) async {
    await tester.tap(find.widgetWithText(ElevatedButton, l.bienvenidaCrear));
    await asentar(tester);
    await tester.tap(find.text(l.ideasDesdeCero));
    await asentar(tester);
    await tester.enterText(find.byType(TextField).first, 'Leer');
    // El recordatorio viene encendido y sin hora: sin apagarlo no guarda.
    await tester.ensureVisible(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.ensureVisible(find.text(l.habBotonCrear));
    await tester.pump();
    await tester.tap(find.text(l.habBotonCrear));
    await asentar(tester);
    await asentar(tester);
  }

  /// Desmonta y deja pasar los timers de la burbuja flotante del core, que no
  /// cancela al desmontarse: el test no termina con ninguno pendiente.
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  Future<AppLocalizations> textos() =>
      AppLocalizations.delegate.load(const Locale('es'));

  group('apertura normal', () {
    testWidgets('sale una vez, y no en la siguiente apertura', (tester) async {
      final l = await textos();
      await montar(tester, onboarding: false);
      expect(find.text(l.permisoAvisosTitulo), findsOneWidget);
      // El aviso de versión espera a que se cierre la tarjeta.
      expect(comprobaciones, 0);

      await tester.tap(find.text(l.permisoAvisosAhoraNo));
      await asentar(tester);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      expect(comprobaciones, 1);
      expect(pedidos, 0);

      // Otra apertura: se desmonta y se vuelve a montar con las mismas
      // preferencias.
      await desmontar(tester);
      await montar(tester, onboarding: false);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      await desmontar(tester);
    });

    testWidgets('no sale con permiso ni bloqueado en los ajustes', (
      tester,
    ) async {
      final l = await textos();
      PermisoAvisos.concedido = () async => true;
      await montar(tester, onboarding: false);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);

      await desmontar(tester);
      PermisoAvisos.concedido = () async => false;
      PermisoAvisos.bloqueadoEnAjustes = () async => true;
      await montar(tester, onboarding: false);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      await desmontar(tester);
    });

    testWidgets('no sale en la misma apertura que la tarjeta del gorro', (
      tester,
    ) async {
      final l = await textos();
      RegaloGorro.obtenerCatalogo = () async => [
        {
          'productoId': 77,
          'codigo': 'PRENDA_GORRO_NOEL',
          'categoria': 'Cabeza',
          'precio': 150,
          'ofertas': [
            {'desde': '2026-11-20', 'hasta': '2027-01-07', 'precio': 0},
          ],
        },
      ];
      RegaloGorro.ahora = () => DateTime(2026, 11, 22);
      RegaloGorro.comprar = (_, _) async => <String>[];
      RegaloGorro.equipar = (_, _, _, _) async => <String>[];

      await montar(tester, onboarding: false);
      expect(find.text(l.regaloGorroTitulo), findsOneWidget);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);

      await tester.tap(find.text(l.regaloGorroBoton));
      await asentar(tester);
      await asentar(tester);
      // Cerrada la del gorro, la del permiso espera a la siguiente apertura.
      expect(find.text(l.regaloGorroTitulo), findsNothing);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          PermisoAvisos.claveOfrecido,
        ),
        isNull,
      );
      await desmontar(tester);
    });
  });

  group('alta nueva', () {
    testWidgets('sale tras la pista del primer hábito y no antes', (
      tester,
    ) async {
      final l = await textos();
      await montar(tester, onboarding: true);
      expect(find.text(l.bienvenidaTitulo), findsOneWidget);
      await guardarPrimerHabito(tester, l);

      // Guardado: la pista está abierta y la tarjeta aún no.
      expect(find.text(l.pistaCheckTitulo), findsOneWidget);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);

      await tester.tap(find.text(l.recFin));
      await asentar(tester);
      await asentar(tester);

      expect(find.text(l.pistaCheckTitulo), findsNothing);
      expect(find.text(l.permisoAvisosTitulo), findsOneWidget);

      await tester.tap(find.text(l.permisoAvisosActivar));
      await asentar(tester);
      expect(pedidos, 1);
      // En un alta nueva no hay aviso de versión.
      expect(comprobaciones, 0);
      await desmontar(tester);
    });

    testWidgets('si el formulario ya preguntó el permiso, no sale', (
      tester,
    ) async {
      final l = await textos();
      SharedPreferences.setMockInitialValues({
        'usuarioId': 7,
        PermisoAvisos.claveOfrecido: true,
      });
      await montar(tester, onboarding: true);
      await guardarPrimerHabito(tester, l);
      await tester.tap(find.text(l.recFin));
      await asentar(tester);
      await asentar(tester);

      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      await desmontar(tester);
    });
  });
}
