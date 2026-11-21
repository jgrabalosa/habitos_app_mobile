import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/dashboard_screen.dart';
import 'package:habitos_app_mobile/widgets/panel_minutos.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
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

  final usuarioOriginal = DashboardScreen.cargarUsuario;
  final hoyOriginal = DashboardScreen.cargarHoy;
  final resenaOriginal = DashboardScreen.solicitarResena;
  final completarOriginal = PanelMinutos.completar;
  final registrosOriginal = PanelMinutos.registros;

  late int peticionesResena;
  late int minutosEnviados;
  late AppLocalizations l;

  /// El servidor: parte de 20 min y suma lo que la app le ha enviado.
  Future<Map<String, dynamic>> cargarHoyDelServidor(
    int usuarioId, {
    String? fecha,
  }) async {
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
  }

  setUpAll(() async {
    await initializeDateFormatting();
    l = await AppLocalizations.delegate.load(const Locale('es'));
  });

  /// [diasUso] ya contados antes de hoy (ayer fue el último).
  void prefs({required int diasUso, bool pendiente = false}) {
    SharedPreferences.setMockInitialValues({
      'mini_mascota_oculta': true,
      'detalle_habito_descubierto': true,
      'resena_dias_uso': diasUso,
      'resena_ultima_fecha': '2000-01-01',
      if (pendiente) 'resena_pendiente': true,
    });
  }

  setUp(() {
    peticionesResena = 0;
    DashboardScreen.cargarUsuario = () async => {'usuarioId': 7};
    minutosEnviados = 0;
    DashboardScreen.cargarHoy = cargarHoyDelServidor;
    DashboardScreen.solicitarResena = () async {
      peticionesResena++;
    };
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
  });

  tearDown(() {
    DashboardScreen.cargarUsuario = usuarioOriginal;
    DashboardScreen.cargarHoy = hoyOriginal;
    DashboardScreen.solicitarResena = resenaOriginal;
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

  /// La ceremonia del cierre no se asienta (su animación no acaba): se avanza
  /// el reloj a pasos en vez de `pumpAndSettle`.
  Future<void> avanzar(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// Suma lo que falta desde el panel: deja el día hecho y corre toda la
  /// secuencia (celebración, día de uso y, si toca, cierre).
  Future<void> completarElDia(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp('Sumar minutos a Leer')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Completar ·'));
    await avanzar(tester);
  }

  /// Suma 5 minutos: cuenta el día de uso pero no deja el día hecho.
  Future<void> sumarSinCerrar(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp('Sumar minutos a Leer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.minSumaRapida(5)));
    await avanzar(tester);
  }

  testWidgets(
    'llegar al hito sin cerrar el día: no se pide y queda pendiente',
    (tester) async {
      prefs(diasUso: 2);
      await montar(tester);
      await sumarSinCerrar(tester);

      final sp = await SharedPreferences.getInstance();
      expect(sp.getInt('resena_dias_uso'), 3);
      expect(sp.getBool('resena_pendiente'), isTrue);
      expect(peticionesResena, 0);
    },
  );

  testWidgets('cerrar el día con una pendiente: se pide una vez y se borra', (
    tester,
  ) async {
    prefs(diasUso: 5, pendiente: true);
    await montar(tester);
    await completarElDia(tester);

    final sp = await SharedPreferences.getInstance();
    expect(peticionesResena, 1);
    expect(sp.containsKey('resena_pendiente'), isFalse);
  });

  testWidgets('el día del hito, si también se cierra el día: se pide en ese '
      'cierre', (tester) async {
    prefs(diasUso: 2);
    await montar(tester);
    await completarElDia(tester);

    final sp = await SharedPreferences.getInstance();
    expect(sp.getInt('resena_dias_uso'), 3);
    expect(peticionesResena, 1);
    expect(sp.containsKey('resena_pendiente'), isFalse);
  });

  testWidgets('sin pendiente, cerrar el día no pide nada', (tester) async {
    prefs(diasUso: 5);
    await montar(tester);
    await completarElDia(tester);

    expect(peticionesResena, 0);
  });

  testWidgets('la marca sigue después de volver a montar la pantalla', (
    tester,
  ) async {
    prefs(diasUso: 2);
    await montar(tester);
    await sumarSinCerrar(tester);

    await tester.pumpWidget(const SizedBox());
    await montar(tester);

    final sp = await SharedPreferences.getInstance();
    expect(sp.getBool('resena_pendiente'), isTrue);
    expect(peticionesResena, 0);

    // Y en el siguiente cierre, ya con la pantalla nueva, se pide.
    await completarElDia(tester);
    expect(peticionesResena, 1);
  });
}
