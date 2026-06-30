import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(_detalle != null ? _detalle!['nombre'] : 'Detalle'),
        backgroundColor: Colors.white,
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
                    const SizedBox(height: 16),
                    _buildHeatmap(),
                    const SizedBox(height: 16),
                    _buildUltimosRegistros(),
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
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _cambiarMes(-1),
                ),
                Text('${_nombresMeses[_mesActual.month - 1]} ${_mesActual.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
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
                return Container(
                  decoration: BoxDecoration(
                    color: completado ? Colors.green : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${fecha.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: completado ? Colors.white : Colors.grey[600],
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
                              if (r['nota'] != null && r['nota'].toString().isNotEmpty)
                                Text(r['nota'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Icon(
                          r['completado'] ? Icons.check_circle : Icons.cancel,
                          color: r['completado'] ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}