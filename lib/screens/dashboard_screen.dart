import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../services/analytics_service.dart';
import '../services/habitos_refresh.dart';
import '../services/app_refresh.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habito.dart';
import '../models/hoy.dart';
import '../services/anclas_recorrido.dart';
import '../services/recorrido_onboarding.dart';
import '../widgets/estados_hoy.dart';
import '../widgets/identidad_ui.dart';
import '../widgets/panel_ritmo.dart';
import '../widgets/cabecera_otro_dia.dart';
import '../widgets/tira_semana.dart';
import '../widgets/transito_fila.dart';
import '../services/descubrimiento_detalle.dart';
import '../widgets/chevron_detalle.dart';
import 'dashboard_logica.dart';
import 'habito_detalle_screen.dart';

/// Lunes de la semana ISO a la que pertenece [dia], a medianoche.
///
/// Se construye con el constructor de DateTime y no con
/// `subtract(Duration(days: ...))` a propósito: Duration es tiempo absoluto,
/// y en una zona cuyo cambio de horario cae a medianoche (varias de América
/// del Sur, y `pt` es un idioma soportado) restar días puede aterrizar a las
/// 23:00 del día anterior. El constructor normaliza el día fuera de rango y
/// no depende de la duración real del día.
DateTime lunesDeLaSemanaDe(DateTime dia) =>
    DateTime(dia.year, dia.month, dia.day - (dia.weekday - 1));

/// Si [fecha] cae antes del lunes de la semana de [hoy]. Es la misma regla
/// que aplica el backend al completar y al deshacer (el suelo es el lunes de
/// la semana en curso, lunes incluido). Está duplicada aquí porque el
/// cliente necesita conocerla para apagar el check: un control que se puede
/// tocar y siempre falla es peor que un control apagado.
bool esAnteriorALaSemanaEnCurso(DateTime fecha, DateTime hoy) => DateTime(
  fecha.year,
  fecha.month,
  fecha.day,
).isBefore(lunesDeLaSemanaDe(DateTime(hoy.year, hoy.month, hoy.day)));

/// El ISO del día equivalente a [hoyIso] desplazado [offsetSemanas] semanas,
/// o null si aún no se conoce el hoy del servidor.
///
/// Aritmética con el constructor de DateTime y no con `Duration`, por la
/// misma razón que en [lunesDeLaSemanaDe]: Duration es tiempo absoluto y en
/// una zona que cambia de hora a medianoche aterriza en el día anterior.
String? isoDeSemanaDesplazada(String? hoyIso, int offsetSemanas) {
  if (hoyIso == null) return null;
  final hoy = DateTime.parse(hoyIso);
  final base = DateTime(hoy.year, hoy.month, hoy.day + 7 * offsetSemanas);
  return base.toIso8601String().split('T')[0];
}

/// `AAAA-MM-DD` de [fecha], sin hora.
String _iso(DateTime fecha) => fecha.toIso8601String().split('T')[0];

class DashboardScreen extends StatefulWidget {
  /// True cuando Hoy es la pestaña visible. El `PageView` la mantiene viva,
  /// así que su `initState` no se repite al volver: este es el único aviso.
  /// Mismo mecanismo que `activa` en `MascotaScreen`.
  final bool activa;

  const DashboardScreen({super.key, this.activa = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  /// La pantalla entera, tal como la manda `/hoy` para el día que se mira.
  /// Null hasta la primera respuesta.
  HoyLeido? _hoy;

  /// El día que se mira, `AAAA-MM-DD`. Null es "hoy": se deja que el servidor
  /// decida qué día es hoy en la zona del usuario.
  String? _fechaMirada;

  /// Pasos marcados (positivos) o deshechos (negativos) en esta pantalla que
  /// `/hoy` todavía no ha devuelto, por hábito. Se vacía en cada carga: es
  /// sólo para que el check, el contador y el anillo cambien al momento.
  final Map<int, int> _pasosPendientes = {};

  /// Cada carga lleva un número. Si el usuario toca dos días seguidos, la
  /// respuesta del primero no debe pisar la del segundo.
  int _cargaEnCurso = 0;

  bool _loading = true;
  int _usuarioId = 0;

  /// Las dos secciones se pueden plegar. Sólo dura mientras la pantalla vive.
  bool _hoyPlegada = false;
  bool _semanaPlegada = false;

  /// Días distintos en los que el usuario ha completado algún hábito. No es
  /// el número de checks: varios el mismo día cuentan como uno. Mide que
  /// vuelva, que es lo que da sentido a pedirle una reseña.
  int _diasUsoResena = 0;

  /// El último día ya contado, en `AAAA-MM-DD`, para no sumar dos veces.
  String _ultimaFechaResena = '';

  /// Días de uso en los que se pide la reseña. En el último se acaba: si a
  /// la tercera no la ha dejado, insistir sólo molesta.
  static const List<int> _hitosResena = [3, 15, 30];

  /// El último día en que se cerró el día, en `AAAA-MM-DD`: una sola vez al
  /// día aunque se desmarque y se vuelva a marcar. Va por usuario, así que
  /// una cuenta nueva en el mismo móvil tiene el suyo.
  String _ultimaFechaCierre = '';

  /// Entre el último check del día y el final de su secuencia. Mientras
  /// tanto el día no se marca cerrado: el realce de la constelación no debe
  /// llegar antes que la fugaz, los logros y la valoración.
  bool _cierrePendiente = false;

  String get _claveCierre => 'cierre_dia_fecha_$_usuarioId';

  /// Si la última carga falló. Un SnackBar solo se iba y dejaba una lista
  /// vacía detrás, que se lee igual que "no tienes hábitos".
  bool _errorCarga = false;

  /// El tránsito visual de una fila de "pendientes" a "completados" al
  /// completarse hoy, cuando quedan más pendientes detrás. `null` en reposo.
  AnimationController? _ctrlTransito;
  int? _habitoEnTransito;

  /// Caida al codigo crudo si llega una frecuencia desconocida, igual que
  /// hace Catalogos: nunca se deja al usuario sin texto.
  String _frecuenciaLegible(AppLocalizations l, String codigo) =>
      switch (codigo) {
        'DIARIO' => l.frecDiario,
        'SEMANAL' => l.frecSemanal,
        _ => codigo,
      };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    cargarDetalleDescubierto();
    habitosCambiadosNotifier.addListener(_alCambiarHabitos);
    appRefreshNotifier.addListener(_alRefrescoApp);
  }

  void _alRefrescoApp() {
    if (!mounted) return;
    _recargarDesdeApp();
  }

  /// Al volver a la app desde fuera se recarga todo y se vuelve a hoy, porque
  /// puede haber pasado la medianoche.
  Future<void> _recargarDesdeApp() async {
    if (!mounted) return;
    _fechaMirada = null;
    await _cargarDatos();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activa && !oldWidget.activa) {
      _volverAHoy();
    }
  }

