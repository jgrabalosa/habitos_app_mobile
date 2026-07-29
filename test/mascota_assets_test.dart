import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/theme/mascota_assets.dart';

/// Al quitar el respaldo de emoji, un PNG que falte ya no degrada: revienta al
/// pintar. Aqui se cargan de verdad desde el bundle, igual que hara
/// Image.asset, para que una errata en el nombre no llegue al movil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fases = ['HUEVO', 'CRIA', 'ADULTO'];
  const estados = ['feliz', 'triste', 'dormida'];

  test('las 9 combinaciones de fase y estado existen en el bundle', () async {
    for (final fase in fases) {
      for (final estado in estados) {
        final ruta = assetMascota(fase: fase, estado: estado);
        final datos = await rootBundle.load(ruta);
        expect(datos.lengthInBytes, greaterThan(0), reason: '$fase/$estado -> $ruta');
      }
    }
  });

  test('el estado del backend se traduce al sufijo visual acordado', () {
    expect(assetMascota(fase: 'HUEVO', estado: 'feliz'),
        'assets/mascota/Nori_huevo_sonriente.png');
    expect(assetMascota(fase: 'CRIA', estado: 'dormida'),
        'assets/mascota/Nori_cria_dormido.png');
    expect(assetMascota(fase: 'ADULTO', estado: 'triste'),
        'assets/mascota/Nori_adulto_triste.png');
  });

  test('una fase o un estado desconocidos caen a un asset que existe', () async {
    // El backend puede anadir una fase que este cliente aun no conozca.
    for (final ruta in [
      assetMascota(fase: 'ANCIANO', estado: 'feliz'),
      assetMascota(fase: 'CRIA', estado: 'eufori'),
      assetMascota(fase: null, estado: null),
    ]) {
      final datos = await rootBundle.load(ruta);
      expect(datos.lengthInBytes, greaterThan(0), reason: ruta);
    }
  });

  test('sin datos todavia, la mascota no se pinta contenta', () {
    expect(assetMascota(fase: null, estado: null),
        'assets/mascota/Nori_huevo_triste.png');
  });
}
