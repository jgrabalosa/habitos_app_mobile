import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/mensajes_error.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import '../services/api_service.dart';
import '../models/habito.dart';
import '../theme/app_theme.dart';
import 'habito_detalle_screen.dart';
import '../services/analytics_service.dart';
import '../services/celebracion_service.dart';
import '../widgets/animacion_puntos.dart';
import '../services/sonido_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/valoracion_sheet.dart';
import '../widgets/check_circular.dart';
import '../widgets/anillo_progreso.dart';
import '../widgets/skeleton.dart';
import '../widgets/mini_mascota.dart';

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
    final usuario = await ApiService.getUsuarioLocal();
    if (usuario == null || !mounted) return;
    setState(() {
      _usuarioId = usuario['usuarioId'] ?? 0;
    });
    // En paralelo: el estado de reseña no depende de los hábitos
    await Future.wait([
      _cargarHabitos(),
      _cargarEstadoResena(),
    ]);
  }

  Future<void> _cargarEstadoResena() async {
    try {
      final logros = await ApiService.getLogrosUsuario(_usuarioId);
      final yaPidio = logros.any((l) => l['logro']?['codigo'] == 'INTERACCION_RESENA');
      if (mounted) setState(() { _yaPidioResena = yaPidio; });
    } catch (_) {
      // Si falla, dejamos _yaPidioResena en false (se volverá a intentar pedir)
    }
  }

  Future<void> _cargarHabitos() async {
    try {
      final dashboard = await ApiService.getDashboard(_usuarioId);

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      // Antes la lista se quedaba vacia sin decir por que.
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
      final resultado = await ApiService.completarHabito(habitoId);
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

    // Analytics en segundo plano: no bloquea la celebración
    AnalyticsService.habitoCompletado(habitoActual.frecuencia);

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
    ApiService.getProgresoHoy(habitoId).then((prog) {
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
            await ApiService.valorarRegistro(registroId, valoracion);
          }
          if (nota != null) {
            await ApiService.actualizarNotaRegistro(registroId, nota);
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
        await ApiService.registrarInteraccionResena(_usuarioId);
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

    // Reparto: diarios y semanales que tocan hoy → lista principal;
    // semanales con días planificados que NO tocan hoy → "Esta semana"
    final pendientes = <Habito>[];
    final completados = <Habito>[];
    final noTocaHoy = <Habito>[];
    final hoyDia = DateTime.now().weekday; // 1=lunes..7=domingo, como diasPlanificados
    for (final h in _habitos) {
      if (_estaHecho(h)) {
        completados.add(h);
      } else if (h.frecuencia == 'SEMANAL' &&
          h.diasPlanificados.isNotEmpty &&
          !h.diasPlanificados.contains(hoyDia)) {
        noTocaHoy.add(h);
      } else {
        pendientes.add(h);
      }
    }
    // El resumen del día solo cuenta lo que toca hoy
    final totalHoy = _habitos.length - noTocaHoy.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final areaSize = constraints.biggest;
        return Stack(
      children: [
        _loading
            ? const SkeletonLista(cantidad: 3, padding: EdgeInsets.fromLTRB(16, 16, 16, 96))
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
                                  color: completados.length == totalHoy
                                      ? t.success
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
                if (_habitos.isEmpty)
                  _emptyState(l, t)
                else ...[
                  if (pendientes.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(l.dashTodoHecho,
                                style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                            Text(l.dashDisfruta,
                                style: TextStyle(fontSize: 12, color: t.textMuted)),
                          ],
                        ),
                      ),
                    )
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
                  if (noTocaHoy.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Theme(
                      // Sin las líneas divisorias por defecto del ExpansionTile
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(l.dashEstaSemana(noTocaHoy.length),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: t.textMuted)),
                        subtitle: Text(l.dashNoTocanHoy,
                            style:
                                TextStyle(fontSize: 11, color: t.textMuted)),
                        children: noTocaHoy
                            .map((h) => _habitoCard(l, h, false, t))
                            .toList(),
                      ),
                    ),
                  ],
                ],
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

  Widget _emptyState(AppLocalizations l, TokensContextuales t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(LucideIcons.sprout, size: 48, color: t.success),
            const SizedBox(height: 12),
            Text(l.dashVacioTitulo,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: t.text)),
            const SizedBox(height: 4),
            Text(
              l.dashVacioCuerpo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _habitoCard(AppLocalizations l, Habito h, bool hecho, TokensContextuales t) {
    final p = _progreso[h.habitoId] ?? {'completadosPeriodo': 0, 'meta': 1};

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: hecho ? 0.72 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: t.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                                l.dashChipFrecuencia(
                                    _frecuenciaLegible(l, h.frecuencia),
                                    p['completadosPeriodo'] ?? 0,
                                    p['meta'] ?? 1),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: t.primary)),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _miniHeatmap(Habito h, TokensContextuales t) {
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

    return Padding(
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
            // Día de descanso: punto pequeño, visualmente menor
            celda = Container(
              decoration: esHoy
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: t.primary, width: 1.5),
                    )
                  : null,
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
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
                border:
                    esHoy ? Border.all(color: t.primary, width: 1.5) : null,
              ),
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
    );
  }
}