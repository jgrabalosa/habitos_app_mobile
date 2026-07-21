import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'coleccion_screen.dart';
import 'logros_screen.dart';
import 'perfil_screen.dart';
import 'login_screen.dart';
import 'habitos_screen.dart';
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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    // Nota temporal: Colección sigue trayendo su propio AppBar
    // (doble AppBar visible) hasta el paso 3.
    final tabs = [
      const DashboardScreen(),
      HabitosScreen(usuarioId: _usuarioId),
      ColeccionScreen(usuarioId: _usuarioId),
      const _MascotaPlaceholder(),
    ];

    return Scaffold(
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
          IconButton(
            icon: Icon(esOscuro ? LucideIcons.sun : LucideIcons.moon, color: t.textMuted),
            onPressed: () => alternarTema(context),
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
    );
  }
}

class _MascotaPlaceholder extends StatelessWidget {
  const _MascotaPlaceholder();

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    return Center(
      child: Text('Próximamente 🐣', style: TextStyle(color: t.textMuted)),
    );
  }
}