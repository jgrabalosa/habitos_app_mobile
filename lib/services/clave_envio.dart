import 'dart:math';

final Random _azar = Random.secure();

/// Un UUID v4 nuevo, en minúsculas y con guiones, para la `clave` de cada
/// envío de minutos: si el mismo envío llega dos veces, el backend lo
/// reconoce y no registra nada más.
///
/// Se genera aquí, con `Random.secure()`, en vez de añadir el paquete `uuid`:
/// son seis líneas y no merecen una dependencia nueva.
String nuevaClave() {
  final bytes = List<int>.generate(16, (_) => _azar.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // versión 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
