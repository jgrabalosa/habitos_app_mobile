/// Motor: traduce el par (fase, estado) que manda el backend a la ilustración
/// que le toca. Único sitio donde vive ese mapeo — MascotaScreen, MiniMascota
/// y el onboarding piden la ruta aquí en vez de repetir el switch.
///
/// Los ficheros se llaman `Nori_{fase}_{estado}.png` con la fase en minúscula
/// y el estado en su forma visual, que no es la del backend:
/// `feliz→sonriente`, `triste→triste`, `dormida→dormido`.
library;

/// Estado del backend → sufijo del fichero.
const Map<String, String> _sufijoDeEstado = {
  'feliz': 'sonriente',
  'triste': 'triste',
  'dormida': 'dormido',
};

const Set<String> _fasesConocidas = {'huevo', 'cria', 'adulto'};

/// Con lo que se pinta cuando el backend manda algo que este cliente aún no
/// conoce. Mismo criterio que `Catalogos`: nunca dejar al usuario sin nada,
/// y ante la duda no dar por hecho que la mascota está contenta.
const String _fasePorDefecto = 'huevo';
const String _estadoPorDefecto = 'triste';

/// Ruta del PNG para una fase y un estado. Siempre devuelve un asset que
/// existe: una fase o un estado desconocidos caen al valor por defecto, así
/// que quien la use no necesita respaldo de emoji ni `errorBuilder`.
String assetMascota({String? fase, String? estado}) {
  final f = fase?.toLowerCase();
  final faseValida = _fasesConocidas.contains(f) ? f! : _fasePorDefecto;
  final sufijo = _sufijoDeEstado[estado] ?? _sufijoDeEstado[_estadoPorDefecto]!;
  return 'assets/mascota/Nori_${faseValida}_$sufijo.png';
}
