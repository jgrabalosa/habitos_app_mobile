import 'package:norday_flutter_core/norday_flutter_core.dart';

bool _enCurso = false;

/// Pide de nuevo la identidad equipada al backend cuando la app vuelve a
/// primer plano, para que un fallo de red al arrancar o un cambio hecho desde
/// otro móvil se corrijan sin cerrar la app.
///
/// La verdad es el backend. Si la petición falla, el core deja en este móvil
/// la última identidad que el backend confirmó y reintenta por su cuenta.
///
/// El resultado (si el usuario posee identidad) se ignora a propósito: el
/// onboarding de elección solo se decide en el login y en el splash, nunca al
/// volver a primer plano.
///
/// No se solapan peticiones: si una sigue en curso, la nueva no hace nada.
Future<void> recargarIdentidadAlVolver(
  int usuarioId, {
  Future<bool?> Function(int)? cargar,
}) async {
  if (usuarioId <= 0 || _enCurso) return;
  _enCurso = true;
  try {
    await (cargar ?? Equipamiento.cargarDeUsuarioSiSePuede)(usuarioId);
  } catch (_) {
    // El aspecto nunca debe romper la app.
  } finally {
    _enCurso = false;
  }
}
