import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/habito.dart';

class HabitoScreen extends StatefulWidget {
  final int usuarioId;
  final Habito? habito;
  const HabitoScreen({super.key, required this.usuarioId, this.habito});

  @override
  State<HabitoScreen> createState() => _HabitoScreenState();
}

class _HabitoScreenState extends State<HabitoScreen> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _frecuencia = 'DIARIO';
  int _meta = 1;
  bool _loading = false;
  String? _error;

  bool get _esEdicion => widget.habito != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.habito!.nombre;
      _descripcionController.text = widget.habito!.descripcion ?? '';
      _frecuencia = widget.habito!.frecuencia;
      _meta = widget.habito!.meta;
    }
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
    setState(() { _loading = true; _error = null; });
    try {
      if (_esEdicion) {
        await ApiService.actualizarHabito(
          widget.habito!.habitoId,
          _nombreController.text,
          _descripcionController.text,
          _frecuencia,
          _meta,
          widget.usuarioId,
          null,
        );
      } else {
        await ApiService.crearHabito(
          _nombreController.text,
          _descripcionController.text,
          _frecuencia,
          _meta,
          widget.usuarioId,
          null,
        );
      }
      if (mounted) Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar hábito' : 'Nuevo hábito'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del hábito',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _frecuencia,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia',
                    border: OutlineInputBorder(),
                  ),
                  items: ['DIARIO', 'SEMANAL',]
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() { _frecuencia = v!; }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Meta: '),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => setState(() { if (_meta > 1) _meta--; }),
                    ),
                    Text('$_meta', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() { _meta++; }),
                    ),
                  ],
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4a6cf7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_esEdicion ? 'Actualizar hábito' : 'Crear hábito',
                            style: const TextStyle(color: Colors.white, fontSize: 16)),
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