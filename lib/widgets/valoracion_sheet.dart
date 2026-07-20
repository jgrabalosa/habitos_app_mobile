import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';

/// Diálogo genérico de valoración post-acción, centrado y con efecto cristal.
/// Devuelve un Map {'valoracion': int?, 'nota': String?} con lo que el
/// usuario haya elegido, o null si lo descartó sin guardar.
/// Admite valores iniciales para modo edición.
/// No conoce el dominio: quien lo invoca decide qué hacer con el resultado.
/// Exportable a otras apps del ecosistema.
class ValoracionSheet {
  static Future<Map<String, dynamic>?> mostrar(
    BuildContext context, {
    int? valoracionInicial,
    String? notaInicial,
  }) {
    return showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Valoración',
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, _, __) => _ValoracionDialogContent(
        valoracionInicial: valoracionInicial,
        notaInicial: notaInicial,
      ),
      transitionBuilder: (context, anim, _, child) {
        final curva = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curva, child: child),
        );
      },
    );
  }
}

class _ValoracionDialogContent extends StatefulWidget {
  final int? valoracionInicial;
  final String? notaInicial;

  const _ValoracionDialogContent({this.valoracionInicial, this.notaInicial});

  @override
  State<_ValoracionDialogContent> createState() =>
      _ValoracionDialogContentState();
}

class _ValoracionDialogContentState extends State<_ValoracionDialogContent> {
  int? _valoracion;
  late final TextEditingController _notaController;

  bool get _esEdicion =>
      widget.valoracionInicial != null || widget.notaInicial != null;

  @override
  void initState() {
    super.initState();
    _valoracion = widget.valoracionInicial;
    _notaController = TextEditingController(text: widget.notaInicial ?? '');
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  void _seleccionarEstrella(int valor) {
    setState(() {
      // Tocar la misma estrella otra vez la deselecciona
      _valoracion = (_valoracion == valor) ? null : valor;
    });
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
    final t = tokens(context);
    final teclado = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Center(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          // Cuando sube el teclado, el diálogo se desplaza hacia arriba
          padding: EdgeInsets.only(
              left: 24, right: 24, bottom: teclado > 0 ? teclado : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: t.surface.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _esEdicion ? 'Editar valoración' : '¿Cómo te sentiste?',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: t.text),
                      ),
                      const SizedBox(height: 12),
                      // FittedBox: si la fila de estrellas no cabe,
                      // se encoge en vez de desbordar (fix overflow 8.6px)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            final valor = i + 1;
                            final marcada =
                                _valoracion != null && valor <= _valoracion!;
                            return IconButton(
                              iconSize: 36,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              constraints: const BoxConstraints(),
                              onPressed: () => _seleccionarEstrella(valor),
                              icon: Icon(
                                LucideIcons.star,
                                color: marcada
                                    ? Colors.amber
                                    : t.textMuted.withOpacity(0.45),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notaController,
                        maxLines: 3,
                        maxLength: 500,
                        style: TextStyle(color: t.text),
                        decoration: const InputDecoration(
                          hintText: 'Añade una nota (opcional)',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _guardar,
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}