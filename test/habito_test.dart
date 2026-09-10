import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/models/habito.dart';

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
}
