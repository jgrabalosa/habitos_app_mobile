import 'dart:async';

import 'package:norday_flutter_core/norday_flutter_core.dart';

import 'app_refresh.dart';
import 'identidad_al_volver.dart';

/// Lo que pasa al volver a primer plano. Reúne en un único punto cuatro cosas:
/// el refresco de las pantallas de la app, el de la mascota, el de la identidad
/// y el registro del aviso del móvil (el token de FCM).
///
/// La mini Nori vive fuera de Hoy y solo se refrescaba al marcar o desmarcar un
/// hábito, así que quien dejaba la app abierta de un día para otro veía el
/// ánimo de ayer. Por eso se avisa aquí. El ánimo lo calcula el backend en el
/// momento de pedirlo, así que esto también cubre el cambio de día.
///
/// El aviso se registra aquí porque el permiso de notificaciones se concede
/// muchas veces fuera de la app, en Ajustes del sistema: al volver, el token
/// ya puede enviarse. El registro es idempotente, así que no reenvía si no
/// cambió.
///
/// No espera a nada: ninguno de los cuatro puede bloquear el regreso a la app,
/// y un fallo al registrar el aviso nunca llega a quien llama.
void alVolverAPrimerPlano(
  int usuarioId, {
  Future<bool?> Function(int)? recargarIdentidad,
  Future<void> Function(int)? registrarAviso,
}) {
  solicitarRefrescoApp();
  solicitarRefrescoMascota();
  recargarIdentidadAlVolver(usuarioId, cargar: recargarIdentidad);
  if (usuarioId > 0) {
    unawaited(_registrarAviso(usuarioId, registrarAviso));
  }
}

Future<void> _registrarAviso(
  int usuarioId,
  Future<void> Function(int)? registrar,
) async {
  try {
    await (registrar ??
        (id) => NotificacionesService.registrarSiHayPermiso(id))(usuarioId);
  } catch (_) {
    // El aviso se reintenta en el siguiente regreso a la app o login.
  }
}
