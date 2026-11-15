import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/l10n/textos_habits.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desde el core 0.55.0, el nombre, el lema del login y los textos de
/// actualización obligatoria y de borrado de cuenta los pone la app. Con
/// `registrarTextosHabits()`, las pantallas del core dicen lo mismo que en la
/// 0.54.0; sin él, el neutro del core.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    registrarTextosHabits();
  });
  tearDown(TextosApp.reiniciar);

  Widget app(Widget home, Locale locale) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: locale,
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      ...NordayCoreLocalizations.localizationsDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  /// Los textos de Habits, tal cual estaban en el core v0.54.0 (commit
  /// 1f8add7). Literales a propósito: si alguien los cambia en el ARB sin
  /// querer, esto lo dice.
  const habits = {
    'es': (
      nombre: 'Norday Habits',
      lema: 'Construye hábitos, transforma tu vida',
      actualizacion:
          'Para seguir usando Norday, actualiza la app. Tus hábitos y tu '
          'progreso se quedan tal cual.',
      eliminar:
          'Se borrarán para siempre todos tus hábitos, registros, rachas, '
          'logros y puntos.\n\nEsta acción no se puede deshacer.',
    ),
    'en': (
      nombre: 'Norday Habits',
      lema: 'Build habits, transform your life',
      actualizacion:
          'To keep using Norday, update the app. Your habits and progress '
          'stay just as they are.',
      eliminar:
          'All your habits, entries, streaks, achievements and points will '
          "be gone for good.\n\nThis can't be undone.",
    ),
    'pt': (
      nombre: 'Norday Habits',
      lema: 'Cria hábitos, transforma a tua vida',
      actualizacion:
          'Para continuares a usar o Norday, atualiza a app. Os teus hábitos '
          'e o teu progresso ficam tal como estão.',
      eliminar:
          'Todos os teus hábitos, registos, sequências, conquistas e pontos '
          'serão apagados para sempre.\n\nEsta ação não pode ser anulada.',
    ),
  };

  test('los ARB de Habits tienen los textos de la 0.54.0', () async {
    for (final MapEntry(key: idioma, value: v) in habits.entries) {
      final l = await AppLocalizations.delegate.load(Locale(idioma));
      expect(l.appNombre, v.nombre, reason: idioma);
      expect(l.loginLema, v.lema, reason: idioma);
      expect(l.actualizacionObligatoriaTexto, v.actualizacion, reason: idioma);
      expect(l.eliminarCuentaCuerpo, v.eliminar, reason: idioma);
    }
  });

  for (final idioma in habits.keys) {
    final v = habits[idioma]!;
    final locale = Locale(idioma);

    testWidgets('$idioma: el login dice «Norday Habits» y su lema', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(LoginScreen(destinoTrasLogin: (_, _) => const SizedBox()), locale),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<WordmarkIdentidad>(find.byType(WordmarkIdentidad)).texto,
        v.nombre,
      );
      expect(find.text(v.lema), findsOneWidget);
      final core = lookupNordayCoreLocalizations(locale);
      expect(find.text(core.loginTagline), findsNothing);
    });

    testWidgets('$idioma: la actualización obligatoria habla de hábitos', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const ActualizacionObligatoriaScreen(), locale),
      );
      await tester.pump();
      expect(find.text(v.actualizacion), findsOneWidget);
      final core = lookupNordayCoreLocalizations(locale);
      expect(find.text(core.actualizacionTexto), findsNothing);
    });

    testWidgets('$idioma: borrar la cuenta dice qué se pierde en Habits', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          PerfilScreen(
            usuarioId: 1,
            destinoTrasLogin: (_, _) => const SizedBox(),
          ),
          locale,
        ),
      );
      // El perfil carga los datos guardados antes de pintarse; en test el
      // almacén seguro no tiene parte nativa y esa espera es real, no del
      // reloj falso.
      for (
        var i = 0;
        i < 20 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      final core = lookupNordayCoreLocalizations(locale);
      final boton = find.text(core.perfilEliminarCuenta);
      await tester.ensureVisible(boton);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(boton);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(core.perfilEliminarTitulo), findsOneWidget);
      expect(find.text(v.eliminar), findsOneWidget);
      expect(find.text(core.perfilEliminarCuerpo), findsNothing);
    });
  }

  testWidgets('sin registrar, el login cae en el neutro del core', (
    tester,
  ) async {
    TextosApp.reiniciar();
    await tester.pumpWidget(
      app(
        LoginScreen(destinoTrasLogin: (_, _) => const SizedBox()),
        const Locale('es'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final core = lookupNordayCoreLocalizations(const Locale('es'));
    expect(
      tester.widget<WordmarkIdentidad>(find.byType(WordmarkIdentidad)).texto,
      core.appTitulo,
    );
    expect(core.appTitulo, isNot(habits['es']!.nombre));
    expect(find.text(habits['es']!.lema), findsNothing);
  });
}
