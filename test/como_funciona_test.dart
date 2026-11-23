import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/como_funciona_screen.dart';
import 'package:habitos_app_mobile/screens/home_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «Cómo funciona»: la entrada del menú y la pantalla de seis apartados.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Widget app(Widget home, {Locale locale = const Locale('es')}) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: locale,
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      ...NordayCoreLocalizations.localizationsDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  Future<void> pantalla(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
    ApartadoComoFunciona? abierto,
    VoidCallback? alVerPista,
    Future<bool> Function(int)? hayHabitos,
    List<String>? medidos,
  }) async {
    await tester.pumpWidget(
      app(
        ComoFuncionaScreen(
          usuarioId: 1,
          abierto: abierto,
          alVerPista: alVerPista,
          cargarHayHabitos: hayHabitos ?? (_) async => true,
          medir: (id) async => medidos?.add(id),
        ),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('el menú', () {
    Future<void> abrirMenu(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => mostrarMenuShell(
                    context,
                    usuarioId: 1,
                    alCerrarSesion: () {},
                  ),
                  child: const Text('menú'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('menú'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      '«Cómo funciona» va tras «Mi cuenta» y antes de «Cerrar sesión»',
      (tester) async {
        await abrirMenu(tester);
        final entrada = find.text('Cómo funciona');
        expect(entrada, findsOneWidget);
        expect(
          find.descendant(
            of: find.ancestor(of: entrada, matching: find.byType(InkWell)),
            matching: find.byIcon(LucideIcons.circleQuestionMark),
          ),
          findsOneWidget,
        );
        const es = Locale('es');
        final perfil = lookupAppLocalizations(es).perfilTitulo;
        final salir = lookupAppLocalizations(es).shellCerrarSesion;
        final y = tester.getTopLeft(entrada).dy;
        expect(tester.getTopLeft(find.text(perfil)).dy, lessThan(y));
        expect(y, lessThan(tester.getTopLeft(find.text(salir)).dy));
      },
    );

    testWidgets('pulsarla abre ComoFuncionaScreen', (tester) async {
      await abrirMenu(tester);
      await tester.tap(find.text('Cómo funciona'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ComoFuncionaScreen), findsOneWidget);
    });
  });

  group('la pantalla', () {
    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets('tiene los seis apartados en ${locale.languageCode}', (
        tester,
      ) async {
        await pantalla(tester, locale: locale);
        final l = lookupAppLocalizations(locale);
        expect(ApartadoComoFunciona.values, hasLength(6));
        for (final a in ApartadoComoFunciona.values) {
          expect(find.text(a.titulo(l)), findsOneWidget);
          expect(a.titulo(l).trim(), isNotEmpty);
          expect(a.cuerpo(l).trim(), isNotEmpty);
        }
      });
    }

    testWidgets('los textos son distintos en cada idioma', (tester) async {
      final es = lookupAppLocalizations(const Locale('es'));
      final en = lookupAppLocalizations(const Locale('en'));
      final pt = lookupAppLocalizations(const Locale('pt'));
      for (final a in ApartadoComoFunciona.values) {
        expect(a.cuerpo(en), isNot(a.cuerpo(es)));
        expect(a.cuerpo(pt), isNot(a.cuerpo(es)));
        expect(a.cuerpo(pt), isNot(a.cuerpo(en)));
      }
    });

    testWidgets('sin apartado abierto, ningún cuerpo se ve', (tester) async {
      await pantalla(tester);
      final l = lookupAppLocalizations(const Locale('es'));
      for (final a in ApartadoComoFunciona.values) {
        expect(find.text(a.cuerpo(l)), findsNothing);
      }
    });

    testWidgets('abrir con un apartado lo despliega, y solo ese', (
      tester,
    ) async {
      await pantalla(tester, abierto: ApartadoComoFunciona.ritmo);
      final l = lookupAppLocalizations(const Locale('es'));
      expect(find.text(ApartadoComoFunciona.ritmo.cuerpo(l)), findsOneWidget);
      expect(find.text(ApartadoComoFunciona.hoy.cuerpo(l)), findsNothing);
    });

    testWidgets('desplegar otro cierra el anterior y se mide', (tester) async {
      final medidos = <String>[];
      await pantalla(
        tester,
        abierto: ApartadoComoFunciona.hoy,
        medidos: medidos,
      );
      final l = lookupAppLocalizations(const Locale('es'));
      await tester.tap(find.text(ApartadoComoFunciona.puntos.titulo(l)));
      await tester.pumpAndSettle();
      expect(find.text(ApartadoComoFunciona.puntos.cuerpo(l)), findsOneWidget);
      expect(find.text(ApartadoComoFunciona.hoy.cuerpo(l)), findsNothing);
      expect(medidos, ['como_funciona_puntos']);
    });

    testWidgets('el id de medición de «Diarios y semanales»', (tester) async {
      expect(
        ApartadoComoFunciona.diarios.idMedicion,
        'como_funciona_diarios_semanales',
      );
    });
  });

  group('«Ver otra vez la pista»', () {
    testWidgets('sin hábitos no sale', (tester) async {
      await pantalla(tester, alVerPista: () {}, hayHabitos: (_) async => false);
      expect(find.text('Ver otra vez la pista'), findsNothing);
    });

    testWidgets('si no se falla al saber si hay hábitos, tampoco sale', (
      tester,
    ) async {
      await pantalla(
        tester,
        alVerPista: () {},
        hayHabitos: (_) async => throw Exception('sin red'),
      );
      expect(find.text('Ver otra vez la pista'), findsNothing);
    });

    testWidgets('sin quien la lance no sale', (tester) async {
      await pantalla(tester);
      expect(find.text('Ver otra vez la pista'), findsNothing);
    });

    testWidgets('con hábitos sale, cierra la pantalla y lanza la pista', (
      tester,
    ) async {
      var lanzada = 0;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComoFuncionaScreen(
                      usuarioId: 1,
                      alVerPista: () => lanzada++,
                      cargarHayHabitos: (_) async => true,
                      medir: (_) async {},
                    ),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver otra vez la pista'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver otra vez la pista'));
      await tester.pumpAndSettle();
      expect(find.byType(ComoFuncionaScreen), findsNothing);
      expect(lanzada, 1);
    });
  });

  testWidgets('en Dulce, el fondo es el papel de la identidad, no negro', (
    tester,
  ) async {
    // El fondo de Dulce solo dibuja las burbujas: el papel lo pone el
    // Scaffold. Transparente, debajo de la ruta no queda nada y se ve negro.
    aplicarIdentidadEquipada('TEMA_DULCE');
    await pantalla(tester);

    final scaffold = find.byType(Scaffold).first;
    final fondo =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(fondo, temaEquipadoNotifier.value.bg);
  });

  testWidgets('cada apartado es una tarjeta de la identidad', (tester) async {
    // A mano, en Dulce eran cajas blancas sin el filo a lápiz: tapaban las
    // burbujas y parecían un corte. SuperficieIdentidad pone el lenguaje de
    // cada identidad (en Dulce, el filo rosa y la sombra a rayas).
    aplicarIdentidadEquipada('TEMA_DULCE');
    await pantalla(tester);

    expect(
      find.byType(SuperficieIdentidad),
      findsNWidgets(ApartadoComoFunciona.values.length),
    );
  });
}
