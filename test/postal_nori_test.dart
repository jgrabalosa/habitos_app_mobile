import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/services/analytics_service.dart';
import 'package:habitos_app_mobile/services/postal_nori.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final menuOriginal = PostalNori.menu;
  final medirOriginal = PostalNori.medir;

  late List<ShareParams> enviados;
  late List<(String, String)> medidos;
  late ShareResultStatus estadoMenu;

  setUp(() {
    enviados = [];
    medidos = [];
    estadoMenu = ShareResultStatus.success;
    PostalNori.menu = (p) async {
      enviados.add(p);
      return ShareResult('', estadoMenu);
    };
    PostalNori.medir = ({required identidad, required fase}) async =>
        medidos.add((identidad, fase));
  });

  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    PostalNori.menu = menuOriginal;
    PostalNori.medir = medirOriginal;
  });

  const datos = DatosNori(fase: 'CRIA', nombre: 'Brote', nivel: 3);

  /// Monta una app, llama a `compartir` y deja correr el motor real (la
  /// captura no es cosa del reloj falso) hasta que el menú se abre o se agota
  /// la espera.
  Future<void> compartir(WidgetTester tester, {String idioma = 'es'}) async {
    late BuildContext contexto;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        locale: Locale(idioma),
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...NordayCoreLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            contexto = c;
            return const Scaffold();
          },
        ),
      ),
    );
    final hecho = PostalNori.compartir(contexto, datos);
    for (var i = 0; i < 150 && enviados.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.runAsync(() => hecho);
  }

  int entero(List<int> b, int i) =>
      (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];

  testWidgets('manda un PNG de 1080 × 1350 y el texto con el enlace', (
    tester,
  ) async {
    await compartir(tester);

    expect(enviados, hasLength(1));
    final p = enviados.single;
    expect(
      p.text,
      'Este es mi Nori en Norday Habits. ¿Te animas? '
      'https://norday.app/invitar',
    );
    expect(p.fileNameOverrides, ['norday-nori.png']);
    expect(p.files, hasLength(1));
    expect(p.files!.single.mimeType, 'image/png');
    final bytes = (await tester.runAsync(p.files!.single.readAsBytes))!;
    expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(entero(bytes, 16), 1080);
    expect(entero(bytes, 20), 1350);
  });

  testWidgets('compartido, mide una vez con la identidad y la fase', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    await compartir(tester);
    expect(medidos, [('TEMA_DULCE', 'CRIA')]);
  });

  testWidgets('con el menú cancelado, no mide', (tester) async {
    estadoMenu = ShareResultStatus.dismissed;
    await compartir(tester);
    expect(enviados, hasLength(1));
    expect(medidos, isEmpty);
  });

  testWidgets('si el menú falla, no lanza y no mide', (tester) async {
    PostalNori.menu = (_) async => throw StateError('sin menú');
    await compartir(tester);
    expect(medidos, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el texto, en inglés y en portugués', (tester) async {
    await compartir(tester, idioma: 'en');
    expect(
      enviados.single.text,
      'This is my Nori in Norday Habits. Want to join? '
      'https://norday.app/invitar',
    );
    enviados.clear();
    await compartir(tester, idioma: 'pt');
    expect(
      enviados.single.text,
      'Este é o meu Nori no Norday Habits. Vens experimentar? '
      'https://norday.app/invitar',
    );
  });

  test('los parámetros de nori_compartido: identidad y fase', () {
    expect(
      AnalyticsHabitos.parametrosNoriCompartido(
        identidad: 'TEMA_DULCE',
        fase: 'CRIA',
      ),
      {'identidad': 'TEMA_DULCE', 'fase': 'CRIA'},
    );
  });
}
