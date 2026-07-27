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

  static String logroDescripcion(
          BuildContext context, String? codigo, String descripcionBackend) =>
      _traducir(_logrosDescripcion(context), codigo, descripcionBackend);

  static String productoDescripcion(
          BuildContext context, String? codigo, String descripcionBackend) =>
      _traducir(_productosDescripcion(context), codigo, descripcionBackend);

  /// Categoría y nivel del logro no viajan por código: el backend manda el
  /// literal en español ('Constancia', 'Facil'). Se traducen por ese valor,
  /// que aquí hace de clave.
  static String logroCategoria(BuildContext context, String categoriaBackend) =>
      _traducir(_logrosCategoria(context), categoriaBackend, categoriaBackend);

  static String logroNivel(BuildContext context, String nivelBackend) =>
      _traducir(_logrosNivel(context), nivelBackend, nivelBackend);

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
      'AVATAR_PERRO': l.prodAvatarPerro,
      'AVATAR_CONEJO': l.prodAvatarConejo,
      'AVATAR_KOALA': l.prodAvatarKoala,
      'AVATAR_PINGUINO': l.prodAvatarPinguino,
      'AVATAR_LEON': l.prodAvatarLeon,
      'COMIDA_BASICA': l.prodComidaBasica,
    };
  }

  static Map<String, String> _logrosDescripcion(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return {
      'PRIMER_HABITO': l.logroDescPrimerHabito,
      'BIENVENIDO': l.logroDescBienvenido,
      'PRIMERA_CATEGORIA': l.logroDescPrimeraCategoria,
      'LOGIN_GOOGLE': l.logroDescLoginGoogle,
      'PRIMEROS_PASOS': l.logroDescPrimerosPasos,
      'RACHA_3': l.logroDescRacha3,
      'RACHA_7': l.logroDescRacha7,
      'RACHA_RECUPERADA': l.logroDescRachaRecuperada,
      'RACHA_30': l.logroDescRacha30,
      'RACHA_100': l.logroDescRacha100,
      'RACHA_365': l.logroDescRacha365,
      'HABITOS_ACTIVOS_3': l.logroDescHabitosActivos3,
      'HABITOS_ACTIVOS_5': l.logroDescHabitosActivos5,
      'REGISTROS_100': l.logroDescRegistros100,
      'REGISTROS_500': l.logroDescRegistros500,
      'REGISTROS_1000': l.logroDescRegistros1000,
      'CATEGORIAS_3': l.logroDescCategorias3,
      'CATEGORIAS_5': l.logroDescCategorias5,
      'PRIMERA_NOTA': l.logroDescPrimeraNota,
      'INTERACCION_RESENA': l.logroDescInteraccionResena,
    };
  }

  static Map<String, String> _productosDescripcion(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return {
      'ESCUDO_RACHA': l.prodDescEscudoRacha,
      'TEMA_BASICO_CLARO': l.prodDescTemaBasicoClaro,
      'TEMA_BASICO_OSCURO': l.prodDescTemaBasicoOscuro,
      'TEMA_CALIDEZ': l.prodDescTemaCalidez,
      'TEMA_NEOTOKYO': l.prodDescTemaNeotokyo,
      'TEMA_OCEANO': l.prodDescTemaOceano,
      'TEMA_BOSQUE': l.prodDescTemaBosque,
      'TEMA_COBRE': l.prodDescTemaCobre,
      'AVATAR_ZORRO': l.prodDescAvatarZorro,
      'AVATAR_GATO': l.prodDescAvatarGato,
      'AVATAR_BUHO': l.prodDescAvatarBuho,
      'AVATAR_PANDA': l.prodDescAvatarPanda,
      'AVATAR_TORTUGA': l.prodDescAvatarTortuga,
      'AVATAR_PERRO': l.prodDescAvatarPerro,
      'AVATAR_CONEJO': l.prodDescAvatarConejo,
      'AVATAR_KOALA': l.prodDescAvatarKoala,
      'AVATAR_PINGUINO': l.prodDescAvatarPinguino,
      'AVATAR_LEON': l.prodDescAvatarLeon,
      'COMIDA_BASICA': l.prodDescComidaBasica,
    };
  }

  static Map<String, String> _logrosCategoria(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return {
      'Inicio': l.logroCatInicio,
      'Constancia': l.logroCatConstancia,
      'Volumen': l.logroCatVolumen,
      'Variedad': l.logroCatVariedad,
      'Exploración': l.logroCatExploracion,
    };
  }

  // Sin tilde en las claves: así es como llegan de los initializers.
  static Map<String, String> _logrosNivel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return {
      'Facil': l.nivelFacil,
      'Medio': l.nivelMedio,
      'Dificil': l.nivelDificil,
    };
  }
}
