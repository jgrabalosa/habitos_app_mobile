import 'package:norday_flutter_core/norday_flutter_core.dart';

import 'app_refresh.dart';
import 'identidad_al_volver.dart';

/// Lo que pasa al volver a primer plano. Reúne los refrescos de la app, de la
/// mascota y de la identidad en un único punto, para que ninguno se quede fuera.
///
/// La mini Nori vive fuera de Hoy y solo se refrescaba al marcar o desmarcar un
/// hábito, así que quien dejaba la app abierta de un día para otro veía el
/// ánimo de ayer. Por eso se avisa aquí. El ánimo lo calcula el backend en el
/// momento de pedirlo, así que esto también cubre el cambio de día.
///
/// No espera a nada: ninguno de los tres puede bloquear el regreso a la app.
void alVolverAPrimerPlano(
  int usuarioId, {
  Future<bool?> Function(int)? recargarIdentidad,
}) {
  solicitarRefrescoApp();
  solicitarRefrescoMascota();
  recargarIdentidadAlVolver(usuarioId, cargar: recargarIdentidad);
}
