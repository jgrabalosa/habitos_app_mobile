import 'package:flutter/material.dart';

/// Bottom sheet genérico de valoración post-acción.
/// Devuelve un Map {'valoracion': int?, 'nota': String?} con lo que el
/// usuario haya elegido, o null si lo descartó sin interactuar.
/// No conoce el dominio (hábitos, registros...): quien lo invoca decide
/// qué hacer con el resultado. Exportable a otras apps del ecosistema.
class ValoracionSheet {
  static Future<Map<String, dynamic>?> mostrar(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true, // para que suba con el teclado al escribir nota
      builder: (context) => const _ValoracionSheetContent(),
    );
  }
}

class _ValoracionSheetContent extends StatefulWidget {
  const _ValoracionSheetContent();

  @override
  State<_ValoracionSheetContent> createState() => _ValoracionSheetContentState();
}

class _ValoracionSheetContentState extends State<_ValoracionSheetContent> {
  int? _valoracion;
  bool _notaAbierta = false;
  final _notaController = TextEditingController();

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  void _seleccionarEstrella(int valor) {
    setState(() { _valoracion = valor; });
    // Si la nota no está abierta, un tap basta: guarda y cierra solo
    if (!_notaAbierta) {
      Navigator.pop(context, {'valoracion': valor, 'nota': null});
    }
  }

  void _guardar() {
    final nota = _notaController.text.trim();
    Navigator.pop(context, {
      'valoracion': _valoracion,
      'nota': nota.isEmpty ? null : nota,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Deja sitio al teclado cuando se abre la nota
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Cómo te sentiste?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final valor = i + 1;
                  final marcada = _valoracion != null && valor <= _valoracion!;
                  return IconButton(
                    iconSize: 40,
                    onPressed: () => _seleccionarEstrella(valor),
                    icon: Icon(
                      marcada ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: marcada ? Colors.amber : Colors.grey,
                    ),
                  );
                }),
              ),
              if (!_notaAbierta)
                TextButton(
                  onPressed: () => setState(() { _notaAbierta = true; }),
                  child: const Text('añadir nota'),
                ),
              if (_notaAbierta) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _notaController,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: '¿Cómo te ha ido?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}