import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import 'recorrido_onboarding.dart';

/// Las pistas de Nori «la primera vez» (T-054): una nota corta que explica una
/// regla justo cuando aparece por primera vez, en vez de todas al principio.
///
/// Este servicio solo decide SI una pista puede salir y recuerda que salió; no
/// sabe qué dicen ni dónde se pintan (eso lo hace quien la pide, con
/// `NotaPista`). Tampoco sabe nada de hábitos: una pista es un `id`.
///
/// Reglas:
/// - Cada pista sale **una sola vez por cuenta y móvil** (`SharedPreferences`,
///   con el id del usuario en la clave).
/// - **Como mucho una al día** (fecha del móvil), por cuenta.
/// - **Nunca con la pista del alta** ([RecorridoOnboarding]) **ni con otra
///   nota abierta**.
/// - Se marca como vista al **enseñarla**, no al cerrarla: si se cierra la app
///   con la nota puesta, no vuelve.
///
/// Para añadir una pista: un `id` aquí, su texto en los tres ARB, y quien la
/// enseñe llama a [intentar] cuando se dé su momento y, si devuelve true, pinta
/// la `NotaPista` hasta que el usuario la cierre ([cerrar]).
class PistasNori {
  PistasNori._();

  /// La pista de la sección «ESTA SEMANA», la primera vez que sale en Hoy.
  static const String estaSemana = 'esta_semana';

  /// La de la semana que acaba de cerrarse, junto al ritmo.
  static const String semanaCerrada = 'semana_cerrada';

  /// La del extra semanal, la primera vez que llega.
  static const String extraSemana = 'extra_semana';

  /// Seam de test: de dónde salen las preferencias.
  @visibleForTesting
  static Future<SharedPreferences> Function() preferencias =
      SharedPreferences.getInstance;

  /// Seam de test: la hora del móvil.
  @visibleForTesting
  static DateTime Function() ahora = DateTime.now;

  /// Seam de test: la medida de que una pista se ha visto.
  @visibleForTesting
  static Future<void> Function(String id) registrarVista =
      AnalyticsHabitos.pistaVista;

  /// La pista que está en pantalla (o reservada mientras se decide).
  static String? _abierta;

  /// True mientras hay una nota de pista abierta.
  static bool get hayAbierta => _abierta != null;

  static String _claveVista(int usuarioId, String id) =>
      'pista_vista_${usuarioId}_$id';

  static String _claveFecha(int usuarioId) => 'pista_ultima_fecha_$usuarioId';

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Pide enseñar la pista [id]. Devuelve true si puede salir, y entonces ya
  /// queda apuntada como vista, con la fecha de hoy, y como abierta hasta que
  /// se llame a [cerrar]. Si devuelve false, no se ha tocado nada.
  ///
  /// Nunca lanza: si no se pueden leer las preferencias, no sale (una pista
  /// que podría repetirse es peor que una pista que falta).
  static Future<bool> intentar(String id, {required int usuarioId}) async {
    if (usuarioId == 0 || RecorridoOnboarding.instancia.activo) return false;
    // Se reserva antes de esperar: dos peticiones a la vez no pueden salir las
    // dos.
    if (_abierta != null) return false;
    _abierta = id;
    try {
      final prefs = await preferencias();
      final hoy = _iso(ahora());
      final yaVista = prefs.getBool(_claveVista(usuarioId, id)) ?? false;
      final hoyYaSalio = prefs.getString(_claveFecha(usuarioId)) == hoy;
      // El recorrido pudo empezar mientras se leía.
      if (yaVista || hoyYaSalio || RecorridoOnboarding.instancia.activo) {
        _abierta = null;
        return false;
      }
      await prefs.setBool(_claveVista(usuarioId, id), true);
      await prefs.setString(_claveFecha(usuarioId), hoy);
    } catch (e) {
      debugPrint('Pistas: no se pudo decidir $id: $e');
      _abierta = null;
      return false;
    }
    // Medir en segundo plano: no puede retrasar ni romper la nota.
    registrarVista(id);
    return true;
  }

  static String _claveSemana(int usuarioId) => 'pista_semana_vista_$usuarioId';

  /// Dice si hay una semana cerrada por contar: la apuntada es anterior a la
  /// en curso ([lunes], `AAAA-MM-DD`). **No la apunta**: eso lo hace
  /// [apuntarSemana] cuando la pista sale o cuando no le toca, para que una
  /// pista tapada por otra (como mucho una al día) se reintente otro día.
  /// Sin semana apuntada (la primera vez que se abre con esta versión) apunta
  /// la en curso y devuelve false. Nunca lanza.
  static Future<bool> estrenaSemana(int usuarioId, String lunes) async {
    try {
      final prefs = await preferencias();
      final anterior = prefs.getString(_claveSemana(usuarioId));
      if (anterior == null) {
        await prefs.setString(_claveSemana(usuarioId), lunes);
        return false;
      }
      return anterior != lunes;
    } catch (_) {
      return false;
    }
  }

  /// Apunta la semana en curso: la semana cerrada ya está contada. Nunca lanza.
  static Future<void> apuntarSemana(int usuarioId, String lunes) async {
    try {
      final prefs = await preferencias();
      await prefs.setString(_claveSemana(usuarioId), lunes);
    } catch (_) {}
  }

  /// La nota se ha cerrado (o su pantalla ya no está): otra puede salir otro
  /// día. Solo cierra si la abierta es [id].
  static void cerrar(String id) {
    if (_abierta == id) _abierta = null;
  }

  /// Solo para tests: olvida la pista abierta.
  @visibleForTesting
  static void reiniciar() => _abierta = null;
}
