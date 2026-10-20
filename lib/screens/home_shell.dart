import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/identidad_ui.dart';
import '../services/anclas_recorrido.dart';
import '../services/recorrido_onboarding.dart';
import '../widgets/bienvenida.dart';
import 'habito_screen.dart';
import '../services/habitos_refresh.dart';
import '../services/al_volver.dart';
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
Widget destinoConIdentidad(
  BuildContext context,
  bool mostrarOnboarding,
  bool? poseeIdentidad,
  int usuarioId,
) {
  if (poseeIdentidad == false) {
    return EleccionIdentidadScreen(
      usuarioId: usuarioId,
      alElegir: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeShell(mostrarOnboarding: mostrarOnboarding),
        ),
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

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tabIndex = 0;
  int _usuarioId = 0;
  bool _loading = true;

  /// Deslizar y tocar la barra mueven el mismo PageView, asi que el indice
  /// activo tiene una sola fuente: lo que diga `onPageChanged`.
  final _pageController = PageController();

  /// El titulo del AppBar y la etiqueta de la pestaña son el mismo texto:
  /// se leen de aqui para que no puedan divergir.
  List<String> _titulos(AppLocalizations l) => [
    l.navHoy,
    l.navMascota,
    l.navHabitos,
  ];

  /// Etiquetas de la barra inferior: las tres pestañas más el menú, que no es
  /// una pestaña sino un panel. Va aparte de `_titulos` a propósito, porque
  /// `_titulos` nombra páginas del PageView y el menú no lo es.
  List<String> _etiquetasNav(AppLocalizations l) => [..._titulos(l), l.navMenu];

  DateTime? _ultimaPulsacionAtras;

  final _recorrido = RecorridoOnboarding.instancia;

  /// El controlador ha cambiado de paso (o ha arrancado, o ha terminado). Sólo
  /// hace falta repintar: las anclas se enganchan mientras el recorrido está
  /// activo, y la pista de Hoy tiene que aparecer en cuanto empieza.
  void _alCambiarPaso() {
    if (mounted) setState(() {});
  }

  /// La pista de Hoy tras guardar el primer hábito: una sola, sobre el círculo
  /// del hábito. Sin «Saltar»: mientras está abierta el círculo no responde, y
  /// se cierra solo con «Entendido».
  void _iniciarPista() {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    _recorrido.iniciar(
      context,
      pasos: [
        PasoRecorrido(
          ancla: AnclasRecorrido.checkHabito,
          titulo: l.pistaCheckTitulo,
          cuerpo: l.pistaCheckCuerpo,
          textoBoton: l.recFin,
        ),
      ],
      textoContinuar: l.recFin,
    );
  }

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
    // Lo único que el velo del recorrido no bloquea por sí solo: el atrás no
    // pasa por el hit-test de la pantalla. La salida es el botón de saltar.
    if (_recorrido.activo) return;

    if (_tabIndex != 0) {
      _irAPestana(0);
      return;
    }

    final ahora = DateTime.now();
    final esSegundaPulsacion =
        _ultimaPulsacionAtras != null &&
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
    WidgetsBinding.instance.addObserver(this);
    _recorrido.addListener(_alCambiarPaso);
    _cargarUsuario();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      alVolverAPrimerPlano(_usuarioId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recorrido.removeListener(_alCambiarPaso);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await ApiServiceCore.getUsuarioLocal();
    if (usuario == null || !mounted) return;
    setState(() {
      _usuarioId = usuario['usuarioId'] ?? 0;
      _loading = false;
    });

    if (widget.mostrarOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _empezarAltaNueva());
    }
  }

  /// El alta nueva: la bienvenida, el formulario real del primer hábito y,
  /// si se guarda, una pista sobre su círculo en Hoy. Si se vuelve sin
  /// guardar, Hoy queda vacío y sin pista.
  Future<void> _empezarAltaNueva() async {
    if (!mounted) return;
    await Bienvenida.mostrar(context);
    if (!mounted) return;
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HabitoScreen(
          usuarioId: _usuarioId,
          nombresHabitosExistentes: const [],
        ),
      ),
    );
    if (guardado != true || !mounted) return;
    notificarHabitosCambiados();
    _irAPestana(0);
    _iniciarPista();
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
          builder: (_) => const LoginScreen(destinoTrasLogin: destinoTrasLogin),
        ),
      );
    }
  }

  /// El menú, que antes colgaba del AppBar. Se ancla abajo a la derecha,
  /// encima del botón que lo abre: el menú sale donde ha ido el dedo. Mide
  /// lo que mide su entrada más larga, no el ancho de la pantalla. No
  /// repite las tres pestañas: están en la misma barra, a dos dedos.
  void _abrirMenu() {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final id = identidad(context);

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (hoja) {
        Widget entrada(IconData icono, String texto, VoidCallback alPulsar) {
          return InkWell(
            onTap: () {
              // Se cierra ANTES de navegar: si no, la ruta nueva se empuja
              // debajo del panel y queda tapada.
              Navigator.pop(hoja);
              alPulsar();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icono, size: 18, color: t.points),
                  const SizedBox(width: 12),
                  Text(
                    texto,
                    style: TextStyle(
                      color: t.text,
                      fontSize: tamanoLectura(id, 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // En vez del Divider de borde a borde: un filo corto que se
        // desvanece por los dos lados. Separa lo que uno abre por gusto de
        // lo que uno abre por necesidad, sin cortar el panel en dos.
        final filo = Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Container(
              height: 1,
              width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    t.points.withValues(alpha: 0.0),
                    t.points.withValues(alpha: 0.45),
                    t.points.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        );

        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            // Justo encima de la barra de navegación, separado del borde.
            padding: EdgeInsets.only(
              right: 8,
              bottom: MediaQuery.of(context).padding.bottom + 88,
              left: 8,
            ),
            child: Material(
              color: t.surface,
              elevation: 8,
              borderRadius: BorderRadius.circular(id.radioSecundario),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    entrada(
                      LucideIcons.trophy,
                      l.navColeccion,
                      _abrirColeccion,
                    ),
                    entrada(LucideIcons.medal, l.logrosTitulo, _abrirLogros),
                    entrada(
                      LucideIcons.store,
                      // El título sale del paquete, que es de quien es la
                      // pantalla: aquí no se duplica la clave.
                      NordayCoreLocalizations.of(context)!.tiendaTitulo,
                      _abrirTienda,
                    ),
                    filo,
                    entrada(LucideIcons.userRound, l.perfilTitulo, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PerfilScreen(
                            usuarioId: _usuarioId,
                            destinoTrasLogin: destinoTrasLogin,
                          ),
                        ),
                      );
                    }),
                    entrada(LucideIcons.logOut, l.shellCerrarSesion, _logout),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final etiquetas = _etiquetasNav(l);
    const indiceMenu = 3;

    // Colección ya no es pestaña: se abre desde el icono del AppBar, con su
    // propia cabecera. Aquí solo viven las tres que se deslizan.
    final tabs = [
      DashboardScreen(activa: _tabIndex == 0),
      // `activa` es lo que hace que la mascota se recargue al volver a su
      // pestaña: el PageView la mantiene viva y su initState no se repite.
      MascotaScreen(
        usuarioId: _usuarioId,
        embebida: true,
        activa: _tabIndex == 1,
        // Los textos los pone la app: el core no puede nombrar hábitos.
        ayudaAnimo: AyudaCampo(
          texto: l.mascotaAyudaAnimo,
          etiquetaSemantica: l.mascotaAyudaAnimoEtiqueta,
          superindice: true,
        ),
        ayudaXp: AyudaCampo(
          texto: l.mascotaAyudaXp,
          etiquetaSemantica: l.mascotaAyudaXpEtiqueta,
          superindice: true,
        ),
      ),
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
        // Sin barra superior. La tenía para el avatar y el nombre, que se
        // fueron con los avatares, y para dos iconos que el menú ya lleva.
        // Quitarla sube el contenido unos 56 px, que es lo que necesitaba la
        // pantalla Hoy. El menú vive ahora en la barra inferior.
        body: Stack(
          // Un hijo no posicionado de Stack recibe constraints holgadas, no
          // las ajustadas que daba body: directamente: sin esto el contenido
          // se encogería a su tamaño mínimo.
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              key: ValueKey('fondo'),
              child: FondoIdentidad(),
            ),
            // La constelación va DELANTE del contenido, no detrás: detrás la
            // tapaban las tarjetas. Se pinta con luz aditiva, así que no puede
            // oscurecer nada de lo que queda debajo. Lleva IgnorePointer
            // dentro, así que no roba los toques de las tarjetas.
            // En Mascota no hay tarjetas que tapar, y detrás es donde se ve
            // bien detrás de Nori.
            if (_tabIndex == 1)
              const Positioned.fill(
                key: ValueKey('constelacion'),
                child: CapaProgresoIdentidad(),
              ),
            // Sin AppBar, este SafeArea sólo aparta la barra de estado del
            // sistema. Es lo único que separa el contenido del borde de
            // arriba, así que no se puede quitar.
            SafeArea(
              key: const ValueKey('paginas'),
              child: OcultoAlLectorDuranteCierre(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _tabIndex = i);
                  },
                  // Cada pestaña se mantiene viva al salir de pantalla, como
                  // hacía el IndexedStack: deslizar no debe recargar lo que
                  // ya estaba cargado.
                  children: [for (final tab in tabs) _MantenerVivo(child: tab)],
                ),
              ),
            ),
            // El cierre del día va ENTRE las páginas y la constelación: su
            // velo oscurece el contenido y las estrellas brillan por encima.
            // Sin cierre en curso no pinta nada ni roba toques.
            const Positioned.fill(
              key: ValueKey('cierre'),
              child: CapaCierreDelDia(),
            ),
            if (_tabIndex != 1)
              Positioned.fill(
                key: const ValueKey('constelacion'),
                child: CapaProgresoIdentidad(enHoy: _tabIndex == 0),
              ),
          ],
        ),
        // Lo único de la app que se ve en todo momento: la forma del indicador
        // y el color de lo activo salen de la identidad equipada.
        // La barra va fuera del Stack: el velo del cierre del día la cubre
        // con su propia pieza, que además impide cambiar de pestaña a media
        // ceremonia. Y OcultoAlLectorDuranteCierre la esconde al lector de
        // pantalla mientras tanto, como a las páginas.
        bottomNavigationBar: Stack(
          children: [
            OcultoAlLectorDuranteCierre(
              child: NavigationBarTheme(
                data: barraNavegacionIdentidad(
                  identidad(context),
                  t,
                  Theme.of(context).textTheme.labelMedium,
                ),
                child: NavigationBar(
                  // `selectedIndex` sigue valiendo 0, 1 o 2: el menú es el cuarto
                  // destino pero nunca queda seleccionado, porque no es una página.
                  // Al volver de la hoja, la pestaña marcada es la que ya estaba.
                  selectedIndex: _tabIndex,
                  onDestinationSelected: (i) {
                    if (i == indiceMenu) {
                      _abrirMenu();
                      return;
                    }
                    _irAPestana(i);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(LucideIcons.house),
                      label: etiquetas[0],
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.pawPrint),
                      label: etiquetas[1],
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.listChecks),
                      label: etiquetas[2],
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.menu),
                      label: etiquetas[3],
                    ),
                  ],
                ),
              ),
            ),
            const Positioned.fill(child: VeloBarraCierreDelDia()),
          ],
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
