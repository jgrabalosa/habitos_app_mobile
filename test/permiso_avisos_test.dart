import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/widgets/permiso_avisos.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La tarjeta de Nori que pide el permiso de avisos: cuándo sale, cuántas
/// veces y qué hace cada botón.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    PermisoAvisos.reiniciarParaTest();
  });

  // Lo que han pedido los seams.
  late List<int> pedidos;
  late bool tienePermiso;
  late bool bloqueado;
  late bool concederAlPedir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    pedidos = [];
    tienePermiso = false;
    bloqueado = false;
    concederAlPedir = true;
    PermisoAvisos.concedido = () async => tienePermiso;
    PermisoAvisos.bloqueadoEnAjustes = () async => bloqueado;
    PermisoAvisos.pedirYRegistrar = (usuarioId) async {
      pedidos.add(usuarioId);
      return concederAlPedir;
    };
  });

  late bool? salio;

  Widget montar({Locale locale = const Locale('es')}) => MaterialApp(
    locale: locale,
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      NordayCoreLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              salio = await PermisoAvisos.mostrarSiToca(
                context,
                usuarioId: 5,
                origen: OrigenPermisoAvisos.apertura,
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );

  Future<void> abrir(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
  }) async {
    salio = null;
    await tester.pumpWidget(montar(locale: locale));
    await tester.tap(find.text('abrir'));
    // Las preferencias son de verdad asíncronas: se deja correr el reloj real.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<AppLocalizations> textos([String idioma = 'es']) =>
      AppLocalizations.delegate.load(Locale(idioma));

  Future<void> asentar(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<bool> marcado() async =>
      (await SharedPreferences.getInstance()).getBool(
        PermisoAvisos.claveOfrecido,
      ) ??
      false;

  group('cuándo sale', () {
    testWidgets('sale sin permiso, y se marca', (tester) async {
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.permisoAvisosTitulo), findsOneWidget);
      expect(find.text(l.permisoAvisosCuerpo), findsOneWidget);
      expect(find.text(l.permisoAvisosActivar), findsOneWidget);
      expect(find.text(l.permisoAvisosAhoraNo), findsOneWidget);
      expect(await tester.runAsync(marcado), isTrue);
    });

    testWidgets('sale una vez y no la siguiente', (tester) async {
      final l = await textos();
      await abrir(tester);
      expect(find.text(l.permisoAvisosTitulo), findsOneWidget);
      expect(salio, isNull); // sigue abierta: aún no se ha completado

      await tester.tap(find.text(l.permisoAvisosAhoraNo));
      await asentar(tester);
      expect(salio, isTrue);

      // «Siguiente apertura»: otra montada con las mismas preferencias.
      await abrir(tester);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      expect(salio, isFalse);
    });

    testWidgets('no sale si ya hay permiso', (tester) async {
      tienePermiso = true;
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      expect(salio, isFalse);
      expect(await tester.runAsync(marcado), isFalse);
    });

    testWidgets('no sale si está bloqueado en los ajustes', (tester) async {
      bloqueado = true;
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      expect(salio, isFalse);
    });

    testWidgets('no sale si el formulario ya preguntó (marca puesta)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        PermisoAvisos.claveOfrecido: true,
      });
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.permisoAvisosTitulo), findsNothing);
    });

    testWidgets('si falla la comprobación, no sale y no lanza', (tester) async {
      PermisoAvisos.concedido = () async => throw Exception('plugin');
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('los botones', () {
    testWidgets('«Activar» pide el permiso y se cierra', (tester) async {
      final l = await textos();
      await abrir(tester);

      await tester.tap(find.text(l.permisoAvisosActivar));
      await asentar(tester);

      expect(pedidos, [5]);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);
    });

    testWidgets('«Activar» se cierra aunque el permiso falle', (tester) async {
      PermisoAvisos.pedirYRegistrar = (_) async => throw Exception('red');
      final l = await textos();
      await abrir(tester);

      await tester.tap(find.text(l.permisoAvisosActivar));
      await asentar(tester);

      expect(find.text(l.permisoAvisosTitulo), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Ahora no» no pide el permiso y se cierra', (tester) async {
      final l = await textos();
      await abrir(tester);

      await tester.tap(find.text(l.permisoAvisosAhoraNo));
      await asentar(tester);

      expect(pedidos, isEmpty);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);
    });

    testWidgets('atrás no pide el permiso y se cierra', (tester) async {
      final l = await textos();
      await abrir(tester);

      await tester.binding.handlePopRoute();
      // Un pump sin duración antes: el ticker de la salida toma la hora en su
      // primer tic.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(pedidos, isEmpty);
      expect(find.text(l.permisoAvisosTitulo), findsNothing);
    });
  });

  group('los textos', () {
    const esperados = {
      'es': (
        '¿Te aviso para no olvidarlo?',
        'Activa las notificaciones y Nori te avisará a la hora de tus recordatorios. Sin agobios: como mucho dos avisos más a la semana.',
        'Activar',
        'Ahora no',
      ),
      'en': (
        "Shall I nudge you so you don't forget?",
        'Turn on notifications and Nori will let you know at your reminder times. No pressure: at most two extra nudges a week.',
        'Turn on',
        'Not now',
      ),
      'pt': (
        'Aviso-te para não te esqueceres?',
        'Ativa as notificações e o Nori avisa-te à hora dos teus lembretes. Sem stress: no máximo dois avisos extra por semana.',
        'Ativar',
        'Agora não',
      ),
    };

    for (final MapEntry(key: idioma, value: (titulo, cuerpo, activar, ahoraNo))
        in esperados.entries) {
      testWidgets('en $idioma', (tester) async {
        await abrir(tester, locale: Locale(idioma));

        expect(find.text(titulo), findsOneWidget);
        expect(find.text(cuerpo), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, activar), findsOneWidget);
        expect(find.widgetWithText(TextButton, ahoraNo), findsOneWidget);
      });
    }
  });
}
