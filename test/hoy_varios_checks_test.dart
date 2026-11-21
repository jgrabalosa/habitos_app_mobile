import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/dashboard_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Varios checks seguidos en Hoy (T-045). Cada check con tránsito de fila
/// crea un `AnimationController` nuevo con `vsync: this`: con un
/// `SingleTickerProviderStateMixin` el segundo hace saltar el `assert` de
/// Flutter (solo en depuración, que es lo que corre `flutter test`) después
/// de marcar la fila y antes de publicar el progreso del día.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final usuarioOriginal = DashboardScreen.cargarUsuario;
  final hoyOriginal = DashboardScreen.cargarHoy;
  final completarOriginal = DashboardScreen.completarHabito;

  final hechos = <int>{};

  Map<String, dynamic> fila(int id) {
    final hecho = hechos.contains(id);
    return {
      'habito': {
        'habitoId': id,
        'nombre': 'Hábito $id',
        'frecuencia': 'DIARIO',
        'meta': 1,
        'activo': true,
      },
      'completados': hecho ? 1 : 0,
      'meta': 1,
      'hecho': hecho,
      'completadoEnFecha': hecho,
      'ritmoNivel': 2,
      'fechasCompletadas': hecho ? ['2026-11-15'] : <String>[],
    };
  }

  Map<String, dynamic> hoy() => {
    'fecha': '2026-11-15',
    'hoy': '2026-11-15',
    'dias': [
      for (var d = 9; d <= 15; d++)
        {'fecha': '2026-11-${d.toString().padLeft(2, '0')}', 'avance': 0.0},
    ],
    'avance': hechos.length / 4,
    'ritmoNivel': null,
    'delDia': {
      'hechos': hechos.length,
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
    hechos.clear();
    SharedPreferences.setMockInitialValues({
      'mini_mascota_oculta': true,
      'detalle_habito_descubierto': true,
    });
    DashboardScreen.cargarUsuario = () async => {'usuarioId': 7};
    DashboardScreen.cargarHoy = (int usuarioId, {String? fecha}) async => hoy();
    DashboardScreen.completarHabito = (int habitoId, {String? fecha}) async {
      hechos.add(habitoId);
      return {
        'logros': <String>[],
        'puntosGanados': 0,
        'registroId': habitoId,
        'mostrarValoracion': false,
      };
    };
  });

  tearDown(() {
    DashboardScreen.cargarUsuario = usuarioOriginal;
    DashboardScreen.cargarHoy = hoyOriginal;
    DashboardScreen.completarHabito = completarOriginal;
    marcarDiaCerrado(false);
    limpiarProgresoDia();
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  testWidgets(
    'tres checks seguidos en Dulce: el progreso llega a 3 y el ramo pinta 3 '
    'flores',
    (tester) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
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
          home: const Scaffold(body: DashboardScreen()),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      for (var n = 1; n <= 3; n++) {
        final pendiente = find
            .byWidgetPredicate(
              (w) => w is CheckCircular && !w.hecho && w.onTap != null,
            )
            .first;
        tester.widget<CheckCircular>(pendiente).onTap!();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: 'tras el check $n');
      }
      // Que acaben el tránsito, la pausa de la celebración y la recarga.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(progresoDiaNotifier.value.hechos, 3);
      expect(tester.widget<RamoDulce>(find.byType(RamoDulce)).flores, 3);
    },
  );
}
