import 'package:flutter/widgets.dart';

/// Las anclas del recorrido guiado, en un solo sitio.
///
/// Es estado global a conciencia. Las cinco anclas viven en cuatro pantallas
/// y dos repos, y el controlador no puede alcanzarlas de otra forma sin
/// ensuciar cuatro firmas permanentes —una de ellas al otro lado de un
/// Navigator.push— para una función que cada instalación usa una vez.
///
/// La quinta ancla, la del botón de alimentar, no está aquí: vive en el core,
/// que no puede importar este fichero, y entra por el parámetro
/// `anclaAlimentar` de MascotaScreen. Se declara igual aquí abajo y se le pasa
/// desde el shell.
///
/// REGLA: cada pantalla se engancha su ancla SÓLO mientras el recorrido está
/// activo (`RecorridoOnboarding.instancia.activo`). Una GlobalKey no puede
/// estar en dos widgets a la vez, y sin esa guarda dos pantallas de creación
/// abiertas a la vez petarían.
class AnclasRecorrido {
  AnclasRecorrido._();

  static final GlobalKey pestanaHabitos =
      GlobalKey(debugLabel: 'recorrido: pestaña Hábitos');
  static final GlobalKey botonNuevoHabito =
      GlobalKey(debugLabel: 'recorrido: botón nuevo hábito');
  static final GlobalKey recomendados =
      GlobalKey(debugLabel: 'recorrido: hábitos recomendados');
  static final GlobalKey checkHabito =
      GlobalKey(debugLabel: 'recorrido: check del hábito');
  static final GlobalKey alimentar =
      GlobalKey(debugLabel: 'recorrido: botón de alimentar');
  static final GlobalKey valoracion =
      GlobalKey(debugLabel: 'recorrido: hoja de valoración');
}
