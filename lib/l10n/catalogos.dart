import 'package:flutter/widgets.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'app_localizations.dart';

/// Traducción de los catálogos que sí saben de hábitos.
///
/// Lo genérico —productos de la tienda, niveles, categorías de logro y los
/// cuatro logros que se ganan sin hacer nada de dominio— lo traduce
/// [CatalogosCore], dentro del paquete. Aquí quedan las categorías de hábito
/// y los ~37 logros que hablan de rachas, registros y hábitos activos.
///
/// CAÍDA OBLIGATORIA: si el código no está traducido —o viene a null, que es
/// el caso de las categorías que crea el usuario— se muestra el nombre que
/// manda el backend tal cual. Nunca se enseña un código crudo ni una cadena
/// vacía.
class Catalogos {
  const Catalogos._();

  /// Le pasa al motor los logros de hábitos. Sin esto, `LogrosScreen` y las
  /// celebraciones —que viven en el paquete— enseñarían el nombre en español
  /// que manda el backend en vez del traducido.
  ///
  /// Se llama una vez desde `main()`, antes de `runApp`.
  static void registrarEnElMotor() {
    CatalogosCore.registrarLogrosDeDominio(
      nombres: _logros,
      descripciones: _logrosDescripcion,
    );
  }

  static String categoria(BuildContext context, String? codigo, String nombreBackend) =>
      CatalogosCore.traducir(_categorias(context), codigo, nombreBackend);

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
      'PRIMERA_CATEGORIA': l.logroPrimeraCategoria,
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
    };
  }

  static Map<String, String> _logrosDescripcion(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return {
      'PRIMER_HABITO': l.logroDescPrimerHabito,
      'PRIMERA_CATEGORIA': l.logroDescPrimeraCategoria,
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
    };
  }
}
