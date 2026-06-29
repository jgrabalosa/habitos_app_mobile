import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../models/habito.dart';

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

  static Future<void> completarHabito(int habitoId) async {
    final headers = await getHeaders();
    await http.post(
      Uri.parse('$baseUrl/registros/completar/$habitoId'),
      headers: headers,
      body: jsonEncode({'nota': ''}),
    );
  }

  static Future<void> crearHabito(String nombre, String descripcion,
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
    await http.post(
      Uri.parse('$baseUrl/habitos'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
}