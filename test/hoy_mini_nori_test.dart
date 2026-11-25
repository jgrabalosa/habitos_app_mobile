import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/dashboard_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mini Nori en Hoy (T-071b), con la maquetación real de Hoy: la lista con
/// relleno de 16 y los checks a la derecha de cada fila. Comprueba que Nori
/// va por toda la altura y que, arrastrada a la derecha, queda a entre 8 y 16
/// px del primer check sin taparlo. Si el hueco no cayera ahí con el
/// `margenDerecho` por defecto del core, no se arregla desde Hoy.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final usuarioOriginal = DashboardScreen.cargarUsuario;
  final hoyOriginal = DashboardScreen.cargarHoy;

  Map<String, dynamic> fila(int id) => {
    'habito': {
      'habitoId': id,
      'nombre': 'Hábito $id',
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
  };

  Map<String, dynamic> hoy() => {
    'fecha': '2026-11-15',
    'hoy': '2026-11-15',
    'dias': [
      for (var d = 9; d <= 15; d++)
        {'fecha': '2026-11-${d.toString().padLeft(2, '0')}', 'avance': 0.0},
    ],
    'avance': 0.0,
    'ritmoNivel': null,
    'delDia': {
      'hechos': 0,
      'total': 4,
      'habitos': [for (var id = 1; id <= 4; id++) fila(id)],
    },
    'deLaSemana': {'hechos': 0, 'total': 0, 'habitos': <dynamic>[]},
    'logrosOtorgados': <String>[],
  };

  setUpAll(() async {
    await initializeDateFormatting();
  });

  setUp(() {
    // Sin posición guardada: Nori parte de la esquina de arriba a la
    // izquierda del área.
    SharedPreferences.setMockInitialValues({
      'detalle_habito_descubierto': true,
    });
    DashboardScreen.cargarUsuario = () async => {'usuarioId': 7};
    DashboardScreen.cargarHoy = (int usuarioId, {String? fecha}) async => hoy();
  });

  tearDown(() {
    DashboardScreen.cargarUsuario = usuarioOriginal;
    DashboardScreen.cargarHoy = hoyOriginal;
    marcarDiaCerrado(false);
    limpiarProgresoDia();
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  Future<void> montarHoy(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
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
        home: const Scaffold(body: DashboardScreen()),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    // La mini Nori lee la mascota por red real (fuera del reloj falso del
    // test) y falla; se le da tiempo de verdad a fallar y a que aparezca.
    for (
      var i = 0;
      i < 20 && find.byType(MiniMascota).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // El vagabundeo de Nori deja un `Future.delayed` sin cancelar y el test
  // comprueba que no queda ninguno antes de sus tearDown: se desmonta Hoy
  // dentro del test, después de medir y antes de los `expect`, y se deja
  // pasar más que su espera máxima para que salte y no haga nada.
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  // La caja de Nori: la de gestos de la burbuja, que mide lo que la burbuja
  // tiene por tamaño.
  Finder cajaNori() => find
      .descendant(
        of: find.byType(MiniMascota),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width != null && w.width == w.height,
        ),
      )
      .first;

  testWidgets(
    'T-071b: arrastrada a la derecha, Nori queda entre 8 y 16 px del primer '
    'check',
    (tester) async {
      await montarHoy(tester);
      expect(find.byType(MiniMascota), findsOneWidget);

      await tester.drag(cajaNori(), const Offset(3000, 0));
      await tester.pump(const Duration(milliseconds: 500));

      final nori = tester.getRect(cajaNori());
      final check = tester.getRect(find.byType(CheckCircular).first);
      await desmontar(tester);
      final hueco = check.left - nori.right;
      expect(
        hueco,
        inInclusiveRange(8.0, 16.0),
        reason: 'Nori $nori, primer check $check',
      );
    },
  );

  testWidgets('T-071b: arrastrada del todo arriba, Nori pasa de la mitad', (
    tester,
  ) async {
    await montarHoy(tester);
    final area = tester.getRect(find.byType(DashboardScreen));

    await tester.drag(cajaNori(), const Offset(0, -3000));
    await tester.pump(const Duration(milliseconds: 500));

    final nori = tester.getRect(cajaNori());
    await desmontar(tester);
    expect(
      nori.top,
      lessThan(area.top + area.height / 2),
      reason: 'Nori $nori, área $area',
    );
  });
}
