import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';


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
      setState(() { _isLogin = true; _error = null; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cuenta creada! Ya puedes iniciar sesión.')),
      );
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
                const Text('HábitosApp',
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