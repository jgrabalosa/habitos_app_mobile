import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/identidad_ui.dart';
import '../services/anclas_recorrido.dart';
import '../services/recorrido_onboarding.dart';
import '../services/api_service_habitos.dart';
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
  bool _loading = true;

  /// Deslizar y tocar la barra mueven el mismo PageView, asi que el indice
  /// activo tiene una sola fuente: lo que diga `onPageChanged`.
  final _pageController = PageController();

  /// El titulo del AppBar y la etiqueta de la pestaña son el mismo texto:
  /// se leen de aqui para que no puedan divergir.
  List<String> _titulos(AppLocalizations l) =>
      [l.navHoy, l.navMascota, l.navHabitos];

  /// Etiquetas de la barra inferior: las tres pestañas más el menú, que no es
  /// una pestaña sino un panel. Va aparte de `_titulos` a propósito, porque
  /// `_titulos` nombra páginas del PageView y el menú no lo es.
  List<String> _etiquetasNav(AppLocalizations l) =>
      [..._titulos(l), l.navMenu];

  DateTime? _ultimaPulsacionAtras;

  final _recorrido = RecorridoOnboarding.instancia;

  /// Referencias a los dos pasos que viven en una pestaña concreta. Se guardan
  /// para reconocerlos por identidad al cambiar de paso: el controlador no
  /// numera los pasos a propósito, porque la lista no siempre es la misma.
  PasoRecorrido? _pasoPestanaHabitos;
  PasoRecorrido? _pasoCheck;
  PasoRecorrido? _pasoValoracion;
  PasoRecorrido? _pasoAlimentar;

  /// En qué pestaña se puede ver la marca de este paso, o null si da igual.
  int? _pestanaDe(PasoRecorrido paso) {
    if (paso == _pasoCheck || paso == _pasoValoracion) return 0;
    if (paso == _pasoAlimentar) return 1;
    return null;
  }

  /// El controlador ha cambiado de paso (o ha arrancado, o ha terminado).
  ///
  /// El shell hace dos cosas aquí y sólo él puede hacerlas: llevar al usuario
  /// a la pestaña donde vive la marca siguiente —tras guardar el hábito se
  /// sigue en Hábitos y la marca del check está en Hoy—, y repintarse, porque
  /// las anclas sólo se enganchan mientras el recorrido está activo.
  void _alCambiarPaso() {
    if (!mounted) return;
    final paso = _recorrido.pasoActual;
    if (paso != null) {
      final destino = _pestanaDe(paso);
      if (destino != null && destino != _tabIndex) _irAPestana(destino);
    }
    setState(() {});
  }

  /// Monta los pasos y arranca.
  ///
  /// `completo` distingue al usuario recién creado, que no tiene nada y pasa
  /// por el recorrido entero, del que reinstala con una cuenta que ya existe
  /// y por tanto ya tiene hábitos: a ése se le enseña sólo el tramo de
  /// explicación, porque empujarle a crear un segundo hábito no tendría
  /// sentido. Es una aproximación deliberada: se deduce de `mostrarOnboarding`
  /// en vez de preguntarle al backend cuántos hábitos hay.
  ///
  /// Al arrancar, las anclas todavía no están enganchadas —lo estarán en el
  /// repintado que provoca este mismo arranque—, y por eso el controlador
  /// reintenta medirlas unos frames antes de rendirse.
  void _iniciarRecorrido({required bool completo}) {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;

    _pasoPestanaHabitos = PasoRecorrido(
      ancla: AnclasRecorrido.pestanaHabitos,
      titulo: l.recPaso1Titulo,
      cuerpo: l.recPaso1Cuerpo,
    );
    final pasoNuevo = PasoRecorrido(
      ancla: AnclasRecorrido.botonNuevoHabito,
      titulo: l.recPaso2Titulo,
      cuerpo: l.recPaso2Cuerpo,
    );
    final pasoRecomendados = PasoRecorrido(
      ancla: AnclasRecorrido.recomendados,
      titulo: l.recPaso3Titulo,
      cuerpo: l.recPaso3Cuerpo,
    );
    _pasoCheck = PasoRecorrido(
      ancla: AnclasRecorrido.checkHabito,
      titulo: l.recPaso4Titulo,
      cuerpo: l.recPaso4Cuerpo,
      textoBoton: l.recSiguiente,
    );
    // Señala el mismo check que el paso anterior: la hoja de valoración sale
    // después de marcar, es una ruta, y el recorrido se pinta por encima de
    // todas. No hay forma de apuntarle, así que se cuenta antes.
    _pasoValoracion = PasoRecorrido(
      ancla: AnclasRecorrido.checkHabito,
      titulo: l.recValoracionTitulo,
      cuerpo: l.recValoracionCuerpo,
      textoBoton: l.recSiguiente,
    );
    _pasoAlimentar = PasoRecorrido(
      ancla: AnclasRecorrido.alimentar,
      titulo: l.recPaso5Titulo,
      cuerpo: l.recPaso5Cuerpo,
      textoBoton: l.recFin,
    );

    _recorrido.iniciar(
      context,
      pasos: completo
          ? [
              _pasoPestanaHabitos!,
              pasoNuevo,
              pasoRecomendados,
              _pasoCheck!,
              _pasoValoracion!,
              _pasoAlimentar!,
            ]
          : [_pasoCheck!, _pasoValoracion!, _pasoAlimentar!],
      textoSaltar: l.recSaltar,
      textoContinuar: l.recSiguiente,
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
    _recorrido.addListener(_alCambiarPaso);
    _cargarUsuario();
  }

  @override
  void dispose() {
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarOnboarding());
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _recorridoSiNoSeHaVisto());
    }
  }

  /// Sin alta nueva no hay bienvenida, pero el recorrido puede no haberse
  /// visto nunca en ESTE móvil: la marca es local, así que una reinstalación
  /// cuenta como primera vez. Es el caso de los testers.
  Future<void> _recorridoSiNoSeHaVisto() async {
    if (await RecorridoService.yaHecho()) return;
    await _arrancarSegunHabitos();
  }

  /// Arranca el recorrido eligiendo su longitud por lo que el usuario tiene,
  /// no por si acaba de registrarse.
  ///
  /// Sin hábitos hay que enseñarle a crear uno, y además la marca del check no
  /// tendría a qué apuntar. Con hábitos, empujarle a crear otro no tiene
  /// sentido y basta el tramo de explicación.
  ///
  /// Si la llamada falla no se arranca nada. No se puede adivinar qué enseñar,
  /// y como la marca de «hecho» no se pone, el recorrido vuelve a intentarlo
  /// en el siguiente arranque. Es preferible a enseñar un paso que miente.
  Future<void> _arrancarSegunHabitos() async {
    final List<Map<String, dynamic>> resumen;
    try {
      resumen = await ApiServiceHabitos.getResumenHabitos(_usuarioId);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    _iniciarRecorrido(completo: resumen.isEmpty);
  }

  // Antes esto preguntaba al backend si el usuario ya tenía algún avatar, para
  // no enseñar el selector dos veces. Con los avatares retirados del catálogo
  // esa pregunta devuelve siempre que no tiene ninguno, y el paso que los
  // ofrecía ya no existe en el overlay: la condición dejó de significar nada.
  void _mostrarOnboarding() {
    if (!mounted) return;
    // La bienvenida y el recorrido son un solo flujo: en cuanto se cierra el
    // overlay arranca el recorrido, sin que el usuario tenga que hacer nada
    // en medio.
    OnboardingOverlay.mostrar(context, usuarioId: _usuarioId)
        .then((_) => _iniciarRecorrido(completo: true));
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icono, size: 18, color: t.points),
                  const SizedBox(width: 12),
                  Text(
                    texto,
                    style: TextStyle(color: t.text, fontSize: 14),
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
                    entrada(LucideIcons.trophy, l.navColeccion, _abrirColeccion),
                    entrada(LucideIcons.medal, l.logrosTitulo, _abrirLogros),
                    entrada(
                      LucideIcons.store,
                      // El título sale del paquete, que es de quien es la
                      // pantalla: aquí no se duplica la clave.
                      NordayCoreLocalizations.of(context)!.tiendaTitulo,
                      _abrirTienda,
                    ),
                    filo,
                    entrada(LucideIcons.compass, l.recMenu,
                        () => _arrancarSegunHabitos()),
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
        // El core no puede conocer AnclasRecorrido, así que la key entra por
        // parámetro. Sólo mientras el recorrido corre.
        anclaAlimentar:
            _recorrido.activo ? AnclasRecorrido.alimentar : null,
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
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) {
                  setState(() => _tabIndex = i);
                  // Paso de acción: llegar a Hábitos ES la acción.
                  if (_recorrido.pasoActual == _pasoPestanaHabitos && i == 2) {
                    _recorrido.avanzar();
                  }
                },
                // Cada pestaña se mantiene viva al salir de pantalla, como
                // hacía el IndexedStack: deslizar no debe recargar lo que
                // ya estaba cargado.
                children: [for (final tab in tabs) _MantenerVivo(child: tab)],
              ),
            ),
            if (_tabIndex != 1)
              const Positioned.fill(
                key: ValueKey('constelacion'),
                child: CapaProgresoIdentidad(),
              ),
          ],
        ),
        // Lo único de la app que se ve en todo momento: la forma del indicador
        // y el color de lo activo salen de la identidad equipada.
        bottomNavigationBar: NavigationBarTheme(
          data: barraNavegacionIdentidad(
              identidad(context), t, Theme.of(context).textTheme.labelMedium),
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
              NavigationDestination(icon: const Icon(LucideIcons.house), label: etiquetas[0]),
              NavigationDestination(icon: const Icon(LucideIcons.pawPrint), label: etiquetas[1]),
              NavigationDestination(
                  icon: Icon(LucideIcons.listChecks,
                      key: _recorrido.activo
                          ? AnclasRecorrido.pestanaHabitos
                          : null),
                  label: etiquetas[2]),
              NavigationDestination(icon: const Icon(LucideIcons.menu), label: etiquetas[3]),
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