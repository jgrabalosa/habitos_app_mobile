import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'home_shell.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/analytics_service.dart';
import '../services/idioma_service.dart';
import '../services/zona_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'recuperacion_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

 Future<void> _registrarNotificaciones(int usuarioId) async {
    try {
      final status = await Permission.notification.request();
      if (!status.isGranted) return;

      final messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final String? token = await messaging.getToken();
        if (token != null) {
          await ApiService.actualizarFcmToken(usuarioId, token);
        }
      }
    } catch (_) {
      // No bloqueamos el login si falla el registro de notificaciones
    }
  }

  /// Tras iniciar sesion, el backend manda la ultima palabra sobre las
  /// preferencias (puede haberlas cambiado desde otro dispositivo). En un
  /// alta nueva aun no hay nada guardado, asi que se propone la zona del
  /// dispositivo.
  Future<void> _sincronizarPreferencias(int usuarioId) async {
    try {
      final prefs = await ApiService.getPreferencias(usuarioId);
      await IdiomaService.sincronizarDesdeBackend(prefs['idioma']);
      await ZonaService.sincronizarDesdeBackend(prefs['zonaHoraria']);
    } catch (_) {
      // Sin conexion se sigue con lo que haya en local
    }
    await ZonaService.inicializarSiHaceFalta(usuarioId: usuarioId);
  }

  // ── Login ──────────────────────────────────────────────
  Future<void> _login() async {
    final l = AppLocalizations.of(context)!;
    setState(() { _loading = true; _error = null; });
    try {
      final usuario = await ApiService.login(
        _emailController.text,
        _contrasenaController.text,
      );
      await ApiService.saveToken(usuario.token);
      await ApiService.saveUsuario(usuario);
      await AnalyticsService.login(usuario.usuarioId);
      await _registrarNotificaciones(usuario.usuarioId);
      await _sincronizarPreferencias(usuario.usuarioId);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    } catch (e) {
      setState(() { _error = l.loginError; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ── Registro ───────────────────────────────────────────
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();

Future<void> _registro() async {
    final l = AppLocalizations.of(context)!;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.registro(
        _nombreController.text,
        _usernameController.text,
        _emailController.text,
        _contrasenaController.text,
      );

      // Auto-login tras registrarse, para poder ir directo a crear el primer hábito
      final usuario = await ApiService.login(
        _emailController.text,
        _contrasenaController.text,
      );
      await ApiService.saveToken(usuario.token);
      await ApiService.saveUsuario(usuario);
      await AnalyticsService.registro(usuario.usuarioId);
      await _registrarNotificaciones(usuario.usuarioId);
      await _sincronizarPreferencias(usuario.usuarioId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell(mostrarOnboarding: true)),
        );
      }
    } catch (e) {
      setState(() { _error = l.loginError; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ── Login con Google ───────────────────────────────────
  Future<void> _loginConGoogle() async {
    final l = AppLocalizations.of(context)!;
    setState(() { _loading = true; _error = null; });
    try {
      final esNuevo = await ApiService.loginConGoogle();
      final usuarioLocal = await ApiService.getUsuarioLocal();
      if (usuarioLocal != null && usuarioLocal['usuarioId'] != null) {
        await _registrarNotificaciones(usuarioLocal['usuarioId']);
        await _sincronizarPreferencias(usuarioLocal['usuarioId']);
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeShell(mostrarOnboarding: esNuevo)),
        );
      }
    } catch (e) {
      setState(() { _error = l.loginError; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Icon(LucideIcons.circleCheck, size: 72, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(l.appTitulo,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(l.loginTagline,
                  style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),

                // Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Tabs
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() { _isLogin = true; _error = null; }),
                                child: Column(children: [
                                  Text(l.loginIniciarSesion,
                                    style: TextStyle(
                                      color: _isLogin ? AppColors.primary : Colors.grey,
                                      fontWeight: _isLogin ? FontWeight.bold : FontWeight.normal,
                                    )),
                                  const SizedBox(height: 4),
                                  Container(height: 2,
                                    color: _isLogin ? AppColors.primary : Colors.transparent),
                                ]),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() { _isLogin = false; _error = null; }),
                                child: Column(children: [
                                  Text(l.loginRegistrarse,
                                    style: TextStyle(
                                      color: !_isLogin ? AppColors.primary : Colors.grey,
                                      fontWeight: !_isLogin ? FontWeight.bold : FontWeight.normal,
                                    )),
                                  const SizedBox(height: 4),
                                  Container(height: 2,
                                    color: !_isLogin ? AppColors.primary : Colors.transparent),
                                ]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Botón Google
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _loginConGoogle,
                            icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                            label: Text(l.loginContinuarGoogle),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(l.loginO, style: const TextStyle(color: Colors.grey)),
                          ),
                          const Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 12),

                        // Campos registro
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nombreController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: l.perfilLabelNombre,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: l.perfilLabelUsuario,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l.perfilLabelEmail,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Contraseña
                        TextField(
                          controller: _contrasenaController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l.loginLabelContrasena,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff),
                              onPressed: () => setState(() { _obscurePassword = !_obscurePassword; }),
                            ),
                          ),
                        ),

                        // ¿Olvidaste tu contraseña?
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RecuperacionScreen(),
                                        ),
                                      );
                                    },
                              child: Text(l.loginOlvidasteContrasena),
                            ),
                          )
                        else
                          const SizedBox(height: 16),

                        // Error
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_error!,
                              style: const TextStyle(color: Colors.red)),
                          ),
                        const SizedBox(height: 16),

                        // Botón
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : (_isLogin ? _login : _registro),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _isLogin ? l.loginIniciarSesion : l.loginCrearCuenta,
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}