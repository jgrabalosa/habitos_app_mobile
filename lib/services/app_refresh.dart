import 'package:flutter/foundation.dart';

/// Señal global para sincronizar las pantallas vivas al recuperar el foco.
final ValueNotifier<int> appRefreshNotifier = ValueNotifier<int>(0);

void solicitarRefrescoApp() {
  appRefreshNotifier.value++;
}
