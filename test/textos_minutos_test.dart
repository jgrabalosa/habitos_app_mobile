import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/l10n/textos_minutos.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/models/objetivo_programado.dart';

Habito habito({
  String frecuencia = 'DIARIO',
  int meta = 1,
  UnidadHabito unidad = UnidadHabito.veces,
  int? minutos,
  String? dias,
}) => Habito(
  habitoId: 1,
  nombre: 'Leer',
  frecuencia: frecuencia,
  meta: meta,
  activo: true,
  unidad: unidad,
  minutosObjetivo: minutos,
  diasSemana: dias,
);

void main() {
  late AppLocalizations es;
  late AppLocalizations en;
  late AppLocalizations pt;

  setUpAll(() async {
    await initializeDateFormatting();
    es = await AppLocalizations.delegate.load(const Locale('es'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
    pt = await AppLocalizations.delegate.load(const Locale('pt'));
  });

  group('horas y minutos', () {
    test('en español', () {
      expect(duracionLegible(es, 0), '0 min');
      expect(duracionLegible(es, 45), '45 min');
      expect(duracionLegible(es, 60), '1 h');
      expect(duracionLegible(es, 180), '3 h');
      expect(duracionLegible(es, 755), '12 h 35 min');
    });

    test('en inglés', () {
      expect(duracionLegible(en, 45), '45 min');
      expect(duracionLegible(en, 120), '2 h');
      expect(duracionLegible(en, 755), '12 h 35 min');
    });

    test('en portugués', () {
      expect(duracionLegible(pt, 45), '45 min');
      expect(duracionLegible(pt, 120), '2 h');
      expect(duracionLegible(pt, 755), '12 h 35 min');
    });

    test('un total negativo no se pinta negativo', () {
      expect(duracionLegible(es, -5), '0 min');
    });
  });

  group('aviso de aplicaDesde', () {
    // Domingo 15 de noviembre de 2026.
    final hoy = DateTime(2026, 11, 15);

    test('si ya vale, o si el backend no lo manda, no hay aviso', () {
      expect(
        avisoAplicaDesde(es, aplicaDesde: hoy, hoy: hoy, locale: 'es'),
        isNull,
      );
      expect(
        avisoAplicaDesde(es, aplicaDesde: null, hoy: hoy, locale: 'es'),
        isNull,
      );
    });

    test('mañana, con la cifra de minutos si el cambio es de minutos', () {
      expect(
        avisoAplicaDesde(
          es,
          aplicaDesde: DateTime(2026, 11, 16),
          hoy: hoy,
          locale: 'es',
          minutosNuevos: 40,
        ),
        'Los 40 min se aplican desde mañana. Hoy ya tienes registros con la '
        'meta anterior.',
      );
      expect(
        avisoAplicaDesde(
          es,
          aplicaDesde: DateTime(2026, 11, 16),
          hoy: hoy,
          locale: 'es',
        ),
        es.habAplicaManana,
      );
    });

    test('el lunes', () {
      expect(
        avisoAplicaDesde(
          es,
          aplicaDesde: DateTime(2026, 11, 23),
          hoy: DateTime(2026, 11, 18),
          locale: 'es',
        ),
        es.habAplicaLunes,
      );
    });

    test('otra fecha, con la fecha en el idioma', () {
      expect(
        avisoAplicaDesde(
          es,
          aplicaDesde: DateTime(2026, 11, 20),
          hoy: hoy,
          locale: 'es',
        ),
        'El cambio se aplica desde el 20 de noviembre.',
      );
      expect(
        avisoAplicaDesde(
          en,
          aplicaDesde: DateTime(2026, 11, 20),
          hoy: hoy,
          locale: 'en',
        ),
        'The change applies from November 20.',
      );
    });
  });

  group('objetivo programado', () {
    test('«Desde el lunes: 4 días por semana»', () {
      final p = ObjetivoProgramado(
        desde: DateTime(2026, 11, 23),
        unidad: UnidadHabito.veces,
        frecuencia: 'SEMANAL',
        meta: 4,
      );
      expect(
        textoObjetivoProgramado(
          es,
          p,
          actual: habito(frecuencia: 'SEMANAL', meta: 3),
          hoy: DateTime(2026, 11, 18),
          locale: 'es',
        ),
        'Desde el lunes: 4 días por semana',
      );
    });

    test('«Desde mañana: 40 min» si solo cambian los minutos', () {
      final p = ObjetivoProgramado(
        desde: DateTime(2026, 11, 16),
        unidad: UnidadHabito.minutos,
        frecuencia: 'DIARIO',
        meta: 1,
        minutosObjetivo: 40,
      );
      expect(
        textoObjetivoProgramado(
          es,
          p,
          actual: habito(unidad: UnidadHabito.minutos, minutos: 30),
          hoy: DateTime(2026, 11, 15),
          locale: 'es',
        ),
        'Desde mañana: 40 min',
      );
      expect(
        textoObjetivoProgramado(
          pt,
          p,
          actual: habito(unidad: UnidadHabito.minutos, minutos: 30),
          hoy: DateTime(2026, 11, 15),
          locale: 'pt',
        ),
        'A partir de amanhã: 40 min',
      );
    });

    test('pasar de veces a minutos dice los minutos', () {
      final p = ObjetivoProgramado(
        desde: DateTime(2026, 11, 16),
        unidad: UnidadHabito.minutos,
        frecuencia: 'DIARIO',
        meta: 1,
        minutosObjetivo: 15,
      );
      expect(
        describirObjetivo(es, p, actual: habito(), locale: 'es'),
        '15 min',
      );
    });

    test('minutos y días a la vez van juntos', () {
      final p = ObjetivoProgramado(
        desde: DateTime(2026, 11, 23),
        unidad: UnidadHabito.minutos,
        frecuencia: 'SEMANAL',
        meta: 3,
        minutosObjetivo: 60,
      );
      expect(
        describirObjetivo(
          en,
          p,
          actual: habito(
            frecuencia: 'SEMANAL',
            meta: 2,
            unidad: UnidadHabito.minutos,
            minutos: 45,
          ),
          locale: 'en',
        ),
        '60 min · 3 days a week',
      );
    });
  });
}
