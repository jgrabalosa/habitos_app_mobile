import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service_habitos.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/habito.dart';
import '../widgets/identidad_ui.dart';
import 'habito_screen.dart';

class HabitoDetalleScreen extends StatefulWidget {
  final int habitoId;
  final int usuarioId;
  final String? nombre; // para el Hero: título visible desde el primer frame
  const HabitoDetalleScreen({super.key, required this.habitoId, required this.usuarioId, this.nombre});

  @override
  State<HabitoDetalleScreen> createState() => _HabitoDetalleScreenState();
}

class _HabitoDetalleScreenState extends State<HabitoDetalleScreen> {
  Map<String, dynamic>? _detalle;
  bool _loading = true;
  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, dynamic>? _diaSeleccionado; // día tocado en el heatmap (tooltip)

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() { _loading = true; });
    try {
      final mesParam =
          '${_mesActual.year}-${_mesActual.month.toString().padLeft(2, '0')}';
      final detalle = await ApiServiceHabitos.getHabitoDetalle(widget.habitoId, mes: mesParam);
      if (!mounted) return;
      setState(() {
        _detalle = detalle;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: AppLocalizations.of(context)!.detErrorCargarDetalle)),
        ),
      );
    }
  }

  Future<void> _abrirEdicion() async {
    try {
      final Habito habito = await ApiServiceHabitos.getHabito(widget.habitoId);
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HabitoScreen(usuarioId: widget.usuarioId, habito: habito),
        ),
      );
      if (result == true) _cargarDetalle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(MensajesError.de(context, e,
                generico: AppLocalizations.of(context)!.detErrorCargar)),
          ),
        );
      }
    }
  }

  void _cambiarMes(int direccion) {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + direccion, 1);
      _diaSeleccionado = null;
    });
    _cargarDetalle();
  }

  bool get _esMesActual {
    final hoy = DateTime.now();
    return _mesActual.year == hoy.year && _mesActual.month == hoy.month;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
   resizeToAvoidBottomInset: false,   
appBar: AppBar(
  // El Hero envuelve al condicional del texto
title: Hero(
          tag: 'habito-nombre-${widget.habitoId}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              _detalle != null ? _detalle!['nombre'] : (widget.nombre ?? ''),
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
  elevation: 1,
  actions: [
    IconButton(
      icon: const Icon(LucideIcons.pencil),
      tooltip: l.habTituloEditar,
      onPressed: _abrirEdicion,
    ),
  ],
),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detalle == null
              ? Center(child: Text(l.detErrorCargarDetalle))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildLineaFrecuencia(),
                    _buildStatCards(),
                    _buildValoracionMedia(),
                    const SizedBox(height: 16),
                    _buildHeatmap(),
                    const SizedBox(height: 16),
                    _buildUltimosRegistros(),
                    const SizedBox(height: 48),
                  ],
                ),
    );
  }

  Widget _buildLineaFrecuencia() {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final bool esDiario = _detalle!['frecuencia'] == 'DIARIO';
    final int meta = _detalle!['meta'] ?? 1;
    final String? diasSemana = _detalle!['diasSemana'];

    const etiquetas = ['L', 'M', 'X', 'J', 'V', 'S', 'D']; // 1=lunes..7=domingo

    final String texto;
    if (esDiario) {
      texto = meta > 1 ? l.detDiarioMeta(meta) : l.frecDiario;
    } else if (diasSemana != null && diasSemana.trim().isNotEmpty) {
      // Semanal con días planificados: "Semanal · M · J · S"
      final dias = diasSemana
          .split(',')
          .map((d) => etiquetas[int.parse(d.trim()) - 1])
          .join(' · ');
      texto = l.detSemanalDias(dias);
    } else {
      texto = meta > 1
          ? l.detSemanalMeta(meta)
          : '${l.frecSemanal} · ${l.detSemanalUnDia}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(LucideIcons.repeat, size: 14, color: t.textMuted),
          const SizedBox(width: 6),
          Text(texto,
              style: TextStyle(
                  fontSize: 13,
                  color: t.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Cuatro cifras que son en realidad dos métricas miradas a dos plazos: la
  /// racha (ahora / récord) y los completados (siempre / este mes). El color
  /// dice de qué familia es cada una; el icono y la etiqueta, el plazo.
  ///
  /// Los iconos son Lucide y ya no emoji, por lo mismo que en la tienda y en
  /// logros: el emoji lo pinta la fuente del sistema y cambia de dibujo, color
  /// y peso entre plataformas, así que no se alinea con la identidad equipada.
  Widget _buildStatCards() {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    return Row(
      children: [
        _statCard(LucideIcons.flame, _detalle!['rachaActual'].toString(),
            l.detRachaActual, t.streakText),
        const SizedBox(width: 8),
        _statCard(LucideIcons.trophy, _detalle!['rachaMaxima'].toString(),
            l.detMejorRacha, t.streakText),
        const SizedBox(width: 8),
        _statCard(LucideIcons.chartColumn,
            _detalle!['totalCompletados'].toString(), l.detTotal, t.successText),
        const SizedBox(width: 8),
        _statCard(LucideIcons.calendarDays,
            (_detalle!['completadosMesActual'] ?? 0).toString(),
            _esMesActual ? l.detDiasEsteMes : l.detDiasDelMes, t.successText),
      ],
    );
  }

  Widget _buildValoracionMedia() {
    final l = AppLocalizations.of(context)!;
    final media = _detalle!['valoracionMedia'];
    if (media == null) return const SizedBox.shrink();

    final t = tokens(context);
    final valor = (media as num).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TarjetaIdentidad(
        margen: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // La estrella va en el color de puntos de la identidad, no en el
              // ámbar de Material: es la misma familia que el resto de premios.
              Icon(LucideIcons.star, color: t.points, size: 20),
              const SizedBox(width: 6),
              Text(
                valor.toStringAsFixed(1).replaceAll('.', ','),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: t.text),
              ),
              const SizedBox(width: 6),
              Text(l.detSatisfaccion,
                  style: TextStyle(fontSize: 12, color: t.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  /// El `color` es el de la cifra, y llega ya resuelto para texto: quien
  /// llama pasa `successText`, no `success`.
  Widget _statCard(IconData icono, String valor, String label, Color color) {
    final t = tokens(context);
    return Expanded(
      child: TarjetaIdentidad(
        margen: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(height: 4),
              Text(valor,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: TextStyle(fontSize: 10, color: t.textMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final l = AppLocalizations.of(context)!;
    final List<dynamic> heatmap = _detalle!['heatmap'];
    final int meta = _detalle!['meta'] ?? 1;
    final bool esDiario = _detalle!['frecuencia'] == 'DIARIO';
    final bool conNiveles = esDiario && meta > 1;

    final primerDia = DateTime.parse(heatmap[0]['fecha']);
    final diaSemana = (primerDia.weekday - 1); // Lunes = 0
    final t = tokens(context);
    final id = identidad(context);

    Color colorDia(int veces) {
      if (veces == 0) return t.surface2;
      if (!conNiveles) return t.primary;
      if (veces < meta) return t.primary.withValues(alpha: 0.35);
      if (veces == meta) return t.primary;
      return AppColors.primaryDark; // superada
    }

    return TarjetaIdentidad(
      margen: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft),
                  onPressed: () => _cambiarMes(-1),
                ),
                Text(
                    DateFormat.yMMMM(Localizations.localeOf(context).toLanguageTag())
                        .format(_mesActual),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight),
                  onPressed: _esMesActual ? null : () => _cambiarMes(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Etiquetas de días de la semana
            Row(
              children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                  .map((d) => Expanded(
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: t.textMuted)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: diaSemana + heatmap.length,
              itemBuilder: (context, index) {
                if (index < diaSemana) return const SizedBox();
                final dia = heatmap[index - diaSemana];
                final int veces = dia['veces'] ?? (dia['completado'] == true ? 1 : 0);
                final esHoy = dia['fecha'] ==
                    DateTime.now().toIso8601String().split('T')[0];
                final seleccionado = _diaSeleccionado?['fecha'] == dia['fecha'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _diaSeleccionado = seleccionado ? null : dia;
                  }),
                  // La celda es exactamente la misma que la de los diez días de
                  // Hoy: LED con halo en Neotokyo+, puntito hueco en Alba,
                  // circulito pastel en Dulce y celda con brillo verde en
                  // Profundidad. Lo único distinto aquí es el layout —un mes
                  // entero en rejilla de siete— y que un día se puede tocar.
                  child: Container(
                    decoration: celdaHeatmap(
                      id,
                      t,
                      color: colorDia(veces),
                      llena: veces > 0,
                      esHoy: esHoy,
                      seleccionada: seleccionado,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Info del día seleccionado (tooltip) o leyenda
            if (_diaSeleccionado != null)
              Text(
                _infoDia(_diaSeleccionado!, meta, conNiveles),
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: t.text),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${l.detMenos} ',
                      style: TextStyle(fontSize: 10, color: t.textMuted)),
                  ...[
                    t.surface2,
                    if (conNiveles) t.primary.withValues(alpha: 0.35),
                    t.primary,
                    if (conNiveles) AppColors.primaryDark,
                  ].map((c) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        // La leyenda son celdas en pequeño, así que se pintan
                        // con la misma función: si la rejilla son puntos y la
                        // leyenda cuadraditos, la leyenda deja de explicarla.
                        decoration: celdaHeatmap(id, t,
                            color: c, llena: c != t.surface2, esHoy: false),
                      )),
                  Text(' ${l.detMas}',
                      style: TextStyle(fontSize: 10, color: t.textMuted)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _infoDia(Map<String, dynamic> dia, int meta, bool conNiveles) {
    final fecha = DateTime.parse(dia['fecha']);
    final int veces = dia['veces'] ?? (dia['completado'] == true ? 1 : 0);
    final base = DateFormat.MMMMd(Localizations.localeOf(context).toLanguageTag())
        .format(fecha);
    final l = AppLocalizations.of(context)!;
    if (veces == 0) return '$base · ${l.detSinCompletar}';
    if (conNiveles) return '$base · ${l.detProgresoDia(veces, meta)}';
    return '$base · ${l.detCompletado}';
  }

  Widget _buildUltimosRegistros() {
    final l = AppLocalizations.of(context)!;
    final t = tokens(context);
    final List<dynamic> registros = _detalle!['ultimosRegistros'];

    return TarjetaIdentidad(
      margen: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.detUltimosRegistros,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: t.text)),
            const SizedBox(height: 8),
            if (registros.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(LucideIcons.calendarHeart,
                          size: 36, color: tokens(context).textMuted),
                      const SizedBox(height: 8),
                      Text(l.detVacioTitulo,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tokens(context).text)),
                      Text(l.detVacioRegistro,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: tokens(context).textMuted)),
                    ],
                  ),
                ),
              )
            else
              ...registros.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['fecha'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: t.text)),
                              if (r['valoracion'] != null)
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    LucideIcons.star,
                                    size: 14,
                                    color: i < (r['valoracion'] as int)
                                        ? t.points
                                        : t.textMuted.withValues(alpha: 0.3),
                                  )),
                                ),
                              if (r['nota'] != null && r['nota'].toString().isNotEmpty)
                                Text(r['nota'],
                                    style: TextStyle(
                                        fontSize: 12, color: t.textMuted)),
                            ],
                          ),
                        ),
                        Icon(
                          r['completado'] ? LucideIcons.circleCheck : LucideIcons.circleX,
                          // Como icono basta el verde de relleno; el que hace
                          // falta oscurecer es el que se escribe.
                          color: r['completado'] ? t.success : t.textMuted,
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.pencil, size: 18, color: t.textMuted),
                          onPressed: () => _editarValoracion(
                            r['registroId'],
                            r['valoracion'] as int?,
                            r['nota'] as String?,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

 Future<void> _editarValoracion(
      int registroId, int? valoracionActual, String? notaActual) async {
    final respuesta = await ValoracionSheet.mostrar(
      context,
      valoracionInicial: valoracionActual,
      notaInicial: notaActual,
    );

    if (respuesta == null) return; // descartó sin guardar

    try {
      final int? valoracion = respuesta['valoracion'];
      final String? nota = respuesta['nota'];

      // Solo se envía la valoración si hay una elegida
      // (el backend no admite borrar una valoración existente)
      if (valoracion != null && valoracion != valoracionActual) {
        await ApiServiceHabitos.valorarRegistro(registroId, valoracion);
      }
      // La nota sí se puede vaciar: enviamos '' si la borró
      if ((nota ?? '') != (notaActual ?? '')) {
        await ApiServiceHabitos.actualizarNotaRegistro(registroId, nota ?? '');
      }
      _cargarDetalle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(MensajesError.de(context, e,
                generico: AppLocalizations.of(context)!.errorGuardar)),
          ),
        );
      }
    }
  }
}