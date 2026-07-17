import 'package:flutter/material.dart';
import '../main.dart';
import 'api_service.dart';
import 'package:lottie/lottie.dart';
import 'sonido_service.dart';

class CelebracionService {
  static bool _mostrando = false;
  static final List<String> _cola = [];

  static Future<void> mostrar(List<String> codigos) async {
    if (codigos.isEmpty) return;
    _cola.addAll(codigos);
    if (_mostrando) return;
    _mostrando = true;
    await _procesarCola();
    _mostrando = false;
  }

static Future<void> _procesarCola() async {
    Map<String, String> nombres = {};
    try {
      final catalogo = await ApiService.getCatalogoLogros();
      for (var l in catalogo) {
        nombres[l['codigo']] = l['nombre'];
      }
    } catch (_) {}

    while (_cola.isNotEmpty) {
      final codigo = _cola.removeAt(0);
      final context = navigatorKey.currentContext;
      if (context == null) continue;
      SonidoService.reproducir('logro');

      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Cerrar',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
        transitionBuilder: (context, anim, anim2, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
          return Stack(
            children: [
              // Diálogo del logro (debajo)
              Transform.scale(
                scale: curved.value,
                child: Opacity(
                  opacity: anim.value.clamp(0.0, 1.0),
                  child: _CelebracionDialog(
                    nombre: nombres[codigo] ?? codigo,
                  ),
                ),
              ),
              // Confeti a pantalla completa (encima, sin bloquear toques)
              IgnorePointer(
                child: SizedBox.expand(
                  child: Lottie.asset(
                    'assets/animations/confetti.json',
                    fit: BoxFit.cover,
                    repeat: false,
                  ),
                ),
              ),
            ],
          );
        },
      );

      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
}

class _CelebracionDialog extends StatelessWidget {
  final String nombre;
  const _CelebracionDialog({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/confetti.json',
                      height: 140,
                      width: 140,
                      repeat: false,
                    ),
                    const Text('🏆', style: TextStyle(fontSize: 56)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('¡Logro desbloqueado!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(nombre,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('¡Genial!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}