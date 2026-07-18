import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../models/habito.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ApiService {
  static const String baseUrl = 'https://habitos-app-production.up.railway.app/api';

  // ── Token ──────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> saveUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usuarioId', usuario.usuarioId);
    await prefs.setString('nombre', usuario.nombre);
    await prefs.setString('username', usuario.username);
    await prefs.setString('email', usuario.email);
    await prefs.setString('proveedorAuth', usuario.proveedorAuth);
  }

  static Future<Map<String, dynamic>?> getUsuarioLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;
    return {
      'usuarioId': prefs.getInt('usuarioId'),
      'nombre': prefs.getString('nombre'),
      'username': prefs.getString('username'),
      'email': prefs.getString('email'),
      'proveedorAuth': prefs.getString('proveedorAuth') ?? 'LOCAL',
      'token': token,
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Headers ────────────────────────────────────────────
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Usuarios ───────────────────────────────────────────
  static Future<Usuario> login(String email, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'contrasena': contrasena}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Usuario.fromJson(data);
    } else {
      throw Exception(response.body);
    }
  }

  static Future<void> registro(String nombre, String username, 
                                String email, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'username': username,
        'email': email,
        'contrasena': contrasena,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }
  }
  static Future<void> actualizarUsuario(
      int usuarioId, String nombre, String username, String email) async {
    final response = await http.put(
      Uri.parse('$baseUrl/usuarios/$usuarioId'),
      headers: await getHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'username': username,
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
    

    // Actualizar también los datos guardados en local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
  }

  static Future<void> cambiarContrasena(
      int usuarioId, String contrasenaActual, String contrasenaNueva) async {
    final response = await http.put(
      Uri.parse('$baseUrl/usuarios/$usuarioId/contrasena'),
      headers: await getHeaders(),
      body: jsonEncode({
        'contrasenaActual': contrasenaActual,
        'contrasenaNueva': contrasenaNueva,
      }),
    );

    

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

// ── Recuperación de contraseña ─────────────────────────
  static Future<void> solicitarCodigoRecuperacion(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/recuperar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  static Future<void> restablecerContrasena(
      String email, String codigo, String contrasenaNueva) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/restablecer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'codigo': codigo,
        'contrasenaNueva': contrasenaNueva,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }
  
  static Future<void> eliminarUsuario(int usuarioId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/usuarios/$usuarioId'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    // Cuenta eliminada: limpiar toda la sesión local
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

// ── Hábitos ────────────────────────────────────────────
  static Future<List<Habito>> getHabitosActivos(int usuarioId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/habitos/usuario/$usuarioId/activos'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Habito.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar hábitos');
    }
  }

  static Future<Map<String, dynamic>> getHabitoDetalle(int habitoId, {String? mes}) async {
    final headers = await getHeaders();
    final mesParam = mes != null ? '?mes=$mes' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/habitos/$habitoId/detalle$mesParam'),
      headers: headers,
    );
    

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar el detalle del hábito');
    }
  }
  
  static Future<void> actualizarNotaRegistro(int registroId, String nota) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/registros/$registroId/nota'),
      headers: headers,
      body: jsonEncode({'nota': nota}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la nota');
    }
  }


  static Future<bool> estaCompletadoHoy(int habitoId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/registros/habito/$habitoId/hoy'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['completadoHoy'];
    }
    return false;
  }

  static Future<Map<String, dynamic>> getProgresoHoy(int habitoId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/registros/habito/$habitoId/hoy'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar el progreso');
    }
  }

  static Future<List<dynamic>> getRegistrosHabito(int habitoId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/registros/habito/$habitoId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar los registros');
    }
  }

