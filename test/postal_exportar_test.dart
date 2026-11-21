import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/screens/invitar_screen.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No es un test: exporta la postal de invitación en las tres identidades,
/// con y sin dato (y, en Profundidad, en las otras dos fases), a
/// `build/postal/`, para enseñarla en un PR. Solo corre a petición:
///
/// `flutter test test/postal_exportar_test.dart --dart-define=EXPORTAR_POSTAL=true`
///
/// Las letras y el dibujo de Nori salen de los assets; las prendas, que la
/// app descarga, no salen aquí: Nori va sin prendas.
const exportar = bool.fromEnvironment('EXPORTAR_POSTAL');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final identidadInicial = identidadEquipadaNotifier.value;

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  const identidades = ['TEMA_PROFUNDIDAD', 'TEMA_NEOTOKYO_PLUS', 'TEMA_DULCE'];
  final variantes = <(String, String, DatoNori?)>[
    for (final codigo in identidades) ...[
      (
        codigo,
        'con_dato',
        const DatoNori(fase: 'cria', nombre: 'Pipo', nivel: 7),
      ),
      (codigo, 'sin_dato', null),
    ],
    ('TEMA_PROFUNDIDAD', 'huevo', const DatoNori(fase: 'huevo', nivel: 1)),
    (
      'TEMA_PROFUNDIDAD',
      'adulto',
      const DatoNori(fase: 'adulto', nombre: 'Pipo', nivel: 12),
    ),
  ];

  for (final (codigo, sufijo, dato) in variantes) {
    final nombre = '${codigo.toLowerCase()}_$sufijo';
    testWidgets('exporta $nombre', skip: !exportar, (tester) async {
      aplicarIdentidadEquipada(codigo);
      final clave = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.deTema(temaEquipadoNotifier.value),
          locale: const Locale('es'),
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...NordayCoreLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Center(
            child: RepaintBoundary(
              key: clave,
              child: TarjetaInvitacion(fase: dato?.fase ?? 'cria', dato: dato),
            ),
          ),
        ),
      );
      // Las letras y el dibujo de Nori se cargan de verdad, fuera del reloj
      // falso.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.runAsync(() async {
        final boundary =
            clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final imagen = await boundary.toImage(
          pixelRatio: TarjetaInvitacion.anchoPx / TarjetaInvitacion.ancho,
        );
        final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
        imagen.dispose();
        final fichero = File('build/postal/$nombre.png');
        await fichero.create(recursive: true);
        await fichero.writeAsBytes(png!.buffer.asUint8List());
      });
    });
  }
}
