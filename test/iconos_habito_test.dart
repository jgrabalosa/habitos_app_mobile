import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/models/iconos_habito.dart';
import 'package:habitos_app_mobile/models/plantilla_habito.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('catálogo', () {
    test('tiene 27 entradas, sin códigos repetidos', () {
      expect(iconosHabito, hasLength(27));
      // Un mapa literal con una clave repetida ni compila, pero los dibujos
      // sí podrían repetirse con códigos distintos: eso tampoco debe pasar.
      expect(iconosHabito.values.toSet(), hasLength(27));
    });

    test('el icono por defecto está en el catálogo', () {
      expect(iconosHabito, contains(codigoIconoPorDefecto));
      expect(codigoIconoPorDefecto, 'sparkles');
    });

    test('un código desconocido o nulo da sparkles', () {
      expect(iconoDeHabito(null), LucideIcons.sparkles);
      expect(iconoDeHabito(''), LucideIcons.sparkles);
      expect(iconoDeHabito('noExiste'), LucideIcons.sparkles);
      expect(iconoDeHabito('bookOpen'), LucideIcons.bookOpen);
    });

    test('cada icono tiene nombre en es, en y pt, distinto del código', () {
      for (final l in ['es', 'en', 'pt']) {
        final loc = lookupAppLocalizations(Locale(l));
        for (final codigo in iconosHabito.keys) {
          final nombre = nombreIconoHabito(loc, codigo);
          expect(nombre, isNotEmpty, reason: '$l $codigo');
          expect(nombre, isNot(codigo), reason: '$l $codigo');
          if (codigo != codigoIconoPorDefecto) {
            expect(
              nombre,
              isNot(nombreIconoHabito(loc, codigoIconoPorDefecto)),
              reason: '$l $codigo cae al nombre por defecto',
            );
          }
        }
      }
    });
  });

  group('plantillas', () {
    test('el codigoIcono de cada plantilla está en el catálogo', () {
      for (final p in plantillasHabito) {
        expect(iconosHabito, contains(p.codigoIcono), reason: p.id);
      }
    });

    test('cada plantilla enseña el mismo icono que antes de T-011b', () {
      expect(
        {for (final p in plantillasHabito) p.id: p.icono},
        {
          'meditar': LucideIcons.flower2,
          'planificarDia': LucideIcons.listChecks,
          'beberAgua': LucideIcons.droplet,
          'comerFrutaVerdura': LucideIcons.apple,
          'caminar': LucideIcons.footprints,
          'tocarInstrumento': LucideIcons.music,
          'ejercicio': LucideIcons.dumbbell,
          'llamarQuerido': LucideIcons.phone,
          'apuntarGastos': LucideIcons.piggyBank,
          'escribirDiario': LucideIcons.notebookPen,
          'leer': LucideIcons.bookOpen,
          'diaSinAlcohol': LucideIcons.wineOff,
          'dejarMovil': LucideIcons.phoneOff,
          'dormir8h': LucideIcons.moon,
        },
      );
    });
  });
}
