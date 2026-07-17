import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  final int usuarioId;

  const PerfilScreen({super.key, required this.usuarioId});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contrasenaActualController = TextEditingController();
  final _contrasenaNuevaController = TextEditingController();
  final _formContrasenaKey = GlobalKey<FormState>();

  bool _cargando = true;
  bool _esGoogle = false;
  bool _guardando = false;
  bool _cambiandoContrasena = false;
  bool _verContrasenas = false;
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final datos = await ApiService.getUsuarioLocal();
    if (datos != null && mounted) {
      _nombreController.text = datos['nombre'] ?? '';
      _usernameController.text = datos['username'] ?? '';
      _emailController.text = datos['email'] ?? '';
      _esGoogle = datos['proveedorAuth'] == 'GOOGLE';
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await ApiService.actualizarUsuario(
        widget.usuarioId,
        _nombreController.text.trim(),
        _usernameController.text.trim(),
        _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cambiarContrasena() async {
    if (!_formContrasenaKey.currentState!.validate()) return;

    setState(() => _cambiandoContrasena = true);
    try {
      await ApiService.cambiarContrasena(
        widget.usuarioId,
        _contrasenaActualController.text,
        _contrasenaNuevaController.text,
      );
      if (mounted) {
        _contrasenaActualController.clear();
        _contrasenaNuevaController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cambiandoContrasena = false);
    }
  }

  Future<void> _confirmarEliminarCuenta() async {
    // ── Primera confirmación ──
    final primera = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
            'Se borrarán para siempre todos tus hábitos, registros, '
            'rachas, logros y puntos.\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (primera != true || !mounted) return;

    // ── Segunda confirmación ──
    final segunda = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Última confirmación'),
        content: const Text(
            '¿Estás completamente seguro? Tu cuenta y todos tus datos '
            'se eliminarán de forma definitiva.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, eliminar mi cuenta'),
          ),
        ],
      ),
    );
    if (segunda != true || !mounted) return;

    setState(() => _eliminando = true);
    try {
      await ApiService.eliminarUsuario(widget.usuarioId);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _eliminando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la cuenta: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _contrasenaActualController.dispose();
    _contrasenaNuevaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi cuenta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(LucideIcons.userRound),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El nombre no puede estar vacío'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de usuario',
                          prefixIcon: Icon(LucideIcons.atSign),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El nombre de usuario no puede estar vacío'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_esGoogle,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(LucideIcons.mail),
                          helperText: _esGoogle
                              ? 'Gestionado por tu cuenta de Google'
                              : null,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'El email no puede estar vacío';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Introduce un email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        child: _guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Guardar cambios'),
                      ),
                      if (!_esGoogle) ...[
                        const SizedBox(height: 40),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Cambiar contraseña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: t.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formContrasenaKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _contrasenaActualController,
                                obscureText: !_verContrasenas,
                                decoration: const InputDecoration(
                                  labelText: 'Contraseña actual',
                                  prefixIcon: Icon(LucideIcons.lock),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Introduce tu contraseña actual'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contrasenaNuevaController,
                                obscureText: !_verContrasenas,
                                decoration: InputDecoration(
                                  labelText: 'Nueva contraseña',
                                  prefixIcon: const Icon(LucideIcons.keyRound),
                                  suffixIcon: IconButton(
                                    icon: Icon(_verContrasenas
                                        ? LucideIcons.eyeOff
                                        : LucideIcons.eye),
                                    onPressed: () => setState(() =>
                                        _verContrasenas = !_verContrasenas),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Introduce la nueva contraseña';
                                  }
                                  if (v.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton(
                                onPressed: _cambiandoContrasena
                                    ? null
                                    : _cambiarContrasena,
                                child: _cambiandoContrasena
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Cambiar contraseña'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Zona de peligro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed:
                            _eliminando ? null : _confirmarEliminarCuenta,
                        icon: _eliminando
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.red),
                              )
                            : const Icon(LucideIcons.trash2),
                        label: const Text('Eliminar mi cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}