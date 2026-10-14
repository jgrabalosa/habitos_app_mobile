import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:habitos_app_mobile/widgets/identidad_ui.dart';

/// En Dulce el rosa de relleno no llega a 3:1 como trazo: el borde de «hoy»
/// y el icono de la pestaña activa tienen que ir en `primaryTrazo`.
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
      expect(
        (celda.border! as Border).top.color,
        t.primaryTrazo,
        reason: codigo,
      );
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
}
