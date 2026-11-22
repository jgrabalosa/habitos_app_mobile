import 'package:flutter/material.dart';
// Dependencia del core, no de la app: sólo se usa para simular el token.
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/home_shell.dart';
import 'package:habitos_app_mobile/widgets/permiso_avisos.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El aviso de actualización del core (T-058a) lo llama `HomeShell` al entrar:
/// una vez en una apertura normal y nunca en un alta nueva.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final llamadaOriginal = HomeShell.comprobarActualizacion;
  var llamadas = 0;

  setUp(() {
    llamadas = 0;
    SharedPreferences.setMockInitialValues({'usuarioId': 7});
    FlutterSecureStorage.setMockInitialValues({'token': 'token-de-prueba'});
    HomeShell.comprobarActualizacion = (_) async {
      llamadas++;
    };
    // Con permiso, la tarjeta de avisos (T-060) no sale ni retrasa el aviso.
    PermisoAvisos.concedido = () async => true;
  });

  tearDown(() {
    HomeShell.comprobarActualizacion = llamadaOriginal;
    PermisoAvisos.reiniciarParaTest();
  });

  Future<void> montar(WidgetTester tester, {required bool onboarding}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          NordayCoreLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: HomeShell(mostrarOnboarding: onboarding),
      ),
    );
    // Deja que `_cargarUsuario` termine.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  testWidgets('en una apertura normal se comprueba una vez', (tester) async {
    await montar(tester, onboarding: false);
    expect(llamadas, 1);
  });

  testWidgets('en un alta nueva no se comprueba', (tester) async {
    await montar(tester, onboarding: true);
    expect(llamadas, 0);
  });
}
