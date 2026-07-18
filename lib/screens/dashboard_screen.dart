import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import '../services/api_service.dart';
import '../models/habito.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'habito_screen.dart';
import 'habito_detalle_screen.dart';
import 'logros_screen.dart';
import '../services/analytics_service.dart';
import '../services/celebracion_service.dart';
import 'perfil_screen.dart';
import '../widgets/animacion_puntos.dart';
import '../services/sonido_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/valoracion_sheet.dart';

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
  String _nombre = '';
  int _usuarioId = 0;
  int? _animandoId;
  bool _yaPidioResena = false;

  static const nombresFrecuencia = {'DIARIO': 'Diario', 'SEMANAL': 'Semanal'};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final usuario = await ApiService.getUsuarioLocal();
    if (usuario == null) return;
    setState(() {
      _nombre = usuario['nombre'] ?? '';
      _usuarioId = usuario['usuarioId'] ?? 0;
    });
    await _cargarHabitos();
    await _cargarEstadoResena();
  }

  Future<void> _cargarEstadoResena() async {
    try {
      final logros = await ApiService.getLogrosUsuario(_usuarioId);
      final yaPidio = logros.any((l) => l['logro']?['codigo'] == 'INTERACCION_RESENA');
      setState(() { _yaPidioResena = yaPidio; });
    } catch (_) {
      // Si falla, dejamos _yaPidioResena en false (se volverá a intentar pedir)
    }
  }

  Future<void> _cargarHabitos() async {
    try {
      final habitos = await ApiService.getHabitosActivos(_usuarioId);
      for (var h in habitos) {
        _progreso[h.habitoId] = await ApiService.getProgresoHoy(h.habitoId);
        try {
          final registros = await ApiService.getRegistrosHabito(h.habitoId);
          _fechasCompletadas[h.habitoId] = registros
              .where((r) => r['completado'] == true)
              .map<String>((r) => r['fecha'] as String)
              .toSet();
        } catch (_) {
          _fechasCompletadas[h.habitoId] = {};
        }
      }
      setState(() {
        _habitos = habitos;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  bool _estaHecho(Habito h) {
    final p = _progreso[h.habitoId];
    if (p == null) return false;
    return (p['completadosPeriodo'] ?? 0) >= (p['meta'] ?? 1);
  }

Future<void> _completar(int habitoId) async {
    List<String> logrosOtorgados;
    int puntosGanados;
    int? registroId;
    bool mostrarValoracion;
    try {
      final resultado = await ApiService.completarHabito(habitoId);
      logrosOtorgados = resultado['logros'];
      puntosGanados = resultado['puntosGanados'];
      registroId = resultado['registroId'];
      mostrarValoracion = resultado['mostrarValoracion'] ?? false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin conexión. Inténtalo de nuevo.')),
        );
      }
      return;
    }

    final habito = _habitos.firstWhere((h) => h.habitoId == habitoId);
    await AnalyticsService.habitoCompletado(habito.frecuencia);

    // Feedback háptico + sonido + animación
    HapticFeedback.mediumImpact();
    SonidoService.reproducir('completar');
    setState(() { _animandoId = habitoId; });

    // Refrescar datos de ese hábito
    _progreso[habitoId] = await ApiService.getProgresoHoy(habitoId);
    _fechasCompletadas[habitoId]?.add(DateTime.now().toIso8601String().split('T')[0]);

    await Future.delayed(const Duration(milliseconds: 450));
    setState(() { _animandoId = null; });

    // Secuencia: logro (si hay) → puntos → valoración (si toca)
    if (logrosOtorgados.isNotEmpty) {
      await CelebracionService.mostrar(logrosOtorgados);
    }
    if (puntosGanados > 0 && mounted) {
      AnimacionPuntos.mostrar(context, puntosGanados);
    }

    if (mostrarValoracion && registroId != null && mounted) {
      // Pequeña pausa para no pisar la animación de puntos
      await Future.delayed(const Duration(milliseconds: 600));
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
    final t = tokens(context);
    final pendientes = _habitos.where((h) => !_estaHecho(h)).toList();
    final completados = _habitos.where(_estaHecho).toList();
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, $_nombre 👋',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarHabitos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Hoy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: t.text)),
                  Text(_fechaDeHoy(), style: TextStyle(fontSize: 13, color: t.textMuted)),
                  const SizedBox(height: 16),
                  if (_habitos.isEmpty)
                    _emptyState(t)
                  else ...[
                    if (pendientes.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text('¡Todo hecho por hoy!',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                              Text('Disfruta el resto del día.',
                                  style: TextStyle(fontSize: 12, color: t.textMuted)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...pendientes.map((h) => _habitoCard(h, false, t)),
                    if (completados.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('COMPLETADOS',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              letterSpacing: 1, color: t.textMuted)),
                      const SizedBox(height: 8),
                      ...completados.map((h) => _habitoCard(h, true, t)),
                    ],
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HabitoScreen(usuarioId: _usuarioId),
            ),
          );
          if (result == true) _cargarHabitos();
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  String _fechaDeHoy() {
    const dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    final hoy = DateTime.now();
    return '${dias[hoy.weekday - 1]}, ${hoy.day} de ${meses[hoy.month - 1]}';
  }

  Widget _emptyState(TokensContextuales t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(LucideIcons.sprout, size: 48, color: t.success),
            const SizedBox(height: 12),
            Text('Tu primer hábito te espera',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: t.text)),
            const SizedBox(height: 4),
            Text(
              'Los grandes cambios empiezan con un paso pequeño. Crea tu primer hábito y empieza tu racha hoy.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HabitoScreen(usuarioId: _usuarioId)),
                );
                if (result == true) _cargarHabitos();
              },
              icon: const Icon(LucideIcons.plus),
              label: const Text('Crear mi primer hábito'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _habitoCard(Habito h, bool hecho, TokensContextuales t) {
    final p = _progreso[h.habitoId] ?? {'completadosPeriodo': 0, 'meta': 1};
    final frec = nombresFrecuencia[h.frecuencia] ?? h.frecuencia;
    final animando = _animandoId == h.habitoId;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: animando ? 0.25 : (hecho ? 0.72 : 1.0),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        offset: animando ? const Offset(0.06, 0) : Offset.zero,
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HabitoDetalleScreen(habitoId: h.habitoId),
                ),
              );
              if (result == true) _cargarHabitos();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(h.nombre,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: hecho ? TextDecoration.lineThrough : null,
                              color: hecho ? t.textMuted : t.text,
                            )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: t.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('$frec · ${p['completadosPeriodo']}/${p['meta']}',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: t.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _miniHeatmap(h.habitoId, t),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (!hecho)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _completar(h.habitoId),
                            icon: const Icon(LucideIcons.check, size: 18),
                            label: const Text('Completar'),
                          ),
                        )
                      else
                        Expanded(
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: t.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(LucideIcons.circleCheck, color: t.success),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(LucideIcons.pencil, size: 20, color: t.textMuted),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HabitoScreen(usuarioId: _usuarioId, habito: h),
                            ),
                          );
                          if (result == true) _cargarHabitos();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniHeatmap(int habitoId, TokensContextuales t) {
    final fechas = _fechasCompletadas[habitoId] ?? {};
    final hoy = DateTime.now();
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: List.generate(28, (i) {
        final d = hoy.subtract(Duration(days: 27 - i));
        final iso = d.toIso8601String().split('T')[0];
        final lleno = fechas.contains(iso);
        final esHoy = i == 27;
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: lleno ? t.success : t.surface2,
            borderRadius: BorderRadius.circular(2.5),
            border: esHoy ? Border.all(color: t.primary, width: 1.5) : null,
          ),
        );
      }),
    );
  }
}