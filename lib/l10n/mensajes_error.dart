import 'package:flutter/widgets.dart';
import '../services/api_error.dart';
import 'app_localizations.dart';

/// Traduce un error de red al idioma activo, igual que [Catalogos] hace con
/// los codigos que manda el backend.
///
/// El texto crudo del backend nunca llega al usuario: responde en un solo
/// idioma y la app habla tres.
class MensajesError {
  /// [generico] es el mensaje propio de la pantalla ("No se pudo crear el
  /// habito"). Se usa cuando el fallo no es de red, que es justo cuando el
  /// contexto de la pantalla informa mas que un texto de conexion.
  static String de(BuildContext context, Object error, {String? generico}) {
    final l = AppLocalizations.of(context)!;
    if (error is! ApiException) return generico ?? l.errorGenerico;

    return switch (error.tipo) {
      TipoErrorApi.sinConexion => l.errorSinConexion,
      TipoErrorApi.timeout => l.errorTimeout,
      TipoErrorApi.servidor => l.errorServidor,
      TipoErrorApi.noAutorizado => l.errorSesionCaducada,
      TipoErrorApi.respuestaInesperada => l.errorRespuesta,
      TipoErrorApi.peticionInvalida => generico ?? l.errorGenerico,
    };
  }
}
