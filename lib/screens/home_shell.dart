import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/identidad_ui.dart';
import 'dashboard_screen.dart';
import 'habitos_screen.dart';

/// Adónde va el motor cuando la sesión ya es buena.
///
/// `LoginScreen` y `PerfilScreen` viven en norday_flutter_core y no pueden
/// conocer `HomeShell` —el paquete no importa de la app—, así que se lo
/// decimos con esto. Es una función suelta y no un método para que valga como
/// constante donde hace falta.
Widget destinoTrasLogin(BuildContext context, bool mostrarOnboarding) =>
    HomeShell(mostrarOnboarding: mostrarOnboarding);

/// Igual que [destinoTrasLogin] pero intercalando la elección de identidad
/// cuando el usuario no tiene ninguna.
///
/// [poseeIdentidad] viene de `Equipamiento.cargarDeUsuarioSiSePuede`: `null`
/// significa que no se pudo averiguar, y entonces se deja pasar. Un corte de
/// red al arrancar no puede encerrar a nadie en una pantalla sin salida, y la
/// red de seguridad del backend ya cubre el caso persistente.
Widget destinoConIdentidad(BuildContext context, bool mostrarOnboarding,
    bool? poseeIdentidad, int usuarioId) {
  if (poseeIdentidad == false) {
    return EleccionIdentidadScreen(
      usuarioId: usuarioId,
      alElegir: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => HomeShell(mostrarOnboarding: mostrarOnboarding)),
      ),
    );
  }
  return HomeShell(mostrarOnboarding: mostrarOnboarding);
}

class HomeShell extends StatefulWidget {
  final bool mostrarOnboarding;
  const HomeShell({super.key, this.mostrarOnboarding = false});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  int _usuarioId = 0;
  String _nombre = '';
  bool _loading = true;

  /// Deslizar y tocar la barra mueven el mismo PageView, asi que el indice
  /// activo tiene una sola fuente: lo que diga `onPageChanged`.
  final _pageController = PageController();

  /// El titulo del AppBar y la etiqueta de la pestaña son el mismo texto:
  /// se leen de aqui para que no puedan divergir.
  List<String> _titulos(AppLocalizations l) =>
      [l.navHoy, l.navMascota, l.navHabitos];

  DateTime? _ultimaPulsacionAtras;

