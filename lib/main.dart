import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'l10n/app_localizations.dart';
import 'services/crashlytics_service.dart';
import 'services/idioma_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'theme/paletas_premium.dart';
import 'theme/avatares.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'widgets/splash_generico.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Lo primero tras Firebase: si algo de lo de abajo revienta, ya hay red.
  await CrashlyticsService.inicializar();
  await cargarTemaEquipadoGuardado();
  await cargarAvatarGuardado();
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
              navigatorKey: navigatorKey,
              onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitulo,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.deTema(tema),
              locale: locale,
              supportedLocales: IdiomaService.localesSoportados,
              localizationsDelegates: const [
                AppLocalizations.delegate,
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

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<String?> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Widget build(BuildContext context) {
    return SplashGenerico<String?>(
      rutaImagen: 'assets/branding/simbolo_negativo.png',
      colorFondo: const Color(0xFF0A1628),
      wordmark: 'Norday',
      tarea: _checkSession,
      onListo: (context, token) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => token != null ? const HomeShell() : const LoginScreen(),
          ),
        );
      },
    );
  }
}