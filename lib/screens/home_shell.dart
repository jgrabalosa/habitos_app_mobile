import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'coleccion_screen.dart';
import 'logros_screen.dart';
import 'perfil_screen.dart';
import 'login_screen.dart';
import 'habitos_screen.dart';
import 'mascota_screen.dart';
import '../theme/avatares.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  int _usuarioId = 0;
  String _nombre = '';
  bool _loading = true;

  static const _titulos = ['Hoy', 'Hábitos', 'Colección', 'Mascota'];

  DateTime? _ultimaPulsacionAtras;

  // Botón atrás Android: si no estás en "Hoy", vuelve ahí primero.
  // Si ya estás en "Hoy", hace falta pulsar dos veces seguidas para salir.
  Future<void> _manejarAtras() async {
    if (_tabIndex != 0) {
      setState(() => _tabIndex = 0);
      return;
    }

    final ahora = DateTime.now();
    final esSegundaPulsacion = _ultimaPulsacionAtras != null &&
        ahora.difference(_ultimaPulsacionAtras!) < const Duration(seconds: 2);

    if (esSegundaPulsacion) {
      SystemNavigator.pop();
      return;
    }

    _ultimaPulsacionAtras = ahora;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pulsa atrás otra vez para salir'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await ApiService.getUsuarioLocal();
    if (usuario == null) return;
    setState(() {
      _usuarioId = usuario['usuarioId'] ?? 0;
      _nombre = usuario['nombre'] ?? '';
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final t = tokens(context);

    // Nota temporal: Colección sigue trayendo su propio AppBar
    // (doble AppBar visible) hasta el paso 3.
    final tabs = [
      const DashboardScreen(),
      HabitosScreen(usuarioId: _usuarioId),
      ColeccionScreen(usuarioId: _usuarioId),
      MascotaScreen(usuarioId: _usuarioId),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _manejarAtras();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: _tabIndex == 0
              ? GestureDetector(
                  onTap: () => setState(() => _tabIndex = 2), // 2 = Colección
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarUsuario(nombre: _nombre, radius: 16),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(_nombre,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : Text(_titulos[_tabIndex],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(LucideIcons.trophy, color: t.points),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LogrosScreen(usuarioId: _usuarioId)),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(LucideIcons.menu, color: t.textMuted),
              onSelected: (valor) {
                if (valor == 'cuenta') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PerfilScreen(usuarioId: _usuarioId),
                    ),
                  );
                } else if (valor == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'cuenta',
                  child: Row(
                    children: [
                      Icon(LucideIcons.userRound, size: 20),
                      SizedBox(width: 12),
                      Text('Mi cuenta'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(LucideIcons.logOut, size: 20),
                      SizedBox(width: 12),
                      Text('Cerrar sesión'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: IndexedStack(index: _tabIndex, children: tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) => setState(() => _tabIndex = i),
          backgroundColor: t.surface,
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.house), label: 'Hoy'),
            NavigationDestination(icon: Icon(LucideIcons.listChecks), label: 'Hábitos'),
            NavigationDestination(icon: Icon(LucideIcons.layoutGrid), label: 'Colección'),
            NavigationDestination(icon: Icon(LucideIcons.pawPrint), label: 'Mascota'),
          ],
        ),
      ),
    );
  }
}