static Future<Map<String, dynamic>> completarHabito(int habitoId,
      {String nota = ''}) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/registros/completar/$habitoId'),
      headers: headers,
      body: jsonEncode({'nota': nota}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final List<dynamic> logros = data['logrosOtorgados'] ?? [];
      return {
        'logros': logros.cast<String>(),
        'puntosGanados': data['puntosGanados'] ?? 0,
        'registroId': data['registroId'],
        'mostrarValoracion': data['mostrarValoracion'] ?? false,
      };
    } else {
      throw Exception('Error al completar el hábito');
    }
  }

  static Future<void> valorarRegistro(int registroId, int valoracion) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/registros/$registroId/valoracion'),
      headers: headers,
      body: jsonEncode({'valoracion': valoracion}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al guardar la valoración');
    }
  }

  static Future<void> registrarInteraccionResena(int usuarioId) async {
    final headers = await getHeaders();
    await http.post(
      Uri.parse('$baseUrl/gamificacion/resena/$usuarioId'),
      headers: headers,
    );
  }

  // ── Gamificación ───────────────────────────────────────
  static Future<int> getSaldoPuntos(int usuarioId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/gamificacion/saldo/$usuarioId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['saldo'];
    } else {
      throw Exception('Error al cargar el saldo');
    }
  }

  static Future<List<dynamic>> getCatalogoLogros() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/gamificacion/logros/catalogo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar el catálogo de logros');
    }
  }

  static Future<List<dynamic>> getCategoriasUsuario(int usuarioId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/categorias/usuario/$usuarioId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar las categorías');
    }
  }

  static Future<List<dynamic>> getLogrosUsuario(int usuarioId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/gamificacion/logros/usuario/$usuarioId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar los logros del usuario');
    }
  }

static Future<List<String>> crearHabito(String nombre, String descripcion,
      String frecuencia, int meta, int usuarioId, int? categoriaId) async {
    final headers = await getHeaders();
    final body = {
      'nombre': nombre,
      'descripcion': descripcion,
      'frecuencia': frecuencia,
      'meta': meta,
      'propietario': {'usuarioId': usuarioId},
    };
    if (categoriaId != null) {
      body['tipo'] = {'categoriaId': categoriaId};
    }
    final response = await http.post(
      Uri.parse('$baseUrl/habitos'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final List<dynamic> logros = data['logrosOtorgados'] ?? [];
      return logros.cast<String>();
    } else {
      throw Exception('Error al crear el hábito');
    }
  }
    static Future<void> actualizarHabito(int habitoId, String nombre, String descripcion,
      String frecuencia, int meta, int usuarioId, int? categoriaId) async {
    final headers = await getHeaders();
    final body = {
      'nombre': nombre,
      'descripcion': descripcion,
      'frecuencia': frecuencia,
      'meta': meta,
      'propietario': {'usuarioId': usuarioId},
    };
    if (categoriaId != null) {
      body['tipo'] = {'categoriaId': categoriaId};
    }
    final response = await http.put(
      Uri.parse('$baseUrl/habitos/$habitoId'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el hábito');
    }
  }

  static Future<void> eliminarHabito(int habitoId) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/habitos/$habitoId'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar el hábito');
    }
  }
  static Future<void> loginConGoogle() async {
  final GoogleSignIn googleSignIn = GoogleSignIn(
    serverClientId: '177339814167-fdtmn2i1s6aeg1agrqtikq066opib8ce.apps.googleusercontent.com',
  );

  final GoogleSignInAccount? account = await googleSignIn.signIn();
  if (account == null) return;

  final GoogleSignInAuthentication auth = await account.authentication;
  final String? idToken = auth.idToken;
  if (idToken == null) throw Exception('No se obtuvo el token de Google');

  final response = await http.post(
    Uri.parse('$baseUrl/usuarios/login-google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'idToken': idToken}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await saveToken(data['token']);
    await saveUsuario(Usuario.fromJson(data));
  } else {
    throw Exception(response.body);
  }
}
// ── Notificaciones ─────────────────────────────────────
  static Future<void> actualizarFcmToken(int usuarioId, String fcmToken) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/usuarios/$usuarioId/fcm-token'),
      headers: headers,
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el token de notificaciones');
    }
  }

  
}