import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/home_shell.dart';
import 'package:habitos_app_mobile/screens/invitar_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El menú de la barra inferior lleva «Invitar a un amigo», entre el filo y
/// «Perfil», y abre la pantalla de invitación.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> abrirMenu(WidgetTester tester) async {
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

  testWidgets('la entrada va justo antes de «Perfil», con el regalo', (
    tester,
  ) async {
    await abrirMenu(tester);
    final invitar = find.text('Invitar a un amigo');
    expect(invitar, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: invitar, matching: find.byType(InkWell)),
        matching: find.byIcon(LucideIcons.gift),
      ),
      findsOneWidget,
    );
    const es = Locale('es');
    final perfil = lookupAppLocalizations(es).perfilTitulo;
    final tienda = lookupNordayCoreLocalizations(es).tiendaTitulo;
    final yInvitar = tester.getTopLeft(invitar).dy;
    final yPerfil = tester.getTopLeft(find.text(perfil)).dy;
    final yTienda = tester.getTopLeft(find.text(tienda)).dy;
    expect(yTienda, lessThan(yInvitar));
    expect(yInvitar, lessThan(yPerfil));
  });

  testWidgets('pulsarla abre InvitarScreen', (tester) async {
    await abrirMenu(tester);
    await tester.tap(find.text('Invitar a un amigo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(InvitarScreen), findsOneWidget);
  });
}
