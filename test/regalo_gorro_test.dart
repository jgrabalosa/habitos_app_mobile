import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/widgets/regalo_gorro.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La tarjeta que regala el gorro de Papá Noel: cuándo sale y qué hace el
/// botón.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    RegaloGorro.reiniciarParaTest();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const gorroId = 77;

  Map<String, dynamic> gorro({
    String desde = '2026-11-20',
    String hasta = '2027-01-07',
    int precio = 0,
  }) => {
    'productoId': gorroId,
    'codigo': 'PRENDA_GORRO_NOEL',
    'categoria': 'Cabeza',
    'precio': 150,
    'ofertas': [
      {'desde': desde, 'hasta': hasta, 'precio': precio},
    ],
  };

  Map<String, dynamic> inventarioDe(
    int id,
    String categoria, {
    bool equipado = false,
  }) => {
    'equipado': equipado,
    'producto': {'productoId': id, 'codigo': 'X$id', 'categoria': categoria},
  };

  // Lo que han pedido los seams.
  late List<String> compras;
  late List<String> equipados;

  void preparar({
    List<dynamic>? catalogo,
    List<dynamic> inventario = const [],
    Future<List<String>> Function(int, int)? comprar,
    bool falloCatalogo = false,
    bool falloInventario = false,
    DateTime? hoy,
  }) {
    compras = [];
    equipados = [];
    RegaloGorro.obtenerCatalogo = () async {
      if (falloCatalogo) throw Exception('sin red');
      return catalogo ?? [gorro()];
    };
    RegaloGorro.obtenerInventario = (_) async {
      if (falloInventario) throw Exception('sin red');
      return inventario;
    };
    RegaloGorro.comprar =
        comprar ??
        (u, p) async {
          compras.add('$u:$p');
          return <String>[];
        };
    RegaloGorro.equipar = (u, p, codigo, sitio) async {
      equipados.add('$u:$p:$codigo:$sitio');
      return <String>[];
    };
    RegaloGorro.ahora = () => hoy ?? DateTime(2026, 11, 22);
  }

  Widget montar({bool altaNueva = false, Locale locale = const Locale('es')}) =>
      MaterialApp(
        locale: locale,
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          NordayCoreLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => RegaloGorro.mostrarSiToca(
                  context,
                  usuarioId: 5,
                  altaNueva: altaNueva,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

  Future<void> abrir(
    WidgetTester tester, {
    bool altaNueva = false,
    Locale locale = const Locale('es'),
  }) async {
    await tester.pumpWidget(montar(altaNueva: altaNueva, locale: locale));
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<AppLocalizations> textos([String idioma = 'es']) =>
      AppLocalizations.delegate.load(Locale(idioma));

  Finder boton(AppLocalizations l) =>
      find.widgetWithText(ElevatedButton, l.regaloGorroBoton);

  group('cuándo sale', () {
    testWidgets('sale con la oferta vigente y sin el gorro', (tester) async {
      preparar();
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.regaloGorroTitulo), findsOneWidget);
      expect(find.text(l.regaloGorroCuerpo), findsOneWidget);
      expect(boton(l), findsOneWidget);
    });

    testWidgets('no sale si ya lo tiene', (tester) async {
      preparar(inventario: [inventarioDe(gorroId, 'Cabeza')]);
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('no sale fuera de la oferta (el 8-ene)', (tester) async {
      preparar(hoy: DateTime(2027, 1, 8));
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('no sale si el gorro no es gratis hoy', (tester) async {
      preparar(catalogo: [gorro(precio: 100)]);
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('no sale si el catálogo no trae el gorro', (tester) async {
      preparar(catalogo: []);
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('no sale si falla el catálogo', (tester) async {
      preparar(falloCatalogo: true);
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('no sale si falla el inventario', (tester) async {
      preparar(falloInventario: true);
      final l = await textos();
      await abrir(tester);

      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('no sale en un alta nueva', (tester) async {
      preparar();
      final l = await textos();
      await abrir(tester, altaNueva: true);

      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });
  });

  group('no se cierra solo', () {
    testWidgets('ni tocando fuera ni con atrás', (tester) async {
      preparar();
      final l = await textos();
      await abrir(tester);

      await tester.tapAt(const Offset(2, 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l.regaloGorroTitulo), findsOneWidget);

      await tester.binding.handlePopRoute();
      // Un pump sin duración antes: el ticker de la salida toma la hora en su
      // primer tic.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l.regaloGorroTitulo), findsOneWidget);
    });
  });

  group('el botón', () {
    testWidgets('compra, equipa si no lleva nada en la cabeza y se cierra', (
      tester,
    ) async {
      preparar(inventario: [inventarioDe(3, 'Cuello', equipado: true)]);
      final l = await textos();
      await abrir(tester);

      await tester.tap(boton(l));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(compras, ['5:$gorroId']);
      expect(equipados, ['5:$gorroId:PRENDA_GORRO_NOEL:Cabeza']);
      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('con otra prenda en la cabeza compra pero no equipa', (
      tester,
    ) async {
      preparar(inventario: [inventarioDe(3, 'Cabeza', equipado: true)]);
      final l = await textos();
      await abrir(tester);

      await tester.tap(boton(l));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(compras, ['5:$gorroId']);
      expect(equipados, isEmpty);
      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('una prenda de cabeza sin equipar no cuenta como puesta', (
      tester,
    ) async {
      preparar(inventario: [inventarioDe(3, 'Cabeza')]);
      final l = await textos();
      await abrir(tester);

      await tester.tap(boton(l));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(equipados, hasLength(1));
    });

    testWidgets('mientras compra se desactiva y enseña que trabaja', (
      tester,
    ) async {
      preparar();
      final espera = Completer<List<String>>();
      RegaloGorro.comprar = (u, p) => espera.future;
      final l = await textos();
      await abrir(tester);

      await tester.tap(boton(l));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final b = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(b.onPressed, isNull);

      espera.complete(<String>[]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('un 409 cuenta como hecho: equipa y se cierra', (tester) async {
      preparar();
      RegaloGorro.comprar = (u, p) async => throw const ApiException(
        TipoErrorApi.peticionInvalida,
        codigoEstado: 409,
      );
      final l = await textos();
      await abrir(tester);

      await tester.tap(boton(l));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(equipados, ['5:$gorroId:PRENDA_GORRO_NOEL:Cabeza']);
      expect(find.text(l.regaloGorroTitulo), findsNothing);
    });

    testWidgets('si la compra falla, se cierra sin equipar ni avisar', (
      tester,
    ) async {
      preparar();
      RegaloGorro.comprar = (u, p) async =>
          throw const ApiException(TipoErrorApi.servidor, codigoEstado: 500);
      final l = await textos();
      await abrir(tester);

      await tester.tap(boton(l));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(equipados, isEmpty);
      expect(find.text(l.regaloGorroTitulo), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('si equipar falla, se cierra igual', (tester) async {
      preparar();
      RegaloGorro.equipar = (u, p, c, s) async => throw Exception('red');
      final l = await textos();
      await abrir(tester);

      await tester.tap(boton(l));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l.regaloGorroTitulo), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('los textos', () {
    const esperados = {
      'es': (
        '¡Jo, jo, jo! 🎅',
        'Nori ha vuelto del Polo Norte con un gorro de Papá Noel para ti. Es gratis y tuyo para siempre.',
        '¡Lo quiero ya!',
      ),
      'en': (
        'Ho, ho, ho! 🎅',
        "Nori is back from the North Pole with a Santa hat for you. It's free and yours forever.",
        'I want it now!',
      ),
      'pt': (
        'Oh, oh, oh! 🎅',
        'O Nori voltou do Polo Norte com um gorro de Pai Natal para ti. É grátis e teu para sempre.',
        'Quero-o já!',
      ),
    };

    for (final MapEntry(key: idioma, value: (titulo, cuerpo, accion))
        in esperados.entries) {
      testWidgets('en $idioma', (tester) async {
        preparar();
        await abrir(tester, locale: Locale(idioma));

        expect(find.text(titulo), findsOneWidget);
        expect(find.text(cuerpo), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, accion), findsOneWidget);
      });
    }
  });
}
