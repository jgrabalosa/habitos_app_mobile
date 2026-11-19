import 'package:flutter/foundation.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import 'abrir_enfoque.dart';

/// Disparadores: lo que se mide de los hábitos. Entrar y darse de alta son
/// eventos de cualquier app del ecosistema y los registra [AnalyticsCore],
/// dentro del paquete.
///
/// Igual que [AnalyticsCore], ningún método de aquí lanza: medir nunca puede
/// romper lo que se mide. `habito_screen` espera a [habitoCreado] dentro del
/// try de guardar, con el hábito ya creado en el servidor; si esto lanzara,
/// la pantalla diría que no se pudo crear y un reintento lo duplicaría.
///
/// La captura vive aquí y no en un ayudante del core a propósito: esta app
/// depende del core por tag, y no debe hacer falta publicar uno para que
/// medir sea seguro.
class AnalyticsHabitos {
  /// Solo al crear. [plantilla] es el `id` de la `PlantillaHabito` usada o
  /// `ninguna`; [unidad], `veces` o `minutos`.
  static Future<void> habitoCreado(
    String frecuencia, {
    String plantilla = 'ninguna',
    String unidad = 'veces',
  }) async {
    try {
      await AnalyticsCore.analytics.logEvent(
        name: 'habito_creado',
        parameters: {
          'frecuencia': frecuencia,
          'plantilla': plantilla,
          'unidad': unidad,
        },
      );
    } catch (e) {
      debugPrint('Analytics: no se registró habito_creado: $e');
    }
  }

  /// Lo que contestó el sistema al pedir permiso de avisos (no se registra si
  /// el usuario dijo que no en el diálogo propio de la app).
  static Future<void> permisoAvisos(bool concedido) async {
    try {
      await AnalyticsCore.analytics.logEvent(
        name: 'permiso_avisos',
        parameters: {'concedido': concedido ? 'si' : 'no'},
      );
    } catch (e) {
      debugPrint('Analytics: no se registró permiso_avisos: $e');
    }
  }

  /// El valor de `resultado` de `enfoque_abierto`. `faltaPrueba` solo existe
  /// en el flavor de prueba, que no abrió nada: cuenta como `nada`.
  static String resultadoEnfoque(AperturaEnfoque apertura) =>
      switch (apertura) {
        AperturaEnfoque.app => 'app',
        AperturaEnfoque.fichaPlay => 'ficha_play',
        AperturaEnfoque.fichaWeb => 'ficha_web',
        AperturaEnfoque.faltaPrueba || AperturaEnfoque.nada => 'nada',
      };

  /// Qué pasó al pulsar «Empezar sesión». Sin id de hábito.
  static Future<void> enfoqueAbierto(AperturaEnfoque apertura) async {
    try {
      await AnalyticsCore.analytics.logEvent(
        name: 'enfoque_abierto',
        parameters: {'resultado': resultadoEnfoque(apertura)},
      );
    } catch (e) {
      debugPrint('Analytics: no se registró enfoque_abierto: $e');
    }
  }

  /// La identidad que elige el usuario nuevo en el onboarding. Solo el código
  /// del catálogo, nada personal.
  static Future<void> identidadElegida(String codigo) async {
    try {
      await AnalyticsCore.analytics.logEvent(
        name: 'identidad_elegida',
        parameters: {'codigo': codigo},
      );
    } catch (e) {
      debugPrint('Analytics: no se registró identidad_elegida: $e');
    }
  }

  static Future<void> habitoCompletado(String frecuencia) async {
    try {
      await AnalyticsCore.analytics.logEvent(
        name: 'habito_completado',
        parameters: {'frecuencia': frecuencia},
      );
    } catch (e) {
      debugPrint('Analytics: no se registró habito_completado: $e');
    }
  }

  /// Se abre «Invitar a un amigo».
  static Future<void> invitarAbierto() async {
    try {
      await AnalyticsCore.analytics.logEvent(name: 'invitar_abierto');
    } catch (e) {
      debugPrint('Analytics: no se registró invitar_abierto: $e');
    }
  }

  /// Lo que devolvió el menú de compartir: `compartido`, `cancelado` o
  /// `no_disponible`.
  static Future<void> invitarCompartido(String resultado) async {
    try {
      await AnalyticsCore.analytics.logEvent(
        name: 'invitar_compartido',
        parameters: {'resultado': resultado},
      );
    } catch (e) {
      debugPrint('Analytics: no se registró invitar_compartido: $e');
    }
  }
}
