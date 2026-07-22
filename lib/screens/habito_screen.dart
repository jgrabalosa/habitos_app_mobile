import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../services/analytics_service.dart';
import '../services/celebracion_service.dart';
import '../models/habito.dart';
import '../theme/app_theme.dart';

class HabitoScreen extends StatefulWidget {
  final int usuarioId;
  final Habito? habito;
  final List<dynamic>? categoriasIniciales;
  const HabitoScreen({super.key, required this.usuarioId, this.habito, this.categoriasIniciales});

  @override
  State<HabitoScreen> createState() => _HabitoScreenState();
}

class _HabitoScreenState extends State<HabitoScreen> {
  static const List<Map<String, dynamic>> _plantillas = [
    {'emoji': '💧', 'nombre': 'Beber agua', 'frecuencia': 'DIARIO', 'meta': 4},
    {'emoji': '📖', 'nombre': 'Leer 20 min', 'frecuencia': 'DIARIO', 'meta': 1},
    {'emoji': '🏃', 'nombre': 'Ejercicio', 'frecuencia': 'SEMANAL', 'meta': 3, 'dias': '2,4,6'},
    {'emoji': '🧘', 'nombre': 'Meditar', 'frecuencia': 'DIARIO', 'meta': 1},
    {'emoji': '😴', 'nombre': 'Dormir 8h', 'frecuencia': 'DIARIO', 'meta': 1},
    {'emoji': '🚶', 'nombre': 'Caminar', 'frecuencia': 'DIARIO', 'meta': 1},
    {'emoji': '📓', 'nombre': 'Escribir diario', 'frecuencia': 'DIARIO', 'meta': 1},
    {'emoji': '🧹', 'nombre': 'Limpiar casa', 'frecuencia': 'SEMANAL', 'meta': 2},
  ];

  // Etiquetas L-D en orden ISO (1=lunes .. 7=domingo)
  static const List<String> _etiquetasDias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _frecuencia = 'DIARIO';
  int _meta = 1;
  Set<int> _diasSeleccionados = {}; // días ISO elegidos (solo SEMANAL)
  bool _recordatorioActivo = true;
  TimeOfDay? _recordatorioHora;
  bool _loading = false;
  String? _error;

  List<dynamic> _categorias = [];
  int? _categoriaId;
  bool _categoriasLoading = true;

  bool get _esEdicion => widget.habito != null;

