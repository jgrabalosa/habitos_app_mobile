import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/models/hoy.dart';
import 'package:habitos_app_mobile/widgets/panel_ritmo.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  final hoy = leerHoy({
    'fecha': '2026-10-10',
    'hoy': '2026-10-10',
    'avance': 0.4,
    'ritmoNivel': 3,
    'ritmoTendencia': 'SUBE',
    'dias': [],
    'delDia': {'hechos': 0, 'total': 0, 'habitos': []},
    'deLaSemana': {'habitos': []},
  });

  Future<void> abrirPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
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

  testWidgets('el panel enseña la palabra del nivel, sin el rótulo', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    await abrirPanel(tester);

    expect(find.text(palabraRitmo(l, 3)), findsOneWidget);
    for (final rotulo in ['TU RITMO', 'YOUR PACE', 'O TEU RITMO']) {
      expect(find.text(rotulo), findsNothing, reason: rotulo);
    }
    expect(
      find.bySemanticsLabel(l.a11yRitmoGeneral(palabraRitmo(l, 3), 3)),
      findsOneWidget,
    );
  });

  testWidgets('el último hábito queda por encima de la barra del sistema', (
    tester,
  ) async {
    const barra = 48.0;
    final conHabito = leerHoy({
      'fecha': '2026-10-10',
      'hoy': '2026-10-10',
      'avance': 0.4,
      'ritmoNivel': 3,
      'ritmoTendencia': 'SUBE',
      'dias': [],
      'delDia': {
        'hechos': 0,
        'total': 1,
        'habitos': [
          {
            'habito': {
              'habitoId': 1,
              'nombre': 'Meditar',
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
          },
        ],
      },
      'deLaSemana': {'habitos': []},
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewPadding: const EdgeInsets.only(bottom: barra),
            padding: const EdgeInsets.only(bottom: barra),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => mostrarPanelRitmo(context, conHabito),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final pantalla =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final hastaAbajo = pantalla - tester.getBottomLeft(find.text('Meditar')).dy;
    expect(hastaAbajo, greaterThanOrEqualTo(24 + barra));
  });

  group('causa con hábitos recién empezados', () {
    Map<String, dynamic> filaJson(int id, String nombre, String? alta) => {
      'habito': {
        'habitoId': id,
        'nombre': nombre,
        'frecuencia': 'DIARIO',
        'meta': 1,
        'activo': true,
        'fechaInicio': ?alta,
      },
      'completados': 0,
      'meta': 1,
      'hecho': false,
      'completadoEnFecha': false,
      'ritmoNivel': 3,
      'fechasCompletadas': [],
    };

    Future<void> abrirCon(
      WidgetTester tester,
      List<Map<String, dynamic>> filas,
    ) async {
      final conFilas = leerHoy({
        'fecha': '2026-10-10',
        'hoy': '2026-10-10',
        'avance': 0.4,
        'ritmoNivel': 3,
        'ritmoTendencia': 'IGUAL',
        'dias': [],
        'delDia': {'hechos': 0, 'total': filas.length, 'habitos': filas},
        'deLaSemana': {'habitos': []},
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...NordayCoreLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => mostrarPanelRitmo(context, conFilas),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('un hábito de hace 2 días dice que acaba de empezar', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirCon(tester, [filaJson(1, 'Leer', '2026-10-08')]);
      expect(find.text(l.ritmoRecienEmpezado), findsOneWidget);
      expect(find.text(l.ritmoIgual), findsNothing);
    });

    testWidgets('un hábito de hace 30 días con tendencia igual dice Igual', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirCon(tester, [filaJson(1, 'Leer', '2026-09-10')]);
      expect(find.text(l.ritmoIgual), findsOneWidget);
      expect(find.text(l.ritmoRecienEmpezado), findsNothing);
    });

    testWidgets('con uno nuevo y uno viejo decide el más antiguo', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirCon(tester, [
        filaJson(1, 'Leer', '2026-10-08'),
        filaJson(2, 'Meditar', '2026-09-10'),
      ]);
      expect(find.text(l.ritmoIgual), findsOneWidget);
      expect(find.text(l.ritmoRecienEmpezado), findsNothing);
    });

    testWidgets('una fila sin fecha de alta deja la causa de siempre', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirCon(tester, [filaJson(1, 'Leer', null)]);
      expect(find.text(l.ritmoIgual), findsOneWidget);
    });
  });
}
