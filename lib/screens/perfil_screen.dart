import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/selector_preferencias.dart';
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
    final l = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l.perfilActualizado)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.perfilErrorGuardar)),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cambiarContrasena() async {
    final l = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l.perfilPassActualizada)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.perfilErrorPass)),
        );
      }
    } finally {
      if (mounted) setState(() => _cambiandoContrasena = false);
    }
  }

  Future<void> _confirmarEliminarCuenta() async {
    final l = AppLocalizations.of(context)!;
    // ── Primera confirmación ──
    final primera = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.perfilEliminarTitulo),
        content: Text(l.perfilEliminarCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.comunContinuar,
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
        title: Text(l.perfilUltimaConfirmacion),
        content: Text(l.perfilUltimaConfirmacionCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.perfilNoVolver),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.perfilSiEliminar),
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
          SnackBar(content: Text(l.perfilErrorEliminar)),
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
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.perfilTitulo,
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
                      SelectorPreferencias(usuarioId: widget.usuarioId),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l.perfilLabelNombre,
                          prefixIcon: const Icon(LucideIcons.userRound),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.perfilNombreVacio
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: l.perfilLabelUsuario,
                          prefixIcon: const Icon(LucideIcons.atSign),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.perfilUsuarioVacio
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_esGoogle,
                        decoration: InputDecoration(
                          labelText: l.perfilLabelEmail,
                          prefixIcon: const Icon(LucideIcons.mail),
                          helperText: _esGoogle
                              ? l.perfilGestionadoGoogle
                              : null,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l.perfilEmailVacio;
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return l.perfilEmailInvalido;
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
                            : Text(l.perfilGuardarCambios),
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
                                decoration: InputDecoration(
                                  labelText: l.perfilPassActual,
                                  prefixIcon: Icon(LucideIcons.lock),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l.perfilPassActualVacia
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contrasenaNuevaController,
                                obscureText: !_verContrasenas,
                                decoration: InputDecoration(
                                  labelText: l.perfilPassNueva,
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
                                    return l.perfilPassNuevaVacia;
                                  }
                                  if (v.length < 6) {
                                    return l.perfilMinimo6;
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
                                    : Text(l.perfilCambiarPass),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        l.perfilZonaPeligro,
                        style: const TextStyle(
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
                        label: Text(l.perfilEliminarCuenta),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}