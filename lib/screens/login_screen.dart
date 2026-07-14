import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'habito_screen.dart';
import '../services/analytics_service.dart';


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
      final messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final String? token = await messaging.getToken();
        if (token != null) {
          await ApiService.actualizarFcmToken(usuarioId, token);
        }
      }
    } catch (e) {
      // No bloqueamos el login si falla el registro de notificaciones
      print('Error al registrar notificaciones: $e');
    }
  }

  // ── Login ──────────────────────────────────────────────
  Future<void> _login() async {
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
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ── Registro ───────────────────────────────────────────
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();

Future<void> _registro() async {
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HabitoScreen(usuarioId: usuario.usuarioId)),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ── Login con Google ───────────────────────────────────
  Future<void> _loginConGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.loginConGoogle();
      final usuarioLocal = await ApiService.getUsuarioLocal();
      if (usuarioLocal != null && usuarioLocal['usuarioId'] != null) {
        await _registrarNotificaciones(usuarioLocal['usuarioId']);
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Icon(Icons.check_circle, size: 72, color: Color(0xFF4a6cf7)),
                const SizedBox(height: 12),
                const Text('Norday Hábitos',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('Construye hábitos, transforma tu vida',
                  style: TextStyle(color: Colors.grey)),
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
                                  Text('Iniciar sesión',
                                    style: TextStyle(
                                      color: _isLogin ? const Color(0xFF4a6cf7) : Colors.grey,
                                      fontWeight: _isLogin ? FontWeight.bold : FontWeight.normal,
                                    )),
                                  const SizedBox(height: 4),
                                  Container(height: 2,
                                    color: _isLogin ? const Color(0xFF4a6cf7) : Colors.transparent),
                                ]),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() { _isLogin = false; _error = null; }),
                                child: Column(children: [
                                  Text('Registrarse',
                                    style: TextStyle(
                                      color: !_isLogin ? const Color(0xFF4a6cf7) : Colors.grey,
                                      fontWeight: !_isLogin ? FontWeight.bold : FontWeight.normal,
                                    )),
                                  const SizedBox(height: 4),
                                  Container(height: 2,
                                    color: !_isLogin ? const Color(0xFF4a6cf7) : Colors.transparent),
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
                            label: const Text('Continuar con Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('o', style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 12),

                        // Campos registro
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Contraseña
                        TextField(
                          controller: _contrasenaController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() { _obscurePassword = !_obscurePassword; }),
                            ),
                          ),
                        ),
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
                              backgroundColor: const Color(0xFF4a6cf7),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
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