import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// La fila de estrellas de un registro del historial: cinco, las primeras
/// tantas como diga la valoración. Fuera de rango se recorta a 0 o 5.
class EstrellasRegistro extends StatelessWidget {
  final int valoracion;
  final double tamano;

  const EstrellasRegistro({
    super.key,
    required this.valoracion,
    this.tamano = 14,
  });

  @override
  Widget build(BuildContext context) {
    final llenas = valoracion.clamp(0, 5);
    return Row(
      children: List.generate(
        5,
        (i) => EstrellaValoracion(marcada: i < llenas, tamano: tamano),
      ),
    );
  }
}
