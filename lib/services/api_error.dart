/// Motor: taxonomia de errores de red, generica y sin dominio. Dart puro
/// (sin Flutter ni l10n), asi se extrae tal cual al paquete compartido.
enum TipoErrorApi {
  /// No se pudo abrir la conexion: sin red, DNS caido, servidor inalcanzable
  /// o handshake TLS fallido. El movil no llego a hablar con el backend.
  sinConexion,

  /// La peticion salio pero el backend no contesto a tiempo.
  timeout,

  /// 401/403. Se distingue del resto de 4xx porque la app puede reaccionar
  /// mandando al login en vez de pedir que se reintente.
  noAutorizado,

  /// Resto de 4xx: la peticion no es valida para el estado actual (saldo
  /// insuficiente, email duplicado...). El "por que" lo sabe la pantalla.
  peticionInvalida,

  /// 5xx: el backend esta roto. Reintentar mas tarde, no cambiar los datos.
  servidor,

  /// Codigo 2xx pero el cuerpo no es el que esperaba el cliente: JSON
  /// malformado, un campo que falta o llega con otro tipo.
  respuestaInesperada,
}

/// Error de red ya clasificado. Lo lanza [ApiService] y lo traduce
/// `MensajesError`; ninguna pantalla deberia inspeccionar [cuerpo].
class ApiException implements Exception {
  final TipoErrorApi tipo;

  /// Codigo HTTP, cuando lo hubo. Null en fallos de transporte.
  final int? codigoEstado;

  /// Cuerpo crudo del backend. Sirve para logs y para Crashlytics, pero
  /// **no se le ensena al usuario**: el backend responde en un solo idioma
  /// y la app habla tres.
  final String? cuerpo;

  const ApiException(this.tipo, {this.codigoEstado, this.cuerpo});

  @override
  String toString() =>
      'ApiException(${tipo.name}${codigoEstado != null ? ', HTTP $codigoEstado' : ''})';
}
