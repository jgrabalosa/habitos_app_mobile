import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Info visual de un avatar — PLACEHOLDER (emoji + color) hasta que revises
/// los assets reales de DiceBear. Sustituir por imágenes cuando estén listas.
class AvatarInfo {
  final String emoji;
  final Color color;
  const AvatarInfo({required this.emoji, required this.color});
}

/// Registro de avatares por código de producto — mismo patrón que catalogoPaletas.
const Map<String, AvatarInfo> catalogoAvatares = {
  'AVATAR_ZORRO': AvatarInfo(emoji: '🦊', color: Color(0xFFE07856)),
  'AVATAR_GATO': AvatarInfo(emoji: '🐱', color: Color(0xFF8B7EC8)),
  'AVATAR_BUHO': AvatarInfo(emoji: '🦉', color: Color(0xFF6B7280)),
  'AVATAR_PANDA': AvatarInfo(emoji: '🐼', color: Color(0xFF374151)),
  'AVATAR_TORTUGA': AvatarInfo(emoji: '🐢', color: Color(0xFF27C76F)),
};

const _keyAvatarEquipado = 'avatar_equipado_codigo';

final ValueNotifier<String?> avatarEquipadoNotifier = ValueNotifier(null);

/// Llamar al arrancar la app (junto a cargarTemaGuardado/cargarTemaPremiumGuardado),
/// para que el avatar se pinte sin parpadeo desde el primer frame.
Future<void> cargarAvatarGuardado() async {
  final prefs = await SharedPreferences.getInstance();
  avatarEquipadoNotifier.value = prefs.getString(_keyAvatarEquipado);
}

/// Llamar al equipar un avatar. No existe "desequipar" avatar: el círculo
/// con la inicial del nombre es el estado por defecto, no un producto.
Future<void> guardarAvatarEquipado(String? codigo) async {
  final prefs = await SharedPreferences.getInstance();
  avatarEquipadoNotifier.value = codigo;
  if (codigo == null || !catalogoAvatares.containsKey(codigo)) {
    await prefs.remove(_keyAvatarEquipado);
  } else {
    await prefs.setString(_keyAvatarEquipado, codigo);
  }
}

/// Círculo de avatar reutilizable: el avatar equipado (placeholder emoji
/// por ahora), o si no hay ninguno, un círculo con la inicial del nombre.
class AvatarUsuario extends StatelessWidget {
  final String nombre;
  final double radius;
  const AvatarUsuario({super.key, required this.nombre, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: avatarEquipadoNotifier,
      builder: (context, codigo, _) {
        final info = codigo != null ? catalogoAvatares[codigo] : null;
        if (info != null) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: info.color.withOpacity(0.25),
            child: Text(info.emoji, style: TextStyle(fontSize: radius)),
          );
        }
        final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
        return CircleAvatar(
          radius: radius,
          child: Text(inicial, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}