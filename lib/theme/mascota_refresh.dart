import 'package:flutter/material.dart';

/// Señal global para forzar que la mascota vuelva a leer su estado del
/// backend. Mismo patrón que `avatarEquipadoNotifier` en avatares.dart.
///
/// El valor en sí no significa nada: es un contador que solo existe para que
/// cada incremento sea un cambio distinto y despierte a los oyentes. Quien
/// escucha no mira el número, solo reacciona.
///
/// Es un mecanismo de motor: no sabe por qué hay que refrescar. Son las
/// pantallas de dominio las que deciden cuándo llamarlo.
final ValueNotifier<int> refrescoMascotaNotifier = ValueNotifier(0);

/// Llamar cuando algo haya podido cambiar el estado de ánimo o la fase de la
/// mascota en el servidor.
void solicitarRefrescoMascota() {
  refrescoMascotaNotifier.value++;
}
