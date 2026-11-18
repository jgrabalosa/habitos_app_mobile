import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/l10n/catalogos.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/models/plantilla_habito.dart';

PlantillaHabito _plantilla(String id) =>
    plantillasHabito.firstWhere((p) => p.id == id);

void main() {
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  group('plantillasDisponibles', () {
    test('sin hábitos existentes salen las 14, en el orden del día', () {
      expect(plantillasDisponibles(const []).map((p) => p.id), [
        'meditar',
        'planificarDia',
        'beberAgua',
        'comerFrutaVerdura',
        'caminar',
        'tocarInstrumento',
        'ejercicio',
        'llamarQuerido',
        'apuntarGastos',
        'escribirDiario',
        'leer',
        'diaSinAlcohol',
        'dejarMovil',
        'dormir8h',
      ]);
    });

    test('no hay ids repetidos', () {
      final ids = plantillasHabito.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('van ordenadas por la hora del aviso', () {
      int minutos(TimeOfDay t) => t.hour * 60 + t.minute;
      for (var i = 1; i < plantillasHabito.length; i++) {
        expect(
          minutos(plantillasHabito[i].horaAviso),
          greaterThanOrEqualTo(minutos(plantillasHabito[i - 1].horaAviso)),
          reason: plantillasHabito[i].id,
        );
      }
    });

    test('un hábito con el nombre de una plantilla la oculta', () {
      final disponibles = plantillasDisponibles([es.plantillaBeberAgua]);
      expect(disponibles, hasLength(13));
      expect(disponibles.map((p) => p.id), isNot(contains('beberAgua')));
    });

    test('el nombre en otro idioma también la oculta', () {
      final disponibles = plantillasDisponibles([en.plantillaBeberAgua]);
      expect(disponibles.map((p) => p.id), isNot(contains('beberAgua')));
    });

    test('si todas existen, no queda ninguna', () {
      final nombres = [
        for (final p in plantillasHabito) nombrePlantilla(es, p.id),
      ];
      expect(plantillasDisponibles(nombres), isEmpty);
    });

    test('cada plantilla tiene nombre en es, en y pt', () {
      for (final p in plantillasHabito) {
        for (final l in [es, en, pt]) {
          expect(nombrePlantilla(l, p.id), isNot(p.id), reason: p.id);
        }
      }
    });

    test('los nombres antiguos «Escribir diario» y «Dormir 8h» ocultan su '
        'plantilla', () {
      final ids = plantillasDisponibles([
        'Escribir diario',
        'Dormir 8h',
      ]).map((p) => p.id);
      expect(ids, isNot(contains('escribirDiario')));
      expect(ids, isNot(contains('dormir8h')));
      expect(
        plantillasDisponibles(['Escrever diário']).map((p) => p.id),
        isNot(contains('escribirDiario')),
      );
      expect(
        plantillasDisponibles(['Sleep 8h']).map((p) => p.id),
        isNot(contains('dormir8h')),
      );
    });

    test('los nombres nuevos', () {
      expect(nombrePlantilla(es, 'escribirDiario'), 'Escribir en el diario');
      expect(nombrePlantilla(en, 'escribirDiario'), 'Journal');
      expect(nombrePlantilla(pt, 'escribirDiario'), 'Escrever no diário');
      expect(nombrePlantilla(es, 'dormir8h'), 'Dormir 8 horas');
      expect(nombrePlantilla(en, 'dormir8h'), 'Sleep 8 hours');
      expect(
        nombrePlantilla(pt, 'dejarMovil'),
        'Deixar o telemóvel antes de dormir',
      );
    });
  });

  group('valores de las plantillas', () {
    testWidgets('cada categoría de la app tiene al menos una plantilla', (
      tester,
    ) async {
      late Iterable<String> codigos;
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('es'),
          delegates: AppLocalizations.localizationsDelegates,
          child: Builder(
            builder: (context) {
              codigos = Catalogos.codigosCategoria(context).toList();
              return const SizedBox();
            },
          ),
        ),
      );
      expect(codigos, hasLength(10));
      final conPlantilla = plantillasHabito.map((p) => p.categoriaCodigo);
      for (final c in codigos) {
        expect(conPlantilla, contains(c), reason: c);
      }
    });

    test('cada una trae su hora de aviso', () {
      final horas = {
        for (final p in plantillasHabito)
          p.id: '${p.horaAviso.hour}:${p.horaAviso.minute}',
      };
      expect(horas, {
        'meditar': '8:0',
        'planificarDia': '9:0',
        'beberAgua': '10:0',
        'comerFrutaVerdura': '13:0',
        'caminar': '18:0',
        'tocarInstrumento': '18:30',
        'ejercicio': '19:0',
        'llamarQuerido': '19:30',
        'apuntarGastos': '21:0',
        'escribirDiario': '21:30',
        'leer': '22:0',
        'diaSinAlcohol': '22:30',
        'dejarMovil': '22:30',
        'dormir8h': '23:0',
      });
    });

    test('Caminar es de minutos: diario, 30 min', () {
      final p = _plantilla('caminar');
      expect(p.unidad, UnidadHabito.minutos);
      expect(p.minutos, 30);
      expect(p.frecuencia, 'DIARIO');
    });

    test('Llamar a alguien querido es semanal flexible de 2 días', () {
      final p = _plantilla('llamarQuerido');
      expect(p.frecuencia, 'SEMANAL');
      expect(p.meta, 2);
      expect(p.dias, isNull);
    });
  });

  group('unidad y minutos', () {
    test('Leer es de minutos: diario, 30 min, y se llama «Leer»', () {
      final p = _plantilla('leer');
      expect(p.unidad, UnidadHabito.minutos);
      expect(p.minutos, 30);
      expect(p.frecuencia, 'DIARIO');
      expect(p.meta, 1);
      expect(nombrePlantilla(es, 'leer'), 'Leer');
      expect(nombrePlantilla(en, 'leer'), 'Read');
      expect(nombrePlantilla(pt, 'leer'), 'Ler');
    });

    test('Meditar es de minutos: diario, 15 min', () {
      final p = _plantilla('meditar');
      expect(p.unidad, UnidadHabito.minutos);
      expect(p.minutos, 15);
      expect(p.frecuencia, 'DIARIO');
    });

    test('las demás siguen en veces y sin minutos', () {
      const deMinutos = {'leer', 'meditar', 'caminar', 'tocarInstrumento'};
      for (final p in plantillasHabito.where(
        (p) => !deMinutos.contains(p.id),
      )) {
        expect(p.unidad, UnidadHabito.veces, reason: p.id);
        expect(p.minutos, isNull, reason: p.id);
      }
    });

    test('un hábito viejo «Leer 20 min» sigue ocultando la idea de Leer', () {
      expect(
        plantillasDisponibles(['Leer 20 min']).map((p) => p.id),
        isNot(contains('leer')),
      );
    });

    test('un nombre que empieza por la plantilla la oculta: «Reading»', () {
      List<String> ocultas(String nombre) => [
        for (final p in plantillasHabito)
          if (!plantillasDisponibles([nombre]).contains(p)) p.id,
      ];
      expect(ocultas('Reading'), contains('leer'));
      expect(ocultas('Walking'), contains('caminar'));
      expect(ocultas('Ejercicios'), contains('ejercicio'));
      expect(ocultas('Exercises'), contains('ejercicio'));
      expect(ocultas('Journaling'), contains('escribirDiario'));
    });

    test('un nombre que es solo un trozo de la plantilla no la oculta', () {
      // «Be» está al principio de «Beber agua», pero no es una palabra suya.
      expect(
        plantillasDisponibles(['Be']).map((p) => p.id),
        contains('beberAgua'),
      );
    });

    test('un nombre que solo contiene las letras no la oculta', () {
      // «Ler» (pt) está dentro de «Taller», y «Read» dentro de «Bread».
      expect(
        plantillasDisponibles(['Taller de cerámica']).map((p) => p.id),
        contains('leer'),
      );
      expect(
        plantillasDisponibles(['Bake bread']).map((p) => p.id),
        contains('leer'),
      );
    });
  });

  group('descripcionPlantilla', () {
    test('diario con meta 1 dice «Cada día»', () {
      expect(descripcionPlantilla(es, _plantilla('dormir8h')), 'Cada día');
    });

    test('semanal sin días fijos dice los días por semana, no «Cada día»', () {
      expect(
        descripcionPlantilla(es, _plantilla('llamarQuerido')),
        '2 días por semana',
      );
      expect(
        descripcionPlantilla(en, _plantilla('llamarQuerido')),
        '2 days a week',
      );
      expect(
        descripcionPlantilla(pt, _plantilla('llamarQuerido')),
        '2 dias por semana',
      );
    });

    test('las de minutos dicen sus minutos', () {
      expect(descripcionPlantilla(es, _plantilla('leer')), '30 min cada día');
      expect(
        descripcionPlantilla(es, _plantilla('meditar')),
        '15 min cada día',
      );
      expect(descripcionPlantilla(en, _plantilla('leer')), '30 min every day');
      expect(
        descripcionPlantilla(pt, _plantilla('meditar')),
        '15 min todos os dias',
      );
    });

    test('diario con meta N dice las veces', () {
      expect(
        descripcionPlantilla(es, _plantilla('beberAgua')),
        'Cada día · 4 veces',
      );
    });

    test('semanal con días dice los días por semana y cuáles, en orden', () {
      expect(
        descripcionPlantilla(es, _plantilla('ejercicio')),
        '3 días por semana · mar, jue, sáb',
      );
    });

    test('en pt sale en portugués', () {
      expect(
        descripcionPlantilla(pt, _plantilla('beberAgua')),
        'Todos os dias · 4 vezes',
      );
      expect(
        descripcionPlantilla(pt, _plantilla('ejercicio')),
        '3 dias por semana · ter, qui, sáb',
      );
    });
  });
}
