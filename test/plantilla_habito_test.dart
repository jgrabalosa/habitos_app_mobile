import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
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
        es.plantillaLeer20Min,
        es.plantillaEjercicio,
        es.plantillaMeditar,
        es.plantillaDormir8h,
        es.plantillaCaminar,
        es.plantillaEscribirDiario,
      ];
      expect(plantillasDisponibles(nombres), isEmpty);
    });
  });

  group('descripcionPlantilla', () {
    test('diario con meta 1 dice «Cada día»', () {
      expect(descripcionPlantilla(es, _plantilla('leer20Min')), 'Cada día');
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