  /// Al volver a la pestaña se vuelve siempre al día de hoy. Sin esto, el día
  /// que estuvieras mirando sobrevive al cambio de pestaña, porque la
  /// pantalla no se destruye.
  Future<void> _volverAHoy() async {
    if (!mounted || _fechaMirada == null) return;
    _fechaMirada = null;
    await _cargarHoy();
  }

  @override
  void dispose() {
    habitosCambiadosNotifier.removeListener(_alCambiarHabitos);
    appRefreshNotifier.removeListener(_alRefrescoApp);
    _ctrlTransito?.dispose();
    super.dispose();
  }

  /// Los hábitos han cambiado en otra pestaña: dar de alta uno cambia las
  /// secciones y la tira.
  void _alCambiarHabitos() {
    if (!mounted) return;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final usuario = await ApiServiceCore.getUsuarioLocal();
    if (usuario == null || !mounted) return;
    setState(() {
      _usuarioId = usuario['usuarioId'] ?? 0;
    });
    // En paralelo: el estado de reseña y el del cierre no dependen de Hoy.
    await Future.wait([
      _cargarHoy(),
      _cargarEstadoResena(),
      _cargarEstadoCierre(),
    ]);
  }

  /// Trae `/hoy` para el día que se mira. Es la única fuente de la pantalla:
  /// las dos secciones, la tira, el avance y los niveles de ritmo.
  Future<void> _cargarHoy() async {
    final carga = ++_cargaEnCurso;
    try {
      final data = await ApiServiceHabitos.getHoy(
        _usuarioId,
        fecha: _fechaMirada,
      );
      final hoy = leerHoy(data);
      if (!mounted || carga != _cargaEnCurso) return;
      setState(() {
        _hoy = hoy;
        _pasosPendientes.clear();
        _loading = false;
        _errorCarga = false;
      });
      _publicarProgreso();
      // Los logros de ritmo se ganan al leer Hoy, que es cuando se ve que el
      // ritmo ha subido: se celebran aquí. Casi siempre no hay ninguno.
      if (hoy.logrosOtorgados.isNotEmpty) {
        CelebracionService.mostrar(hoy.logrosOtorgados);
      }
    } catch (e) {
      if (!mounted || carga != _cargaEnCurso) return;
      // El aviso efímero dice QUÉ ha fallado. El panel de error sólo sale si
      // no hay nada que enseñar: con datos de una carga anterior, mejor los
      // datos viejos que un panel de error.
      setState(() {
        _loading = false;
        _errorCarga = _hoy == null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MensajesError.de(
              context,
              e,
              generico: AppLocalizations.of(context)!.dashSinConexion,
            ),
          ),
        ),
      );
    }
  }

  /// Mira otro día. Hoy se pide sin fecha, para que lo decida el servidor.
  Future<void> _irADia(String fecha) async {
    final hoy = _hoy;
    setState(() {
      _fechaMirada = (hoy != null && fecha == hoy.hoy) ? null : fecha;
    });
    await _cargarHoy();
  }

  /// El mismo día de la semana, [semanas] semanas antes o después. Sin
  /// límite a propósito: cada semana es una sola llamada, y una flecha
  /// apagada sin motivo visible confunde más de lo que protege. El freno es
  /// el botón de volver a hoy.
  Future<void> _moverSemanas(int semanas) async {
    final hoy = _hoy;
    if (hoy == null) return;
    final base = DateTime.parse(hoy.fecha);
    await _irADia(
      _iso(DateTime(base.year, base.month, base.day + 7 * semanas)),
    );
  }

  Future<void> _cargarEstadoCierre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ultimaFechaCierre = prefs.getString(_claveCierre) ?? '';
    } catch (_) {
      // Si falla, como mucho el día se cerraría otra vez hoy.
    }
  }

  Future<void> _cargarEstadoResena() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dias = prefs.getInt('resena_dias_uso') ?? 0;
      final ultima = prefs.getString('resena_ultima_fecha') ?? '';
      if (mounted) {
        setState(() {
          _diasUsoResena = dias;
          _ultimaFechaResena = ultima;
        });
      }
    } catch (_) {
      // Si falla, se queda en cero: como mucho se le pedirá más tarde de la
      // cuenta, que es el lado bueno por el que equivocarse.
    }
  }

  /// La fila tal como se pinta: la de `/hoy` con los pasos que aún no ha
  /// devuelto la recarga.
  FilaHoy _vista(FilaHoy f, {required bool delDia}) {
    final hoy = _hoy;
    final pasos = _pasosPendientes[f.habito.habitoId] ?? 0;
    if (hoy == null || pasos == 0) return f;
    return f.conPasos(pasos, delDia: delDia, fecha: hoy.fecha);
  }

  List<FilaHoy> _filasDelDia() => [
    for (final f in _hoy?.delDia.habitos ?? const <FilaHoy>[])
      _vista(f, delDia: true),
  ];

  List<FilaHoy> _filasDeLaSemana() => [
    for (final f in _hoy?.deLaSemana.habitos ?? const <FilaHoy>[])
      _vista(f, delDia: false),
  ];

  /// La fila de un hábito, venga de la sección que venga.
  FilaHoy? _filaDe(int habitoId) {
    for (final f in [..._filasDelDia(), ..._filasDeLaSemana()]) {
      if (f.habito.habitoId == habitoId) return f;
    }
    return null;
  }

  /// Si se está mirando hoy y todo lo de la sección del día está hecho.
  bool _diaCompleto() {
    final hoy = _hoy;
    if (hoy == null || !hoy.viendoHoy) return false;
    final filas = _filasDelDia();
    return filas.isNotEmpty && filas.every((f) => f.hecho);
  }

  /// Arranca el tránsito visual de la fila de `habitoId` de "pendientes" a
  /// "completados". Devuelve la duración real del gesto (para que quien
  /// celebra sepa cuánto esperar), o `Duration.zero` si no se ha animado
  /// nada —con "reducir movimiento" la fila salta igual que antes.
  Duration _arrancarTransito(int habitoId) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return Duration.zero;
    }

    // Si ya había un tránsito en vuelo, se da por completado de golpe antes
    // de empezar el nuevo: no se permiten dos a la vez.
    _ctrlTransito?.dispose();
    _ctrlTransito = null;
    _habitoEnTransito = null;

    final id = identidad(context);
    // Dos fases —hundimiento y traslado— sobre el mismo controller:
    // RanuraTransito reparte 0.0-0.5 y 0.5-1.0 de su propio progreso.
    final duracion = id.duracionTransicion * 2;

    final ctrl = AnimationController(vsync: this, duration: duracion);
    _ctrlTransito = ctrl;
    _habitoEnTransito = habitoId;
    ctrl.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _habitoEnTransito = null;
      });
      ctrl.dispose();
      _ctrlTransito = null;
    });
    return duracion;
  }

  /// Marca un paso del hábito el día que se mira.
  Future<void> _completar(int habitoId) async {
    // Red de seguridad: con la pista abierta el check no responde (ver
    // `checkTocable`), así que aquí no debería llegar.
    if (RecorridoOnboarding.instancia.activo) return;
    final hoy = _hoy;
    final antes = _filaDe(habitoId);
    if (hoy == null || antes == null) return;

    // Un semanal se apunta una vez por día como mucho.
    if (antes.esSemanal && antes.completadoEnFecha) return;

    final enDelDia = hoy.delDia.habitos.any(
      (f) => f.habito.habitoId == habitoId,
    );
    final esHoy = hoy.viendoHoy;

    List<String> logrosOtorgados;
    int puntosGanados;
    int puntosExtraSemana;
    int? registroId;
    bool mostrarValoracion;
    try {
      // Hoy se manda sin fecha y lo resuelve el servidor en la zona del
      // usuario; otro día, con la suya.
      final resultado = await ApiServiceHabitos.completarHabito(
        habitoId,
        fecha: esHoy ? null : hoy.fecha,
      );
      logrosOtorgados = resultado['logros'];
      puntosGanados = resultado['puntosGanados'];
      puntosExtraSemana = resultado['puntosExtraSemana'] ?? 0;
      registroId = resultado['registroId'];
      mostrarValoracion = resultado['mostrarValoracion'] ?? false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              MensajesError.de(
                context,
                e,
                generico: AppLocalizations.of(context)!.dashSinConexion,
              ),
            ),
          ),
        );
      }
      return;
    }

    // Completar cambia el ánimo de la mascota en el servidor: hay que avisar a
    // quien la esté pintando (la mini-mascota flotante no se entera sola).
    solicitarRefrescoMascota();

    // Analytics en segundo plano: no bloquea la celebración
    AnalyticsHabitos.habitoCompletado(antes.habito.frecuencia);

    // Feedback háptico + sonido
    HapticFeedback.mediumImpact();
    SonidoService.reproducir('completar');

    // El paso cuenta ya en pantalla, sin esperar a la recarga: el cambio
    // dispara la animación del check.
    if (!mounted) return;
    setState(() {
      _pasosPendientes[habitoId] = (_pasosPendientes[habitoId] ?? 0) + 1;
    });
    final despues = _filaDe(habitoId);

    // El tránsito de la fila a "completados" sólo tiene sentido en la sección
    // del día de hoy, si con este paso la fila pasa a hecha y queda al menos
    // otra pendiente detrás.
    final pasaAHecha = !antes.hecho && (despues?.hecho ?? false);
    final quedanPendientes = _filasDelDia().any(
      (f) => f.habito.habitoId != habitoId && !f.hecho,
    );
    final Duration duracionTransito =
        esHoy && enDelDia && pasaAHecha && quedanPendientes
        ? _arrancarTransito(habitoId)
        : Duration.zero;

    // Si con este paso el día queda completo, el cierre espera al final de
    // la secuencia (ver `_cierrePendiente`).
    final diaCompleto = esHoy && enDelDia && _diaCompleto();
    if (diaCompleto) _cierrePendiente = true;

    _publicarProgreso();

    // La verdad la trae /hoy: contadores, avance, tira y ritmo. En segundo
    // plano, sin bloquear la celebración.
    _cargarHoy();

    // Si arrancó el tránsito de la fila, la celebración espera a que termine.
    // Sin tránsito se conserva una pausa corta.
    await Future.delayed(
      duracionTransito > Duration.zero
          ? duracionTransito
          : const Duration(milliseconds: 400),
    );

    // Secuencia: logro (si hay) → puntos → valoración (si toca)
    if (logrosOtorgados.isNotEmpty) {
      await CelebracionService.mostrar(logrosOtorgados);
    }
    if (puntosGanados > 0 && mounted) {
      AnimacionPuntos.mostrar(context, puntosGanados);
    }
    // Al cobrar el extra de la semana se dice por qué ha llegado (sección 11
    // del rediseño de rachas).
    if (puntosExtraSemana > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.dashExtraSemana(puntosExtraSemana),
          ),
        ),
      );
    }

    if (mostrarValoracion && registroId != null && mounted) {
      // Pequeña pausa para no pisar la animación de puntos
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      final respuesta = await ValoracionSheet.mostrar(context);
      if (respuesta != null) {
        try {
          final int? valoracion = respuesta['valoracion'];
          final String? nota = respuesta['nota'];
          if (valoracion != null) {
            await ApiServiceHabitos.valorarRegistro(registroId, valoracion);
          }
          if (nota != null) {
            await ApiServiceHabitos.actualizarNotaRegistro(registroId, nota);
          }
        } catch (e) {
          // La valoración es opcional: si falla, no molestamos al usuario
        }
      }
    }

    if (diaCompleto) await _cerrarDia();

    _registrarDiaDeUso();
  }

  /// El cierre del día, al final de toda la secuencia del último check: el
  /// día queda cerrado (en Profundidad, la constelación realzada; en Dulce, el
  /// ramo). Una vez al día, y nunca mientras la pista de Hoy está abierta. Va antes de la
  /// reseña de Play para que no se coma el momento.
  Future<void> _cerrarDia() async {
    final hoy = _fechaDeHoy();
    if (mounted &&
        _diaCompleto() &&
        !RecorridoOnboarding.instancia.activo &&
        hoy != _ultimaFechaCierre) {
      _ultimaFechaCierre = hoy;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_claveCierre, hoy);
      } catch (_) {
        // Si no se guarda, como mucho saldría otra vez hoy.
      }
      // Desde aquí el día ya cuenta como cerrado: la ceremonia enciende el
      // realce, y cualquier refresco a media ceremonia lo tiene que respetar.
      _cierrePendiente = false;
      // La ceremonia de fin de día. Hace algo en Profundidad (la constelación)
      // y en Dulce (el ramo); en Neotokyo+ termina en el acto. Al irse el velo
      // queda el realce del día cerrado, que pone _publicarProgreso, justo
      // debajo.
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        await mostrarCierreDelDia(
          titulo: l.dashTodoHecho,
          despedida: l.dashDisfruta,
        );
      }
    }
    _cierrePendiente = false;
    if (mounted) _publicarProgreso();
  }

  /// Hoy en el reloj del móvil, en `AAAA-MM-DD`.
  static String _fechaDeHoy() {
    final ahora = DateTime.now();
    return '${ahora.year.toString().padLeft(4, '0')}-'
        '${ahora.month.toString().padLeft(2, '0')}-'
        '${ahora.day.toString().padLeft(2, '0')}';
  }

  /// Deshace el último paso del hábito el día que se mira.
  ///
  /// El `registroId` no viaja en `/hoy`, así que se busca en el momento entre
  /// los registros de ese día. Es una acción rara, y así no hay un id
  /// guardado que se quede rancio si el hábito se marcó desde otro sitio.
  Future<void> _deshacer(int habitoId) async {
    final l = AppLocalizations.of(context)!;
    final hoy = _hoy;
    if (hoy == null) return;
    final fecha = hoy.fecha;

    // Apagado local inmediato: el usuario ha tocado un check marcado y lo que
    // espera es verlo apagarse, no esperar a la red.
    setState(() {
      _pasosPendientes[habitoId] = (_pasosPendientes[habitoId] ?? 0) - 1;
    });
    _publicarProgreso();
    HapticFeedback.selectionClick();

    try {
      final registros = await ApiServiceHabitos.getRegistrosHabito(habitoId);
      final candidatos = registros
          .cast<Map<String, dynamic>>()
          .where((r) => r['fecha'] == fecha)
          .toList();
      if (candidatos.isEmpty) {
        throw Exception('No hay un registro en esa fecha');
      }
      final registro = candidatos.reduce(
        (a, b) => (a['registroId'] as int) > (b['registroId'] as int) ? a : b,
      );
      await ApiServiceHabitos.deshacerRegistro(registro['registroId'] as int);
    } catch (e) {
      // El paso sigue vivo en el servidor: se devuelve lo local.
      if (!mounted) return;
      setState(() {
        _pasosPendientes[habitoId] = (_pasosPendientes[habitoId] ?? 0) + 1;
      });
      _publicarProgreso();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MensajesError.de(context, e, generico: l.dashDeshacerError),
          ),
        ),
      );
      return;
    }

    // Deshacer devuelve experiencia a la mascota: quien la esté pintando no
    // se entera solo.
    solicitarRefrescoMascota();

    // Y el servidor manda sobre lo local, igual que al completar.
    await _cargarHoy();
  }

  /// Suma un día de uso si hoy no estaba contado, y pide la reseña si con
  /// eso se alcanza uno de los hitos.
  ///
  /// Se llama al completar un hábito, no al abrir la app: abrirla y no hacer
  /// nada no es usarla.
  Future<void> _registrarDiaDeUso() async {
    try {
      final ahora = DateTime.now();
      final hoy =
          '${ahora.year.toString().padLeft(4, '0')}-'
          '${ahora.month.toString().padLeft(2, '0')}-'
          '${ahora.day.toString().padLeft(2, '0')}';
      if (hoy == _ultimaFechaResena) return;

      final dias = _diasUsoResena + 1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('resena_dias_uso', dias);
      await prefs.setString('resena_ultima_fecha', hoy);
      if (mounted) {
        setState(() {
          _diasUsoResena = dias;
          _ultimaFechaResena = hoy;
        });
      }

      if (_hitosResena.contains(dias)) await _solicitarResena();
    } catch (_) {
      // Contar días no es crítico: si falla, no se molesta al usuario.
    }
  }

  Future<void> _solicitarResena() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        // `requestReview()` no dice si se mostró el diálogo ni si el usuario
        // valoró —Google aplica su propia cuota y calla—, así que los
        // reintentos de los hitos siguientes van a ciegas a propósito.
        await inAppReview.requestReview();
      }
    } catch (e) {
      // Si falla, no bloqueamos nada
    }
  }

  /// Publica en el core el progreso del día que se mira, para que el fondo de
  /// la identidad dibuje con él: cuántos hay en la sección del día, cuántos
  /// están hechos y el avance con lo hecho a medias.
  ///
  /// Se llama desde los puntos donde el dato cambia de verdad —las cargas,
  /// marcar y deshacer— y NUNCA desde `build`: notificar a un
  /// `ValueNotifier` durante un `build` es excepción o frame perdido.
  void _publicarProgreso() {
    final hoy = _hoy;
    if (hoy == null) return;
    final filas = _filasDelDia();
    publicarProgresoDia(
      hechos: filas.where((f) => f.hecho).length,
      total: filas.length,
      fecha: DateTime.parse(hoy.fecha),
      avance: avanceDelDia(filas) ?? 0,
    );
    if (hoy.viendoHoy) {
      _publicarCierre();
    } else {
      // Otro día de la tira, aunque esté completo, se ve normal.
      marcarDiaCerrado(false);
    }
  }

  /// Hoy, completo y con su secuencia terminada, es un día cerrado.
  void _publicarCierre() {
    marcarDiaCerrado(!_cierrePendiente && _diaCompleto());
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;
    final hoy = _hoy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final areaSize = constraints.biggest;
        return Stack(
          children: [
            _loading
                ? const SkeletonHoy()
                : RefreshIndicator(
                    onRefresh: _cargarHoy,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        96 + MediaQuery.of(context).padding.bottom,
                      ),
                      children: hoy == null
                          ? [
                              if (_errorCarga)
                                EstadoErrorHoy(onReintentar: _cargarHoy),
                            ]
                          : _contenido(l, t, hoy),
                    ),
                  ),
            if (!_loading && _usuarioId != 0)
              MiniMascota(usuarioId: _usuarioId, areaSize: areaSize),
          ],
        );
      },
    );
  }

  /// Todo lo que va dentro de la lista, una vez cargado `/hoy`.
  List<Widget> _contenido(
    AppLocalizations l,
    TokensContextuales t,
    HoyLeido hoy,
  ) {
    final filasDia = _filasDelDia();
    final filasSemana = _filasDeLaSemana();
    final hechosDia = filasDia.where((f) => f.hecho).length;
    final hechosSemana = filasSemana.where((f) => f.hecho).length;
    final viendoHoy = hoy.viendoHoy;

    // El check se apaga en un día futuro o de una semana anterior: el
    // backend no deja marcar ni deshacer ahí.
    final fechaMirada = DateTime.parse(hoy.fecha);
    final fechaHoy = DateTime.parse(hoy.hoy);
    final bool habilitado =
        !fechaMirada.isAfter(fechaHoy) &&
        !esAnteriorALaSemanaEnCurso(fechaMirada, fechaHoy);

    // El hábito en tránsito (ver _arrancarTransito) se queda en su posición
    // de "pendientes" aunque ya cuente como hecho, y aparece ADEMÁS al final
    // de "completados": las dos apariciones conviven mientras dura el gesto.
    final pendientes = <FilaHoy>[];
    final completados = <FilaHoy>[];
    for (final f in filasDia) {
      if (f.hecho && f.habito.habitoId != _habitoEnTransito) {
        completados.add(f);
      } else {
        pendientes.add(f);
      }
    }
    if (_habitoEnTransito != null) {
      final enTransito = filasDia.where(
        (f) => f.habito.habitoId == _habitoEnTransito,
      );
      if (enTransito.isNotEmpty) completados.add(enTransito.first);
    }

    final sinNada = filasDia.isEmpty && filasSemana.isEmpty;
    // Sin nada que hacer hoy, la pista de Hoy señala el check de la primera
    // fila de Esta semana (un primer hábito semanal que hoy no toca).
    final anclaEnSemana = viendoHoy && filasDia.isEmpty;

    return [
      // La línea del día que se mira, solo si no es hoy; luego la tira, pegada
      // al borde, que es lo que más se toca.
      CabeceraOtroDia(
        fecha: DateTime.parse(hoy.fecha),
        viendoHoy: viendoHoy,
        onHoy: () => _irADia(hoy.hoy),
      ),
      TiraSemana(
        dias: hoy.dias,
        diaSeleccionado: hoy.indiceFecha,
        indiceHoy: hoy.indiceHoy,
        onSeleccionar: (i) => _irADia(hoy.dias[i].fecha),
        onSemanaAnterior: () => _moverSemanas(-1),
        onSemanaSiguiente: () => _moverSemanas(1),
      ),
      const SizedBox(height: 12),
      if (hoy.ritmoNivel != null) ...[
        _tarjetaRitmo(l, t, hoy.ritmoNivel!),
        const SizedBox(height: 4),
      ],
      if (sinNada)
        viendoHoy
            ? const EstadoVacioHoy()
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l.dashDiaSinHabitos,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textMuted),
                ),
              ),
      if (filasDia.isNotEmpty) ...[
        _tituloSeccion(
          l,
          t,
          titulo: l.dashSeccionHoy,
          hechos: hechosDia,
          total: filasDia.length,
          plegada: _hoyPlegada,
          alPlegar: () => setState(() => _hoyPlegada = !_hoyPlegada),
        ),
        const SizedBox(height: 8),
        if (!_hoyPlegada) ...[
          if (pendientes.isEmpty && viendoHoy)
            FinalDelDiaHoy(total: filasDia.length)
          else
            ...pendientes.asMap().entries.map(
              (e) => _filaEnLista(
                l,
                e.value,
                false,
                t,
                habilitado: habilitado,
                primera: viendoHoy && e.key == 0,
              ),
            ),
          if (completados.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l.dashCompletados,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 8),
            ...completados.map(
              (f) => _filaEnLista(l, f, true, t, habilitado: habilitado),
            ),
          ],
        ],
        const SizedBox(height: 16),
      ],
      if (filasSemana.isNotEmpty) ...[
        _tituloSeccion(
          l,
          t,
          titulo: l.dashFlexiblesTitulo,
          hechos: hechosSemana,
          total: filasSemana.length,
          plegada: _semanaPlegada,
          alPlegar: () => setState(() => _semanaPlegada = !_semanaPlegada),
          ayuda: AyudaCampo(
            texto: l.dashAyudaFlexibles,
            etiquetaSemantica: l.dashAyudaFlexiblesEtiqueta,
            superindice: true,
          ),
          acento: t.streakText,
        ),
        const SizedBox(height: 8),
        if (!_semanaPlegada)
          ...filasSemana.asMap().entries.map(
            (e) => _habitoCard(
              l,
              e.value,
              t,
              habilitado: habilitado,
              anclaPista: anclaEnSemana && e.key == 0,
            ),
          ),
      ],
    ];
  }

  /// El título de una sección: nombre, «1 de 4» y el botón de plegar.
  Widget _tituloSeccion(
    AppLocalizations l,
    TokensContextuales t, {
    required String titulo,
    required int hechos,
    required int total,
    required bool plegada,
    required VoidCallback alPlegar,
    Widget? ayuda,
    Color? acento,
  }) {
    final estilo = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: acento ?? t.textMuted);
    return Row(
      children: [
        Text(titulo, style: estilo),
        ?ayuda,
        const SizedBox(width: 10),
        Text(
          l.dashSeccionContador(hechos, total),
          style: estilo?.copyWith(color: t.text),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(plegada ? LucideIcons.chevronDown : LucideIcons.chevronUp),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          color: t.textMuted,
          tooltip: plegada
              ? l.a11yDesplegarSeccion(titulo)
              : l.a11yPlegarSeccion(titulo),
          onPressed: alPlegar,
        ),
      ],
    );
  }

  /// Abre el panel «Tu ritmo». Si se toca un hábito, se va a su detalle.
  Future<void> _abrirPanelRitmo() async {
    final hoy = _hoy;
    if (hoy == null) return;
    final habito = await mostrarPanelRitmo(context, hoy);
    if (habito == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitoDetalleScreen(
          habitoId: habito.habitoId,
          usuarioId: _usuarioId,
          nombre: habito.nombre,
          descripcion: habito.descripcion,
        ),
      ),
    );
    _cargarHoy();
  }

  /// La tarjeta del ritmo general: su palabra en una línea y el dibujo de la
  /// identidad. Al tocarla se abre el panel «Tu ritmo».
  Widget _tarjetaRitmo(AppLocalizations l, TokensContextuales t, int nivel) {
    final palabra = palabraRitmo(l, nivel);
    final texto = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      button: true,
      label: l.a11yRitmoGeneral(palabra, nivel),
      onTap: _abrirPanelRitmo,
      child: ExcludeSemantics(
        child: TarjetaIdentidad(
          onTap: _abrirPanelRitmo,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                // La palabra en el color de los puntos, el mismo de las
                // estrellas llenas: es lo que se ve de lejos. Una línea: la
                // causa ya se ve en el panel «Tu ritmo».
                Expanded(
                  child: Text(
                    palabra,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texto.titleLarge?.copyWith(
                      color: t.points,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IndicadorNivel(nivel: nivel, tamano: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Una fila de la sección del día: la del hábito en tránsito (ver
  /// `_arrancarTransito`) se pinta dentro de un `RanuraTransito` animado por
  /// `_ctrlTransito`, una vez como origen (en pendientes) y otra como
  /// destino (en completados); las demás se pintan tal cual.
  Widget _filaEnLista(
    AppLocalizations l,
    FilaHoy f,
    bool enCompletados,
    TokensContextuales t, {
    required bool habilitado,
    bool primera = false,
  }) {
    final ctrl = _ctrlTransito;
    if (ctrl == null || f.habito.habitoId != _habitoEnTransito) {
      return _habitoCard(l, f, t, habilitado: habilitado, primera: primera);
    }

    final id = identidad(context);
    return AnimatedBuilder(
      animation: ctrl,
      child: _habitoCard(l, f, t, habilitado: habilitado),
      builder: (context, child) => RanuraTransito(
        progreso: ctrl.value,
        papel: enCompletados ? PapelTransito.destino : PapelTransito.origen,
        curva: id.curvaTransicion,
        child: child!,
      ),
    );
  }

  /// Una fila de hábito, de cualquiera de las dos secciones.
  ///
  /// `primera` marca la primera pendiente de hoy, donde se empuja el chevron
  /// del detalle.
  ///
  /// `anclaPista` engancha el ancla de la pista de Hoy en el check de esta
  /// fila: se usa en la primera fila de Esta semana cuando la sección Hoy está
  /// vacía (un primer hábito semanal que hoy no toca). No empuja el chevron.
  Widget _habitoCard(
    AppLocalizations l,
    FilaHoy f,
    TokensContextuales t, {
    required bool habilitado,
    bool primera = false,
    bool anclaPista = false,
  }) {
    final Habito h = f.habito;
    final bool hecho = f.hecho;
    // El check se ve marcado si la fila cuenta como hecha o, en un semanal,
    // si ya se hizo el día que se mira: un semanal se apunta una vez por día.
    final bool checkMarcado = hecho || (f.esSemanal && f.completadoEnFecha);

    return AnimatedOpacity(
      // La fila se apaga al completarse. Con "reducir movimiento" llega al
      // mismo valor, sin recorrido.
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 400),
      opacity: hecho ? 0.80 : 1.0,
      child: TarjetaIdentidad(
        // En Neotokyo+ el filo dice el estado: late mientras está pendiente,
        // se queda encendido al hacerlo. En un día que no se puede marcar
        // (futuro o de una semana anterior), fijo: no late lo que no se
        // puede hacer.
        filoNeon: !habilitado
            ? FiloNeon.fijo
            : (checkMarcado ? FiloNeon.encendido : FiloNeon.latiendo),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HabitoDetalleScreen(
                habitoId: h.habitoId,
                usuarioId: _usuarioId,
                nombre: h.nombre,
                descripcion: h.descripcion,
              ),
            ),
          );
          _cargarHoy();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Hero(
                            tag: 'habito-nombre-${h.habitoId}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                h.nombre,
                                // Dos líneas antes de cortar: los nombres
                                // reales son frases.
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      decoration: hecho
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: hecho ? t.textMuted : t.text,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Como en la maqueta: debajo del nombre, la frecuencia
                    // con lo que lleva y el dibujo de su ritmo.
                    Row(
                      children: [
                        ChipIdentidad(
                          texto: l.dashChipFrecuencia(
                            _frecuenciaLegible(l, h.frecuencia),
                            f.completados,
                            f.meta,
                          ),
                          semanal: f.esSemanal,
                        ),
                        const SizedBox(width: 8),
                        IndicadorNivel(
                          nivel: f.ritmoNivel,
                          tamano: 11,
                          etiquetaSemantica: l.a11yRitmoHabito(
                            palabraRitmo(l, f.ritmoNivel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _miniHeatmap(f, t),
                        const SizedBox(width: 8),
                        // "Ver detalle" en voz baja: el texto en `textMuted`
                        // y sólo el chevron en `primary`.
                        Expanded(
                          child: Text(
                            l.verDetalle,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: t.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        // Sólo empuja la primera tarjeta, y sólo hasta que se
                        // entra en un detalle por primera vez.
                        ValueListenableBuilder<bool>(
                          valueListenable: detalleDescubiertoNotifier,
                          builder: (context, descubierto, child) =>
                              ChevronDetalle(
                                color: t.primaryTrazo,
                                empujar: primera && !descubierto,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // En un día que no se puede tocar (futuro o de una semana
              // anterior) el check va apagado y sin toque.
              AnimatedOpacity(
                duration:
                    (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                opacity: habilitado ? 1.0 : 0.25,
                child: CheckCircular(
                  key:
                      (primera || anclaPista) &&
                          RecorridoOnboarding.instancia.activo
                      ? AnclasRecorrido.checkHabito
                      : null,
                  hecho: checkMarcado,
                  onTap:
                      checkTocable(
                        habilitado: habilitado,
                        checkMarcado: checkMarcado,
                        pistaActiva: RecorridoOnboarding.instancia.activo,
                      )
                      ? () => _completar(h.habitoId)
                      : null,
                  onDeshacer: habilitado && f.completadoEnFecha
                      ? () => _deshacer(h.habitoId)
                      : null,
                  // El hábito hecho se pinta con `success`, no con
                  // `primary`: `primary` es lo que se puede tocar y esto es
                  // lo que ya está.
                  color: t.success,
                  etiquetaSemantica: l.a11yCompletarHabito(h.nombre),
                  etiquetaSemanticaDeshacer: l.a11yDeshacerHabito(h.nombre),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Los siete días de la semana que se mira, con lo hecho en cada uno.
  Widget _miniHeatmap(FilaHoy f, TokensContextuales t) {
    final id = identidad(context);
    final l = AppLocalizations.of(context)!;
    final hoyLeido = _hoy!;
    final fechas = f.fechasCompletadas;
    final hoy = DateTime.parse(hoyLeido.hoy);
    final bool esSemanal = f.esSemanal;
    final int meta = f.meta;
    final List<int> planificados = f.habito.diasPlanificados;
    final bool conPlan = esSemanal && planificados.isNotEmpty;

    // La ventana es la semana que se mira, la misma que pinta la tira de
    // arriba: así las siete casillas caen bajo los mismos días.
    final lunesVentana = lunesDeLaSemanaDe(DateTime.parse(hoyLeido.fecha));
    final diasVentana = List.generate(
      7,
      (i) =>
          DateTime(lunesVentana.year, lunesVentana.month, lunesVentana.day + i),
    );

    final fechasVentana = diasVentana
        .where((d) => fechas.contains(_iso(d)))
        .length;
    // En un semanal, la semana que ya llegó al objetivo pinta sus días
    // vacíos en verde tenue: "no pasa nada".
    final bool semanaCumplida = esSemanal && fechasVentana >= meta;

    return Semantics(
      label: l.a11yResumenHeatmap(fechasVentana),
      child: ExcludeSemantics(
        child: Padding(
          // Aire entre el mini-mapa y el check: la fila no llega al borde
          padding: const EdgeInsets.only(right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(7, (i) {
              final d = diasVentana[i];
              final bool lleno = fechas.contains(_iso(d));
              final bool esHoy = _iso(d) == hoyLeido.hoy;
              // Un día que todavía no ha llegado no puede pintarse como uno
              // fallado: lleva el mismo punto que el día de descanso.
              final bool esFuturo = d.isAfter(hoy) && !lleno;
              final bool esDescanso =
                  esFuturo ||
                  (conPlan && !lleno && !planificados.contains(d.weekday));

              final Widget celda;
              if (esDescanso) {
                celda = Container(
                  decoration: celdaHeatmap(
                    id,
                    t,
                    color: Colors.transparent,
                    llena: false,
                    esHoy: esHoy,
                  ),
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.38,
                      heightFactor: 0.38,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.inactivo,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                final Color color;
                if (lleno) {
                  color = t.success;
                } else if (semanaCumplida) {
                  color = t.success.withValues(alpha: 0.18);
                } else {
                  color = Colors.transparent;
                }
                celda = Container(
                  decoration: celdaHeatmap(
                    id,
                    t,
                    color: color,
                    llena: lleno,
                    esHoy: esHoy,
                    vacia: !lleno && !semanaCumplida,
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                child: SizedBox(width: 16, height: 16, child: celda),
              );
            }),
          ),
        ),
      ),
    );
  }
}
