import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/theme/avatares.dart';

/// Las rutas de catalogoAvatares se escriben a mano: una errata o un PNG que
/// falte no lo ve flutter analyze, solo se nota al pintar la pantalla. Aqui se
/// cargan de verdad desde el bundle, que es lo mismo que hara Image.asset.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('los 10 avatares del catalogo existen en el bundle', () async {
    expect(catalogoAvatares.length, 10);

    for (final entrada in catalogoAvatares.entries) {
      final datos = await rootBundle.load(entrada.value.asset);
      expect(datos.lengthInBytes, greaterThan(0),
          reason: '${entrada.key} -> ${entrada.value.asset}');
    }
  });

  test('cada avatar apunta al PNG que lleva su propio codigo', () {
    for (final entrada in catalogoAvatares.entries) {
      expect(entrada.value.asset, 'assets/avatares/${entrada.key}.png');
    }
  });
}
