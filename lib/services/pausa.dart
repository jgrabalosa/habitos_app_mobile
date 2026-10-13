/// Código del producto «Pausa» en el backend (ProductosHabitosInitializer).
/// Pausar un hábito gasta una; se compran en la tienda.
const String codigoPausa = 'PAUSA_HABITO';

/// Cuántas pausas tiene el usuario según su inventario
/// (`ApiServiceCore.getInventarioProductos`). Nunca lanza: un inventario que
/// no se entiende cuenta como cero.
int pausasEn(List<dynamic> inventario) {
  for (final up in inventario) {
    if (up is! Map) continue;
    final producto = up['producto'];
    if (producto is Map && producto['codigo'] == codigoPausa) {
      final cantidad = up['cantidad'];
      return cantidad is int ? cantidad : 0;
    }
  }
  return 0;
}
