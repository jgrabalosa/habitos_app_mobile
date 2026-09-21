import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Si el usuario ha entrado ya alguna vez en el detalle de un hábito.
///
/// Mientras no lo haya hecho, el chevron de la primera tarjeta de Hoy da un
/// empujón de vez en cuando para enseñarle que la tarjeta lleva a algún
/// sitio. En cuanto entra una vez —desde Hoy, desde Hábitos o desde donde
/// sea— el empujón se acaba para siempre: lo que ya se sabe no hace falta
/// repetirlo.
///
/// Es un `ValueNotifier` y no una lectura puntual por lo mismo que
/// `habitosCambiadosNotifier`: Hoy se mantiene viva dentro del `PageView` y
/// su `initState` no se repite. Si el detalle se abre desde Hábitos, Hoy
/// tiene que enterarse sin volver a construirse.
///
/// Empieza en `true` a propósito: hasta leer la preferencia no se sabe, y
/// ante la duda es mejor no empujar que empujar a quien ya lo sabe.
final ValueNotifier<bool> detalleDescubiertoNotifier =
    ValueNotifier<bool>(true);

const _clave = 'detalle_habito_descubierto';

/// Lee de disco si ya se descubrió. Lo llama Hoy al arrancar.
Future<void> cargarDetalleDescubierto() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    detalleDescubiertoNotifier.value = prefs.getBool(_clave) ?? false;
  } catch (_) {
    // Sin preferencias no se empuja: es una pista, no algo que pueda fallar.
    detalleDescubiertoNotifier.value = true;
  }
}

/// Marca que ya se ha entrado en un detalle. Lo llama el propio detalle.
Future<void> marcarDetalleDescubierto() async {
  detalleDescubiertoNotifier.value = true;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clave, true);
  } catch (_) {
    // Si no se puede guardar, volverá a empujar la próxima vez que se abra
    // la app. Molesta poco y no merece un error.
  }
}
