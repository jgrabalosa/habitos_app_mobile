import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/entorno.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

const _staging = 'https://staging-api.norday.app/api';

void main() {
  test('produccion contra producción arranca', () {
    expect(errorDeEntorno(flavor: 'produccion', url: urlProduccion), isNull);
  });

  test('produccion contra staging no arranca', () {
    expect(errorDeEntorno(flavor: 'produccion', url: _staging), isNotNull);
  });

  test('prueba contra staging arranca', () {
    expect(errorDeEntorno(flavor: 'prueba', url: _staging), isNull);
  });

  test('prueba contra producción no arranca', () {
    expect(errorDeEntorno(flavor: 'prueba', url: urlProduccion), isNotNull);
  });

  test('sin flavor o con uno desconocido no arranca', () {
    expect(errorDeEntorno(flavor: null, url: urlProduccion), isNotNull);
    expect(errorDeEntorno(flavor: 'otro', url: _staging), isNotNull);
  });

  test('urlProduccion es el valor por defecto del core', () {
    expect(ApiServiceCore.baseUrl, urlProduccion);
  });
}
