import 'dart:convert';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../models/habito.dart';

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
  static Future<List<Habito>> getHabitosActivos(int usuarioId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/habitos/usuario/$usuarioId/activos'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Habito.fromJson(json)).toList();
    });
  }

  static Future<Habito> getHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/habitos/$habitoId'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() => Habito.fromJson(jsonDecode(response.body)));
  }

  static Future<List<Map<String, dynamic>>> getResumenHabitos(int usuarioId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/habitos/usuario/$usuarioId/resumen'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => {
        'habito': Habito.fromJson(item['habito']),
        'totalCompletados': item['totalCompletados'] ?? 0,
      }).toList();
    });
  }

  static Future<void> activarHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.patch(
          Uri.parse('$_baseUrl/habitos/$habitoId/activar'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
  }

  static Future<void> desactivarHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.patch(
          Uri.parse('$_baseUrl/habitos/$habitoId/desactivar'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
  }

  static Future<List<dynamic>> getDashboard(int usuarioId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/habitos/usuario/$usuarioId/dashboard'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() => jsonDecode(response.body) as List<dynamic>);
  }

  static Future<Map<String, dynamic>> getSemana(int usuarioId, {String? desde}) async {
    final headers = await ApiServiceCore.getHeaders();
    final desdeParam = desde != null ? '?desde=$desde' : '';
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/habitos/usuario/$usuarioId/semana$desdeParam'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() => jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getHabitoDetalle(int habitoId, {String? mes}) async {
    final headers = await ApiServiceCore.getHeaders();
    final mesParam = mes != null ? '?mes=$mes' : '';
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/habitos/$habitoId/detalle$mesParam'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() => jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ── Registros ──────────────────────────────────────────
  static Future<void> actualizarNotaRegistro(int registroId, String nota) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.put(
          Uri.parse('$_baseUrl/registros/$registroId/nota'),
          headers: headers,
          body: jsonEncode({'nota': nota}),
        ));
    ApiServiceCore.verificar(response);
  }

  static Future<bool> estaCompletadoHoy(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/registros/habito/$habitoId/hoy'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() => jsonDecode(response.body)['completadoHoy'] as bool);
  }

  static Future<Map<String, dynamic>> getProgresoHoy(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/registros/habito/$habitoId/hoy'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() => jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<List<dynamic>> getRegistrosHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/registros/habito/$habitoId'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() => jsonDecode(response.body) as List<dynamic>);
  }

  static Future<Map<String, dynamic>> completarHabito(int habitoId,
      {String nota = ''}) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.post(
          Uri.parse('$_baseUrl/registros/completar/$habitoId'),
          headers: headers,
          body: jsonEncode({'nota': nota}),
        ));
    ApiServiceCore.verificar(response, ok: const [201]);
    return ApiServiceCore.parsear(() {
      final data = jsonDecode(response.body);
      final List<dynamic> logros = data['logrosOtorgados'] ?? [];
      return {
        'logros': logros.cast<String>(),
        'puntosGanados': data['puntosGanados'] ?? 0,
        'registroId': data['registroId'],
        'mostrarValoracion': data['mostrarValoracion'] ?? false,
        'subioNivel': data['subioNivel'] ?? false,
        'nivelNuevo': data['nivelNuevo'] ?? 0,
      };
    });
  }

  static Future<void> valorarRegistro(int registroId, int valoracion) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.put(
          Uri.parse('$_baseUrl/registros/$registroId/valoracion'),
          headers: headers,
          body: jsonEncode({'valoracion': valoracion}),
        ));
    ApiServiceCore.verificar(response);
  }

  // ── Categorías ─────────────────────────────────────────
  static Future<List<dynamic>> getCategoriasUsuario(int usuarioId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/categorias/usuario/$usuarioId'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() => jsonDecode(response.body) as List<dynamic>);
  }

  // ── Alta / edición / baja ──────────────────────────────
  static Future<List<String>> crearHabito(String nombre, String descripcion,
      String frecuencia, int meta, int usuarioId, int? categoriaId,
      {String? diasSemana, bool recordatorioActivo = true, String? recordatorioHora}) async {
    final headers = await ApiServiceCore.getHeaders();
    final body = {
      'nombre': nombre,
      'descripcion': descripcion,
      'frecuencia': frecuencia,
      'meta': meta,
      'propietario': {'usuarioId': usuarioId},
      'diasSemana': diasSemana,
      'recordatorioActivo': recordatorioActivo,
      'recordatorioHora': recordatorioHora,
    };
    if (categoriaId != null) {
      body['tipo'] = {'categoriaId': categoriaId};
    }
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.post(
          Uri.parse('$_baseUrl/habitos'),
          headers: headers,
          body: jsonEncode(body),
        ));
    ApiServiceCore.verificar(response, ok: const [201]);
    return ApiServiceCore.parsear(() {
      final data = jsonDecode(response.body);
      final List<dynamic> logros = data['logrosOtorgados'] ?? [];
      return logros.cast<String>();
    });
  }

  static Future<void> actualizarHabito(int habitoId, String nombre, String descripcion,
      String frecuencia, int meta, int usuarioId, int? categoriaId,
      {String? diasSemana, bool recordatorioActivo = true, String? recordatorioHora}) async {
    final headers = await ApiServiceCore.getHeaders();
    final body = {
      'nombre': nombre,
      'descripcion': descripcion,
      'frecuencia': frecuencia,
      'meta': meta,
      'propietario': {'usuarioId': usuarioId},
      'diasSemana': diasSemana,
      'recordatorioActivo': recordatorioActivo,
      'recordatorioHora': recordatorioHora,
    };
    if (categoriaId != null) {
      body['tipo'] = {'categoriaId': categoriaId};
    }
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.put(
          Uri.parse('$_baseUrl/habitos/$habitoId'),
          headers: headers,
          body: jsonEncode(body),
        ));
    ApiServiceCore.verificar(response);
  }

  static Future<void> eliminarHabito(int habitoId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.delete(
          Uri.parse('$_baseUrl/habitos/$habitoId'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
  }
}
