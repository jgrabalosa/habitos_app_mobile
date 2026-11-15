import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/models/plantilla_habito.dart';

PlantillaHabito _plantilla(String id) =>
    plantillasHabito.firstWhere((p) => p.id == id);

void main() {
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  group('plantillasDisponibles', () {
    test('sin hábitos existentes salen las 7', () {
      expect(plantillasDisponibles(const []), hasLength(7));
    });

    test('un hábito con el nombre de una plantilla la oculta', () {
      final disponibles = plantillasDisponibles([es.plantillaBeberAgua]);
      expect(disponibles, hasLength(6));
      expect(disponibles.map((p) => p.id), isNot(contains('beberAgua')));
    });

    test('el nombre en otro idioma también la oculta', () {
      final disponibles = plantillasDisponibles([en.plantillaBeberAgua]);
      expect(disponibles.map((p) => p.id), isNot(contains('beberAgua')));
    });

    test('si todas existen, no queda ninguna', () {
      final nombres = [
        es.plantillaBeberAgua,
        es.plantillaLeer,
        es.plantillaEjercicio,
        es.plantillaMeditar,
        es.plantillaDormir8h,
        es.plantillaCaminar,
        es.plantillaEscribirDiario,
      ];
      expect(plantillasDisponibles(nombres), isEmpty);
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
      for (final p in plantillasHabito.where(
        (p) => p.id != 'leer' && p.id != 'meditar',
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
      expect(descripcionPlantilla(es, _plantilla('caminar')), 'Cada día');
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

    test('semanal con días dice las veces por semana y los días en orden', () {
      expect(
        descripcionPlantilla(es, _plantilla('ejercicio')),
        '3 veces por semana · mar, jue, sáb',
      );
    });

    test('en pt sale en portugués', () {
      expect(
        descripcionPlantilla(pt, _plantilla('beberAgua')),
        'Todos os dias · 4 vezes',
      );
      expect(
        descripcionPlantilla(pt, _plantilla('ejercicio')),
        '3 vezes por semana · ter, qui, sáb',
      );
    });
  });
}
