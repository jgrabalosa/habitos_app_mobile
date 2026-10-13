import 'package:flutter/material.dart';

/// URL del backend de producción. Es el valor por defecto de
/// `ApiServiceCore.baseUrl` en el core; un test vigila que sigan iguales.
const String urlProduccion = 'https://api.norday.app/api';

/// Comprueba que el flavor con el que se compiló la app y la URL del backend
/// van juntos. Devuelve `null` si cuadran y, si no, el motivo.
///
/// - `produccion` sólo habla con producción: ningún AAB de Play sale
///   apuntando a staging.
/// - `prueba` nunca habla con producción: la app de prueba no escribe en
///   cuentas reales aunque se olvide el `--dart-define`.
/// - Sin flavor no se arranca: los comandos llevan siempre `--flavor`.
String? errorDeEntorno({required String? flavor, required String url}) {
  switch (flavor) {
    case 'produccion':
      return url == urlProduccion
          ? null
          : 'El flavor produccion apunta a $url, no a producción.';
    case 'prueba':
      return url == urlProduccion
          ? 'El flavor prueba apunta a producción. Falta '
                '--dart-define=NORDAY_API_URL=<url de staging>.'
          : null;
    default:
      return 'Flavor desconocido ($flavor). Lanza con --flavor prueba '
          'o --flavor produccion.';
  }
}

/// Lo único que se pinta si el entorno no cuadra: sin Firebase, sin sesión
/// y sin ninguna petición. Es sólo para desarrollo, por eso no se traduce.
class PantallaEntornoIncorrecto extends StatelessWidget {
  const PantallaEntornoIncorrecto({super.key, required this.motivo});

  final String motivo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Entorno incorrecto\n\n$motivo',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
