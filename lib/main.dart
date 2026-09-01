import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'l10n/app_localizations.dart';
import 'l10n/catalogos.dart';
import 'services/crashlytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Las nueve familias van empaquetadas en `google_fonts/`, así que no hay
  // que salir a la red a por ellas. Con esto, un fichero que falte deja de
  // ser un fallo invisible —la fuente del sistema en su lugar— y pasa a
  // gritar en consola con el nombre exacto del que falta.
  GoogleFonts.config.allowRuntimeFetching = false;

  // La OFL obliga a distribuir la licencia con la fuente. Una por familia:
  // los nombres llevan sufijo porque los nueve ficheros originales se llaman
  // igual y se pisarían al estar todos en la misma carpeta.
  LicenseRegistry.addLicense(() async* {
    for (final familia in const [
      'Caveat',
      'Chakra_Petch',
      'Fraunces',
      'IBM_Plex_Sans',
      'Manrope',
      'Nunito',
      'Quicksand',
      'Space_Grotesk',
      'Work_Sans',
    ]) {
      final texto = await rootBundle.loadString('google_fonts/OFL-$familia.txt');
      yield LicenseEntryWithLineBreaks(['google_fonts'], texto);
    }
  });

  await Firebase.initializeApp();
  // Lo primero tras Firebase: si algo de lo de abajo revienta, ya hay red.
  await CrashlyticsService.inicializar();
  // El motor pinta la pantalla de logros y las celebraciones, pero los logros
  // de hábitos son nuestros: hay que dárselos antes del primer frame.
  Catalogos.registrarEnElMotor();
  // Antes de runApp: si no, el primer frame se pinta en el idioma equivocado
  await IdiomaService.cargarAlArrancar();
  // Obligatorio: sin esto DateFormat lanza LocaleDataException para es/en/pt.
  // GlobalMaterialLocalizations no cubre los símbolos de fecha de intl.
  await initializeDateFormatting();
  runApp(const HabitosApp());
}

class HabitosApp extends StatelessWidget {
  const HabitosApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dos notifiers anidados: el tema y el idioma cambian por su cuenta y
    // cualquiera de los dos debe repintar sin reiniciar la app.
    return ValueListenableBuilder<TokensContextuales>(
      valueListenable: temaEquipadoNotifier,
      builder: (context, tema, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: IdiomaService.localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              // El del paquete, no uno propio: el motor lo necesita para abrir
              // cosas que no cuelgan de ninguna pantalla (la celebración de un
              // logro puede dispararse desde cualquier sitio).
              navigatorKey: nordayNavigatorKey,
              onGenerateTitle: (context) =>
                  NordayCoreLocalizations.of(context)!.appTitulo,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.deTema(tema),
              locale: locale,
              supportedLocales: IdiomaService.localesSoportados,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                NordayCoreLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

/// Lo que el splash averigua antes de decidir a dónde ir.
class _Sesion {
  final String? token;
  final int? usuarioId;
  final bool? poseeIdentidad;
  const _Sesion(this.token, this.usuarioId, this.poseeIdentidad);
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<_Sesion> _checkSession() async {
    final token = await ApiServiceCore.getToken();
    if (token == null) return const _Sesion(null, null, null);
    final prefs = await SharedPreferences.getInstance();
    // Con sesión guardada, el aspecto lo manda el backend: puede haber
    // equipado otro tema desde otro dispositivo. No se puede hacer antes del
    // splash porque hasta aquí no hay ni usuarioId ni token.
    final usuarioId = prefs.getInt('usuarioId');
    bool? posee;
    if (usuarioId != null) {
      posee = await Equipamiento.cargarDeUsuarioSiSePuede(usuarioId);
    }
    return _Sesion(token, usuarioId, posee);
  }

  @override
  Widget build(BuildContext context) {
    return SplashGenerico<_Sesion>(
      // Asset de esta app, no del paquete: el branding no se comparte.
      rutaImagen: 'assets/branding/simbolo_negativo.png',
      colorFondo: const Color(0xFF0A1628),
      wordmark: 'Norday',
      anchoImagen: 220,
      tamanoWordmark: 32,
      tarea: _checkSession,
      onListo: (context, sesion) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => sesion.token != null
                ? destinoConIdentidad(
                    ctx, false, sesion.poseeIdentidad, sesion.usuarioId ?? 0)
                : const LoginScreen(destinoTrasLogin: destinoTrasLogin),
          ),
        );
      },
    );
  }
}
