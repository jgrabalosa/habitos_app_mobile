import 'package:flutter/foundation.dart';

/// Avisa de que la lista de hábitos ha cambiado: se ha creado, editado o
/// borrado uno.
///
/// Existe porque la pestaña Hoy va envuelta en `_MantenerVivo` dentro del
/// `PageView` del shell: se mantiene viva al salir de pantalla —para que
/// deslizar no recargue— y por eso su `initState` no vuelve a ejecutarse
/// nunca. Sin este aviso, dar de alta un hábito desde la pestaña Hábitos deja
/// a Hoy enseñando la lista vieja hasta que el usuario refresca a mano.
///
/// Es un contador y no un `bool` a propósito: incrementar siempre notifica,
/// mientras que poner `true` sobre `true` no lo haría y se perdería el
/// segundo cambio seguido.
final ValueNotifier<int> habitosCambiadosNotifier = ValueNotifier<int>(0);

/// Señala que los hábitos han cambiado. Lo llama quien los modifica.
void notificarHabitosCambiados() {
  habitosCambiadosNotifier.value++;
}
