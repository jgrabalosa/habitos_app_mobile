import 'package:flutter/widgets.dart';

/// Las anclas del recorrido guiado, en un solo sitio.
///
/// Hoy queda una sola: la del check del hábito, donde la pista de Hoy señala
/// el círculo tras guardar el primer hábito. Es estado global a conciencia:
/// el ancla vive en la lista de Hoy y la pista la busca desde el shell.
///
/// REGLA: la pantalla se engancha el ancla SÓLO mientras el recorrido está
/// activo (`RecorridoOnboarding.instancia.activo`). Una GlobalKey no puede
/// estar en dos widgets a la vez.
class AnclasRecorrido {
  AnclasRecorrido._();

  static final GlobalKey checkHabito = GlobalKey(
    debugLabel: 'recorrido: check del hábito',
  );
}
