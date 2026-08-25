import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import '../services/analytics_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habito.dart';
import '../widgets/estados_hoy.dart';
import '../widgets/identidad_ui.dart';
import '../widgets/tira_semana.dart';
import 'habito_detalle_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  /// Si la última carga falló. Antes esto sólo era un SnackBar que se iba solo
  /// y una lista vacía detrás, que se lee igual que "no tienes hábitos": el
  /// usuario no podía distinguir un fallo de red de una cuenta recién creada.
  bool _errorCarga = false;

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
  }

  Future<void> _cargarDatos() async {
    final usuario = await ApiServiceCore.getUsuarioLocal();
    if (usuario == null || !mounted) return;
    setState(() {
      _usuarioId = usuario['usuarioId'] ?? 0;
    });
    // En paralelo: el estado de reseña no depende de los hábitos, y la
    // semana es un complemento de navegación, no una dependencia de Hoy.
    await Future.wait([
      _cargarHabitos(),
      _cargarEstadoResena(),
      _cargarSemana(),
    ]);
  }

  /// La semana completa (lunes→domingo) para la tira de navegación y la fila
  /// de flexibles. Es un complemento de Hoy, no su fuente: si falla, Hoy
  /// sigue funcionando igual con los datos de [_cargarHabitos] — sólo no se
  /// pinta la tira (`_dias` se queda vacía). Por eso no hay SnackBar propio:
  /// uno ya lo pone [_cargarHabitos] si el fallo es de red en general.
  Future<void> _cargarSemana() async {
    try {
      final data = await ApiServiceHabitos.getSemana(_usuarioId);

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

      final hoyIso = DateTime.now().toIso8601String().split('T')[0];
      final indiceHoy = dias.indexWhere((d) => d['fecha'] == hoyIso);

      if (!mounted) return;
      setState(() {
        _dias = dias;
        _flexibles = flexibles;
        _indiceHoy = indiceHoy >= 0 ? indiceHoy : 0;
        _diaSeleccionado = _indiceHoy;
      });
    } catch (_) {
      // Ver comentario del método: Hoy no depende de esto.
    }
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

  Future<void> _completar(int habitoId) async {
    List<String> logrosOtorgados;
    int puntosGanados;
    int? registroId;
    bool mostrarValoracion;
    final habitoActual = _habitos.firstWhere((h) => h.habitoId == habitoId);
    if (habitoActual.frecuencia == 'SEMANAL' &&
        _progreso[habitoId]?['completadoHoy'] == true) {
      return; // ya está hecho hoy: no se puede volver a completar
    }
    try {
      final resultado = await ApiServiceHabitos.completarHabito(habitoId);
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

    // Actualización local inmediata (sin esperar al servidor)
    final p = _progreso[habitoId];
    if (p != null) {
      p['completadoHoy'] = true;
      p['completadosPeriodo'] = (p['completadosPeriodo'] ?? 0) + 1;
    }
    _fechasCompletadas[habitoId]?.add(DateTime.now().toIso8601String().split('T')[0]);
    setState(() {}); // el cambio de progreso dispara la animación del check

    // Sincronización real en segundo plano (por si el conteo local se desviara)
    ApiServiceHabitos.getProgresoHoy(habitoId).then((prog) {
      if (mounted) setState(() { _progreso[habitoId] = prog; });
    }).catchError((_) {});

    await Future.delayed(const Duration(milliseconds: 400));

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

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = AppLocalizations.of(context)!;

    // _habitos ya viene filtrado por el backend (sólo lo que toca hoy), así
    // que ya no hace falta apartar aquí lo que no toca: todo lo que llega
    // cuenta para el resumen del día.
    final pendientes = <Habito>[];
    final completados = <Habito>[];
    for (final h in _habitos) {
      if (_estaHecho(h)) {
        completados.add(h);
      } else {
        pendientes.add(h);
      }
    }
    final totalHoy = _habitos.length;

    // Mientras la semana no ha cargado (o falló), la pantalla se comporta
    // exactamente como antes: sólo Hoy, sin tira ni contenido de otro día.
    final bool semanaLista = _dias.isNotEmpty;
    final bool viendoHoy = !semanaLista || _diaSeleccionado == _indiceHoy;
    final List<Map<String, dynamic>> habitosDelDiaSeleccionado =
        semanaLista ? (_dias[_diaSeleccionado]['habitos'] as List<Map<String, dynamic>>) : const [];

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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.navHoy,
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: t.text)),
                          Text(_fechaDeHoy(context),
                              style:
                                  TextStyle(fontSize: 13, color: t.textMuted)),
                          if (totalHoy > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              _fraseProgreso(l, completados.length, totalHoy),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  // Va como texto, no como relleno: el verde
                                  // del tema claro no contrasta ahí.
                                  color: completados.length == totalHoy
                                      ? t.successText
                                      : t.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (totalHoy > 0)
                      AnilloProgreso(
                        actual: completados.length,
                        total: totalHoy,
                        color: t.primary,
                        colorPista: t.surface2,
                        colorTexto: t.text,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (semanaLista) ...[
                  TiraSemana(
                    dias: _dias,
                    diaSeleccionado: _diaSeleccionado,
                    indiceHoy: _indiceHoy,
                    onSeleccionar: (i) => setState(() => _diaSeleccionado = i),
                  ),
                  const SizedBox(height: 16),
                ],
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
                      ...pendientes.map((h) => _habitoCard(l, h, false, t)),
                    if (completados.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(l.dashCompletados,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              letterSpacing: 1, color: t.textMuted)),
                      const SizedBox(height: 8),
                      ...completados.map((h) => _habitoCard(l, h, true, t)),
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
                      l, item['habito'] as Habito, item['completado'] as bool, t)),
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

  /// Fecha en el idioma activo. MMMMEEEEd resuelve por sí solo el orden y
  /// las preposiciones de cada idioma ("miércoles, 4 de junio" / "Wednesday,
  /// June 4"), que es justo lo que una plantilla fija no puede hacer.
  String _fechaDeHoy(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.MMMMEEEEd(locale).format(DateTime.now());
  }

  String _fraseProgreso(AppLocalizations l, int hechos, int total) {
    if (hechos == 0) return l.dashProgresoPrimero;
    if (hechos == total) return l.dashProgresoPerfecto;
    if (hechos / total >= 0.5) return l.dashProgresoCasi;
    return l.dashProgresoBuenRitmo;
  }

  Widget _habitoCard(AppLocalizations l, Habito h, bool hecho, TokensContextuales t) {
    final p = _progreso[h.habitoId] ?? {'completadosPeriodo': 0, 'meta': 1};

    return AnimatedOpacity(
      // La fila se apaga al completarse. Con "reducir movimiento" llega al
      // mismo 0.72, sin recorrido: el estado no cambia, sólo el camino.
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 400),
      opacity: hecho ? 0.72 : 1.0,
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
            padding: const EdgeInsets.all(14),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
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
                  color: t.primary,
                  colorVacio: t.surface2,
                  etiquetaSemantica: l.a11yCompletarHabito(h.nombre),
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
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: t.textMuted)),
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
                      style: TextStyle(fontWeight: FontWeight.w600, color: t.text)),
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
  /// ese día") y con el check apagado y no tocable: sólo se completa hoy.
  Widget _habitoCardOtroDia(
      AppLocalizations l, Habito h, bool completado, TokensContextuales t) {
    return AnimatedOpacity(
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 400),
      opacity: completado ? 0.72 : 1.0,
      child: TarjetaIdentidad(
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(h.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
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
              // Sólo se completa hoy: apagado y sin onTap en cualquier otro día.
              Opacity(
                opacity: 0.5,
                child: CheckCircular(
                  hecho: completado,
                  onTap: null,
                  color: t.primary,
                  colorVacio: t.surface2,
                ),
              ),
            ],
          ),
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

    // Solo los días de la ventana que se pinta: `fechas` tiene todo el
    // historial del hábito y anunciar su tamaño daría un número imposible.
    final fechasVentana = List.generate(10, (i) => hoy.subtract(Duration(days: 9 - i)))
        .where((d) => fechas.contains(iso(d)))
        .length;

    return Semantics(
      label: l.a11yResumenHeatmap(fechasVentana),
      child: ExcludeSemantics(
        child: Padding(
          // Aire entre la heatmap y el check: la fila no llega al borde
          padding: const EdgeInsets.only(right: 24),
          child: Row(
            children: List.generate(10, (i) {
              final d = hoy.subtract(Duration(days: 9 - i));
              final bool lleno = fechas.contains(iso(d));
              final bool esHoy = i == 9;
              final bool esDescanso =
                  conPlan && !lleno && !planificados.contains(d.weekday);

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
                          color: t.surface2,
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
                  color = t.surface2;
                }
                celda = Container(
                  decoration: celdaHeatmap(id, t,
                      color: color, llena: lleno, esHoy: esHoy),
                );
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 9 ? 5 : 0),
                  child: AspectRatio(aspectRatio: 1, child: celda),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}