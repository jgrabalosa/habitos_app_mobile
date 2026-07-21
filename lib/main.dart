import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'theme/paletas_premium.dart';
import 'theme/avatares.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await cargarTemaGuardado();
  await cargarTemaPremiumGuardado();
  await cargarAvatarGuardado();
  runApp(const HabitosApp());
}

class HabitosApp extends StatelessWidget {
  const HabitosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaNotifier,
      builder: (context, modo, _) {
        return ValueListenableBuilder<TokensContextuales?>(
          valueListenable: temaPremiumNotifier,
          builder: (context, premium, __) {
            final temaFijo = premium != null ? AppTheme.premium(premium) : null;
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Norday Hábitos',
              debugShowCheckedModeBanner: false,
              theme: temaFijo ?? AppTheme.light,
              darkTheme: temaFijo ?? AppTheme.dark,
              themeMode: modo,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => token != null
            ? const HomeShell()
            : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}