import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../services/analytics_service.dart';
import '../services/habitos_refresh.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habito.dart';
import '../widgets/estados_hoy.dart';
import '../widgets/identidad_ui.dart';
import '../widgets/tira_semana.dart';
import '../widgets/transito_fila.dart';
import 'habito_detalle_screen.dart';

String formatearTituloDelDia({
  required DateTime fecha,
  required String locale,
  required String textoHoy,
  required bool viendoHoy,
}) {
  if (viendoHoy) {
    return '$textoHoy, ${DateFormat.MMMMd(locale).format(fecha)}';
  }

  final largo = DateFormat.MMMMEEEEd(locale).format(fecha);
  return largo.isEmpty ? largo : largo[0].toUpperCase() + largo.substring(1);
}

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
bool esAnteriorALaSemanaEnCurso(DateTime fecha, DateTime hoy) =>
    DateTime(fecha.year, fecha.month, fecha.day)
        .isBefore(lunesDeLaSemanaDe(DateTime(hoy.year, hoy.month, hoy.day)));

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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Habito> _habitos = [];
  final Map<int, Map<String, dynamic>> _progreso = {}; // habitoId -> {completadoHoy, completadosPeriodo, meta}
  final Map<int, Set<String>> _fechasCompletadas = {}; // habitoId -> fechas ISO (mini-heatmap)
  bool _loading = true;
  int _usuarioId = 0;
  bool _yaPidioResena = false;

  /// Los 7 días de la semana (lunes→domingo), crudos del backend, para la
  /// tira de navegación. `_diaSeleccionado` e `_indiceHoy` son índices dentro
  /// de esta lista, no días de la semana ISO.
  List<Map<String, dynamic>> _dias = [];
  List<Map<String, dynamic>> _flexibles = [];
  int _diaSeleccionado = 0;
  int _indiceHoy = 0;

  /// Hoy según el servidor, en la zona del usuario. Null hasta la primera
  /// respuesta de /semana. Es la única fuente de "qué día es hoy" para esta
  /// pantalla: el reloj del dispositivo puede estar en otra zona.
  String? _hoyIso;

  /// Qué semana se está mirando: 0 es la de hoy, -1 la anterior, +1 la
  /// siguiente. Sin límite a propósito: cada semana es una sola llamada, el
  /// backend acepta cualquier lunes, y una flecha apagada sin motivo visible
  /// confunde más de lo que protege. El freno es el botón de volver a hoy.
  int _offsetSemana = 0;

  /// Si la última carga falló. Antes esto sólo era un SnackBar que se iba solo
  /// y una lista vacía detrás, que se lee igual que "no tienes hábitos": el
  /// usuario no podía distinguir un fallo de red de una cuenta recién creada.
  bool _errorCarga = false;

  /// El tránsito visual de una fila de "pendientes" a "completados" al
  /// completarse hoy, cuando quedan más pendientes detrás. `null` en reposo.
  AnimationController? _ctrlTransito;
  int? _habitoEnTransito;

  /// Caida al codigo crudo si llega una frecuencia desconocida, igual que
  /// hace Catalogos: nunca se deja al usuario sin texto.
  String _frecuenciaLegible(AppLocalizations l, String codigo) => switch (codigo) {
        'DIARIO' => l.frecDiario,
        'SEMANAL' => l.frecSemanal,
        _ => codigo,
      };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    habitosCambiadosNotifier.addListener(_alCambiarHabitos);
  }

  @override
  void dispose() {
    habitosCambiadosNotifier.removeListener(_alCambiarHabitos);
    _ctrlTransito?.dispose();
    super.dispose();
  }

  /// Mientras la carga inicial está en vuelo, `_publicarProgreso` no publica.
  ///
  /// `_cargarDatos` lanza tres cargas en paralelo y dos de ellas publican al
  /// terminar: `_cargarSemana` y `_cargarHabitos`. Es una carrera, y si gana
  /// la semana el estado que se publica es `_dias` lleno con `_habitos` aún
  /// vacío, o sea `total: 0`. Con `total` a cero la constelación no dibuja
  /// nada, las burbujas de Dulce ninguna y la ciudad apaga las ventanas;
  /// cuando llegan los hábitos se publica otra vez y el fondo entero aparece
  /// de golpe. Ese es el parpadeo.
  ///
  /// No se quitan las llamadas de dentro de cada carga porque `_irASemana` y
  /// el reintento del panel de error las llaman por su cuenta y sí deben
  /// publicar.
  bool _cargaInicialEnVuelo = false;

  /// Los hábitos han cambiado en otra pestaña. Se recarga todo, no sólo la
  /// lista de hoy: dar de alta un hábito cambia también la tira de la semana.
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
    // En paralelo: el estado de reseña no depende de los hábitos, y la
    // semana es un complemento de navegación, no una dependencia de Hoy.
    _cargaInicialEnVuelo = true;
    try {
      await Future.wait([
        _cargarHabitos(),
        _cargarEstadoResena(),
        _cargarSemana(),
      ]);
    } finally {
      // En `finally` a propósito: las tres cargas capturan sus propios
      // errores, pero si alguna dejara escapar uno, el cerrojo no puede
      // quedarse echado o la pantalla no volvería a publicar nunca.
      _cargaInicialEnVuelo = false;
      _publicarProgreso();
    }
  }

  /// La semana completa (lunes→domingo) para la tira de navegación y la fila
  /// de flexibles. Es un complemento de Hoy, no su fuente: si falla, Hoy
  /// sigue funcionando igual con los datos de [_cargarHabitos] — sólo no se
  /// pinta la tira (`_dias` se queda vacía). Por eso no hay SnackBar propio:
  /// uno ya lo pone [_cargarHabitos] si el fallo es de red en general.
  Future<void> _cargarSemana() async {
    try {
      // La primera carga no manda `desde`: el backend responde con la semana
      // de hoy en la zona del usuario y de paso declara cuál es ese hoy. A
      // partir de ahí las semanas se cuentan desde esa fecha.
      final desde = isoDeSemanaDesplazada(_hoyIso, _offsetSemana);
      final data = await ApiServiceHabitos.getSemana(_usuarioId, desde: desde);

      final List<Map<String, dynamic>> dias =
          (data['dias'] as List<dynamic>).map<Map<String, dynamic>>((dia) {
        final List<Map<String, dynamic>> habitosDia =
            (dia['habitos'] as List<dynamic>).map<Map<String, dynamic>>((item) => {
                  'habito': Habito.fromJson(item['habito']),
                  'completado': item['completado'] == true,
                }).toList();
        return {
          'fecha': dia['fecha'] as String,
          'habitos': habitosDia,
        };
      }).toList();

      final List<Map<String, dynamic>> flexibles =
          (data['flexibles'] as List<dynamic>).map<Map<String, dynamic>>((item) => {
                'habito': Habito.fromJson(item['habito']),
                'completadosSemana': item['completadosSemana'] ?? 0,
                'meta': item['meta'] ?? 1,
              }).toList();

      // Hoy lo declara el servidor. Si no viniera, se conserva el que ya
      // teníamos antes que caer al reloj del dispositivo: una fecha
      // equivocada aquí marca el día que no es.
      final hoyIso = (data['hoy'] as String?) ?? _hoyIso;
      final indiceHoy =
          hoyIso == null ? -1 : dias.indexWhere((d) => d['fecha'] == hoyIso);

      // Qué día se estaba mirando, por fecha y no por índice. Antes esto se
      // reposicionaba en hoy en cada carga, y como completar o deshacer un
      // día pasado recarga la semana, la tira saltaba sola bajo el dedo.
      // Se lee de `_dias`, la lista vieja, antes de sustituirla; en el
      // arranque está vacía y el índice es 0, de ahí la guarda de rango.
      final String? fechaSeleccionada =
          (_diaSeleccionado >= 0 && _diaSeleccionado < _dias.length)
              ? _dias[_diaSeleccionado]['fecha'] as String?
              : null;
      final int indiceConservado = fechaSeleccionada == null
          ? -1
          : dias.indexWhere((d) => d['fecha'] == fechaSeleccionada);

      if (!mounted) return;
      setState(() {
        _dias = dias;
        _flexibles = flexibles;
        _hoyIso = hoyIso;
        // -1 significa "hoy no está en esta semana", y hay que distinguirlo
        // de "hoy es el lunes". Con el 0 de antes, el lunes de otra semana se
        // comportaba como hoy.
        _indiceHoy = indiceHoy;
        // Si el día que se miraba sigue en la semana que acaba de llegar, se
        // respeta. Si no —arranque, o cambio de semana con las flechas—, hoy;
        // y si hoy tampoco está en esta semana, el lunes.
        _diaSeleccionado = indiceConservado >= 0
            ? indiceConservado
            : (indiceHoy >= 0 ? indiceHoy : 0);
      });
      _publicarProgreso();
    } catch (_) {
      // Ver comentario del método: Hoy no depende de esto.
    }
  }

  /// Cambia de semana. Recarga sólo la semana: los hábitos de hoy no dependen
  /// de qué semana se esté mirando.
  Future<void> _irASemana(int offset) async {
    setState(() => _offsetSemana = offset);
    await _cargarSemana();
  }

  Future<void> _cargarEstadoResena() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final yaPidio = prefs.getBool('resena_solicitada') ?? false;
      if (mounted) setState(() { _yaPidioResena = yaPidio; });
    } catch (_) {
      // Si falla, dejamos _yaPidioResena en false (se volverá a intentar pedir)
    }
  }

  Future<void> _cargarHabitos() async {
    try {
      final dashboard = await ApiServiceHabitos.getDashboard(_usuarioId);

      final habitos = <Habito>[];
      for (var item in dashboard) {
        final habito = Habito.fromJson(item['habito']);
        habitos.add(habito);

        _progreso[habito.habitoId] = {
          'completadoHoy': item['completadoHoy'],
          'completadosPeriodo': item['completadosPeriodo'],
          'meta': habito.meta,
        };

        final List<dynamic> fechas = item['fechasCompletadas'] ?? [];
        _fechasCompletadas[habito.habitoId] = fechas.cast<String>().toSet();
      }

      if (!mounted) return;
      setState(() {
        _habitos = habitos;
        _loading = false;
        _errorCarga = false;
      });
      _publicarProgreso();
    } catch (e) {
      if (!mounted) return;
      // El aviso efímero se queda: dice QUÉ ha fallado. Lo que añade el estado
      // es que la pantalla siga diciéndolo cuando el SnackBar se haya ido.
      // Sólo se pinta si no hay nada que enseñar: con datos de una carga
      // anterior, mejor los datos viejos que un panel de error.
      setState(() {
        _loading = false;
        _errorCarga = _habitos.isEmpty;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: AppLocalizations.of(context)!.dashSinConexion)),
        ),
      );
    }
  }

  bool _estaHecho(Habito h) {
    final p = _progreso[h.habitoId];
    if (p == null) return false;
    // Semanal: si ya se completó hoy, está hecho por hoy (el Dashboard es el resumen del día)
    if (h.frecuencia == 'SEMANAL' && p['completadoHoy'] == true) return true;
    return (p['completadosPeriodo'] ?? 0) >= (p['meta'] ?? 1);
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

    // Mismo camino que ya usa este fichero para llegar a la identidad
    // equipada (ver _miniHeatmap).
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

  Future<void> _completar(int habitoId, {DateTime? fecha}) async {
    List<String> logrosOtorgados;
    int puntosGanados;
    int? registroId;
    bool mostrarValoracion;
    final habitoActual = _habitos.firstWhere((h) => h.habitoId == habitoId);
    // Sin fecha explícita se completa "hoy", y quien decide cuál es hoy es
    // el servidor: se manda `fecha: null` y lo resuelve él en la zona del
    // usuario. Con fecha explícita se compara contra el hoy declarado.
    final hoyIso = _hoyIso;
    final fechaIso = fecha?.toIso8601String().split('T')[0];
    final esHoy = fechaIso == null || fechaIso == hoyIso;
    if (esHoy && habitoActual.frecuencia == 'SEMANAL' &&
        _progreso[habitoId]?['completadoHoy'] == true) {
      return; // ya está hecho hoy: no se puede volver a completar
    }
    try {
      final resultado = await ApiServiceHabitos.completarHabito(
          habitoId, fecha: esHoy ? null : fechaIso);
      logrosOtorgados = resultado['logros'];
      puntosGanados = resultado['puntosGanados'];
      registroId = resultado['registroId'];
      mostrarValoracion = resultado['mostrarValoracion'] ?? false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(MensajesError.de(context, e,
                generico: AppLocalizations.of(context)!.dashSinConexion)),
          ),
        );
      }
      return;
    }

    // Completar cambia el ánimo de la mascota en el servidor: hay que avisar a
    // quien la esté pintando (la mini-mascota flotante no se entera sola).
    solicitarRefrescoMascota();

    // Analytics en segundo plano: no bloquea la celebración
    AnalyticsHabitos.habitoCompletado(habitoActual.frecuencia);

    // Feedback háptico + sonido
    HapticFeedback.mediumImpact();
    SonidoService.reproducir('completar');

    if (!esHoy) {
      // El estado local de hoy no representa la fecha retroactiva. Recargamos
      // la semana para que el check del día objetivo y sus contadores sean los
      // que manda el servidor.
      await _cargarSemana();
    }

    // Actualización local inmediata (sin esperar al servidor), solo para hoy.
    final p = _progreso[habitoId];
    if (esHoy && p != null) {
      p['completadoHoy'] = true;
      p['completadosPeriodo'] = (p['completadosPeriodo'] ?? 0) + 1;
    }
    if (esHoy && hoyIso != null) _fechasCompletadas[habitoId]?.add(hoyIso);
    setState(() {}); // el cambio de progreso dispara la animación del check

    // El tránsito de la fila a "completados" sólo tiene sentido si se ve hoy
    // y si queda al menos otra pendiente detrás: si esta era la última, ese
    // caso lo trata otra tarea y aquí se comporta exactamente como hoy.
    final quedanPendientes =
        _habitos.any((h) => h.habitoId != habitoId && !_estaHecho(h));
    final Duration duracionTransito = esHoy && quedanPendientes
        ? _arrancarTransito(habitoId)
        : Duration.zero;

    _publicarProgreso();

    // Sincronización real en segundo plano (por si el conteo local se desviara)
    ApiServiceHabitos.getProgresoHoy(habitoId).then((prog) {
      if (mounted) {
        setState(() { _progreso[habitoId] = prog; });
        // El servidor puede corregir el conteo optimista, y si esa corrección
        // cruza la meta el hábito pasa a contar como hecho. Sin esto la
        // estrella no se encendería hasta el siguiente refresco.
        _publicarProgreso();
      }
    // Silencio a propósito: el servidor ya aceptó el completado y esto sólo
    // corrige el conteo optimista. Si falla, se queda el local hasta el
    // siguiente refresco; avisar de un error aquí confundiría.
    }).catchError((_) {});

    // Si arrancó el tránsito de la fila (hundimiento + traslado), la
    // celebración espera a que termine: con la pausa fija de 400 ms de antes
    // entraría a mitad del gesto. Sin tránsito (última pendiente, "reducir
    // movimiento", o un completado que no es de hoy) se conserva esa pausa.
    await Future.delayed(duracionTransito > Duration.zero
        ? duracionTransito
        : const Duration(milliseconds: 400));

    // Secuencia: logro (si hay) → puntos → valoración (si toca)
    if (logrosOtorgados.isNotEmpty) {
      await CelebracionService.mostrar(logrosOtorgados);
    }
    if (puntosGanados > 0 && mounted) {
      AnimacionPuntos.mostrar(context, puntosGanados);
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

    if (!_yaPidioResena) {
      _solicitarResena();
    }
  }

  /// Deshace el último completado de hoy.
  ///
  /// El `registroId` no viaja en el dashboard —`DashboardHabitoDTO` no lo
  /// lleva— así que se pide en el momento. Es una acción rara, y así no hay un
  /// id guardado que se quede rancio si el hábito se completó desde otro sitio.
  Future<void> _deshacer(int habitoId) async {
    final l = AppLocalizations.of(context)!;
    // Hoy lo declara el servidor, no el dispositivo: `_fechasCompletadas`
    // guarda fechas del servidor, y buscar en ese conjunto con la fecha
    // local falla sin dar error cuando las zonas no coinciden. Es null sólo
    // antes de la primera respuesta de /semana; en ese caso no se toca el
    // conjunto y el resto del método funciona igual.
    final hoy = _hoyIso;

    // Estado previo, para poder volver si el servidor dice que no.
    final p = _progreso[habitoId];
    final int completadosAntes = p?['completadosPeriodo'] ?? 0;
    final bool completadoHoyAntes = p?['completadoHoy'] == true;
    final bool teniaFechaHoy =
        hoy != null && (_fechasCompletadas[habitoId]?.contains(hoy) ?? false);

    // Apagado local inmediato: el usuario ha tocado un check marcado y lo que
    // espera es verlo apagarse, no esperar a la red.
    if (p != null) {
      p['completadoHoy'] = false;
      p['completadosPeriodo'] = completadosAntes > 0 ? completadosAntes - 1 : 0;
    }
    if (hoy != null) _fechasCompletadas[habitoId]?.remove(hoy);
    setState(() {});
    _publicarProgreso();
    HapticFeedback.selectionClick();

    try {
      final registros = await ApiServiceHabitos.getRegistrosHabito(habitoId);
      int? ultimo;
      for (final r in registros) {
        final int id = r['registroId'];
        if (ultimo == null || id > ultimo) ultimo = id;
      }
      if (ultimo == null) {
        throw Exception('El hábito no tiene registros que deshacer');
      }
      await ApiServiceHabitos.deshacerRegistro(ultimo);
    } catch (e) {
      // El completado sigue vivo en el servidor: se restaura lo local.
      if (p != null) {
        p['completadoHoy'] = completadoHoyAntes;
        p['completadosPeriodo'] = completadosAntes;
      }
      if (teniaFechaHoy) _fechasCompletadas[habitoId]?.add(hoy);
      if (!mounted) return;
      setState(() {});
      _publicarProgreso();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              MensajesError.de(context, e, generico: l.dashDeshacerError)),
        ),
      );
      return;
    }

    // Deshacer devuelve experiencia a la mascota y rehace la racha: quien la
    // esté pintando no se entera solo.
    solicitarRefrescoMascota();

    // Y el servidor manda sobre el conteo optimista, igual que al completar.
    ApiServiceHabitos.getProgresoHoy(habitoId).then((prog) {
      if (mounted) {
        setState(() { _progreso[habitoId] = prog; });
        _publicarProgreso();
      }
    // Mismo silencio que al completar: el deshacer ya está hecho en el
    // servidor y esto sólo corrige el conteo.
    }).catchError((_) {});
  }

  /// Deshace un registro de un día que no es hoy. No hacemos optimismo sobre
  /// los mapas de hoy: el servidor debe validar que el registro sea el último
  /// y, tras el rollback, la semana se vuelve a cargar completa.
  Future<void> _deshacerFecha(int habitoId, DateTime fecha) async {
    final l = AppLocalizations.of(context)!;
    final fechaIso = fecha.toIso8601String().split('T')[0];
    try {
      final registros = await ApiServiceHabitos.getRegistrosHabito(habitoId);
      final candidatos = registros.cast<Map<String, dynamic>>()
          .where((r) => r['fecha'] == fechaIso)
          .toList();
      final registro = candidatos.isEmpty
          ? <String, dynamic>{}
          : candidatos.reduce((a, b) =>
              (a['registroId'] as int) > (b['registroId'] as int) ? a : b);
      final registroId = registro['registroId'];
      if (registroId is! int) {
        throw Exception('No hay un registro en esa fecha');
      }
      await ApiServiceHabitos.deshacerRegistro(registroId);
      solicitarRefrescoMascota();
      await Future.wait([_cargarSemana(), _cargarHabitos()]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            MensajesError.de(context, e, generico: l.dashDeshacerError))),
      );
    }
  }

  Future<void> _solicitarResena() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('resena_solicitada', true);
        if (mounted) {
          setState(() { _yaPidioResena = true; });
        }
      }
    } catch (e) {
      // Si falla, no bloqueamos nada
    }
  }

  /// Publica en el core cuántos hábitos hay y cuántos están hechos en el día
  /// que la pantalla está mostrando, para que el fondo de la identidad pueda
  /// dibujar con ello.
  ///
  /// Se llama desde los puntos donde el dato cambia de verdad —las cargas, el
  /// completar y el cambio de día en la tira— y NUNCA desde `build`: notificar
  /// a un `ValueNotifier` durante un `build` es excepción o frame perdido.
  ///
  /// Hay dos caminos a propósito, y no son intercambiables. Para hoy la verdad
  /// está en `_habitos` + `_estaHecho`, que conoce metas y periodos. Para
  /// cualquier otro día de la tira la verdad es la clave `'completado'` de
  /// `_dias`, que viene resuelta del backend: `_progreso` y
  /// `_fechasCompletadas` son de hoy y no valen para otro día.
  void _publicarProgreso() {
    // Ver `_cargaInicialEnVuelo`: durante la carga inicial se publica una
    // sola vez, al final, en vez de una por cada carga que acabe.
    if (_cargaInicialEnVuelo) return;

    // Sin semana cargada la pantalla sólo enseña hoy, y no hay ninguna fecha
    // de la tira que consultar: la de hoy la pone el reloj.
    if (_dias.isEmpty) {
      publicarProgresoDia(
        hechos: _habitos.where(_estaHecho).length,
        total: _habitos.length,
        fecha: DateTime.now(),
      );
      return;
    }

    final dia = _dias[_diaSeleccionado];
    final fecha = DateTime.parse(dia['fecha'] as String);

    if (_diaSeleccionado == _indiceHoy) {
      publicarProgresoDia(
        hechos: _habitos.where(_estaHecho).length,
        total: _habitos.length,
        fecha: fecha,
      );
      return;
    }

    final habitosDia = dia['habitos'] as List<Map<String, dynamic>>;
    publicarProgresoDia(
      hechos: habitosDia.where((h) => h['completado'] == true).length,
      total: habitosDia.length,
      fecha: fecha,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;

    // _habitos ya viene filtrado por el backend (sólo lo que toca hoy), así
    // que ya no hace falta apartar aquí lo que no toca: todo lo que llega
    // cuenta para el resumen del día.
    // El hábito en tránsito (ver _arrancarTransito) se queda en su posición
    // exacta de "pendientes" aunque _estaHecho ya diga true, y aparece
    // ADEMÁS al final de "completados": las dos apariciones conviven
    // mientras dura el gesto, una encogiéndose y otra creciendo. Ninguna de
    // las dos listas se reordena para conseguirlo.
    final pendientes = <Habito>[];
    final completados = <Habito>[];
    for (final h in _habitos) {
      if (_estaHecho(h) && h.habitoId != _habitoEnTransito) {
        completados.add(h);
      } else {
        pendientes.add(h);
      }
    }
    if (_habitoEnTransito != null) {
      final indiceEnTransito =
          _habitos.indexWhere((h) => h.habitoId == _habitoEnTransito);
      if (indiceEnTransito != -1) completados.add(_habitos[indiceEnTransito]);
    }
    final totalHoy = _habitos.length;

    // Mientras la semana no ha cargado (o falló), la pantalla se comporta
    // exactamente como antes: sólo Hoy, sin tira ni contenido de otro día.
    final bool semanaLista = _dias.isNotEmpty;
    final bool viendoHoy = !semanaLista || _diaSeleccionado == _indiceHoy;
    final List<Map<String, dynamic>> habitosDelDiaSeleccionado =
        semanaLista ? (_dias[_diaSeleccionado]['habitos'] as List<Map<String, dynamic>>) : const [];

    // Hoy lo declara el servidor. Mientras la semana no ha cargado no se
    // pinta ni la tira ni ninguna tarjeta de otro día, así que el valor de
    // respaldo no llega a decidir nada visible.
    final DateTime hoySinHora = () {
      final iso = _hoyIso;
      if (iso != null) return DateTime.parse(iso);
      final ahora = DateTime.now();
      return DateTime(ahora.year, ahora.month, ahora.day);
    }();
    final DateTime fechaSeleccionadaSinHora = () {
      final fecha = _fechaSeleccionada();
      return DateTime(fecha.year, fecha.month, fecha.day);
    }();
    // Futuro es estrictamente posterior a hoy: hoy mismo no es futuro. Ambas
    // fechas normalizadas a medianoche para que la hora del reloj no decida.
    final bool esFuturo = fechaSeleccionadaSinHora.isAfter(hoySinHora);
    // No se compara contra `_offsetSemana`: si la app se queda abierta
    // cruzando la medianoche del domingo, el offset sigue valiendo 0 y ya
    // apunta a la semana pasada. Se compara contra la fecha real.
    final bool fueraDeSemana =
        esAnteriorALaSemanaEnCurso(fechaSeleccionadaSinHora, hoySinHora);

    return LayoutBuilder(
      builder: (context, constraints) {
        final areaSize = constraints.biggest;
        return Stack(
      children: [
        _loading
            ? const SkeletonHoy()
            : RefreshIndicator(
            onRefresh: _cargarHabitos,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, 96 + MediaQuery.of(context).padding.bottom),
              children: [
                // La tira va la primera, pegada al borde: es lo que más se
                // toca y ahora no hay barra superior que la empuje hacia
                // abajo. Debajo queda la franja de contexto —fecha, frase y
                // anillo— como una sola banda.
                //
                // Las flechas siguen en la franja y no en la tira: la tira es
                // un Row de siete Expanded sin holgura.
                if (semanaLista) ...[
                  TiraSemana(
                    dias: _dias,
                    diaSeleccionado: _diaSeleccionado,
                    indiceHoy: _indiceHoy,
                    onSeleccionar: (i) {
                      setState(() => _diaSeleccionado = i);
                      // Fuera del setState pero dentro del callback: esto lo
                      // dispara un gesto del usuario, no un build, así que
                      // notificar aquí es seguro.
                      _publicarProgreso();
                    },
                  ),
                  const SizedBox(height: 13),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // La fila de navegación del día: flechas, fecha, y
                          // el botón de volver a esta semana cuando te has
                          // ido. Va debajo de la tira, no encima, porque la
                          // tira es lo que gobierna.
                          Row(
                            children: [
                              // Las flechas van aquí y no en la tira porque la
                              // tira es un Row de siete Expanded sin holgura, y
                              // deslizar tampoco vale: el PageView del shell ya
                              // se queda el arrastre horizontal para cambiar de
                              // pestaña.
                              IconButton(
                                icon: const Icon(LucideIcons.chevronLeft),
                                iconSize: 20,
                                visualDensity: VisualDensity.compact,
                                color: t.textMuted,
                                onPressed: () => _irASemana(_offsetSemana - 1),
                              ),
                              // Una línea siempre. `headlineMedium` partía
                              // «Hoy, 15 de septiembre» en dos y dejaba las
                              // flechas descolgadas respecto a la primera
                              // mitad. `titleLarge` cabe en español, y el
                              // FittedBox cubre lo que no puedo saber desde
                              // aquí: los meses largos en pt y en, y el
                              // escalado de fuente del sistema. Encoge sólo
                              // cuando hace falta; si cabe, no toca nada.
                              //
                              // No se acorta el formato de la fecha: lo fijan
                              // dos tests que comparan cadenas exactas en los
                              // tres idiomas, y ese cambio va aparte.
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _tituloDelDia(context, l, viendoHoy),
                                    maxLines: 1,
                                    softWrap: false,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: t.text),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.chevronRight),
                                iconSize: 20,
                                visualDensity: VisualDensity.compact,
                                color: t.textMuted,
                                onPressed: () => _irASemana(_offsetSemana + 1),
                              ),
                              // Sólo aparece cuando te has ido de esta semana:
                              // con dos flechas es fácil perderse tres semanas
                              // atrás, y volver no debe costar tres toques.
                              if (_offsetSemana != 0)
                                TextButton(
                                  onPressed: () => _irASemana(0),
                                  child: Text(l.navHoy),
                                ),
                            ],
                          ),
                          if (viendoHoy && totalHoy > 0) ...[
                            const SizedBox(height: 4),
                            // La frase va en la superficie de la identidad, no
                            // suelta: cristal en Profundidad, panel cortado en
                            // Neotokyo+, post-it en Dulce, itálica desnuda en
                            // Alba. El color sólo se fuerza al completar el
                            // día, que es la única señal cromática de que ya
                            // está todo hecho; el resto del tiempo pinta cada
                            // forma el suyo.
                            BurbujaContexto(
                              texto: _fraseProgreso(
                                  l, completados.length, totalHoy),
                              color: completados.length == totalHoy
                                  ? t.successText
                                  : null,
                            ),
                          ] else if (!viendoHoy &&
                              habitosDelDiaSeleccionado.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            BurbujaContexto(
                              texto: _fraseProgreso(
                                  l,
                                  habitosDelDiaSeleccionado
                                      .where((h) => h['completado'] == true)
                                      .length,
                                  habitosDelDiaSeleccionado.length),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 64 en vez del tamaño por defecto: a su tamaño anterior
                    // competía con la fecha y la empujaba contra el borde.
                    // Sigue siendo el objeto redondo en un bloque de
                    // rectángulos, que es lo que hace que se vea.
                    if (totalHoy > 0)
                      AnilloProgreso(
                        actual: completados.length,
                        total: totalHoy,
                        tamano: 64,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (semanaLista && _flexibles.isNotEmpty) ...[
                  _filaFlexibles(l, t),
                  const SizedBox(height: 16),
                ],
                if (_errorCarga)
                  EstadoErrorHoy(onReintentar: _cargarHabitos)
                else if (viendoHoy) ...[
                  if (_habitos.isEmpty)
                    const EstadoVacioHoy()
                  else ...[
                    if (pendientes.isEmpty)
                      const TarjetaTodoHecho()
                    else
                      ...pendientes.map((h) => _filaEnLista(l, h, false, t)),
                    if (completados.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(l.dashCompletados,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: t.textMuted)),
                      const SizedBox(height: 8),
                      ...completados.map((h) => _filaEnLista(l, h, true, t)),
                    ],
                  ],
                ] else if (habitosDelDiaSeleccionado.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l.dashDiaSinHabitos,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.textMuted)),
                  )
                else
                  ...habitosDelDiaSeleccionado.map((item) => _habitoCardOtroDia(
                      l, item['habito'] as Habito, item['completado'] as bool, t,
                      fecha: _fechaSeleccionada(), esFuturo: esFuturo,
                      fueraDeSemana: fueraDeSemana)),
              ],
            ),
          ),
        if (!_loading && _usuarioId != 0)
          MiniMascota(usuarioId: _usuarioId, areaSize: areaSize),
      ],
    );
      },
    );
  }

  /// El título de la cabecera: el día que se está mirando, no siempre hoy.
  ///
  /// En hoy pone «Hoy, 30 de agosto» y no «Hoy, domingo, 30 de agosto»: en
  /// español `MMMMEEEEd` ya trae su propia coma y el día de la semana sobra
  /// cuando decimos «Hoy». En cualquier otro día va el formato largo con la
  /// inicial en mayúscula, porque `DateFormat` la devuelve en minúscula y
  /// aquí es un título.
  String _tituloDelDia(BuildContext context, AppLocalizations l, bool viendoHoy) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return formatearTituloDelDia(
      fecha: _fechaSeleccionada(),
      locale: locale,
      textoHoy: l.navHoy,
      viendoHoy: viendoHoy,
    );
  }

  /// La fecha del día seleccionado en la tira. Sin semana cargada, hoy: es
  /// el mismo criterio que usa `_publicarProgreso`.
  DateTime _fechaSeleccionada() {
    if (_dias.isEmpty) return DateTime.now();
    return DateTime.parse(_dias[_diaSeleccionado]['fecha'] as String);
  }

  String _fraseProgreso(AppLocalizations l, int hechos, int total) {
    if (hechos == 0) return l.dashProgresoPrimero;
    if (hechos == total) return l.dashProgresoPerfecto;
    if (hechos / total >= 0.5) return l.dashProgresoCasi;
    return l.dashProgresoBuenRitmo;
  }

  /// Una fila de la lista de Hoy: la del hábito en tránsito (ver
  /// `_arrancarTransito`) se pinta dentro de un `RanuraTransito` animado por
  /// `_ctrlTransito`, una vez como origen (en pendientes) y otra como
  /// destino (en completados); las demás se pintan tal cual, sin envolver.
  Widget _filaEnLista(AppLocalizations l, Habito h, bool hecho, TokensContextuales t) {
    final ctrl = _ctrlTransito;
    if (ctrl == null || h.habitoId != _habitoEnTransito) {
      return _habitoCard(l, h, hecho, t);
    }

    final id = identidad(context);
    // Las dos ranuras pintan la MISMA fila ya completada —una yéndose, otra
    // llegando—: `hecho` aquí sólo elige el papel (destino/origen), no el
    // aspecto de la tarjeta, que siempre es el de "hecho".
    return AnimatedBuilder(
      animation: ctrl,
      child: _habitoCard(l, h, true, t),
      builder: (context, child) => RanuraTransito(
        progreso: ctrl.value,
        papel: hecho ? PapelTransito.destino : PapelTransito.origen,
        curva: id.curvaTransicion,
        child: child!,
      ),
    );
  }

  Widget _habitoCard(AppLocalizations l, Habito h, bool hecho, TokensContextuales t) {
    final p = _progreso[h.habitoId] ?? {'completadosPeriodo': 0, 'meta': 1};

    return AnimatedOpacity(
      // La fila se apaga al completarse. Con "reducir movimiento" llega al
      // mismo 0.72, sin recorrido: el estado no cambia, sólo el camino.
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 400),
      // 0.80: la fila hecha se apaga sin dejar de leerse. El fondo de
      // referencia ya no es el relleno de la tarjeta —en Profundidad la fila
      // va sobre el cielo y SuperficieIdentidad no pinta superficie en las
      // secundarias de glass— así que las dos opacidades ya no se
      // multiplican. Sobre `bg` (#070D19), `textMuted` al 0.80 da 8.11 y
      // `text` 11.10. En las otras tres identidades sigue habiendo tarjeta
      // opaca, y ahí el 0.80 atenúa la fila entera, tarjeta incluida.
      opacity: hecho ? 0.80 : 1.0,
      // El radio, el corte y la sombra los pone la identidad equipada; aquí
      // sólo se dice que esto es una tarjeta de fila.
      child: TarjetaIdentidad(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HabitoDetalleScreen(
                    habitoId: h.habitoId,
                    usuarioId: _usuarioId,
                    nombre: h.nombre),
              ),
            );
            _cargarHabitos();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
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
                                child: Text(h.nombre,
                                    // Dos líneas antes de cortar: los nombres
                                    // reales son frases ("Escribir en el
                                    // diario de gratitud"), y en una sola
                                    // línea el chip les comía media frase.
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      decoration: hecho
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: hecho ? t.textMuted : t.text,
                                    )),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChipIdentidad(
                            texto: l.dashChipFrecuencia(
                                _frecuenciaLegible(l, h.frecuencia),
                                p['completadosPeriodo'] ?? 0,
                                p['meta'] ?? 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _miniHeatmap(h, t),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CheckCircular(
                  hecho: hecho,
                  onTap: () => _completar(h.habitoId),
                  onDeshacer: () => _deshacer(h.habitoId),
                  // El hábito hecho se pinta con `success`, no con `primary`:
                  // `primary` es lo que se puede tocar y esto es lo que ya
                  // está. En tres identidades son el mismo color y no cambia
                  // nada; en Dulce, `success` es la salvia.
                  color: t.success,
                  etiquetaSemantica: l.a11yCompletarHabito(h.nombre),
                  etiquetaSemanticaDeshacer: l.a11yDeshacerHabito(h.nombre),
                ),
              ],
            ),
          ),
      ),
    );
  }

  /// Fila corta con el progreso semanal de cada SEMANAL flexible: no tienen
  /// un día fijo que los represente en la tira, así que van aparte y
  /// siempre visibles, sea cual sea el día seleccionado arriba.
  Widget _filaFlexibles(AppLocalizations l, TokensContextuales t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.dashFlexiblesTitulo,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: t.textMuted)),
        const SizedBox(height: 8),
        ..._flexibles.map((item) {
          final habito = item['habito'] as Habito;
          final completadosSemana = item['completadosSemana'] as int;
          final meta = item['meta'] as int;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(habito.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: t.text)),
                ),
                const SizedBox(width: 8),
                ChipIdentidad(
                    texto: l.dashFlexibleProgreso(completadosSemana, meta)),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Versión mínima de [_habitoCard] para un día que no es hoy: recibe el
  /// par (hábito, completado) directamente de `_dias[i]`, en vez de leer de
  /// `_progreso`/`_fechasCompletadas` — esos mapas son de hoy, no de
  /// cualquier día. Sin mini-heatmap (es info de racha, no de "qué tocaba
  /// ese día"). Un día de la semana en curso permite completar y deshacer;
  /// un día futuro o de una semana anterior, no.
  Widget _habitoCardOtroDia(
      AppLocalizations l, Habito h, bool completado, TokensContextuales t,
      {required DateTime fecha, required bool esFuturo,
       required bool fueraDeSemana}) {
    // La atenuación va SÓLO en el check, no en la tarjeta entera.
    //
    // Antes un `AnimatedOpacity` envolvía todo y apagaba también el texto:
    // el nombre del hábito de un día futuro quedaba a 4.13 de contraste en
    // Profundidad, 3.99 en Neotokyo+, 2.58 en Alba y 2.54 en Dulce, y su
    // chip en `textMuted` bajaba a 3.26 / 2.17 / 1.89 / 2.00. Las ocho
    // cifras fuera de AA, y estas filas SON pulsables —llevan al detalle—,
    // así que no valía la exención de contenido deshabilitado. Subir el
    // número tampoco servía: a 0.70 el `textMuted` sigue cayendo en tres de
    // las cuatro identidades.
    //
    // Que un día no sea hoy ya lo dicen el check apagado y sin `onTap`, la
    // tira de arriba, y —si está completado— la tachadura y el `textMuted`
    // del propio texto. No hacía falta apagar la información.
    return TarjetaIdentidad(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HabitoDetalleScreen(
                  habitoId: h.habitoId, usuarioId: _usuarioId, nombre: h.nombre),
            ),
          );
          _cargarSemana();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(h.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration:
                                completado ? TextDecoration.lineThrough : null,
                            color: completado ? t.textMuted : t.text,
                          )),
                    ),
                    const SizedBox(width: 8),
                    ChipIdentidad(texto: _frecuenciaLegible(l, h.frecuencia)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Sólo la semana en curso permite completar o deshacer, según
              // el estado de la fila. Un día futuro o una fecha de una
              // semana anterior van apagados y sin toque.
              // El 0.25 reproduce lo que se veía antes, cuando el 0.5 de aquí
              // se multiplicaba por el 0.45 del envoltorio.
              AnimatedOpacity(
                duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                opacity: (esFuturo || fueraDeSemana) ? 0.25 : 0.5,
                child: CheckCircular(
                  hecho: completado,
                  onTap: (!esFuturo && !fueraDeSemana && !completado)
                      ? () => _completar(h.habitoId, fecha: fecha)
                      : null,
                  onDeshacer: (!esFuturo && !fueraDeSemana && completado)
                      ? () => _deshacerFecha(h.habitoId, fecha)
                      : null,
                  color: t.success,
                ),
              ),
            ],
          ),
        ),
    );
  }

