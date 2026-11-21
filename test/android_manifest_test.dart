import 'dart:io';

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
}
