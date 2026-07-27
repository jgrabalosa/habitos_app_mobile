import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Idioma de la app. Motor: no sabe qué textos hay ni de qué app son.
///
/// En el primer arranque se detecta del dispositivo, con caída a español si
/// el idioma del sistema no está entre los soportados. A partir de ahí manda
/// lo que el usuario haya elegido.
///
/// El idioma y la zona horaria son preferencias independientes: se guardan y
/// se cambian por separado.
class IdiomaService {
  static const List<String> soportados = ['es', 'en', 'pt'];
  static const String porDefecto = 'es';

  static const _clave = 'idioma';

  /// Escuchado por MaterialApp: cambiarlo repinta la app sin reiniciarla.
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale(porDefecto));

  static List<Locale> get localesSoportados =>
      soportados.map((c) => Locale(c)).toList();

  /// Idioma del dispositivo si lo soportamos; si no, español.
  static String detectarDelDispositivo() {
    final delSistema = PlatformDispatcher.instance.locale.languageCode;
    return soportados.contains(delSistema) ? delSistema : porDefecto;
  }

  /// Llamar al arrancar, antes de runApp, para no pintar en el idioma
  /// equivocado durante un frame.
  static Future<void> cargarAlArrancar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_clave);

    if (guardado != null && soportados.contains(guardado)) {
      localeNotifier.value = Locale(guardado);
      return;
    }

    // Primer arranque: lo detectamos y lo dejamos guardado
    final detectado = detectarDelDispositivo();
    await prefs.setString(_clave, detectado);
    localeNotifier.value = Locale(detectado);
  }

  /// Cambia el idioma, lo persiste y lo sincroniza con el backend (que lo
  /// necesita para los emails y los push, que salen sin la app abierta).
  static Future<void> cambiar(String codigo, {int? usuarioId}) async {
    if (!soportados.contains(codigo)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, codigo);
    localeNotifier.value = Locale(codigo);

    if (usuarioId != null) {
      // Que falle la sincronización no debe deshacer el cambio local: la app
      // ya está en el idioma nuevo y el backend se pondrá al día al reintentar.
      try {
        await ApiService.actualizarPreferencias(usuarioId, idioma: codigo);
      } catch (_) {}
    }
  }

  /// Alinea el estado local con lo que diga el backend tras iniciar sesión.
  static Future<void> sincronizarDesdeBackend(String? idiomaBackend) async {
    if (idiomaBackend == null || !soportados.contains(idiomaBackend)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, idiomaBackend);
    localeNotifier.value = Locale(idiomaBackend);
  }

  static String get actual => localeNotifier.value.languageCode;
}
