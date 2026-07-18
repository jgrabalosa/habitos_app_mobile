import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class RecuperacionScreen extends StatefulWidget {
  const RecuperacionScreen({super.key});

  @override
  State<RecuperacionScreen> createState() => _RecuperacionScreenState();
}

class _RecuperacionScreenState extends State<RecuperacionScreen> {
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _codigoEnviado = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _enviarCodigo() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Escribe tu email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.solicitarCodigoRecuperacion(_emailController.text.trim());
      setState(() => _codigoEnviado = true);
    } catch (e) {
      setState(() => _error = 'No se pudo enviar el código. Inténtalo de nuevo.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _restablecer() async {
    if (_codigoController.text.trim().isEmpty ||
        _contrasenaController.text.isEmpty) {
      setState(() => _error = 'Rellena el código y la nueva contraseña');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.restablecerContrasena(
        _emailController.text.trim(),
        _codigoController.text.trim(),
        _contrasenaController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña restablecida ✅ Ya puedes iniciar sesión'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Icon(LucideIcons.keyRound, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _codigoEnviado
                    ? 'Revisa tu correo. Si el email está registrado, te hemos enviado un código de 6 dígitos (caduca en 15 minutos).'
                    : 'Escribe el email de tu cuenta y te enviaremos un código para restablecer la contraseña.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),

              // Email
              TextField(
                controller: _emailController,
                enabled: !_codigoEnviado,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),

              if (_codigoEnviado) ...[
                const SizedBox(height: 12),

                // Código
                TextField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Código de 6 dígitos',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),

                // Nueva contraseña
                TextField(
                  controller: _contrasenaController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    helperText: 'Mínimo 6 caracteres',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? LucideIcons.eye
                          : LucideIcons.eyeOff),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Error
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)),
                ),

              // Botón principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_codigoEnviado ? _restablecer : _enviarCodigo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _codigoEnviado
                              ? 'Restablecer contraseña'
                              : 'Enviar código',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                ),
              ),

              if (_codigoEnviado) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading ? null : _enviarCodigo,
                  child: const Text('Reenviar código'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}