import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../models/habito.dart';
import '../models/minutos.dart';
import '../models/registro.dart';

/// Disparadores: los endpoints que sí saben de hábitos, registros y
/// categorías. Todo lo genérico —sesión, usuario, gamificación, tienda,
/// mascota— vive en `ApiServiceCore`, dentro de norday_flutter_core.
///
/// Se apoya en la tubería del motor ([ApiServiceCore.enviar], `verificar`,
/// `parsear`) para que un fallo de red se clasifique igual aquí que allí:
/// las pantallas solo ven `ApiException`.
class ApiServiceHabitos {
  static const String _baseUrl = ApiServiceCore.baseUrl;

  // ── Hábitos ────────────────────────────────────────────
  static Future<Habito> getHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.get(
        Uri.parse('$_baseUrl/habitos/$habitoId'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
      () => Habito.fromJson(jsonDecode(response.body)),
    );
  }

  static Future<List<Map<String, dynamic>>> getResumenHabitos(
    int usuarioId,
  ) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.get(
        Uri.parse('$_baseUrl/habitos/usuario/$usuarioId/resumen'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (item) => {
              'habito': Habito.fromJson(item['habito']),
              'totalCompletados': item['totalCompletados'] ?? 0,
            },
          )
          .toList();
    });
  }

  static Future<void> activarHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.patch(
        Uri.parse('$_baseUrl/habitos/$habitoId/activar'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
  }

  static Future<void> desactivarHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.patch(
        Uri.parse('$_baseUrl/habitos/$habitoId/desactivar'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
  }

  /// La pantalla de Hoy entera (`GET /habitos/usuario/{id}/hoy`): las dos
  /// secciones, la tira, el avance del día y los niveles de ritmo. Con
  /// [fecha] (`AAAA-MM-DD`) se mira otro día de la tira; sin ella, hoy en la
  /// zona del usuario.
  static Future<Map<String, dynamic>> getHoy(
    int usuarioId, {
    String? fecha,
  }) async {
    final headers = await ApiServiceCore.getHeaders();
    final fechaParam = fecha != null ? '?fecha=$fecha' : '';
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.get(
        Uri.parse('$_baseUrl/habitos/usuario/$usuarioId/hoy$fechaParam'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
      () => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// La semana pasada (`GET /habitos/usuario/{id}/semana-pasada`, T-055): lo
  /// que se hizo de lunes a domingo. Mismo 403/404 que `/hoy`.
  static Future<Map<String, dynamic>> getSemanaPasada(int usuarioId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.get(
        Uri.parse('$_baseUrl/habitos/usuario/$usuarioId/semana-pasada'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
      () => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<Map<String, dynamic>> getHabitoDetalle(
    int habitoId, {
    String? mes,
  }) async {
    final headers = await ApiServiceCore.getHeaders();
    final mesParam = mes != null ? '?mes=$mes' : '';
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.get(
        Uri.parse('$_baseUrl/habitos/$habitoId/detalle$mesParam'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
      () => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // ── Registros ──────────────────────────────────────────
  static Future<void> actualizarNotaRegistro(
    int registroId,
    String nota,
  ) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.put(
        Uri.parse('$_baseUrl/registros/$registroId/nota'),
        headers: headers,
        body: jsonEncode({'nota': nota}),
      ),
    );
    ApiServiceCore.verificar(response);
  }

  static Future<Map<String, dynamic>> getProgresoHoy(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.get(
        Uri.parse('$_baseUrl/registros/habito/$habitoId/hoy'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
      () => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<List<dynamic>> getRegistrosHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.get(
        Uri.parse('$_baseUrl/registros/habito/$habitoId'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
      () => jsonDecode(response.body) as List<dynamic>,
    );
  }

  /// Deshace un completado. El backend sólo lo permite si es el último
  /// registro del hábito y si guardó su reversión; en los casos contrarios
  /// responde 409. La fecha puede ser hoy o un día pasado.
  static Future<void> deshacerRegistro(int registroId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.delete(
        Uri.parse('$_baseUrl/registros/$registroId'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
  }

  /// Marca un completado. En un hábito de veces se llama sin [minutos] ni
  /// [clave], exactamente como siempre.
  ///
  /// En uno de minutos, [minutos] es obligatorio (1-600: sin él el backend
  /// responde 409) y [clave] es un UUID nuevo por cada envío: si el mismo
  /// envío llega dos veces, el backend devuelve el original sin registrar
  /// nada más, y entonces puede responder 200 en vez de 201. El body viaja con
  /// todos los valores como texto, que es lo que lee el backend.
  static Future<Map<String, dynamic>> completarHabito(
    int habitoId, {
    String nota = '',
    String? fecha,
    int? minutos,
    String? clave,
    String? origen,
  }) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.post(
        Uri.parse('$_baseUrl/registros/completar/$habitoId'),
        headers: headers,
        body: cuerpoCompletar(
          nota: nota,
          fecha: fecha,
          minutos: minutos,
          clave: clave,
          origen: origen,
        ),
      ),
    );
    ApiServiceCore.verificar(
      response,
      ok: clave == null ? const [201] : const [200, 201],
    );
    return ApiServiceCore.parsear(
      () => leerCompletado(jsonDecode(response.body)),
    );
  }

  /// El body de completar, tal como sale por la red. Un hábito de veces lo
  /// llama sin los campos de minutos y sale idéntico al de antes de existir:
  /// `{"nota":""}`, o con `fecha` si se marca otro día.
  @visibleForTesting
  static String cuerpoCompletar({
    String nota = '',
    String? fecha,
    int? minutos,
    String? clave,
    String? origen,
  }) => jsonEncode({
    'nota': nota,
    // Elemento null-aware: con `fecha` a null la clave no se envía,
    // exactamente igual que con el `if` anterior. Lo mismo con los campos
    // de minutos, que un hábito de veces no manda.
    'fecha': ?fecha,
    'minutos': ?minutos?.toString(),
    'clave': ?clave,
    'origen': ?origen,
  });

  /// El body del alta (POST) y de la edición (PUT) de un hábito, tal como sale
  /// por la red. Sin [unidad] ni [minutosObjetivo] (un hábito de veces) sale
  /// idéntico al de antes de existir los de minutos: campo ausente = sin
  /// cambio en el backend.
  @visibleForTesting
  static String cuerpoHabito(
    String nombre,
    String descripcion,
    String frecuencia,
    int meta,
    int usuarioId,
    int? categoriaId, {
    String? diasSemana,
    bool recordatorioActivo = true,
    String? recordatorioHora,
    String? unidad,
    int? minutosObjetivo,
    String? icono,
  }) {
    final body = {
      'nombre': nombre,
      'descripcion': descripcion,
      'frecuencia': frecuencia,
      'meta': meta,
      'propietario': {'usuarioId': usuarioId},
      'diasSemana': diasSemana,
      'recordatorioActivo': recordatorioActivo,
      'recordatorioHora': recordatorioHora,
      'unidad': ?unidad,
      'minutosObjetivo': ?minutosObjetivo,
      // Sin icono el campo no sale y el backend conserva el que hubiera.
      'icono': ?icono,
    };
    if (categoriaId != null) {
      body['categoriaId'] = categoriaId;
    }
    return jsonEncode(body);
  }

  /// Lee la respuesta de completar. Los campos de minutos faltan en un
  /// backend anterior: `minutosDia` a 0, `minutosObjetivo` a null y
  /// `diaHecho` a false.
  @visibleForTesting
  static Map<String, dynamic> leerCompletado(dynamic data) {
    final List<dynamic> logros = data['logrosOtorgados'] ?? [];
    return {
      'logros': logros.cast<String>(),
      'puntosGanados': data['puntosGanados'] ?? 0,
      // La parte de esos puntos que es el extra por completar la semana
      // (rediseño de rachas, B1). Cero si el backend no la manda.
      'puntosExtraSemana': data['puntosExtraSemana'] ?? 0,
      'registroId': data['registroId'],
      'mostrarValoracion': data['mostrarValoracion'] ?? false,
      'subioNivel': data['subioNivel'] ?? false,
      'nivelNuevo': data['nivelNuevo'] ?? 0,
      'minutosDia': (data['minutosDia'] as num?)?.toInt() ?? 0,
      'minutosObjetivo': (data['minutosObjetivo'] as num?)?.toInt(),
      'diaHecho': data['diaHecho'] == true,
    };
  }

  /// Los registros de un hábito ya leídos, con su `cantidad` y su `origen`.
  static Future<List<Registro>> getRegistros(int habitoId) async =>
      Registro.deLista(await getRegistrosHabito(habitoId));

  static Future<void> valorarRegistro(int registroId, int valoracion) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.put(
        Uri.parse('$_baseUrl/registros/$registroId/valoracion'),
        headers: headers,
        body: jsonEncode({'valoracion': valoracion}),
      ),
    );
    ApiServiceCore.verificar(response);
  }

  // ── Categorías ─────────────────────────────────────────
  static Future<List<dynamic>> getCategoriasUsuario(int usuarioId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.get(
        Uri.parse('$_baseUrl/categorias/usuario/$usuarioId'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
      () => jsonDecode(response.body) as List<dynamic>,
    );
  }

  /// El body de crear (POST) y renombrar (PUT) una categoría propia. Sin
  /// emoji, `icono` sale a null: la categoría queda sin él.
  @visibleForTesting
  static String cuerpoCategoria(String nombre, String? icono) =>
      jsonEncode({'nombre': nombre, 'icono': icono});

  /// Crea una categoría propia y devuelve la creada (con su `categoriaId`).
  /// Un 409 (nombre repetido o tope de 20) llega como [ApiException]: su texto
  /// sale con [mensajeDelServidor].
  static Future<Map<String, dynamic>> crearCategoria(
    String nombre,
    String? icono,
  ) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.post(
        Uri.parse('$_baseUrl/categorias'),
        headers: headers,
        body: cuerpoCategoria(nombre, icono),
      ),
    );
    ApiServiceCore.verificar(response, ok: const [200, 201]);
    return ApiServiceCore.parsear(
      () => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Cambia el nombre y el emoji de una categoría propia.
  static Future<Map<String, dynamic>> actualizarCategoria(
    int categoriaId,
    String nombre,
    String? icono,
  ) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.put(
        Uri.parse('$_baseUrl/categorias/$categoriaId'),
        headers: headers,
        body: cuerpoCategoria(nombre, icono),
      ),
    );
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
      () => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Borra una categoría propia. Sus hábitos no se borran: el backend los deja
  /// sin categoría.
  static Future<void> borrarCategoria(int categoriaId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.delete(
        Uri.parse('$_baseUrl/categorias/$categoriaId'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response, ok: const [200, 204]);
  }

  /// El mensaje que manda el servidor en un 409 de categorías, o null si [e]
  /// no es un 409 o no trae texto. Acepta un JSON con `mensaje`, `message` o
  /// `error`, o un texto plano. Es la única excepción a «el texto crudo del
  /// backend no se enseña»: explica un nombre repetido o el tope de 20, que la
  /// app no puede saber de antemano.
  static String? mensajeDelServidor(Object e) {
    if (e is! ApiException || e.codigoEstado != 409) return null;
    final cuerpo = e.cuerpo?.trim();
    if (cuerpo == null || cuerpo.isEmpty) return null;
    try {
      final data = jsonDecode(cuerpo);
      if (data is Map) {
        for (final clave in const ['mensaje', 'message', 'error']) {
          final v = data[clave];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return null;
      }
      if (data is String && data.trim().isNotEmpty) return data.trim();
      return null;
    } catch (_) {
      return cuerpo;
    }
  }

  // ── Alta / edición / baja ──────────────────────────────
  static Future<List<String>> crearHabito(
    String nombre,
    String descripcion,
    String frecuencia,
    int meta,
    int usuarioId,
    int? categoriaId, {
    String? diasSemana,
    bool recordatorioActivo = true,
    String? recordatorioHora,
    String? unidad,
    int? minutosObjetivo,
    String? icono,
  }) async {
    final headers = await ApiServiceCore.getHeaders();
    final body = cuerpoHabito(
      nombre,
      descripcion,
      frecuencia,
      meta,
      usuarioId,
      categoriaId,
      diasSemana: diasSemana,
      recordatorioActivo: recordatorioActivo,
      recordatorioHora: recordatorioHora,
      unidad: unidad,
      minutosObjetivo: minutosObjetivo,
      icono: icono,
    );
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.post(
        Uri.parse('$_baseUrl/habitos'),
        headers: headers,
        body: body,
      ),
    );
    ApiServiceCore.verificar(response, ok: const [201]);
    return ApiServiceCore.parsear(() {
      final data = jsonDecode(response.body);
      final List<dynamic> logros = data['logrosOtorgados'] ?? [];
      return logros.cast<String>();
    });
  }

  /// Guarda los cambios de un hábito. Devuelve `aplicaDesde`, el día en que
  /// empieza a valer el objetivo nuevo, o null si el backend es anterior y no
  /// lo manda (entonces todo vale desde ya, como siempre).
  static Future<DateTime?> actualizarHabito(
    int habitoId,
    String nombre,
    String descripcion,
    String frecuencia,
    int meta,
    int usuarioId,
    int? categoriaId, {
    String? diasSemana,
    bool recordatorioActivo = true,
    String? recordatorioHora,
    String? unidad,
    int? minutosObjetivo,
    String? icono,
  }) async {
    final headers = await ApiServiceCore.getHeaders();
    final body = cuerpoHabito(
      nombre,
      descripcion,
      frecuencia,
      meta,
      usuarioId,
      categoriaId,
      diasSemana: diasSemana,
      recordatorioActivo: recordatorioActivo,
      recordatorioHora: recordatorioHora,
      unidad: unidad,
      minutosObjetivo: minutosObjetivo,
      icono: icono,
    );
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.put(
        Uri.parse('$_baseUrl/habitos/$habitoId'),
        headers: headers,
        body: body,
      ),
    );
    ApiServiceCore.verificar(response);
    return leerAplicaDesde(response.body);
  }

  /// El `aplicaDesde` de la respuesta del PUT, o null si no viene. Un cuerpo
  /// que no es JSON (el backend anterior respondía texto) también es null: el
  /// cambio ya está guardado y no hay que dar error por no poder leerlo.
  @visibleForTesting
  static DateTime? leerAplicaDesde(String cuerpo) {
    try {
      final data = jsonDecode(cuerpo);
      if (data is! Map<String, dynamic>) return null;
      return fechaSinHoraDe(data['aplicaDesde']);
    } catch (_) {
      return null;
    }
  }

  /// Anula el cambio de objetivo programado: el hábito sigue con el de hoy.
  static Future<void> anularObjetivoProgramado(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.delete(
        Uri.parse('$_baseUrl/habitos/$habitoId/objetivo-programado'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
  }

  static Future<void> eliminarHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.delete(
        Uri.parse('$_baseUrl/habitos/$habitoId'),
        headers: headers,
      ),
    );
    ApiServiceCore.verificar(response);
  }
}
