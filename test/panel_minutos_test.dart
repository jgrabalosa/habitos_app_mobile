import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/models/hoy.dart';
import 'package:habitos_app_mobile/models/registro.dart';
import 'package:habitos_app_mobile/services/abrir_enfoque.dart';
import 'package:habitos_app_mobile/widgets/panel_minutos.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Lo que recibe el falso de completar en cada envío.
class Envio {
  final int habitoId;
  final String? fecha;
  final int? minutos;
  final String? clave;
  final String? origen;

  Envio(this.habitoId, this.fecha, this.minutos, this.clave, this.origen);
}

/// Un lanzador de enlaces falso: apunta lo que se le pide abrir y contesta
/// con [abre] para cada enlace (false si no está).
class LanzadorFalso implements LanzadorEnlaces {
  final Map<String, bool> abre;
  final List<(String, String?)> pedidos = [];

  LanzadorFalso(this.abre);

  @override
  Future<bool> abrir(Uri enlace, {String? paquete}) async {
    pedidos.add((enlace.toString(), paquete));
    return abre[enlace.toString()] ?? false;
  }
}

FilaHoy fila({int hechos = 20, int objetivo = 30}) => FilaHoy.fromJson({
  'habito': {
    'habitoId': 5,
    'nombre': 'Leer',
    'frecuencia': 'DIARIO',
    'meta': 1,
    'activo': true,
    'unidad': 'MINUTOS',
    'minutosObjetivo': objetivo,
  },
  'completados': hechos >= objetivo ? 1 : 0,
  'meta': 1,
  'hecho': hechos >= objetivo,
  'completadoEnFecha': hechos > 0,
  'unidad': 'MINUTOS',
  'minutosHechos': hechos,
  'minutosObjetivo': objetivo,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final completarOriginal = PanelMinutos.completar;
  final registrosOriginal = PanelMinutos.registros;
  final deshacerOriginal = PanelMinutos.deshacer;
  final lanzadorOriginal = PanelMinutos.lanzadorEnlaces;
  final flavorOriginal = PanelMinutos.flavor;

  late List<Envio> envios;
  late List<int> deshechos;
  late List<Registro> registros;
  late AppLocalizations l;

  setUpAll(() async {
    await initializeDateFormatting();
    l = await AppLocalizations.delegate.load(const Locale('es'));
  });

  setUp(() {
    envios = [];
    deshechos = [];
    registros = const [
      Registro(registroId: 10, fecha: '2026-11-15', cantidad: 5),
      Registro(registroId: 12, fecha: '2026-11-15', cantidad: 15),
      Registro(registroId: 14, fecha: '2026-11-14', cantidad: 30),
    ];
    PanelMinutos.completar =
        (
          int habitoId, {
          String? fecha,
          int? minutos,
          String? clave,
          String? origen,
        }) async {
          envios.add(Envio(habitoId, fecha, minutos, clave, origen));
          return {
            'logros': <String>[],
            'puntosGanados': 5,
            'registroId': 99,
            'minutosDia': 0,
            'diaHecho': false,
          };
        };
    PanelMinutos.registros = (_) async => registros;
    PanelMinutos.deshacer = (id) async => deshechos.add(id);
  });

  tearDown(() {
    PanelMinutos.completar = completarOriginal;
    PanelMinutos.registros = registrosOriginal;
    PanelMinutos.deshacer = deshacerOriginal;
    PanelMinutos.lanzadorEnlaces = lanzadorOriginal;
    PanelMinutos.flavor = flavorOriginal;
  });

  /// Abre el panel como lo abre Hoy y deja en [resultado] lo que devuelve.
  Future<void> abrir(
    WidgetTester tester,
    List<ResultadoMinutos?> resultado, {
    FilaHoy? f,
    String fechaDia = '2026-11-15',
    bool esHoy = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        locale: const Locale('es'),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado.add(
                    await mostrarPanelMinutos(
                      context,
                      fila: f ?? fila(),
                      fechaDia: fechaDia,
                      esHoy: esHoy,
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('enseña lo que lleva el día: «20 / 30 min» y lo que falta', (
    tester,
  ) async {
    await abrir(tester, []);
    expect(find.text('20 / 30 min'), findsOneWidget);
    expect(find.text(l.minPanelFaltan(10)), findsOneWidget);
  });

  testWidgets('+5 envía 5 minutos hoy, sin fecha, con clave y MANUAL', (
    tester,
  ) async {
    final resultado = <ResultadoMinutos?>[];
    await abrir(tester, resultado);
    await tester.tap(find.text(l.minSumaRapida(5)));
    await tester.pumpAndSettle();

    expect(envios, hasLength(1));
    expect(envios.single.habitoId, 5);
    expect(envios.single.minutos, 5);
    expect(envios.single.fecha, isNull);
    expect(envios.single.origen, 'MANUAL');
    expect(envios.single.clave, matches(RegExp(r'^[0-9a-f-]{36}$')));
    // Se cierra y devuelve lo sumado, con la respuesta para celebrarlo.
    expect(resultado.single!.minutos, 5);
    expect(resultado.single!.completado!['registroId'], 99);
    expect(find.text('20 / 30 min'), findsNothing);
  });

  testWidgets('+15 y +30 envían 15 y 30, cada uno con su clave', (
    tester,
  ) async {
    final resultado = <ResultadoMinutos?>[];
    await abrir(tester, resultado);
    await tester.tap(find.text(l.minSumaRapida(15)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.minSumaRapida(30)));
    await tester.pumpAndSettle();

    expect(envios.map((e) => e.minutos), [15, 30]);
    expect(envios[0].clave, isNot(envios[1].clave));
    expect(resultado.map((r) => r!.minutos), [15, 30]);
  });

  testWidgets('en un día pasado manda la fecha de ese día', (tester) async {
    await abrir(tester, [], fechaDia: '2026-11-12', esHoy: false);
    await tester.tap(find.text(l.minSumaRapida(30)));
    await tester.pumpAndSettle();
    expect(envios.single.fecha, '2026-11-12');
  });

  testWidgets('Sumar con cifra libre envía la cifra', (tester) async {
    await abrir(tester, []);
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.widgetWithText(ElevatedButton, l.minBotonSumar));
    await tester.pumpAndSettle();
    expect(envios.single.minutos, 25);
  });

  testWidgets('Establecer 50 con 20 hechos envía la diferencia: 30', (
    tester,
  ) async {
    final resultado = <ResultadoMinutos?>[];
    await abrir(tester, resultado);
    await tester.tap(find.text(l.minModoEstablecer));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '50');
    await tester.tap(find.widgetWithText(ElevatedButton, l.minBotonEstablecer));
    await tester.pumpAndSettle();
    expect(envios.single.minutos, 30);
    expect(resultado.single!.minutos, 30);
  });

  testWidgets('Establecer por debajo de lo que hay no envía y lo dice', (
    tester,
  ) async {
    final resultado = <ResultadoMinutos?>[];
    await abrir(tester, resultado);
    await tester.tap(find.text(l.minModoEstablecer));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '10');
    await tester.tap(find.widgetWithText(ElevatedButton, l.minBotonEstablecer));
    await tester.pumpAndSettle();
    expect(envios, isEmpty);
    expect(resultado, isEmpty);
    expect(find.text(l.minErrorNoSube(20)), findsOneWidget);
  });

  testWidgets('Sumar sin cifra no envía y lo dice', (tester) async {
    await abrir(tester, []);
    await tester.tap(find.widgetWithText(ElevatedButton, l.minBotonSumar));
    await tester.pumpAndSettle();
    expect(envios, isEmpty);
    expect(find.text(l.minErrorVacio), findsOneWidget);
  });

  testWidgets('si el envío falla, el panel sigue abierto con el error', (
    tester,
  ) async {
    PanelMinutos.completar =
        (
          int habitoId, {
          String? fecha,
          int? minutos,
          String? clave,
          String? origen,
        }) async => throw Exception('fallo de prueba');
    final resultado = <ResultadoMinutos?>[];
    await abrir(tester, resultado);
    await tester.tap(find.text(l.minSumaRapida(5)));
    await tester.pumpAndSettle();
    expect(resultado, isEmpty);
    expect(find.text(l.minErrorEnviar), findsOneWidget);
    expect(find.text('20 / 30 min'), findsOneWidget);
  });

  testWidgets('Deshacer quita la última entrada del día que se mira', (
    tester,
  ) async {
    final resultado = <ResultadoMinutos?>[];
    await abrir(tester, resultado);
    // La etiqueta dice cuánto se deshace: la entrada 12, de 15 min.
    final boton = find.text(l.minDeshacerUltimaN(15));
    expect(boton, findsOneWidget);
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(deshechos, [12]);
    expect(resultado.single!.minutos, -15);
    expect(resultado.single!.tipo, TipoResultadoMinutos.deshecho);
  });

  testWidgets('Deshacer con 409 avisa de que solo se deshace lo último', (
    tester,
  ) async {
    PanelMinutos.deshacer = (_) async => throw const ApiException(
      TipoErrorApi.peticionInvalida,
      codigoEstado: 409,
    );
    final resultado = <ResultadoMinutos?>[];
    await abrir(tester, resultado);
    await tester.tap(find.text(l.minDeshacerUltimaN(15)));
    await tester.pumpAndSettle();
    expect(resultado, isEmpty);
    expect(find.text(l.dashDeshacerSoloUltimo), findsOneWidget);
  });

  testWidgets('sin minutos ese día no hay Deshacer', (tester) async {
    await abrir(tester, [], f: fila(hechos: 0));
    expect(find.text(l.minDeshacerUltima), findsNothing);
    expect(find.textContaining('Deshacer'), findsNothing);
  });

  testWidgets('pasada la meta: «43 / 30 min» y se puede seguir sumando', (
    tester,
  ) async {
    await abrir(tester, [], f: fila(hechos: 43));
    expect(find.text('43 / 30 min'), findsOneWidget);
    expect(find.text(l.minPanelHecho), findsOneWidget);
    await tester.tap(find.text(l.minSumaRapida(5)));
    await tester.pumpAndSettle();
    expect(envios.single.minutos, 5);
  });

  group('Empezar sesión (Norday Focus)', () {
    const enlace = 'norday-enfoque://sesion?destino=habito&id=5';
    const market = 'market://details?id=com.norday.enfoque';
    const web =
        'https://play.google.com/store/apps/details?id=com.norday.enfoque';

    Future<void> pulsar(WidgetTester tester) async {
      final boton = find.text(l.minEmpezarSesion);
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }

    testWidgets('con Enfoque instalada la abre con el hábito y se cierra', (
      tester,
    ) async {
      final lanzador = LanzadorFalso({enlace: true});
      PanelMinutos.lanzadorEnlaces = lanzador;
      PanelMinutos.flavor = () => 'produccion';
      final resultado = <ResultadoMinutos?>[];
      await abrir(tester, resultado);
      expect(PanelMinutos.enfoqueDisponible, isTrue);
      await pulsar(tester);
      expect(lanzador.pedidos, [(enlace, 'com.norday.enfoque')]);
      // Cerrado sin resultado: los minutos llegan desde Enfoque.
      expect(resultado, [null]);
      expect(find.text(l.minEmpezarSesion), findsNothing);
      expect(envios, isEmpty);
    });

    testWidgets('la Habits de prueba abre la Enfoque de prueba', (
      tester,
    ) async {
      final lanzador = LanzadorFalso({enlace: true});
      PanelMinutos.lanzadorEnlaces = lanzador;
      PanelMinutos.flavor = () => 'prueba';
      await abrir(tester, []);
      await pulsar(tester);
      expect(lanzador.pedidos, [(enlace, 'com.norday.enfoque.prueba')]);
    });

    testWidgets('sin Enfoque abre su ficha de Google Play', (tester) async {
      final lanzador = LanzadorFalso({market: true});
      PanelMinutos.lanzadorEnlaces = lanzador;
      PanelMinutos.flavor = () => 'produccion';
      final resultado = <ResultadoMinutos?>[];
      await abrir(tester, resultado);
      await pulsar(tester);
      expect(lanzador.pedidos, [
        (enlace, 'com.norday.enfoque'),
        (market, null),
      ]);
      expect(resultado, [null]);
    });

    testWidgets('si no se abre nada, se queda abierto con el error', (
      tester,
    ) async {
      final lanzador = LanzadorFalso({});
      PanelMinutos.lanzadorEnlaces = lanzador;
      final resultado = <ResultadoMinutos?>[];
      await abrir(tester, resultado);
      await pulsar(tester);
      expect(lanzador.pedidos.map((p) => p.$1), [enlace, market, web]);
      expect(resultado, isEmpty);
      expect(find.text(l.minErrorAbrirEnfoque), findsOneWidget);
      expect(find.text(l.minEmpezarSesion), findsOneWidget);
    });

    testWidgets('desde otro día de la semana no sale', (tester) async {
      await abrir(tester, [], fechaDia: '2026-11-13', esHoy: false);
      expect(find.text(l.minEmpezarSesion), findsNothing);
    });
  });

  group('cierre y claves con envíos sin respuesta clara', () {
    /// Un falso de completar que falla con [errores] en orden y después va
    /// bien.
    void completarQueFalla(List<Object> errores) {
      var i = 0;
      PanelMinutos.completar =
          (
            int habitoId, {
            String? fecha,
            int? minutos,
            String? clave,
            String? origen,
          }) async {
            envios.add(Envio(habitoId, fecha, minutos, clave, origen));
            if (i < errores.length) throw errores[i++];
            return {'logros': <String>[], 'puntosGanados': 0};
          };
    }

    Future<void> atras(WidgetTester tester) async {
      final NavigatorState nav = tester.state(find.byType(Navigator));
      await nav.maybePop();
      await tester.pumpAndSettle();
    }

    testWidgets('la hoja no se arrastra para cerrar', (tester) async {
      await abrir(tester, []);
      final hoja = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(hoja.enableDrag, isFalse);
    });

    testWidgets('mientras envía, atrás no cierra el panel', (tester) async {
      final respuesta = Completer<Map<String, dynamic>>();
      PanelMinutos.completar =
          (
            int habitoId, {
            String? fecha,
            int? minutos,
            String? clave,
            String? origen,
          }) {
            envios.add(Envio(habitoId, fecha, minutos, clave, origen));
            return respuesta.future;
          };
      final resultado = <ResultadoMinutos?>[];
      await abrir(tester, resultado);
      await tester.tap(find.text(l.minSumaRapida(5)));
      await tester.pump();

      final NavigatorState nav = tester.state(find.byType(Navigator));
      await nav.maybePop();
      await tester.pump();
      expect(resultado, isEmpty);
      expect(find.text('20 / 30 min'), findsOneWidget);

      respuesta.complete({'logros': <String>[], 'puntosGanados': 5});
      await tester.pumpAndSettle();
      expect(resultado.single!.tipo, TipoResultadoMinutos.sumado);
      expect(resultado.single!.minutos, 5);
    });

    testWidgets('cerrar tras un timeout devuelve «desconocido»', (
      tester,
    ) async {
      completarQueFalla([const ApiException(TipoErrorApi.timeout)]);
      final resultado = <ResultadoMinutos?>[];
      await abrir(tester, resultado);
      await tester.tap(find.text(l.minSumaRapida(5)));
      await tester.pumpAndSettle();
      expect(resultado, isEmpty);

      await atras(tester);
      expect(resultado.single!.tipo, TipoResultadoMinutos.desconocido);
    });

    testWidgets('cerrar tras un 4xx devuelve null: no se registró nada', (
      tester,
    ) async {
      completarQueFalla([
        const ApiException(TipoErrorApi.peticionInvalida, codigoEstado: 409),
      ]);
      final resultado = <ResultadoMinutos?>[];
      await abrir(tester, resultado);
      await tester.tap(find.text(l.minSumaRapida(5)));
      await tester.pumpAndSettle();
      await atras(tester);
      expect(resultado, [null]);
    });

    testWidgets(
      'cerrar tras un deshacer sin respuesta devuelve «desconocido»',
      (tester) async {
        PanelMinutos.deshacer = (_) async =>
            throw const ApiException(TipoErrorApi.sinConexion);
        final resultado = <ResultadoMinutos?>[];
        await abrir(tester, resultado);
        await tester.tap(find.text(l.minDeshacerUltimaN(15)));
        await tester.pumpAndSettle();
        await atras(tester);
        expect(resultado.single!.tipo, TipoResultadoMinutos.desconocido);
      },
    );

    testWidgets('repetir el mismo envío tras un timeout reutiliza la clave', (
      tester,
    ) async {
      completarQueFalla([const ApiException(TipoErrorApi.timeout)]);
      final resultado = <ResultadoMinutos?>[];
      await abrir(tester, resultado);
      await tester.tap(find.text(l.minSumaRapida(15)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.minSumaRapida(15)));
      await tester.pumpAndSettle();

      expect(envios, hasLength(2));
      expect(envios[1].clave, envios[0].clave);
      expect(resultado.single!.tipo, TipoResultadoMinutos.sumado);
    });

    testWidgets('tras un 5xx, otros minutos llevan clave nueva', (
      tester,
    ) async {
      completarQueFalla([const ApiException(TipoErrorApi.servidor)]);
      await abrir(tester, []);
      await tester.tap(find.text(l.minSumaRapida(15)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.minSumaRapida(30)));
      await tester.pumpAndSettle();

      expect(envios.map((e) => e.minutos), [15, 30]);
      expect(envios[1].clave, isNot(envios[0].clave));
    });

    testWidgets('tras un 4xx, el mismo envío lleva clave nueva', (
      tester,
    ) async {
      completarQueFalla([
        const ApiException(TipoErrorApi.peticionInvalida, codigoEstado: 409),
      ]);
      await abrir(tester, []);
      await tester.tap(find.text(l.minSumaRapida(15)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.minSumaRapida(15)));
      await tester.pumpAndSettle();

      expect(envios, hasLength(2));
      expect(envios[1].clave, isNot(envios[0].clave));
    });
  });

  group('claveParaEnvio', () {
    var n = 0;
    String nueva() => 'nueva-${n++}';

    test('sin pendiente, nueva', () {
      expect(
        claveParaEnvio(null, minutos: 5, fecha: null, nueva: nueva),
        startsWith('nueva-'),
      );
    });

    test('mismos minutos y fecha, la pendiente', () {
      const p = (clave: 'k', minutos: 5, fecha: '2026-11-12');
      expect(
        claveParaEnvio(p, minutos: 5, fecha: '2026-11-12', nueva: nueva),
        'k',
      );
    });

    test('otros minutos u otra fecha, nueva', () {
      const p = (clave: 'k', minutos: 5, fecha: null);
      expect(
        claveParaEnvio(p, minutos: 15, fecha: null, nueva: nueva),
        isNot('k'),
      );
      expect(
        claveParaEnvio(p, minutos: 5, fecha: '2026-11-12', nueva: nueva),
        isNot('k'),
      );
    });
  });
}
