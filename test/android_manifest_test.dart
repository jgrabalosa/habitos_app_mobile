import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String manifiesto;

  setUpAll(() {
    manifiesto = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
  });

  test('no queda el cliente de Google de otro proyecto', () {
    expect(manifiesto, isNot(contains('177339814167')));
  });

  test('no hay ningún meta-data después de </application>', () {
    final cierre = manifiesto.indexOf('</application>');
    expect(cierre, isNonNegative);
    final despues = manifiesto.substring(cierre);
    expect(despues, isNot(contains('<meta-data')));
  });

  group('icono de las notificaciones', () {
    // Android pinta el icono pequeño de una notificación solo con su
    // transparencia: sin uno propio usa el de la app, que es opaco, y sale un
    // cuadrado. Lo genera `tool/icono_notificacion.py`.
    test('el manifiesto lo declara, con su color, dentro de <application>', () {
      final aplicacion = manifiesto.substring(
        manifiesto.indexOf('<application'),
        manifiesto.indexOf('</application>'),
      );
      expect(
        aplicacion,
        matches(
          RegExp(
            r'com\.google\.firebase\.messaging\.default_notification_icon"\s*'
            r'android:resource="@drawable/ic_stat_norday"',
          ),
        ),
      );
      expect(
        aplicacion,
        matches(
          RegExp(
            r'com\.google\.firebase\.messaging\.default_notification_color"\s*'
            r'android:resource="@color/notificacion_acento"',
          ),
        ),
      );
      expect(
        File('android/app/src/main/res/values/colors.xml').readAsStringSync(),
        contains('<color name="notificacion_acento">#27C76F</color>'),
      );
    });

    for (final (densidad, px) in [
      ('mdpi', 24),
      ('hdpi', 36),
      ('xhdpi', 48),
      ('xxhdpi', 72),
      ('xxxhdpi', 96),
    ]) {
      test('en $densidad mide $px px y es blanco sobre transparente', () async {
        final fichero = File(
          'android/app/src/main/res/drawable-$densidad/ic_stat_norday.png',
        );
        expect(fichero.existsSync(), isTrue);
        final codec = await ui.instantiateImageCodec(fichero.readAsBytesSync());
        final imagen = (await codec.getNextFrame()).image;
        expect(imagen.width, px);
        expect(imagen.height, px);
        final datos = (await imagen.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        ))!;
        var transparentes = 0;
        var visibles = 0;
        for (var i = 0; i < datos.lengthInBytes; i += 4) {
          final alfa = datos.getUint8(i + 3);
          if (alfa == 0) {
            transparentes++;
            continue;
          }
          visibles++;
          expect(datos.getUint8(i), 255, reason: 'rojo en el píxel ${i ~/ 4}');
          expect(datos.getUint8(i + 1), 255);
          expect(datos.getUint8(i + 2), 255);
        }
        // Una silueta, no un cuadrado lleno ni una imagen vacía.
        expect(transparentes, greaterThan(px * px ~/ 3));
        expect(visibles, greaterThan(px * px ~/ 10));
      });
    }
  });
}
