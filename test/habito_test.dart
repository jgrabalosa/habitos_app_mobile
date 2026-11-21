import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// El backend manda la categoría aplanada en tres campos (HabitoDTO).
void main() {
  test('fromJson lee la categoría aplanada', () {
    final habito = Habito.fromJson({
      'habitoId': 10,
      'nombre': 'Leer',
      'frecuencia': 'DIARIO',
      'meta': 1,
      'activo': true,
      'categoriaId': 3,
      'categoriaCodigo': 'CAT_ESTUDIO',
      'categoriaNombre': 'Estudio',
    });

    expect(habito.categoriaId, 3);
    expect(habito.categoriaCodigo, 'CAT_ESTUDIO');
    expect(habito.categoriaNombre, 'Estudio');
  });

  test('fromJson sin categoría deja los tres campos a null', () {
    final habito = Habito.fromJson({
      'habitoId': 10,
      'nombre': 'Leer',
      'frecuencia': 'DIARIO',
      'meta': 1,
      'activo': true,
      'categoriaId': null,
      'categoriaCodigo': null,
      'categoriaNombre': null,
    });

    expect(habito.categoriaId, isNull);
    expect(habito.categoriaCodigo, isNull);
    expect(habito.categoriaNombre, isNull);
  });

  Map<String, dynamic> base() => {
    'habitoId': 10,
    'nombre': 'Leer',
    'frecuencia': 'DIARIO',
    'meta': 1,
    'activo': true,
  };

  test('fromJson lee el icono', () {
    final habito = Habito.fromJson({...base(), 'icono': 'bookOpen'});
    expect(habito.codigoIcono, 'bookOpen');
    expect(habito.icono, LucideIcons.bookOpen);
  });

  test(
    'fromJson sin icono, o con icono nulo, lo deja a null y dibuja sparkles',
    () {
      for (final json in [
        base(),
        {...base(), 'icono': null},
      ]) {
        final habito = Habito.fromJson(json);
        expect(habito.codigoIcono, isNull);
        expect(habito.icono, LucideIcons.sparkles);
      }
    },
  );

  test('fromJson con un icono que esta versión no conoce no falla', () {
    final habito = Habito.fromJson({...base(), 'icono': 'iconoDelFuturo'});
    expect(habito.codigoIcono, 'iconoDelFuturo');
    expect(habito.icono, LucideIcons.sparkles);
  });
}
