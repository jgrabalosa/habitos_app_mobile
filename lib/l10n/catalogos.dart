import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Traducción de los catálogos que manda el backend.
///
/// El backend envía `codigo` (CAT_SALUD, RACHA_7, TEMA_OCEANO...) y el nombre
/// en español como caída. Aquí se traduce por código.
///
/// CAÍDA OBLIGATORIA: si el código no está traducido —o viene a null, que es
/// el caso de las categorías que crea el usuario— se muestra el nombre que
/// manda el backend tal cual. Nunca se enseña un código crudo ni una cadena
/// vacía.
class Catalogos {
  const Catalogos._();

  static String categoria(BuildContext context, String? codigo, String nombreBackend) =>
      _traducir(_categorias(context), codigo, nombreBackend);

  static String logro(BuildContext context, String? codigo, String nombreBackend) =>
      _traducir(_logros(context), codigo, nombreBackend);

  static String producto(BuildContext context, String? codigo, String nombreBackend) =>
      _traducir(_productos(context), codigo, nombreBackend);

  static String _traducir(Map<String, String> mapa, String? codigo, String nombreBackend) {
    if (codigo == null) return nombreBackend;
    return mapa[codigo] ?? nombreBackend;
  }

  static Map<String, String> _categorias(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return {
      'CAT_SALUD': l.catSalud,
      'CAT_DEPORTE': l.catDeporte,
      'CAT_ALIMENTACION': l.catAlimentacion,
      'CAT_MENTE': l.catMente,
      'CAT_TRABAJO': l.catTrabajo,
      'CAT_ESTUDIO': l.catEstudio,
      'CAT_FINANZAS': l.catFinanzas,
      'CAT_SOCIAL': l.catSocial,
      'CAT_CREATIVIDAD': l.catCreatividad,
      'CAT_SUENO': l.catSueno,
    };
  }

  static Map<String, String> _logros(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return {
      'PRIMER_HABITO': l.logroPrimerHabito,
      'BIENVENIDO': l.logroBienvenido,
      'PRIMERA_CATEGORIA': l.logroPrimeraCategoria,
      'LOGIN_GOOGLE': l.logroLoginGoogle,
      'PRIMEROS_PASOS': l.logroPrimerosPasos,
      'RACHA_3': l.logroRacha3,
      'RACHA_7': l.logroRacha7,
      'RACHA_RECUPERADA': l.logroRachaRecuperada,
      'RACHA_30': l.logroRacha30,
      'RACHA_100': l.logroRacha100,
      'RACHA_365': l.logroRacha365,
      'HABITOS_ACTIVOS_3': l.logroHabitosActivos3,
      'HABITOS_ACTIVOS_5': l.logroHabitosActivos5,
      'REGISTROS_100': l.logroRegistros100,
      'REGISTROS_500': l.logroRegistros500,
      'REGISTROS_1000': l.logroRegistros1000,
      'CATEGORIAS_3': l.logroCategorias3,
      'CATEGORIAS_5': l.logroCategorias5,
      'PRIMERA_NOTA': l.logroPrimeraNota,
      'INTERACCION_RESENA': l.logroInteraccionResena,
    };
  }

  static Map<String, String> _productos(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return {
      'ESCUDO_RACHA': l.prodEscudoRacha,
      'TEMA_BASICO_CLARO': l.prodTemaBasicoClaro,
      'TEMA_BASICO_OSCURO': l.prodTemaBasicoOscuro,
      'TEMA_CALIDEZ': l.prodTemaCalidez,
      'TEMA_NEOTOKYO': l.prodTemaNeotokyo,
      'TEMA_OCEANO': l.prodTemaOceano,
      'TEMA_BOSQUE': l.prodTemaBosque,
      'TEMA_COBRE': l.prodTemaCobre,
      'AVATAR_ZORRO': l.prodAvatarZorro,
      'AVATAR_GATO': l.prodAvatarGato,
      'AVATAR_BUHO': l.prodAvatarBuho,
      'AVATAR_PANDA': l.prodAvatarPanda,
      'AVATAR_TORTUGA': l.prodAvatarTortuga,
      'COMIDA_BASICA': l.prodComidaBasica,
    };
  }
}
