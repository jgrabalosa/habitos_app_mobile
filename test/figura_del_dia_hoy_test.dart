import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/dashboard_screen.dart';
import 'package:habitos_app_mobile/widgets/estados_hoy.dart';
import 'package:habitos_app_mobile/widgets/tira_semana.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La figura del día en su sitio de la lista de Hoy (D-41): el letrero de
/// Neotokyo+ y el ramo de Dulce, siempre arriba de la sección «Hoy», bajo su
/// título y encima del primer hábito, que crecen ahí con cada hábito hecho. Profundidad sigue con su constelación
/// en la capa y con la tarjeta invisible en el sitio de «¡Todo hecho!».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  late AppLocalizations l;
  late NordayCoreLocalizations lc;

  setUpAll(() async {
    await initializeDateFormatting();
    l = await AppLocalizations.delegate.load(const Locale('es'));
    lc = await NordayCoreLocalizations.delegate.load(const Locale('es'));
  });

  tearDown(() {
    marcarDiaCerrado(false);
    limpiarProgresoDia();
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  Widget montar(Widget child) => MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      NordayCoreLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  Finder conEtiqueta(String texto) => find.byWidgetPredicate(
    (w) => w is Semantics && (w.properties.label ?? '').contains(texto),
  );

  group('FiguraDelDiaHoy', () {
    testWidgets('en Neotokyo+, el letrero en su sitio, de su alto', (
      tester,
    ) async {
      aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
      publicarProgresoDia(hechos: 1, total: 3, fecha: DateTime(2026, 11, 20));
      await tester.pumpWidget(montar(const FiguraDelDiaHoy(total: 3)));
      await tester.pump();
      expect(find.byType(LetreroDelDia), findsOneWidget);
      expect(find.byType(RamoDelDia), findsNothing);
      expect(
        tester.getSize(find.byType(LetreroDelDia)).height,
        FiguraDelDiaHoy.alto,
      );
    });

    testWidgets('en Dulce, el ramo en su sitio', (tester) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      publicarProgresoDia(hechos: 1, total: 3, fecha: DateTime(2026, 11, 20));
      await tester.pumpWidget(montar(const FiguraDelDiaHoy(total: 3)));
      await tester.pump();
      expect(find.byType(RamoDelDia), findsOneWidget);
      expect(find.byType(LetreroDelDia), findsNothing);
    });

    testWidgets('en Profundidad no hay nada: la constelación va en su capa', (
      tester,
    ) async {
      aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
      await tester.pumpWidget(montar(const FiguraDelDiaHoy(total: 3)));
      await tester.pump();
      expect(find.byType(LetreroDelDia), findsNothing);
      expect(find.byType(RamoDelDia), findsNothing);
      expect(FiguraDelDiaHoy.tieneSitio(FondoIdentidadTipo.cielo), isFalse);
      expect(FiguraDelDiaHoy.tieneSitio(FondoIdentidadTipo.ciudad), isTrue);
      expect(
        FiguraDelDiaHoy.tieneSitio(FondoIdentidadTipo.acumulacion),
        isTrue,
      );
    });

    testWidgets(
      'con el día cerrado se lee «¡Todo hecho!» con el nombre de la figura; '
      'abierto, no',
      (tester) async {
        aplicarIdentidadEquipada('TEMA_DULCE');
        publicarProgresoDia(hechos: 3, total: 3, fecha: DateTime(2026, 11, 20));
        await tester.pumpWidget(montar(const FiguraDelDiaHoy(total: 3)));
        await tester.pump();
        expect(conEtiqueta(l.dashTodoHecho), findsNothing);

        marcarDiaCerrado(true);
        await tester.pump();
        final etiqueta = tester
            .widget<Semantics>(conEtiqueta(l.dashTodoHecho))
            .properties
            .label!;
        expect(etiqueta, contains(nombreRamo(lc, 3)));

        aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
        await tester.pumpWidget(montar(const FiguraDelDiaHoy(total: 12)));
        await tester.pump();
        expect(conEtiqueta(nombreLetrero(lc, 12)), findsOneWidget);
      },
    );
  });

  group('FinalDelDiaHoy (el sitio de «¡Todo hecho!»)', () {
    Future<void> montarFinal(WidgetTester tester, String codigo) async {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(montar(const FinalDelDiaHoy(total: 3)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets(
      'en Neotokyo+ y en Dulce, ya no ocupa nada: la figura está arriba',
      (tester) async {
        for (final codigo in ['TEMA_NEOTOKYO_PLUS', 'TEMA_DULCE']) {
          for (final cerrado in [false, true]) {
            marcarDiaCerrado(cerrado);
            await montarFinal(tester, codigo);
            expect(
              find.byType(TarjetaTodoHecho),
              findsNothing,
              reason: '$codigo $cerrado',
            );
            expect(
              tester.getSize(find.byType(FinalDelDiaHoy)).height,
              0,
              reason: '$codigo $cerrado',
            );
          }
        }
      },
    );

    testWidgets('en Profundidad, la tarjeta invisible con su hueco', (
      tester,
    ) async {
      await montarFinal(tester, 'TEMA_PROFUNDIDAD');
      expect(find.byType(TarjetaTodoHecho), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(TarjetaTodoHecho),
          matching: find.byWidgetPredicate(
            (w) => w is Opacity && w.opacity == 0,
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('en la pantalla Hoy', () {
    final usuarioOriginal = DashboardScreen.cargarUsuario;
    final hoyOriginal = DashboardScreen.cargarHoy;

    Map<String, dynamic> fila(int id, String nombre, {required bool hecho}) => {
      'habito': {
        'habitoId': id,
        'nombre': nombre,
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

    var fecha = '2026-11-15';

    Map<String, dynamic> hoy() => {
      'fecha': fecha,
      'hoy': '2026-11-15',
      'dias': [
        for (var d = 9; d <= 15; d++)
          {'fecha': '2026-11-${d.toString().padLeft(2, '0')}', 'avance': 0.0},
      ],
      'avance': 0.5,
      'ritmoNivel': null,
      'delDia': {
        'hechos': 1,
        'total': 2,
        'habitos': [
          fila(1, 'Leer', hecho: false),
          fila(2, 'Beber agua', hecho: true),
        ],
      },
      'deLaSemana': {'hechos': 0, 'total': 0, 'habitos': <dynamic>[]},
      'logrosOtorgados': <String>[],
    };

    setUp(() {
      fecha = '2026-11-15';
      SharedPreferences.setMockInitialValues({
        'mini_mascota_oculta': true,
        'detalle_habito_descubierto': true,
      });
      DashboardScreen.cargarUsuario = () async => {'usuarioId': 7};
      DashboardScreen.cargarHoy = (int usuarioId, {String? fecha}) async =>
          hoy();
    });

    tearDown(() {
      DashboardScreen.cargarUsuario = usuarioOriginal;
      DashboardScreen.cargarHoy = hoyOriginal;
    });

    Future<void> montarHoy(WidgetTester tester, String codigo) async {
      aplicarIdentidadEquipada(codigo);
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
      // En Neotokyo+ las tarjetas pendientes laten sin fin: pumpAndSettle no
      // acabaría nunca. Basta con dejar cargar y pintar.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    testWidgets(
      'con hábitos pendientes, el letrero ya está, arriba: bajo la tira y '
      'encima del primer hábito (Quim, 20-nov)',
      (tester) async {
        await montarHoy(tester, 'TEMA_NEOTOKYO_PLUS');
        expect(find.byType(LetreroDelDia), findsOneWidget);
        final letrero = find.byType(LetreroDelDia);
        expect(
          tester.getTopLeft(letrero).dy,
          greaterThan(tester.getBottomLeft(find.byType(TiraSemana)).dy),
        );
        expect(
          tester.getBottomLeft(letrero).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.text('Leer')).dy),
        );
        expect(
          tester.getBottomLeft(letrero).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.text('Beber agua')).dy),
        );
      },
    );

    testWidgets('en Dulce, el ramo, también arriba', (tester) async {
      await montarHoy(tester, 'TEMA_DULCE');
      final ramo = find.byType(RamoDelDia);
      expect(ramo, findsOneWidget);
      expect(
        tester.getTopLeft(ramo).dy,
        greaterThan(tester.getBottomLeft(find.byType(TiraSemana)).dy),
      );
      expect(
        tester.getBottomLeft(ramo).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Leer')).dy),
      );
    });

    testWidgets(
      'mirando otro día de la tira, ni letrero ni ramo (revisión del 20-nov)',
      (tester) async {
        fecha = '2026-11-14';
        await montarHoy(tester, 'TEMA_NEOTOKYO_PLUS');
        expect(find.text('Beber agua'), findsOneWidget);
        expect(find.byType(LetreroDelDia), findsNothing);
        await montarHoy(tester, 'TEMA_DULCE');
        expect(find.byType(RamoDelDia), findsNothing);
      },
    );

    testWidgets('en Profundidad, ni letrero ni ramo en la lista', (
      tester,
    ) async {
      await montarHoy(tester, 'TEMA_PROFUNDIDAD');
      expect(find.byType(LetreroDelDia), findsNothing);
      expect(find.byType(RamoDelDia), findsNothing);
    });
  });
}
