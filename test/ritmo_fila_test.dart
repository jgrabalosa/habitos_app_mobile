import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/models/hoy.dart';
import 'package:habitos_app_mobile/widgets/identidad_ui.dart';
import 'package:habitos_app_mobile/widgets/panel_ritmo.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Map<String, dynamic> filaJson() => {
    'habito': {
      'habitoId': 1,
      'nombre': 'Leer',
      'frecuencia': 'DIARIO',
      'meta': 1,
      'activo': true,
    },
    'completados': 0,
    'meta': 1,
    'hecho': false,
    'completadoEnFecha': false,
    'ritmoNivel': 3,
    'fechasCompletadas': [],
  };

  Future<void> abrirPanel(WidgetTester tester, String locale) async {
    // Desmontar antes: si no, la hoja del panel anterior sigue abierta.
    await tester.pumpWidget(const SizedBox.shrink());
    final hoy = leerHoy({
      'fecha': '2026-10-10',
      'hoy': '2026-10-10',
      'avance': 0.4,
      'ritmoNivel': 3,
      'ritmoTendencia': 'IGUAL',
      'dias': [],
      'delDia': {
        'hechos': 0,
        'total': 1,
        'habitos': [filaJson()],
      },
      'deLaSemana': {'habitos': []},
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        locale: Locale(locale),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => mostrarPanelRitmo(context, hoy),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'la burbuja de cada fila del panel usa el tamaño de la identidad',
    (tester) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      await abrirPanel(tester, 'es');
      // La cabecera va primero (20); la fila, la última.
      expect(
        tester.getSize(find.byType(IndicadorNivel).last),
        IndicadorNivel.medida(14),
      );

      aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
      await abrirPanel(tester, 'es');
      expect(
        tester.getSize(find.byType(IndicadorNivel).last),
        IndicadorNivel.medida(11),
      );
    },
  );

  /// Fila de Hoy, con su chip y su burbuja, dentro de un ancho dado.
  Future<void> filaDeHoy(
    WidgetTester tester, {
    required double ancho,
    required String locale,
    required String texto,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        locale: Locale(locale),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: app!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: ancho,
              child: Row(
                children: [
                  ChipIdentidad(texto: texto),
                  const SizedBox(width: 8),
                  IndicadorNivel(
                    nivel: 5,
                    tamano: tamanoRitmoFila(identidadEquipadaNotifier.value),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Dulce, pt, 1,5 de texto: el panel no desborda a 320 px con un nombre largo',
    (tester) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final hoy = leerHoy({
        'fecha': '2026-10-10',
        'hoy': '2026-10-10',
        'avance': 0.4,
        'ritmoNivel': 3,
        'ritmoTendencia': 'IGUAL',
        'dias': [],
        'delDia': {
          'hechos': 0,
          'total': 1,
          'habitos': [
            {
              ...filaJson(),
              'habito': {
                'habitoId': 1,
                'nombre':
                    'Meditar veinte minutos cada mañana antes de desayunar',
                'frecuencia': 'DIARIO',
                'meta': 1,
                'activo': true,
              },
            },
          ],
        },
        'deLaSemana': {'habitos': []},
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.deTema(temaEquipadoNotifier.value),
          locale: const Locale('pt'),
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...NordayCoreLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: app!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => mostrarPanelRitmo(context, hoy),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Dulce, pt, 1,5 de texto: la fila de Hoy no desborda a 320 px', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    await filaDeHoy(tester, ancho: 320, locale: 'pt', texto: 'Diário · 12/12');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dulce, pt, 1,5 de texto: la fila de Hoy no desborda a 256 px', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    await filaDeHoy(tester, ancho: 256, locale: 'pt', texto: 'Diário · 12/12');
    expect(tester.takeException(), isNull);
  });
}
