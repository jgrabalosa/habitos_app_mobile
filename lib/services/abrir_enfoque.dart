import 'package:flutter/services.dart';

// Abrir Norday Focus (la app Enfoque) desde un hábito de minutos.
//
// Enfoque es otra app, con su propio paquete. Si está instalada se abre con
// el enlace del hábito, que la deja en su Inicio con ese hábito como
// destino; si no, se abre su ficha de Google Play.
//
// Cómo se abre, según la documentación oficial de Android:
//
// - «When an app that targets Android 11 or higher uses an intent to start
//   an activity in another app, the most straightforward approach is to
//   invoke the intent and handle the ActivityNotFoundException exception if
//   no app is available.»
//   https://developer.android.com/training/package-visibility/use-cases
//   Por eso no se pregunta antes si está instalada: se intenta abrir, y si
//   no hay quien lo abra, se pasa al siguiente.
// - Abrir con `setPackage` es tratar con una app concreta, y la visibilidad
//   limitada «also affects explicit interactions with other apps»
//   (https://developer.android.com/training/package-visibility). Así que los
//   dos paquetes de Enfoque van en `<queries>` del AndroidManifest: «If you
//   know the specific apps that you want to query or interact with […]
//   include their package names in a set of `<package>` elements inside the
//   `<queries>` element»
//   (https://developer.android.com/training/package-visibility/declaring).
// - La ficha de Play no necesita `<queries>`: «the `startActivity()` method
//   doesn't require package visibility to start another application's
//   activity […]. This is true for both implicit and explicit intents that
//   open a URL.» (misma página de casos de uso).
//
// No se usa `url_launcher`: no es dependencia de esta app (solo llega a
// través del core) y no deja fijar el paquete que abre el enlace, que hace
// falta para elegir entre la Enfoque de Play y la de prueba si están las
// dos. Lo hace `MainActivity.kt` con un `Intent(ACTION_VIEW)` y
// `setPackage`.

/// El paquete de Enfoque en Google Play.
const String paqueteEnfoque = 'com.norday.enfoque';

/// El paquete de Enfoque que corresponde al flavor de esta app: la Habits de
/// prueba abre la Enfoque de prueba, que va contra el mismo staging; la de
/// Play (o sin flavor) abre la de Play.
String paqueteEnfoqueDe(String? flavor) =>
    flavor == 'prueba' ? '$paqueteEnfoque.prueba' : paqueteEnfoque;

/// El enlace que abre Enfoque con el hábito [habitoId] como destino:
/// `norday-enfoque://sesion?destino=habito&id=<habitoId>`.
Uri enlaceSesionEnfoque(int habitoId) => Uri(
  scheme: 'norday-enfoque',
  host: 'sesion',
  queryParameters: {'destino': 'habito', 'id': '$habitoId'},
);

/// La ficha de Enfoque en la app de Google Play. Sólo desde la Habits de
/// Play: la de prueba no tiene ficha, y la de Play habla con producción.
final Uri fichaPlayEnfoque = Uri.parse('market://details?id=$paqueteEnfoque');

/// La misma ficha en la web, si no hay app de Google Play.
final Uri fichaWebEnfoque = Uri.parse(
  'https://play.google.com/store/apps/details?id=$paqueteEnfoque',
);

/// Lo que de verdad abre enlaces. En la app es [LanzadorEnlacesAndroid]; en
/// los tests, un falso.
abstract interface class LanzadorEnlaces {
  /// Abre [enlace]; con [paquete], solo con esa app. True si se abrió algo;
  /// false si no había quien lo abriera.
  Future<bool> abrir(Uri enlace, {String? paquete});
}

/// El canal con `MainActivity.kt`.
class LanzadorEnlacesAndroid implements LanzadorEnlaces {
  const LanzadorEnlacesAndroid();

  static const MethodChannel _canal = MethodChannel('com.norday.habitos/abrir');

  @override
  Future<bool> abrir(Uri enlace, {String? paquete}) async {
    try {
      final abierto = await _canal.invokeMethod<bool>('abrir', {
        'enlace': enlace.toString(),
        'paquete': ?paquete,
      });
      return abierto ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // Sin la parte nativa (otra plataforma, tests): no se abre nada.
      return false;
    }
  }
}

/// Qué se acabó abriendo.
enum AperturaEnfoque {
  /// Enfoque, con el hábito como destino.
  app,

  /// La ficha de Enfoque en la app de Google Play.
  fichaPlay,

  /// La ficha de Enfoque en el navegador.
  fichaWeb,

  /// Nada, desde la Habits de prueba sin la Enfoque de prueba instalada. No
  /// se cae a Google Play: su ficha es la de la Enfoque de Play, que habla
  /// con producción, y desde allí se acababa entrando en la app equivocada
  /// (prueba del 16-nov-2026).
  faltaPrueba,

  /// Nada: ni Enfoque, ni Google Play, ni navegador.
  nada,
}

/// Abre Enfoque con el hábito [habitoId]; si no está, su ficha de Google
/// Play, y si tampoco hay Google Play, la ficha en la web. Para en lo primero
/// que se abra. Con el flavor `prueba` sólo intenta la Enfoque de prueba: si
/// no está, [AperturaEnfoque.faltaPrueba].
Future<AperturaEnfoque> abrirEnfoque({
  required int habitoId,
  required String? flavor,
  required LanzadorEnlaces lanzador,
}) async {
  if (await lanzador.abrir(
    enlaceSesionEnfoque(habitoId),
    paquete: paqueteEnfoqueDe(flavor),
  )) {
    return AperturaEnfoque.app;
  }
  if (flavor == 'prueba') return AperturaEnfoque.faltaPrueba;
  if (await lanzador.abrir(fichaPlayEnfoque)) return AperturaEnfoque.fichaPlay;
  if (await lanzador.abrir(fichaWebEnfoque)) return AperturaEnfoque.fichaWeb;
  return AperturaEnfoque.nada;
}

/// Lo que se enseña con [AperturaEnfoque.faltaPrueba]. Sólo lo ve quien
/// desarrolla (la Habits de prueba), por eso no se traduce, como
/// `PantallaEntornoIncorrecto`.
const String textoFaltaEnfoquePrueba =
    'Instala Norday Focus PRUEBA: la app de prueba no abre Google Play, '
    'que lleva a la de producción.';
