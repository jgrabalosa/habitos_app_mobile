import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/dashboard_screen.dart';
import 'package:habitos_app_mobile/services/pistas_nori.dart';
import 'package:habitos_app_mobile/widgets/nota_pista.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Las pistas de Nori «la primera vez» (T-054): cada una sale la primera vez
/// y no la segunda, solo una al día, y sin animación con «reducir movimiento».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final usuarioOriginal = DashboardScreen.cargarUsuario;
  final hoyOriginal = DashboardScreen.cargarHoy;
  final completarOriginal = DashboardScreen.completarHabito;

  final vistas = <String>[];
  var extra = 0;

  Map<String, dynamic> fila(int id, String frecuencia) => {
    'habito': {
      'habitoId': id,
      'nombre': 'Hábito $id',
      'frecuencia': frecuencia,
      'meta': 1,
      'activo': true,
    },
    'completados': 0,
    'meta': 1,
    'hecho': false,
    'completadoEnFecha': false,
    'ritmoNivel': 2,
    'fechasCompletadas': <String>[],
  };

  // Un lunes: la semana empieza hoy.
  Map<String, dynamic> hoy({bool semanal = true}) => {
    'fecha': '2026-11-16',
    'hoy': '2026-11-16',
    'dias': [
      for (var d = 16; d <= 22; d++) {'fecha': '2026-11-$d', 'avance': 0.0},
    ],
    'avance': 0.0,
    'ritmoNivel': 2,
    'delDia': {
      'hechos': 0,
      'total': 1,
      'habitos': [fila(1, 'DIARIO')],
    },
    'deLaSemana': {
      'hechos': 0,
      'total': semanal ? 1 : 0,
      'habitos': semanal ? [fila(2, 'SEMANAL')] : <dynamic>[],
    },
    'logrosOtorgados': <String>[],
  };

  setUpAll(() async {
    await initializeDateFormatting();
  });

  void prefs([Map<String, Object> extras = const {}]) {
    SharedPreferences.setMockInitialValues({
      'mini_mascota_oculta': true,
      'detalle_habito_descubierto': true,
      ...extras,
    });
  }

  setUp(() {
    vistas.clear();
    extra = 0;
    PistasNori.reiniciar();
    PistasNori.ahora = () => DateTime(2026, 11, 16, 9);
    PistasNori.registrarVista = (id) async => vistas.add(id);
    DashboardScreen.cargarUsuario = () async => {'usuarioId': 7};
    DashboardScreen.cargarHoy = (int usuarioId, {String? fecha}) async => hoy();
    DashboardScreen.completarHabito = (int habitoId, {String? fecha}) async => {
      'logros': <String>[],
      'puntosGanados': 0,
      'puntosExtraSemana': extra,
      'registroId': habitoId,
      'mostrarValoracion': false,
    };
    prefs();
  });

  tearDown(() {
    DashboardScreen.cargarUsuario = usuarioOriginal;
    DashboardScreen.cargarHoy = hoyOriginal;
    DashboardScreen.completarHabito = completarOriginal;
    PistasNori.reiniciar();
    marcarDiaCerrado(false);
    limpiarProgresoDia();
  });

  Future<void> abrirHoy(WidgetTester tester, {bool reducir = false}) async {
    tester.view.physicalSize = const Size(1080, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        locale: const Locale('es'),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reducir),
          child: child!,
        ),
        home: const Scaffold(body: DashboardScreen()),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// Desmonta Hoy y lo vuelve a montar, como un segundo arranque.
  Future<void> reabrirHoy(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    PistasNori.reiniciar();
    await abrirHoy(tester);
  }

  const textoEsta =
      'Tus semanales, para cuando te venga bien antes del '
      'domingo.';
  const textoCerrada = 'Ha acabado la semana: tu ritmo se ha puesto al día.';
  const textoExtra = '¡Semana completa! Un 20 % más de puntos.';

  testWidgets('esta_semana sale la primera vez y no la segunda', (
    tester,
  ) async {
    await abrirHoy(tester);
    expect(find.text(textoEsta), findsOneWidget);
    expect(vistas, ['esta_semana']);

    // Otro día, otro arranque: ya la vio, no vuelve.
    PistasNori.ahora = () => DateTime(2026, 11, 17, 9);
    await reabrirHoy(tester);
    expect(find.byType(NotaPista), findsNothing);
    expect(vistas, ['esta_semana']);
  });

  testWidgets('tocar la nota la cierra', (tester) async {
    await abrirHoy(tester);
    await tester.tap(find.text(textoEsta));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NotaPista), findsNothing);
    expect(PistasNori.hayAbierta, isFalse);
  });

  testWidgets('semana_cerrada sale el primer día de una semana nueva y solo '
      'una vez', (tester) async {
    prefs({
      'pista_vista_7_esta_semana': true,
      // La última semana en que se abrió la app fue la anterior.
      'pista_semana_vista_7': '2026-11-09',
    });
    await abrirHoy(tester);
    expect(find.text(textoCerrada), findsOneWidget);
    expect(vistas, ['semana_cerrada']);

    PistasNori.ahora = () => DateTime(2026, 11, 17, 9);
    await reabrirHoy(tester);
    expect(find.byType(NotaPista), findsNothing);
    expect(vistas, ['semana_cerrada']);
  });

  testWidgets('semana_cerrada no sale sin semanales', (tester) async {
    DashboardScreen.cargarHoy = (int usuarioId, {String? fecha}) async =>
        hoy(semanal: false);
    prefs({'pista_semana_vista_7': '2026-11-09'});
    await abrirHoy(tester);
    expect(find.byType(NotaPista), findsNothing);
    expect(vistas, isEmpty);
  });

  testWidgets('extra_semana sale la primera vez que llega el extra y no la '
      'segunda', (tester) async {
    // La de «esta semana» ya la vio, otro día.
    prefs({
      'pista_vista_7_esta_semana': true,
      'pista_ultima_fecha_7': '2026-11-10',
      'pista_semana_vista_7': '2026-11-16',
    });
    extra = 20;
    await abrirHoy(tester);
    expect(find.byType(NotaPista), findsNothing);

    await tester.tap(find.byType(CheckCircular).last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text(textoExtra), findsOneWidget);
    expect(vistas, ['extra_semana']);

    // Otro día llega otro extra: ya no.
    PistasNori.ahora = () => DateTime(2026, 11, 23, 9);
    await reabrirHoy(tester);
    await tester.tap(find.byType(CheckCircular).last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(NotaPista), findsNothing);
    expect(vistas, ['extra_semana']);
  });

  testWidgets('dos el mismo día: solo sale la primera', (tester) async {
    // Hoy cumple las dos: sale ESTA SEMANA y es el primer día de la semana.
    prefs({'pista_semana_vista_7': '2026-11-09'});
    await abrirHoy(tester);
    expect(find.text(textoEsta), findsOneWidget);
    expect(find.text(textoCerrada), findsNothing);
    expect(vistas, ['esta_semana']);

    // Ni siquiera tras cerrar la nota: hoy ya salió una.
    await tester.tap(find.text(textoEsta));
    await tester.pump(const Duration(milliseconds: 500));
    await reabrirHoy(tester);
    expect(find.byType(NotaPista), findsNothing);
    expect(vistas, ['esta_semana']);
  });

  testWidgets('semana_cerrada que no pudo salir por otra pista sale otro día '
      'de la misma semana', (tester) async {
    // El lunes sale ESTA SEMANA y tapa a la de la semana cerrada.
    prefs({'pista_semana_vista_7': '2026-11-09'});
    await abrirHoy(tester);
    expect(vistas, ['esta_semana']);
    await tester.tap(find.text(textoEsta));
    await tester.pump(const Duration(milliseconds: 500));

    // El martes, la de la semana cerrada no se ha perdido.
    PistasNori.ahora = () => DateTime(2026, 11, 17, 9);
    await reabrirHoy(tester);
    expect(find.text(textoCerrada), findsOneWidget);
    expect(vistas, ['esta_semana', 'semana_cerrada']);
  });

  testWidgets('una pista que ya salió hoy impide otra, aunque esté cerrada', (
    tester,
  ) async {
    // «Esta semana» salió hoy por la mañana y se cerró: llega el extra.
    prefs({
      'pista_vista_7_esta_semana': true,
      'pista_ultima_fecha_7': '2026-11-16',
      'pista_semana_vista_7': '2026-11-16',
    });
    extra = 20;
    await abrirHoy(tester);
    await tester.tap(find.byType(CheckCircular).last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(NotaPista), findsNothing);
    expect(vistas, isEmpty);

    // Mañana sí podría salir, pero el extra de hoy ya pasó: la pista queda
    // sin ver hasta el siguiente extra.
    final p = await SharedPreferences.getInstance();
    expect(p.getBool('pista_vista_7_extra_semana'), isNull);
  });

  testWidgets('con reducir movimiento la nota entra sin animación', (
    tester,
  ) async {
    await abrirHoy(tester, reducir: true);
    expect(find.text(textoEsta), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NotaPista),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('sin reducir movimiento la nota entra con un fundido', (
    tester,
  ) async {
    await abrirHoy(tester);
    expect(
      find.descendant(
        of: find.byType(NotaPista),
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
  });
}
