import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/coleccion_screen.dart';

/// El catalogo real que siembra CatalogoGamificacionInitializer: cuatro
/// categorias de backend distintas, y dos de ellas ('Protección' y
/// 'Consumible') son lo mismo de cara al usuario.
Map<String, List<dynamic>> catalogoReal() => {
      'Protección': [
        {'codigo': 'ESCUDO_RACHA'},
      ],
      'Tema': [
        {'codigo': 'TEMA_BASICO_CLARO'},
        {'codigo': 'TEMA_OCEANO'},
      ],
      'Avatar': [
        {'codigo': 'AVATAR_ZORRO'},
      ],
      'Consumible': [
        {'codigo': 'COMIDA_BASICA'},
      ],
    };

List<String> codigos(List<dynamic> productos) =>
    [for (final p in productos) p['codigo'] as String];

void main() {
  test('Consumible no abre seccion propia: cae en la misma que Protección', () {
    final secciones = repartirEnSecciones(catalogoReal());

    expect(secciones.length, 3,
        reason: 'Avatares, Consumibles y Temas — nada de una cuarta seccion '
            'con el literal crudo "Consumible"');

    final consumibles = secciones
        .firstWhere((s) => s.$1.categoriasBackend.contains('Protección'));
    expect(codigos(consumibles.$2), ['ESCUDO_RACHA', 'COMIDA_BASICA']);
  });

  test('el titulo de esa seccion esta traducido en los tres idiomas', () {
    final consumibles = repartirEnSecciones(catalogoReal())
        .firstWhere((s) => s.$1.categoriasBackend.contains('Consumible'))
        .$1;

    final esperado = {'es': 'Consumibles', 'en': 'Consumables', 'pt': 'Consumíveis'};
    for (final idioma in esperado.keys) {
      final l = lookupAppLocalizations(Locale(idioma));
      expect(consumibles.titulo(l), esperado[idioma],
          reason: 'idioma $idioma');
    }
  });

  test('una categoria desconocida sigue cayendo a su texto crudo', () {
    final secciones = repartirEnSecciones({
      ...catalogoReal(),
      'Marco': [
        {'codigo': 'MARCO_DORADO'},
      ],
    });

    expect(secciones.length, 4);
    final ultima = secciones.last.$1;
    expect(ultima.titulo(lookupAppLocalizations(const Locale('en'))), 'Marco');
  });

  test('una seccion sin productos no se pinta', () {
    final secciones = repartirEnSecciones({
      'Avatar': [
        {'codigo': 'AVATAR_ZORRO'},
      ],
    });

    expect(secciones.length, 1);
    expect(secciones.single.$1.categoriasBackend, ['Avatar']);
  });
}