  void _irAPestana(int i) {
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _abrirColeccion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ColeccionScreen(usuarioId: _usuarioId)),
    );
  }

  void _abrirLogros() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LogrosScreen(usuarioId: _usuarioId)),
    );
  }

  /// Hasta ahora a la tienda sólo se llegaba desde el botón de la pantalla de
  /// mascota, que no es donde nadie la busca.
  void _abrirTienda() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TiendaScreen(usuarioId: _usuarioId)),
    );
  }

  // Botón atrás Android: si no estás en "Hoy", vuelve ahí primero.
  // Si ya estás en "Hoy", hace falta pulsar dos veces seguidas para salir.
  Future<void> _manejarAtras() async {
    if (_tabIndex != 0) {
      _irAPestana(0);
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.shellPulsaAtras),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await ApiServiceCore.getUsuarioLocal();
    if (usuario == null || !mounted) return;
    setState(() {
      _usuarioId = usuario['usuarioId'] ?? 0;
      _nombre = usuario['nombre'] ?? '';
      _loading = false;
    });

    if (widget.mostrarOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _comprobarOnboarding());
    }
  }

  // Salvaguarda: en circunstancias normales un alta nueva siempre tiene 0
  // avatares, pero si por lo que sea ya tiene alguno, no mostramos nada.
  Future<void> _comprobarOnboarding() async {
    if (!mounted) return;
    try {
      final tieneAvatar = await SelectorAvatarGratis.tieneAlgunAvatar(_usuarioId);
      if (!tieneAvatar && mounted) {
        OnboardingOverlay.mostrar(context, usuarioId: _usuarioId);
      }
    } catch (_) {
      // Sin conexion no se muestra el onboarding, pero tampoco se rompe el
      // arranque: se volvera a intentar en el siguiente alta.
    }
  }

  Future<void> _logout() async {
    await ApiServiceCore.logout();
    // Si no, el cielo del usuario anterior sigue puesto mientras carga el
    // siguiente.
    limpiarProgresoDia();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
                const LoginScreen(destinoTrasLogin: destinoTrasLogin)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final titulos = _titulos(l);

    // Colección ya no es pestaña: se abre desde el icono del AppBar, con su
    // propia cabecera. Aquí solo viven las tres que se deslizan.
    final tabs = [
      const DashboardScreen(),
      // `activa` es lo que hace que la mascota se recargue al volver a su
      // pestaña: el PageView la mantiene viva y su initState no se repite.
      MascotaScreen(usuarioId: _usuarioId, embebida: true, activa: _tabIndex == 1),
      HabitosScreen(usuarioId: _usuarioId),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _manejarAtras();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          // Transparente para que el cielo de FondoEstelar se vea a través de
          // la barra en vez de quedar tapado por un AppBar opaco.
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Imprescindible: sin esto, Material 3 tiñe el AppBar en cuanto hay
          // scroll debajo y vuelve a tapar el cielo.
          scrolledUnderElevation: 0,
          // El body pasa por detrás de la barra (extendBodyBehindAppBar), y
          // con la barra totalmente transparente el texto que sube se corta a
          // media letra sin que nada indique que hay una capa encima. Este
          // degradado es ese límite: el contenido se desvanece al entrar en la
          // zona en vez de cortarse.
          //
          // No es opaco a propósito. Arriba deja pasar algo de cielo y abajo
          // llega a cero, así que la barra sigue sin tapar el fondo. De paso
          // mejora el nombre de usuario y los iconos, que son de los pocos
          // textos de la app que van directos sobre el cielo sin superficie
          // debajo.
          //
          // IgnorePointer es obligatorio: sin él el degradado se traga los
          // toques del avatar y del menú.
          flexibleSpace: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    t.bg.withValues(alpha: 0.92),
                    t.bg.withValues(alpha: 0.55),
                    t.bg.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          title: _tabIndex == 0
              ? GestureDetector(
                  onTap: _abrirColeccion,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarUsuario(nombre: _nombre, radius: 22),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(_nombre,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : Text(titulos[_tabIndex],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: l.navColeccion,
              icon: Icon(LucideIcons.trophy, color: t.points),
              onPressed: _abrirColeccion,
            ),
            IconButton(
              tooltip: l.logrosTitulo,
              icon: Icon(LucideIcons.medal, color: t.textMuted),
              onPressed: _abrirLogros,
            ),
            PopupMenuButton<String>(
              icon: Icon(LucideIcons.menu, color: t.textMuted),
              onSelected: (valor) {
                switch (valor) {
                  case 'hoy':
                    _irAPestana(0);
                  case 'mascota':
                    _irAPestana(1);
                  case 'habitos':
                    _irAPestana(2);
                  case 'coleccion':
                    _abrirColeccion();
                  case 'logros':
                    _abrirLogros();
                  case 'tienda':
                    _abrirTienda();
                  case 'cuenta':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerfilScreen(
                          usuarioId: _usuarioId,
                          destinoTrasLogin: destinoTrasLogin,
                        ),
                      ),
                    );
                  case 'logout':
                    _logout();
                }
              },
              // El menu lleva a todo: las tres pestañas que se deslizan y las
              // dos pantallas que solo tenian icono arriba. Los iconos son los
              // mismos que en la barra inferior y el AppBar, y los textos las
              // mismas claves, para que nada pueda divergir.
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'hoy',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.house, size: 20),
                      const SizedBox(width: 12),
                      Text(l.navHoy),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'mascota',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.pawPrint, size: 20),
                      const SizedBox(width: 12),
                      Text(l.navMascota),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'habitos',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.listChecks, size: 20),
                      const SizedBox(width: 12),
                      Text(l.navHabitos),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'coleccion',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.trophy, size: 20),
                      const SizedBox(width: 12),
                      Text(l.navColeccion),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logros',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.medal, size: 20),
                      const SizedBox(width: 12),
                      Text(l.logrosTitulo),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'tienda',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.store, size: 20),
                      const SizedBox(width: 12),
                      // El título sale del paquete, que es de quien es la
                      // pantalla: aquí no se duplica la clave.
                      Text(NordayCoreLocalizations.of(context)!.tiendaTitulo),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'cuenta',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.userRound, size: 20),
                      const SizedBox(width: 12),
                      Text(l.perfilTitulo),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.logOut, size: 20),
                      const SizedBox(width: 12),
                      Text(l.shellCerrarSesion),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          // Un hijo no posicionado de Stack recibe constraints holgadas, no
          // las ajustadas que daba body: directamente: sin esto el contenido
          // se encogería a su tamaño mínimo.
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: FondoEstelar()),
            // `extendBodyBehindAppBar` ya mete la altura del AppBar en el
            // padding del MediaQuery del body, así que este SafeArea aparta
            // la barra de estado Y el AppBar. Añadir aquí kToolbarHeight
            // reservaba el mismo espacio dos veces.
            SafeArea(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _tabIndex = i),
                // Cada pestaña se mantiene viva al salir de pantalla, como
                // hacía el IndexedStack: deslizar no debe recargar lo que
                // ya estaba cargado.
                children: [for (final tab in tabs) _MantenerVivo(child: tab)],
              ),
            ),
            // La constelación va DELANTE del contenido, no detrás: detrás la
            // tapaban las tarjetas. Se pinta con luz aditiva, así que no puede
            // oscurecer nada de lo que queda debajo. Lleva IgnorePointer
            // dentro, así que no roba los toques de las tarjetas.
            const Positioned.fill(child: CapaConstelacion()),
          ],
        ),
        // Lo único de la app que se ve en todo momento: la forma del indicador
        // y el color de lo activo salen de la identidad equipada.
        bottomNavigationBar: NavigationBarTheme(
          data: barraNavegacionIdentidad(identidad(context), t),
          child: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: _irAPestana,
            destinations: [
              NavigationDestination(icon: const Icon(LucideIcons.house), label: titulos[0]),
              NavigationDestination(icon: const Icon(LucideIcons.pawPrint), label: titulos[1]),
              NavigationDestination(icon: const Icon(LucideIcons.listChecks), label: titulos[2]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mantiene vivo a su hijo cuando el PageView lo saca de pantalla. Genérico:
/// no sabe qué envuelve.
class _MantenerVivo extends StatefulWidget {
  final Widget child;
  const _MantenerVivo({required this.child});

  @override
  State<_MantenerVivo> createState() => _MantenerVivoState();
}

class _MantenerVivoState extends State<_MantenerVivo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}