import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/services/abrir_enfoque.dart';

/// Contesta con [abre] para cada enlace y apunta lo que se le pide.
class LanzadorFalso implements LanzadorEnlaces {
  final Set<String> abre;
  final List<(String, String?)> pedidos = [];

  LanzadorFalso(this.abre);

  @override
  Future<bool> abrir(Uri enlace, {String? paquete}) async {
    pedidos.add((enlace.toString(), paquete));
    return abre.contains(enlace.toString());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const enlace = 'norday-enfoque://sesion?destino=habito&id=42';
  const market = 'market://details?id=com.norday.enfoque';
  const web =
      'https://play.google.com/store/apps/details?id=com.norday.enfoque';

  test('el enlace lleva el hábito como destino', () {
    expect(enlaceSesionEnfoque(42).toString(), enlace);
    expect(fichaPlayEnfoque.toString(), market);
    expect(fichaWebEnfoque.toString(), web);
  });

  test('cada flavor abre su Enfoque', () {
    expect(paqueteEnfoqueDe('produccion'), 'com.norday.enfoque');
    expect(paqueteEnfoqueDe('prueba'), 'com.norday.enfoque.prueba');
    // Sin flavor (no debería pasar: entorno.dart no arranca), la de Play.
    expect(paqueteEnfoqueDe(null), 'com.norday.enfoque');
  });

  test('instalada: abre Enfoque y no pasa por Play', () async {
    final lanzador = LanzadorFalso({enlace});
    final r = await abrirEnfoque(
      habitoId: 42,
      flavor: 'produccion',
      lanzador: lanzador,
    );
    expect(r, AperturaEnfoque.app);
    expect(lanzador.pedidos, [(enlace, 'com.norday.enfoque')]);
  });

  test('no instalada: la ficha en la app de Google Play', () async {
    final lanzador = LanzadorFalso({market, web});
    final r = await abrirEnfoque(
      habitoId: 42,
      flavor: 'prueba',
      lanzador: lanzador,
    );
    expect(r, AperturaEnfoque.fichaPlay);
    // La ficha siempre es la de Play, también desde la Habits de prueba.
    expect(lanzador.pedidos, [
      (enlace, 'com.norday.enfoque.prueba'),
      (market, null),
    ]);
  });

  test('sin Google Play: la ficha en la web', () async {
    final lanzador = LanzadorFalso({web});
    final r = await abrirEnfoque(
      habitoId: 42,
      flavor: 'produccion',
      lanzador: lanzador,
    );
    expect(r, AperturaEnfoque.fichaWeb);
    expect(lanzador.pedidos.map((p) => p.$1), [enlace, market, web]);
  });

  test('nada que lo abra: nada', () async {
    final r = await abrirEnfoque(
      habitoId: 42,
      flavor: 'produccion',
      lanzador: LanzadorFalso({}),
    );
    expect(r, AperturaEnfoque.nada);
  });

  test('sin la parte nativa, el lanzador real dice que no', () async {
    // En `flutter test` no hay MainActivity: MissingPluginException → false.
    expect(
      await const LanzadorEnlacesAndroid().abrir(
        enlaceSesionEnfoque(1),
        paquete: paqueteEnfoque,
      ),
      isFalse,
    );
  });
}