  // Con días elegidos, la meta se deriva de ellos (un solo control)
  bool get _metaDerivada =>
      _frecuencia == 'SEMANAL' && _diasSeleccionados.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.habito!.nombre;
      _descripcionController.text = widget.habito!.descripcion ?? '';
      _frecuencia = widget.habito!.frecuencia;
      _meta = widget.habito!.meta;
      _categoriaId = widget.habito!.categoriaId;
      _diasSeleccionados = widget.habito!.diasPlanificados.toSet();
      _recordatorioActivo = widget.habito!.recordatorioActivo;
      _recordatorioHora = widget.habito!.recordatorioHoraTimeOfDay;
    }
    if (widget.categoriasIniciales != null) {
      _categorias = widget.categoriasIniciales!;
      _categoriasLoading = false;
    }
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await ApiService.getCategoriasUsuario(widget.usuarioId);
      setState(() {
        _categorias = categorias;
        _categoriasLoading = false;
      });
    } catch (e) {
      setState(() { _categoriasLoading = false; });
    }
  }

  void _aplicarPlantilla(Map<String, dynamic> plantilla) {
    setState(() {
      _nombreController.text = plantilla['nombre'];
      _frecuencia = plantilla['frecuencia'];
      _meta = plantilla['meta'];
      _diasSeleccionados = plantilla['dias'] != null
          ? (plantilla['dias'] as String).split(',').map(int.parse).toSet()
          : {};
    });
  }

  void _alternarDia(int dia) {
    setState(() {
      if (_diasSeleccionados.contains(dia)) {
        _diasSeleccionados.remove(dia);
      } else {
        _diasSeleccionados.add(dia);
      }
      // Meta derivada: tantos días como haya marcados
      if (_diasSeleccionados.isNotEmpty) {
        _meta = _diasSeleccionados.length;
      }
    });
  }

  Future<void> _guardar() async {
    if (widget.habito != null && _frecuencia != widget.habito!.frecuencia) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Cambiar la frecuencia?'),
          content: const Text(
              'Cambiar la frecuencia reiniciará tu racha actual a 0.\n'
              'Tu mejor racha se conserva.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    if (_nombreController.text.isEmpty) {
      setState(() { _error = 'El nombre es obligatorio'; });
      return;
    }

    // Días solo si es SEMANAL y hay elegidos; null = semanal flexible o diario.
    // Ordenados para un CSV estable ("2,4,6").
    final String? diasSemana = _metaDerivada
        ? (_diasSeleccionados.toList()..sort()).join(',')
        : null;
    final int meta = _metaDerivada ? _diasSeleccionados.length : _meta;
    final String? recordatorioHora = _recordatorioHora == null
        ? null
        : '${_recordatorioHora!.hour.toString().padLeft(2, '0')}:${_recordatorioHora!.minute.toString().padLeft(2, '0')}';

    setState(() { _loading = true; _error = null; });
    try {
      if (_esEdicion) {
        await ApiService.actualizarHabito(
          widget.habito!.habitoId,
          _nombreController.text,
          _descripcionController.text,
          _frecuencia,
          meta,
          widget.usuarioId,
          _categoriaId,
          diasSemana: diasSemana,
          recordatorioActivo: _recordatorioActivo,
          recordatorioHora: recordatorioHora,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        final logrosOtorgados = await ApiService.crearHabito(
          _nombreController.text,
          _descripcionController.text,
          _frecuencia,
          meta,
          widget.usuarioId,
          _categoriaId,
          diasSemana: diasSemana,
          recordatorioActivo: _recordatorioActivo,
          recordatorioHora: recordatorioHora,
        );
        await AnalyticsService.habitoCreado(_frecuencia);
        if (mounted) Navigator.pop(context, true);
        if (logrosOtorgados.isNotEmpty) {
          CelebracionService.mostrar(logrosOtorgados);
        }
      }
    } catch (e) {
      setState(() { _error = _esEdicion ? 'Error al actualizar el hábito' : 'Error al crear el hábito'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: const Text('¿Seguro que quieres eliminar este hábito? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() { _loading = true; });
      try {
        await ApiService.eliminarHabito(widget.habito!.habitoId);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        setState(() { _error = 'Error al eliminar el hábito'; _loading = false; });
      }
    }
  }

  Future<void> _elegirHoraRecordatorio() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _recordatorioHora ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (hora != null) {
      setState(() { _recordatorioHora = hora; });
    }
  }

  Widget _selectorDias(TokensContextuales t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Días de la semana (opcional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            final dia = i + 1;
            final bool activo = _diasSeleccionados.contains(dia);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _alternarDia(dia),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activo ? t.primary : t.surface2,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _etiquetasDias[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: activo ? Colors.white : t.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _diasSeleccionados.isEmpty
              ? 'Sin días concretos: tú eliges cuándo, la meta marca cuántos.'
              : 'Son tu guía: si un día no puedes, vale cualquier otro de la semana.',
          style: TextStyle(fontSize: 12, color: t.textMuted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar hábito' : 'Nuevo hábito'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_esEdicion) ...[
                  const Text('Empieza rápido (opcional)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _plantillas.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final p = _plantillas[i];
                        return ActionChip(
                          avatar: Text(p['emoji'], style: const TextStyle(fontSize: 16)),
                          label: Text(p['nombre']),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          onPressed: () => _aplicarPlantilla(p),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del hábito',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descripcionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _categoriasLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : DropdownButtonFormField<int?>(
                        value: _categoriaId,
                        decoration: const InputDecoration(
                          labelText: 'Categoría (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sin categoría'),
                          ),
                          ..._categorias.map((c) => DropdownMenuItem<int?>(
                                value: c['categoriaId'],
                                child: Text('${c['icono'] ?? ''} ${c['nombre']}'.trim()),
                              )),
                        ],
                        onChanged: (v) => setState(() { _categoriaId = v; }),
                      ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _frecuencia,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia',
                    border: OutlineInputBorder(),
                  ),
                  items: ['DIARIO', 'SEMANAL']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() { _frecuencia = v!; }),
                ),
                if (_frecuencia == 'SEMANAL') ...[
                  const SizedBox(height: 16),
                  _selectorDias(t),
                ],
                const SizedBox(height: 12),
                if (_metaDerivada)
                  Row(
                    children: [
                      const Text('Meta: '),
                      Text('${_diasSeleccionados.length} días/semana',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Text('Meta: '),
                      IconButton(
                        icon: const Icon(LucideIcons.minus),
                        onPressed: () => setState(() { if (_meta > 1) _meta--; }),
                      ),
                      Text('$_meta', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(LucideIcons.plus),
                        onPressed: () => setState(() { _meta++; }),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recordatorio'),
                  subtitle: Text(_recordatorioActivo
                      ? (_recordatorioHora != null
                          ? 'A las ${_recordatorioHora!.format(context)}'
                          : 'Elige una hora')
                      : 'Desactivado'),
                  value: _recordatorioActivo,
                  onChanged: (v) => setState(() { _recordatorioActivo = v; }),
                ),
                if (_recordatorioActivo)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _elegirHoraRecordatorio,
                      icon: const Icon(LucideIcons.clock),
                      label: Text(_recordatorioHora == null
                          ? 'Elegir hora'
                          : 'Cambiar hora (${_recordatorioHora!.format(context)})'),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _guardar,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_esEdicion ? 'Actualizar hábito' : 'Crear hábito'),
                  ),
                ),
                if (_esEdicion) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _eliminar,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Eliminar hábito',
                          style: TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}