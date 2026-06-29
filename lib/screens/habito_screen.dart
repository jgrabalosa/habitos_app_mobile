import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HabitoScreen extends StatefulWidget {
  final int usuarioId;
  const HabitoScreen({super.key, required this.usuarioId});

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

  Future<void> _crear() async {
    if (_nombreController.text.isEmpty) {
      setState(() { _error = 'El nombre es obligatorio'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.crearHabito(
        _nombreController.text,
        _descripcionController.text,
        _frecuencia,
        _meta,
        widget.usuarioId,
        null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = 'Error al crear el hábito'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Nuevo hábito'),
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
                  items: ['DIARIO', 'SEMANAL', 'MENSUAL']
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
                    onPressed: _loading ? null : _crear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4a6cf7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Crear hábito',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}