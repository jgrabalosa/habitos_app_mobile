import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:habitos_app_mobile/widgets/identidad_ui.dart';

/// En Dulce el rosa de relleno no llega a 3:1 como trazo: el borde de «hoy»
/// y el icono de la pestaña activa tienen que ir en `primaryTrazo`.
///
/// La celda de Dulce es un `ShapeDecoration` con un `BordeLapiz`; las demás,
/// un `BoxDecoration` con `Border`. Estas dos ayudas leen las dos formas.
Color? rellenoDe(Decoration d) =>
    d is ShapeDecoration ? d.color : (d as BoxDecoration).color;

BorderSide ladoDe(Decoration d) => d is ShapeDecoration
    ? (d.shape as OutlinedBorder).side
    : (d as BoxDecoration).border!.top;

void main() {
  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  test('el borde de hoy en la celda va en primaryTrazo', () {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      final id = identidadEquipadaNotifier.value;
      final t = id.tokens;
      final celda = celdaHeatmap(
        id,
        t,
        color: t.inactivo,
        llena: false,
        esHoy: true,
      );
      expect(ladoDe(celda).color, t.primaryTrazo, reason: codigo);
    }
  });

  test('el icono de la pestaña activa va en primaryTrazo', () {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      final id = identidadEquipadaNotifier.value;
      final t = id.tokens;
      final barra = barraNavegacionIdentidad(id, t, null);
      final icono = barra.iconTheme!.resolve({WidgetState.selected});
      expect(icono!.color, t.primaryTrazo, reason: codigo);
    }
  });

  test('una celda vacía es contorno de aroVacio, sin relleno', () {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      final id = identidadEquipadaNotifier.value;
      final t = id.tokens;
      final vacia = celdaHeatmap(
        id,
        t,
        color: t.inactivo,
        llena: false,
        esHoy: false,
        vacia: true,
      );
      // Sin relleno: transparente en Profundidad y Neotokyo+, y null en Dulce,
      // donde el relleno ni se pinta.
      expect(
        rellenoDe(vacia) ?? Colors.transparent,
        Colors.transparent,
        reason: codigo,
      );
      expect(ladoDe(vacia).color, t.aroVacio, reason: codigo);

      // Hoy manda sobre vacía: su borde sigue siendo el de hoy.
      final hoyVacia = celdaHeatmap(
        id,
        t,
        color: t.inactivo,
        llena: false,
        esHoy: true,
        vacia: true,
      );
      expect(ladoDe(hoyVacia).color, t.primaryTrazo, reason: codigo);
    }
  });

  test('el botón + va a lápiz en Dulce, con el borde del botón del tema', () {
    final id = catalogoIdentidades['TEMA_DULCE']!;
    final forma = formaBotonFlotante(id, id.tokens);
    expect(forma, isA<BordeLapiz>());
    final lapiz = forma as BordeLapiz;
    expect(lapiz.radio, 999);
    expect(lapiz.side.color, id.tokens.primaryTrazo);
    expect(lapiz.side.width, 1.4);
    expect(elevacionBotonFlotante(id), 0);
  });

  test('el botón + se queda como Material en Profundidad y Neotokyo+', () {
    for (final codigo in ['TEMA_PROFUNDIDAD', 'TEMA_NEOTOKYO_PLUS']) {
      final id = catalogoIdentidades[codigo]!;
      expect(formaBotonFlotante(id, id.tokens), isNull, reason: codigo);
      expect(elevacionBotonFlotante(id), isNull, reason: codigo);
    }
  });

  test(
    'las burbujas del ritmo en las filas: 14 en Dulce y 11 en las otras',
    () {
      expect(tamanoRitmoFila(catalogoIdentidades['TEMA_DULCE']!), 14);
      expect(tamanoRitmoFila(catalogoIdentidades['TEMA_PROFUNDIDAD']!), 11);
      expect(tamanoRitmoFila(catalogoIdentidades['TEMA_NEOTOKYO_PLUS']!), 11);
    },
  );
}
