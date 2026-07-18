import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HabitoDetalleScreen extends StatefulWidget {
  final int habitoId;
  const HabitoDetalleScreen({super.key, required this.habitoId});

  @override
  State<HabitoDetalleScreen> createState() => _HabitoDetalleScreenState();
}

class _HabitoDetalleScreenState extends State<HabitoDetalleScreen> {
  Map<String, dynamic>? _detalle;
  bool _loading = true;
  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month, 1);

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

  void _cambiarMes(int direccion) {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + direccion, 1);
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
        title: Text(_detalle != null ? _detalle!['nombre'] : 'Detalle'),
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detalle == null
              ? const Center(child: Text('Error al cargar el hábito'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
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
            _detalle!['porcentajeMesActual'] != null
                ? '${(_detalle!['porcentajeMesActual'] as num).round()}%'
                : '-',
            'Este mes', Colors.orange),
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

    final primerDia = DateTime.parse(heatmap[0]['fecha']);
    final diaSemana = (primerDia.weekday - 1); // Lunes = 0

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
            const SizedBox(height: 8),
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
                final fecha = DateTime.parse(dia['fecha']);
                final completado = dia['completado'] as bool;
                final esHoy = dia['fecha'] ==
                    DateTime.now().toIso8601String().split('T')[0];
                final t = tokens(context);
                return Container(
                  decoration: BoxDecoration(
                    color: completado ? t.success : t.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: esHoy ? Border.all(color: t.primary, width: 2) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${fecha.day}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: completado ? FontWeight.bold : FontWeight.normal,
                      color: completado ? Colors.white : t.textMuted,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
              const Text('Todavía no hay registros', style: TextStyle(color: Colors.grey))
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
                          onPressed: () => _editarNota(r['registroId'], r['nota'] ?? ''),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _editarNota(int registroId, String notaActual) async {
    final controller = TextEditingController(text: notaActual);
    final nuevaNota = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nota'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevaNota == null) return;

    try {
      await ApiService.actualizarNotaRegistro(registroId, nuevaNota);
      _cargarDetalle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la nota')),
        );
      }
    }
  }
}