import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/habito.dart';
import '../theme/app_theme.dart';
import 'habito_screen.dart';
import '../widgets/valoracion_sheet.dart';

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

  final List<String> _nombresMeses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

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
      final detalle = await ApiService.getHabitoDetalle(widget.habitoId, mes: mesParam);
      setState(() {
        _detalle = detalle;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _abrirEdicion() async {
    try {
      final Habito habito = await ApiService.getHabito(widget.habitoId);
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
          const SnackBar(content: Text('No se pudo cargar el hábito')),
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
    return Scaffold(
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
      tooltip: 'Editar hábito',
      onPressed: _abrirEdicion,
    ),
  ],
),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detalle == null
              ? const Center(child: Text('Error al cargar el hábito'))
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
    final t = tokens(context);
    final bool esDiario = _detalle!['frecuencia'] == 'DIARIO';
    final int meta = _detalle!['meta'] ?? 1;
    final String? diasSemana = _detalle!['diasSemana'];

    const etiquetas = ['L', 'M', 'X', 'J', 'V', 'S', 'D']; // 1=lunes..7=domingo

    final String texto;
    if (esDiario) {
      texto = meta > 1 ? 'Diario · meta $meta/día' : 'Diario';
    } else if (diasSemana != null && diasSemana.trim().isNotEmpty) {
      // Semanal con días planificados: "Semanal · M · J · S"
      final dias = diasSemana
          .split(',')
          .map((d) => etiquetas[int.parse(d.trim()) - 1])
          .join(' · ');
      texto = 'Semanal · $dias';
    } else {
      texto = meta > 1 ? 'Semanal · meta $meta/semana' : 'Semanal · 1 día/semana';
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

  Widget _buildStatCards() {
    return Row(
      children: [
        _statCard('🔥', _detalle!['rachaActual'].toString(), 'Racha actual', Colors.blue),
        const SizedBox(width: 8),
        _statCard('🏆', _detalle!['rachaMaxima'].toString(), 'Mejor racha', Colors.green),
        const SizedBox(width: 8),
        _statCard('📊', _detalle!['totalCompletados'].toString(), 'Total', Colors.purple),
        const SizedBox(width: 8),
        _statCard('📅',
            (_detalle!['completadosMesActual'] ?? 0).toString(),
            _esMesActual ? 'Días este mes' : 'Días del mes', Colors.orange),
      ],
    );
  }

  Widget _buildValoracionMedia() {
    final media = _detalle!['valoracionMedia'];
    if (media == null) return const SizedBox.shrink();

    final valor = (media as num).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 6),
              Text(
                valor.toStringAsFixed(1).replaceAll('.', ','),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              const Text('Satisfacción media',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String emoji, String valor, String label, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(valor,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final List<dynamic> heatmap = _detalle!['heatmap'];
    final int meta = _detalle!['meta'] ?? 1;
    final bool esDiario = _detalle!['frecuencia'] == 'DIARIO';
    final bool conNiveles = esDiario && meta > 1;

    final primerDia = DateTime.parse(heatmap[0]['fecha']);
    final diaSemana = (primerDia.weekday - 1); // Lunes = 0
    final t = tokens(context);

    Color colorDia(int veces) {
      if (veces == 0) return t.surface2;
      if (!conNiveles) return t.primary;
      if (veces < meta) return t.primary.withOpacity(0.35);
      if (veces == meta) return t.primary;
      return AppColors.primaryDark; // superada
    }

    return Card(
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
                Text('${_nombresMeses[_mesActual.month - 1]} ${_mesActual.year}',
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorDia(veces),
                      borderRadius: BorderRadius.circular(6),
                      border: seleccionado
                          ? Border.all(color: t.text, width: 2)
                          : esHoy
                              ? Border.all(color: t.primary, width: 2)
                              : null,
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
                  Text('Menos ',
                      style: TextStyle(fontSize: 10, color: t.textMuted)),
                  ...[
                    t.surface2,
                    if (conNiveles) t.primary.withOpacity(0.35),
                    t.primary,
                    if (conNiveles) AppColors.primaryDark,
                  ].map((c) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                  Text(' Más',
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
    final nombreMes = _nombresMeses[fecha.month - 1].toLowerCase();
    final base = '${fecha.day} de $nombreMes';
    if (veces == 0) return '$base · Sin completar';
    if (conNiveles) return '$base · $veces/$meta';
    return '$base · Completado';
  }

  Widget _buildUltimosRegistros() {
    final List<dynamic> registros = _detalle!['ultimosRegistros'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Últimos registros',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      Text('Tu historia empieza hoy',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tokens(context).text)),
                      Text('Completa este hábito y aquí quedará el registro.',
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
                              Text(r['fecha'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (r['valoracion'] != null)
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    LucideIcons.star,
                                    size: 14,
                                    color: i < (r['valoracion'] as int)
                                        ? Colors.amber
                                        : Colors.grey.withOpacity(0.3),
                                  )),
                                ),
                              if (r['nota'] != null && r['nota'].toString().isNotEmpty)
                                Text(r['nota'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Icon(
                          r['completado'] ? LucideIcons.circleCheck : LucideIcons.circleX,
                          color: r['completado'] ? Colors.green : Colors.grey,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.pencil, size: 18, color: Colors.grey),
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
        await ApiService.valorarRegistro(registroId, valoracion);
      }
      // La nota sí se puede vaciar: enviamos '' si la borró
      if ((nota ?? '') != (notaActual ?? '')) {
        await ApiService.actualizarNotaRegistro(registroId, nota ?? '');
      }
      _cargarDetalle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Inténtalo de nuevo.')),
        );
      }
    }
  }
}