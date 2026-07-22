import 'package:audioplayers/audioplayers.dart';

/// Servicio genérico y exportable de efectos de sonido.
/// No conoce el dominio de la app: recibe eventos genéricos y reproduce
/// el archivo mapeado. Si un evento no tiene sonido, no hace nada.
class SonidoService {
  SonidoService._();

  /// Mapa evento → archivo. Para añadir un sonido nuevo (p. ej. 'racha'),
  /// basta con añadir la entrada y el mp3 en assets/sounds/.
  static const Map<String, String> _sonidos = {
    'completar': 'sounds/completar.mp3',
    'logro': 'sounds/logro.mp3',
  };

  /// Preparado para la futura preferencia de sonidos on/off
  /// (menú de usuario, Fase 16 junto a notificaciones).
  static bool activado = true;

  static bool _contextoConfigurado = false;

  /// Configura el reproductor para "mezclar" con audio de otras apps
  /// (Spotify, etc.) en vez de pedir el foco exclusivo y cortarlas.
  /// Se hace una sola vez, antes del primer sonido reproducido.
  static Future<void> _asegurarContextoAudio() async {
    if (_contextoConfigurado) return;
    _contextoConfigurado = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
    } catch (_) {
      // El sonido nunca debe romper la app
    }
  }

  static Future<void> reproducir(String evento) async {
    if (!activado) return;
    final ruta = _sonidos[evento];
    if (ruta == null) return;

    await _asegurarContextoAudio();

    try {
      final player = AudioPlayer();
      player.onPlayerComplete.listen((_) => player.dispose());
      await player.play(AssetSource(ruta));
    } catch (_) {
      // El sonido nunca debe romper la app
    }
  }
}