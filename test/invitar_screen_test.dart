import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/invitar_screen.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> faseCria(int _) async => 'cria';

Future<ShareResult> compartirNada(ShareParams _) async =>
    const ShareResult('', ShareResultStatus.success);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  /// La imagen fija de Nori, contenta, en [fase].
  Finder imagenNori(String fase) => find.byWidgetPredicate((w) {
    if (w is! Image) return false;
    final imagen = w.image;
    return imagen is AssetImage &&
        imagen.assetName == assetMascota(fase: fase, estado: 'exultante');
  });

  /// Monta la pantalla y deja que llegue la fase de Nori.
  Future<void> montar(
    WidgetTester tester, {
    CompartirInvitacion compartir = compartirNada,
    CargarFaseNori cargarFase = faseCria,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        InvitarScreen(
          usuarioId: 1,
          compartir: compartir,
          cargarFase: cargarFase,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('pinta la tarjeta con norday.app/invitar', (tester) async {
    await montar(tester);
    expect(find.byType(TarjetaInvitacion), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TarjetaInvitacion),
        matching: find.text('norday.app/invitar'),
      ),
      findsOneWidget,
    );
    expect(find.text('Constancia, no perfección'), findsOneWidget);
  });

  testWidgets('la tarjeta es la superficie protagonista de la identidad', (
    tester,
  ) async {
    // Una tarjeta pintada a mano no sale a lápiz en Dulce ni achaflanada en
    // Neotokyo+ (CLAUDE.md del core): tiene que ser SuperficieIdentidad.
    await montar(tester);
    final superficie = find.descendant(
      of: find.byType(TarjetaInvitacion),
      matching: find.byType(SuperficieIdentidad),
    );
    expect(superficie, findsOneWidget);
    expect(tester.widget<SuperficieIdentidad>(superficie).protagonista, isTrue);
  });

  testWidgets('la tarjeta lleva Nori en la fase que manda el backend', (
    tester,
  ) async {
    await montar(tester);
    expect(
      find.descendant(
        of: find.byType(TarjetaInvitacion),
        matching: imagenNori('cria'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('si getMascota falla, Nori sale adulta y no lanza', (
    tester,
  ) async {
    await montar(tester, cargarFase: (_) async => throw Exception('sin red'));
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(TarjetaInvitacion),
        matching: imagenNori('adulto'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('«Compartir» envía un PNG de 1080 × 1920 y el texto con enlace', (
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
    // La captura y el PNG son trabajo real del motor, no del reloj falso.
    await tester.runAsync(() async {
      await tester.tap(find.text('Compartir'));
      for (var i = 0; i < 50 && enviados.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();

    expect(enviados, hasLength(1));
    final p = enviados.single;
    expect(p.text, contains('https://norday.app/invitar'));
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
    expect(entero(20), 1920);
  });

  testWidgets('la imagen compartida no tiene huecos: las esquinas son opacas', (
    tester,
  ) async {
    // Fuera de las esquinas redondeadas o achaflanadas, un PNG transparente
    // sale negro o blanco en una historia: detrás va el fondo de la identidad.
    final enviados = <ShareParams>[];
    await montar(
      tester,
      compartir: (p) async {
        enviados.add(p);
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    final alfas = await tester.runAsync(() async {
      await tester.tap(find.text('Compartir'));
      for (var i = 0; i < 50 && enviados.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      final bytes = await enviados.single.files!.single.readAsBytes();
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
    await tester.pump();

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
