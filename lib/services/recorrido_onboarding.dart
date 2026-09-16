import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Un paso del recorrido guiado.
class PasoRecorrido {
  /// Qué se señala. Null vela la pantalla entera, sin hueco.
  final GlobalKey? ancla;

  final String titulo;
  final String cuerpo;

  /// Texto del botón que avanza. Null lo convierte en un paso de ACCIÓN: no
  /// hay botón, se avanza haciendo lo que se señala, y quien detecte esa
  /// acción llama a [RecorridoOnboarding.avanzar].
  final String? textoBoton;

  const PasoRecorrido({
    this.ancla,
    required this.titulo,
    required this.cuerpo,
    this.textoBoton,
  });
}

/// El recorrido guiado de la primera vez.
///
/// NO sabe qué recorrido hay: recibe los pasos ya construidos. Así los textos
/// no son una dependencia suya y puede existir antes que ellos.
///
/// Se pinta como entrada del Overlay RAÍZ, no dentro de una pantalla. Dos de
/// los pasos ocurren en rutas empujadas (el botón de nuevo hábito y la
/// pantalla de creación) y una marca pintada dentro del shell quedaría
/// debajo de ellas. El Overlay raíz flota sobre todas las rutas, y el hueco
/// del CoachMark sigue dejando pasar los toques al elemento real.
class RecorridoOnboarding extends ChangeNotifier {
  RecorridoOnboarding._();

  static final RecorridoOnboarding instancia = RecorridoOnboarding._();

  List<PasoRecorrido> _pasos = const [];
  int _indice = 0;
  OverlayEntry? _entrada;
  String? _textoSaltar;
  int _reintentos = 0;

  /// True mientras el recorrido está en pantalla. Lo consultan las pantallas
  /// para engancharse su ancla y el shell para bloquear la navegación.
  bool get activo => _entrada != null;

  PasoRecorrido? get pasoActual =>
      _indice < _pasos.length ? _pasos[_indice] : null;

  void iniciar(
    BuildContext context, {
    required List<PasoRecorrido> pasos,
    String? textoSaltar,
  }) {
    if (activo || pasos.isEmpty) return;
    _pasos = pasos;
    _indice = 0;
    _textoSaltar = textoSaltar;
    _reintentos = 0;
    _entrada = OverlayEntry(builder: _construir);
    Overlay.of(context, rootOverlay: true).insert(_entrada!);
    notifyListeners();
    _repintarTrasElFrame();
  }

  /// Un paso adelante. La llaman tanto el botón de los pasos de explicación
  /// como las pantallas cuando detectan la acción de un paso de acción.
  void avanzar() {
    if (!activo) return;
    _indice++;
    if (_indice >= _pasos.length) {
      terminar();
      return;
    }
    _reintentos = 0;
    notifyListeners();
    _repintarTrasElFrame();
  }

  /// Un paso atrás. Existe para deshacer un avance que se dio por supuesto y
  /// no llegó a ocurrir: se abre la pantalla de creación, se avanza a su
  /// marca, y el usuario se vuelve con el botón de atrás sin guardar. Sin
  /// esto, la marca se quedaría velando una pantalla que ya no está.
  ///
  /// No baja del primer paso.
  void retroceder() {
    if (!activo || _indice == 0) return;
    _indice--;
    _reintentos = 0;
    notifyListeners();
    _repintarTrasElFrame();
  }

  /// Termina el recorrido, se haya completado o abandonado. En los dos casos
  /// se marca como hecho: quien lo salta no quiere que le vuelva a saltar
  /// solo en el siguiente arranque. Para volver a verlo está el menú.
  void terminar() {
    if (!activo) return;
    _entrada!.remove();
    _entrada = null;
    _pasos = const [];
    _indice = 0;
    _textoSaltar = null;
    RecorridoService.marcarHecho();
    notifyListeners();
  }

  /// La ancla del paso puede no estar pintada todavía: se acaba de cambiar de
  /// pestaña, o la ruta aún se está abriendo. Se reintenta unos frames y, si
  /// no aparece, el paso se enseña sin hueco. Feo, pero no deja al usuario
  /// encerrado mirando un velo negro sin explicación.
  void _repintarTrasElFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!activo) return;
      _entrada!.markNeedsBuild();
      final ancla = pasoActual?.ancla;
      if (ancla != null && rectDeAncla(ancla) == null && _reintentos < 20) {
        _reintentos++;
        _repintarTrasElFrame();
      }
    });
  }

  Widget _construir(BuildContext context) {
    final paso = pasoActual;
    if (paso == null) return const SizedBox.shrink();
    return CoachMark(
      foco: paso.ancla == null ? null : rectDeAncla(paso.ancla!),
      titulo: paso.titulo,
      cuerpo: paso.cuerpo,
      textoBoton: paso.textoBoton,
      onBoton: paso.textoBoton == null ? null : avanzar,
      textoSaltar: _textoSaltar,
      onSaltar: terminar,
    );
  }
}
