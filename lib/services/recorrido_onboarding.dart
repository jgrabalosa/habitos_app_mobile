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
  String? _textoContinuar;
  int _reintentos = 0;
  bool _buscando = false;
  bool _pausado = false;

  /// True cuando se ha agotado el margen sin encontrar el ancla del paso. El
  /// paso saca entonces un botón para seguir, también si es de acción.
  bool _anclaPerdida = false;

  /// Último rectángulo pintado. Se guarda para no repintar en cada frame
  /// mientras se busca: sólo cuando cambia de verdad.
  Rect? _foco;

  /// Frames de gracia antes de ofrecer una salida. No detiene la búsqueda:
  /// es el margen a partir del cual el paso deja de fiarse del hueco.
  static const int _margenSalida = 60;

  /// Frames tras los cuales se deja de buscar. Generoso a propósito —unos
  /// cinco segundos—, pero acotado: buscar para siempre significa pedir un
  /// frame nuevo en cada frame, y eso es la pantalla repintándose sin parar.
  static const int _limiteBusqueda = 300;

  /// True mientras el recorrido está en pantalla. Lo consultan las pantallas
  /// para engancharse su ancla y el shell para bloquear la navegación.
  bool get activo => _entrada != null;

  PasoRecorrido? get pasoActual =>
      _indice < _pasos.length ? _pasos[_indice] : null;

  void iniciar(
    BuildContext context, {
    required List<PasoRecorrido> pasos,
    String? textoSaltar,
    String? textoContinuar,
  }) {
    if (activo || pasos.isEmpty) return;
    _pasos = pasos;
    _indice = 0;
    _textoSaltar = textoSaltar;
    _textoContinuar = textoContinuar;
    _entrada = OverlayEntry(builder: _construir);
    Overlay.of(context, rootOverlay: true).insert(_entrada!);
    notifyListeners();
    _buscarAncla();
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
    notifyListeners();
    _buscarAncla();
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
    notifyListeners();
    _buscarAncla();
  }

  /// Deja de pintar sin perder el sitio. Para cuando el usuario tiene que
  /// poder usar una pantalla entera —rellenar un formulario y guardarlo—: el
  /// velo se lleva por delante todo lo que no sea el hueco, y ahí eso estorba
  /// más de lo que ayuda.
  ///
  /// No cambia [activo]: el recorrido sigue en marcha y las anclas siguen
  /// enganchadas.
  void pausar() {
    if (!activo || _pausado) return;
    _pausado = true;
    _entrada!.markNeedsBuild();
  }

  void reanudar() {
    if (!activo || !_pausado) return;
    _pausado = false;
    _buscarAncla();
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
    _textoContinuar = null;
    _foco = null;
    _anclaPerdida = false;
    _pausado = false;
    RecorridoService.marcarHecho();
    notifyListeners();
  }

  /// Empieza a buscar el ancla del paso actual. Sólo puede haber una búsqueda
  /// en marcha: si ya la hay, seguirá sola con el paso nuevo.
  void _buscarAncla() {
    _reintentos = 0;
    _anclaPerdida = false;
    _foco = null;
    if (_buscando) return;
    _buscando = true;
    _intentar();
  }

  /// El ancla del paso puede no estar pintada todavía: se acaba de cambiar de
  /// pestaña, la ruta aún se está abriendo, o la bienvenida está terminando su
  /// animación de cierre.
  ///
  /// Se busca frame a frame. Pasado [_margenSalida] el paso saca un botón para
  /// seguir sin dejar de buscar, porque un paso de acción sin hueco no tiene
  /// nada que tocar: las barreras del velo cubren toda la pantalla y el
  /// usuario queda encerrado. Pasado [_limiteBusqueda] se deja de buscar, ya
  /// con la salida puesta.
  void _intentar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!activo) {
        _buscando = false;
        return;
      }

      final ancla = pasoActual?.ancla;
      final rect = ancla == null ? null : rectDeAncla(ancla);
      if (rect != _foco) {
        _foco = rect;
        _entrada!.markNeedsBuild();
      }

      if (ancla == null || rect != null) {
        _buscando = false;
        return;
      }

      _reintentos++;
      if (_reintentos == _margenSalida) {
        _anclaPerdida = true;
        _entrada!.markNeedsBuild();
      }
      if (_reintentos >= _limiteBusqueda) {
        _buscando = false;
        return;
      }
      _intentar();
    });
  }

  Widget _construir(BuildContext context) {
    final paso = pasoActual;
    if (paso == null || _pausado) return const SizedBox.shrink();
    // Un paso de acción no lleva botón, pero si su ancla no aparece hay que
    // darle uno: sin hueco no hay nada que tocar.
    final textoBoton =
        paso.textoBoton ?? (_anclaPerdida ? _textoContinuar : null);
    return CoachMark(
      foco: _foco,
      titulo: paso.titulo,
      cuerpo: paso.cuerpo,
      textoBoton: textoBoton,
      onBoton: textoBoton == null ? null : avanzar,
      textoSaltar: _textoSaltar,
      onSaltar: terminar,
    );
  }
}
