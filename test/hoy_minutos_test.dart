import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/dashboard_screen.dart';
import 'package:habitos_app_mobile/widgets/panel_minutos.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `/hoy` de un domingo con dos hábitos del día: uno de minutos a 20 de 30 y
/// uno de veces a 0 de 1.
Map<String, dynamic> hoyConMinutos() => {
  'fecha': '2026-11-15',
  'hoy': '2026-11-15',
  'dias': [
    for (var d = 9; d <= 15; d++)
      {'fecha': '2026-11-${d.toString().padLeft(2, '0')}', 'avance': 0.0},
  ],
  'avance': 0.33,
  'ritmoNivel': null,
  'delDia': {
    'hechos': 0,
    'total': 2,
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
      {
        'habito': {
          'habitoId': 2,
          'nombre': 'Beber agua',
          'frecuencia': 'DIARIO',
          'meta': 1,
          'activo': true,
        },
        'completados': 0,
        'meta': 1,
        'hecho': false,
        'completadoEnFecha': false,
        'ritmoNivel': 2,
        'fechasCompletadas': <String>[],
      },
    ],
  },
  'deLaSemana': {'hechos': 0, 'total': 0, 'habitos': <dynamic>[]},
  'logrosOtorgados': <String>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final usuarioOriginal = DashboardScreen.cargarUsuario;
  final hoyOriginal = DashboardScreen.cargarHoy;
  final completarOriginal = PanelMinutos.completar;
  final registrosOriginal = PanelMinutos.registros;

  late int cargasHoy;
  late AppLocalizations l;

  setUpAll(() async {
    await initializeDateFormatting();
    l = await AppLocalizations.delegate.load(const Locale('es'));
  });

  setUp(() {
    // La mini-mascota oculta y el detalle ya descubierto: nada que anime sin
    // fin ni que pida la mascota.
    SharedPreferences.setMockInitialValues({
      'mini_mascota_oculta': true,
      'detalle_habito_descubierto': true,
    });
    cargasHoy = 0;
    DashboardScreen.cargarUsuario = () async => {'usuarioId': 7};
    DashboardScreen.cargarHoy = (int usuarioId, {String? fecha}) async {
      cargasHoy++;
      return hoyConMinutos();
    };
    PanelMinutos.registros = (_) async => const [];
  });

  tearDown(() {
    DashboardScreen.cargarUsuario = usuarioOriginal;
    DashboardScreen.cargarHoy = hoyOriginal;
    PanelMinutos.completar = completarOriginal;
    PanelMinutos.registros = registrosOriginal;
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
        home: const Scaffold(body: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// El aro de la fila de minutos: el botón que anuncia sumar minutos.
  Finder aroDeLeer() =>
      find.bySemanticsLabel(l.a11yMinutosHabito('Leer', 20, 30));

  testWidgets('la fila de minutos lleva su chip y su aro; la de veces, check', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text(l.dashChipMinutos(l.frecDiario, 20, 30)), findsOneWidget);
    expect(find.text(l.dashChipFrecuencia(l.frecDiario, 0, 1)), findsOneWidget);
    // Un solo check (el de veces) y el aro de la identidad en la de minutos.
    expect(find.byType(CheckCircular), findsOneWidget);
    expect(find.byType(AnilloIdentidad), findsOneWidget);
    expect(aroDeLeer(), findsOneWidget);
  });

  testWidgets('tocar el aro abre el panel, no completa de golpe', (
    tester,
  ) async {
    var envios = 0;
    PanelMinutos.completar =
        (
          int habitoId, {
          String? fecha,
          int? minutos,
          String? clave,
          String? origen,
        }) async {
          envios++;
          return {'logros': <String>[], 'puntosGanados': 0};
        };
    await montar(tester);
    await tester.tap(aroDeLeer());
    await tester.pumpAndSettle();

    expect(envios, 0);
    expect(find.text('20 / 30 min'), findsOneWidget);
    expect(find.text(l.minSumaRapida(5)), findsOneWidget);
  });

  testWidgets('cerrar el panel tras un timeout hace que Hoy recargue', (
    tester,
  ) async {
    PanelMinutos.completar =
        (
          int habitoId, {
          String? fecha,
          int? minutos,
          String? clave,
          String? origen,
        }) async => throw const ApiException(TipoErrorApi.timeout);
    await montar(tester);
    final antes = cargasHoy;

    await tester.tap(aroDeLeer());
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.minSumaRapida(5)));
    await tester.pumpAndSettle();
    final NavigatorState nav = tester.state(find.byType(Navigator));
    await nav.maybePop();
    await tester.pumpAndSettle();

    expect(find.text(l.minSumaRapida(5)), findsNothing);
    expect(cargasHoy, antes + 1);
  });

  testWidgets('cerrar el panel sin enviar nada no recarga', (tester) async {
    await montar(tester);
    final antes = cargasHoy;
    await tester.tap(aroDeLeer());
    await tester.pumpAndSettle();
    final NavigatorState nav = tester.state(find.byType(Navigator));
    await nav.maybePop();
    await tester.pumpAndSettle();
    expect(cargasHoy, antes);
  });
}