Widget _miniHeatmap(Habito h, TokensContextuales t) {
    final id = identidad(context);
    final l = AppLocalizations.of(context)!;
    final fechas = _fechasCompletadas[h.habitoId] ?? {};
    final hoy = DateTime.now();
    final bool esSemanal = h.frecuencia == 'SEMANAL';
    final int meta = _progreso[h.habitoId]?['meta'] ?? 1;
    final List<int> planificados = h.diasPlanificados;
    final bool conPlan = esSemanal && planificados.isNotEmpty;

    String iso(DateTime d) => d.toIso8601String().split('T')[0];

    // ¿La semana (L-D) a la que pertenece este día alcanzó la meta?
    bool semanaCumplida(DateTime dia) {
      final lunes = dia.subtract(Duration(days: dia.weekday - 1));
      int count = 0;
      for (int i = 0; i < 7; i++) {
        if (fechas.contains(iso(lunes.add(Duration(days: i))))) count++;
      }
      return count >= meta;
    }

    // La ventana es la semana natural, la misma que pinta TiraSemana arriba:
    // así las siete casillas caen bajo los mismos días. Antes eran los diez
    // últimos, que enseñaban lo que hubo pero no lo que queda.
    //
    // `lunesDeLaSemanaDe` y no `subtract(Duration(days:...))`: ver la nota de
    // esa función sobre los cambios de horario a medianoche.
    final lunesVentana = lunesDeLaSemanaDe(hoy);
    final diasVentana =
        List.generate(7, (i) => lunesVentana.add(Duration(days: i)));

    // Solo los días de la ventana que se pinta: `fechas` tiene todo el
    // historial del hábito y anunciar su tamaño daría un número imposible.
    final fechasVentana =
        diasVentana.where((d) => fechas.contains(iso(d))).length;

    return Semantics(
      label: l.a11yResumenHeatmap(fechasVentana),
      child: ExcludeSemantics(
        child: Padding(
          // Aire entre la heatmap y el check: la fila no llega al borde
          padding: const EdgeInsets.only(right: 24),
          child: Row(
            // Alineadas a la izquierda y con tamaño fijo, no repartiendo el
            // ancho: con `Expanded` la altura de la celda la mandaba el ancho
            // de la pantalla, y con siete celdas en vez de diez la fila habría
            // CRECIDO un 43%. El bloque ya no llega hasta el check, pero todas
            // las filas siguen alineadas entre sí porque el tamaño es el mismo.
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(7, (i) {
              final d = diasVentana[i];
              final bool lleno = fechas.contains(iso(d));
              final bool esHoy = iso(d) == iso(hoy);
              // Un día que todavía no ha llegado no puede pintarse como uno
              // fallado. Se le da el mismo tratamiento que al día de descanso
              // —punto pequeño, sin relleno—, que ya significa "aquí no se
              // espera nada de ti".
              final bool esFuturo = d.isAfter(hoy) && !lleno;
              final bool esDescanso = esFuturo ||
                  (conPlan && !lleno && !planificados.contains(d.weekday));

              final Widget celda;
              if (esDescanso) {
                // Día de descanso: punto pequeño, visualmente menor. La celda no
                // se pinta —sólo marca el hoy, si toca— y el punto es el mismo en
                // las cuatro identidades: un descanso significa lo mismo en todas.
                celda = Container(
                  decoration: celdaHeatmap(id, t,
                      color: Colors.transparent, llena: false, esHoy: esHoy),
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
                } else if (esSemanal && semanaCumplida(d)) {
                  // Día vacío de una semana ganada: verde tenue, "no pasa nada"
                  color = t.success.withValues(alpha: 0.18);
                } else {
                  color = t.inactivo;
                }
                celda = Container(
                  decoration: celdaHeatmap(id, t,
                      color: color, llena: lleno, esHoy: esHoy),
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
