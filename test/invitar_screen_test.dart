import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/invitar_screen.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<DatoNori?> datoPipo(int _) async =>
    const DatoNori(fase: 'cria', nombre: 'Pipo', nivel: 7);

Future<ShareResult> compartirNada(ShareParams _) async =>
    const ShareResult('', ShareResultStatus.success);

Future<void> medirNada(String _, {required bool conDato}) async {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final identidadInicial = identidadEquipadaNotifier.value;

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Widget app(Widget home) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: const Locale('es'),
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      ...NordayCoreLocalizations.localizationsDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  /// Nori, vestida y contenta, en [fase].
  Finder imagenNori(String fase) => find.byWidgetPredicate(
    (w) => w is NoriVestida && w.fase == fase && w.estado == 'exultante',
  );

  Finder enTarjeta(Finder f) =>
      find.descendant(of: find.byType(TarjetaInvitacion), matching: f);

  /// Monta la pantalla y deja que llegue el dato de Nori.
  Future<void> montar(
    WidgetTester tester, {
    CompartirInvitacion compartir = compartirNada,
    CargarDatoNori cargarDato = datoPipo,
    MedirCompartido medir = medirNada,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        InvitarScreen(
          usuarioId: 1,
          compartir: compartir,
          cargarDato: cargarDato,
          medirCompartido: medir,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Pulsa «Compartir» y espera al menú (la captura y el PNG son trabajo
  /// real del motor, no del reloj falso).
  Future<ShareParams> compartirYEsperar(
    WidgetTester tester,
    List<ShareParams> enviados,
  ) async {
    await tester.runAsync(() async {
      await tester.tap(find.text('Compartir'));
      for (var i = 0; i < 100 && enviados.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    expect(enviados, hasLength(1));
    return enviados.single;
  }

  testWidgets('con dato, la postal lleva el nombre y el nivel de Nori', (
    tester,
  ) async {
    await montar(tester);
    expect(enTarjeta(find.text('Pipo ya es cría · nivel 7')), findsOneWidget);
  });

  testWidgets('sin nombre, el dato habla de «Mi Nori»', (tester) async {
    await montar(
      tester,
      cargarDato: (_) async => const DatoNori(fase: 'cria', nivel: 7),
    );
    expect(
      enTarjeta(find.text('Mi Nori ya es cría · nivel 7')),
      findsOneWidget,
    );
  });

  testWidgets('el interruptor sale encendido y, apagado, quita el dato', (
    tester,
  ) async {
    await montar(tester);
    final interruptor = find.widgetWithText(
      SwitchListTile,
      'Incluir el nombre y el nivel de Nori',
    );
    expect(interruptor, findsOneWidget);
    expect(tester.widget<SwitchListTile>(interruptor).value, isTrue);

    await tester.tap(interruptor);
    await tester.pump();

    expect(tester.widget<SwitchListTile>(interruptor).value, isFalse);
    expect(enTarjeta(find.textContaining('Pipo')), findsNothing);
    expect(enTarjeta(find.textContaining('nivel')), findsNothing);
    // Nori sigue en su fase: lo que se quita es el dato, no Nori.
    expect(enTarjeta(imagenNori('cria')), findsOneWidget);
  });

  testWidgets('apagado, se comparte sin dato y Analytics lo dice', (
    tester,
  ) async {
    final enviados = <ShareParams>[];
    final medidos = <bool>[];
    await montar(
      tester,
      compartir: (p) async {
        enviados.add(p);
        return const ShareResult('', ShareResultStatus.success);
      },
      medir: (_, {required conDato}) async => medidos.add(conDato),
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await compartirYEsperar(tester, enviados);
    expect(medidos, [false]);
  });

  testWidgets('encendido, Analytics mide con_dato a true', (tester) async {
    final enviados = <ShareParams>[];
    final medidos = <bool>[];
    await montar(
      tester,
      compartir: (p) async {
        enviados.add(p);
        return const ShareResult('', ShareResultStatus.success);
      },
      medir: (_, {required conDato}) async => medidos.add(conDato),
    );
    await compartirYEsperar(tester, enviados);
    expect(medidos, [true]);
  });

  testWidgets('sin red, Nori sale adulta, sin dato, y se comparte igual', (
    tester,
  ) async {
    final enviados = <ShareParams>[];
    final medidos = <bool>[];
    await montar(
      tester,
      cargarDato: (_) async => throw Exception('sin red'),
      compartir: (p) async {
        enviados.add(p);
        return const ShareResult('', ShareResultStatus.success);
      },
      medir: (_, {required conDato}) async => medidos.add(conDato),
    );
    expect(tester.takeException(), isNull);
    expect(enTarjeta(imagenNori('adulto')), findsOneWidget);
    expect(enTarjeta(find.textContaining('nivel')), findsNothing);
    // Sin dato no hay nada que quitar.
    expect(find.byType(SwitchListTile), findsNothing);

    final p = await compartirYEsperar(tester, enviados);
    expect(p.files, hasLength(1));
    expect(medidos, [false]);
  });

  testWidgets('la postal no lleva panel ni enlace dibujado', (tester) async {
    await montar(tester);
    expect(enTarjeta(find.byType(SuperficieIdentidad)), findsNothing);
    expect(enTarjeta(find.textContaining('norday.app')), findsNothing);
    expect(enTarjeta(find.byType(FondoIdentidad)), findsOneWidget);
    expect(enTarjeta(find.byType(WordmarkIdentidad)), findsOneWidget);
  });

  testWidgets('Nori va vestida y ocupa entre el 55 y el 60 % del alto', (
    tester,
  ) async {
    await montar(tester);
    final nori = enTarjeta(find.byType(NoriVestida));
    expect(nori, findsOneWidget);
    expect(
      tester.widget<NoriVestida>(nori).prendas,
      same(prendasEquipadasNotifier),
    );
    // La caja de NoriVestida es mayor que la figura (el dibujo deja aire
    // alrededor); lo que se mide es lo que se ve.
    expect(
      tester.widget<NoriVestida>(nori).tamano,
      TarjetaInvitacion.tamanoNori('cria'),
    );
    expect(
      TarjetaInvitacion.altoFiguraNori / TarjetaInvitacion.alto,
      inInclusiveRange(0.55, 0.60),
    );
    // Y la figura cabe entre el dato y el wordmark (en puntos de la
    // tarjeta: en pantalla va escalada).
    final tarjeta = tester.getRect(find.byType(TarjetaInvitacion));
    double enPuntos(double y) =>
        (y - tarjeta.top) / tarjeta.height * TarjetaInvitacion.alto;
    final dato = tester.getRect(
      enTarjeta(find.text('Pipo ya es cría · nivel 7')),
    );
    final wordmark = tester.getRect(enTarjeta(find.byType(WordmarkIdentidad)));
    expect(
      TarjetaInvitacion.arribaFiguraNori,
      greaterThan(enPuntos(dato.bottom)),
    );
    expect(
      TarjetaInvitacion.arribaFiguraNori + TarjetaInvitacion.altoFiguraNori,
      lessThan(enPuntos(wordmark.top)),
    );
  });

  for (final codigo in [
    'TEMA_PROFUNDIDAD',
    'TEMA_NEOTOKYO_PLUS',
    'TEMA_DULCE',
  ]) {
    testWidgets('en $codigo, la postal se pinta sin panel y con su fondo', (
      tester,
    ) async {
      aplicarIdentidadEquipada(codigo);
      await montar(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(enTarjeta(find.byType(SuperficieIdentidad)), findsNothing);
      expect(enTarjeta(find.byType(FondoIdentidad)), findsOneWidget);
      expect(enTarjeta(find.text('Pipo ya es cría · nivel 7')), findsOneWidget);
    });
  }

  testWidgets('«Compartir» envía un PNG de 1080 × 1350 y el texto con enlace', (
    tester,
  ) async {
    final enviados = <ShareParams>[];
    await montar(
      tester,
      compartir: (p) async {
        enviados.add(p);
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    final p = await compartirYEsperar(tester, enviados);

    expect(p.text, endsWith('\nhttps://norday.app/invitar'));
    expect(p.fileNameOverrides, ['norday-invitacion.png']);
    expect(p.files, hasLength(1));
    final fichero = p.files!.single;
    expect(fichero.mimeType, 'image/png');
    final bytes = (await tester.runAsync(fichero.readAsBytes))!;
    expect(bytes, isNotEmpty);
    // La firma de un PNG y, en su cabecera IHDR, el ancho y el alto.
    expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    int entero(int i) =>
        (bytes[i] << 24) |
        (bytes[i + 1] << 16) |
        (bytes[i + 2] << 8) |
        bytes[i + 3];
    expect(entero(16), 1080);
    expect(entero(20), 1350);
  });

  testWidgets('la imagen compartida no tiene huecos: las esquinas son opacas', (
    tester,
  ) async {
    // Un PNG transparente sale negro o blanco en una historia: detrás va el
    // fondo de la identidad.
    final enviados = <ShareParams>[];
    await montar(
      tester,
      compartir: (p) async {
        enviados.add(p);
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    final p = await compartirYEsperar(tester, enviados);
    final alfas = await tester.runAsync(() async {
      final bytes = await p.files!.single.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final imagen = (await codec.getNextFrame()).image;
      final rgba = (await imagen.toByteData())!;
      int alfa(int x, int y) => rgba.getUint8((y * imagen.width + x) * 4 + 3);
      final r = [
        alfa(0, 0),
        alfa(imagen.width - 1, 0),
        alfa(0, imagen.height - 1),
        alfa(imagen.width - 1, imagen.height - 1),
      ];
      imagen.dispose();
      return r;
    });
    expect(alfas, [255, 255, 255, 255]);
  });

  testWidgets('si el envío falla, sale un SnackBar y no lanza', (tester) async {
    await montar(
      tester,
      compartir: (_) async => throw Exception('sin menú de compartir'),
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Compartir'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.text('No se ha podido compartir la invitación. Inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  test('el texto que acompaña, en los tres idiomas, con el enlace aparte', () {
    const enlace = 'https://norday.app/invitar';
    expect(
      lookupAppLocalizations(const Locale('es')).invitarTextoCompartir(enlace),
      'Mira cómo va mi Nori: crece cada vez que marco un hábito, y si un día '
      'fallo no pasa nada. ¿Te haces uno? Es gratis y sin anuncios.\n'
      '$enlace',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).invitarTextoCompartir(enlace),
      'Look how my Nori is doing: he grows every time I tick off a habit, '
      'and if I miss a day, that\'s fine. Want one too? It\'s free and has no '
      'ads.\n'
      '$enlace',
    );
    expect(
      lookupAppLocalizations(const Locale('pt')).invitarTextoCompartir(enlace),
      'Vê como está o meu Nori: cresce sempre que marco um hábito e, se um '
      'dia falho, não faz mal. Também queres um? É grátis e sem anúncios.\n'
      '$enlace',
    );
  });

  test('el dato, en los tres idiomas y en las tres fases', () {
    String dato(String idioma, DatoNori d) =>
        textoDatoNori(lookupAppLocalizations(Locale(idioma)), d);
    const pipo = DatoNori(fase: 'cria', nombre: 'Pipo', nivel: 7);
    const sinNombre = DatoNori(fase: 'cria', nivel: 7);
    expect(dato('es', pipo), 'Pipo ya es cría · nivel 7');
    expect(dato('es', sinNombre), 'Mi Nori ya es cría · nivel 7');
    expect(
      dato('es', const DatoNori(fase: 'huevo', nivel: 1)),
      'Mi Nori aún es un huevo · nivel 1',
    );
    expect(
      dato('es', const DatoNori(fase: 'adulto', nombre: 'Pipo', nivel: 12)),
      'Pipo ya ha crecido · nivel 12',
    );
    expect(dato('en', pipo), 'Pipo is a hatchling now · level 7');
    expect(dato('en', sinNombre), 'My Nori is a hatchling now · level 7');
    expect(dato('pt', pipo), 'Pipo já é uma cria · nível 7');
    expect(dato('pt', sinNombre), 'O meu Nori já é uma cria · nível 7');
  });

  test('el dato sale de getMascota: nombre, nivel y fase', () {
    final d = DatoNori.desdeMascota({
      'nombre': '  Pipo ',
      'nivel': 7,
      'fase': 'CRIA',
    });
    expect(d.nombre, 'Pipo');
    expect(d.nivel, 7);
    expect(d.fase, 'cria');
    expect(d.tieneDato, isTrue);

    final vacio = DatoNori.desdeMascota({'nombre': '', 'fase': 'dragón'});
    expect(vacio.nombre, isNull);
    expect(vacio.nivel, isNull);
    expect(vacio.fase, 'adulto');
    expect(vacio.tieneDato, isFalse);
  });

  test('el resultado del menú se mide con su nombre', () {
    expect(resultadoCompartir(ShareResultStatus.success), 'compartido');
    expect(resultadoCompartir(ShareResultStatus.dismissed), 'cancelado');
    expect(resultadoCompartir(ShareResultStatus.unavailable), 'no_disponible');
  });

  test('la fase del backend se lleva a una con imagen', () {
    expect(normalizarFaseNori('HUEVO'), 'huevo');
    expect(normalizarFaseNori('cría'), 'cria');
    expect(normalizarFaseNori('adulto'), 'adulto');
    expect(normalizarFaseNori(null), 'adulto');
    expect(normalizarFaseNori('dragón'), 'adulto');
  });

  test('las tres fases tienen su Nori exultante en los assets', () async {
    for (final fase in fasesNori) {
      final datos = await rootBundle.load(
        'packages/norday_flutter_core/'
        '${assetMascota(fase: fase, estado: 'exultante')}',
      );
      expect(datos.lengthInBytes, greaterThan(0), reason: fase);
    }
  });
}
