import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/l10n/textos_minutos.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/models/objetivo_programado.dart';
import 'package:habitos_app_mobile/models/registro.dart';

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

    test('en los bordes de la hora: 59, 60, 61, 90 y 120', () {
      expect(duracionLegible(es, 59), '59 min');
      expect(duracionLegible(es, 60), '1 h');
      expect(duracionLegible(es, 61), '1 h 1 min');
      expect(duracionLegible(es, 90), '1 h 30 min');
      expect(duracionLegible(es, 120), '2 h');
    });

    test('un total negativo no se pinta negativo', () {
      expect(duracionLegible(es, -5), '0 min');
    });
  });

  group('el panel de minutos', () {
    test('progreso: «20 / 30 min» bajo la hora, horas en cuanto toca', () {
      expect(progresoMinutos(es, 20, 30), '20 / 30 min');
      expect(progresoMinutos(es, 59, 59), '59 / 59 min');
      expect(progresoMinutos(es, 20, 60), '20 min / 1 h');
      expect(progresoMinutos(es, 61, 90), '1 h 1 min / 1 h 30 min');
      expect(progresoMinutos(es, 45, 120), '45 min / 2 h');
      expect(progresoMinutos(es, 60, 30), '1 h / 30 min');
      expect(progresoMinutos(en, 45, 90), '45 min / 1 h 30 min');
      expect(progresoMinutos(pt, 45, 90), '45 min / 1 h 30 min');
    });

    test('lo que falta, en singular con 1 min y con 1 h', () {
      expect(
        textoEstadoPanel(es, hechos: 20, objetivo: 30),
        'Te faltan 10 min',
      );
      expect(textoEstadoPanel(es, hechos: 29, objetivo: 30), 'Te falta 1 min');
      expect(textoEstadoPanel(es, hechos: 1, objetivo: 60), 'Te faltan 59 min');
      expect(textoEstadoPanel(es, hechos: 0, objetivo: 60), 'Te falta 1 h');
      expect(
        textoEstadoPanel(es, hechos: 0, objetivo: 61),
        'Te falta 1 h 1 min',
      );
      expect(
        textoEstadoPanel(es, hechos: 0, objetivo: 90),
        'Te falta 1 h 30 min',
      );
      expect(textoEstadoPanel(es, hechos: 0, objetivo: 120), 'Te faltan 2 h');
      expect(textoEstadoPanel(en, hechos: 20, objetivo: 30), '10 min to go');
      expect(textoEstadoPanel(pt, hechos: 20, objetivo: 30), 'Faltam 10 min');
      expect(textoEstadoPanel(pt, hechos: 0, objetivo: 60), 'Falta 1 h');
    });

    test('meta cumplida, y lo que sobra si sobra', () {
      expect(textoEstadoPanel(es, hechos: 30, objetivo: 30), 'Meta cumplida');
      expect(
        textoEstadoPanel(es, hechos: 43, objetivo: 30),
        'Meta cumplida · +13 min de más',
      );
      expect(
        textoEstadoPanel(es, hechos: 91, objetivo: 30),
        'Meta cumplida · +1 h 1 min de más',
      );
      expect(
        textoEstadoPanel(en, hechos: 43, objetivo: 30),
        'Goal reached · +13 min extra',
      );
      expect(
        textoEstadoPanel(pt, hechos: 43, objetivo: 30),
        'Meta cumprida · +13 min a mais',
      );
    });

    test('Completar dice lo que suma', () {
      expect(textoCompletar(es, 10), 'Completar · +10 min');
      expect(textoCompletar(es, 70), 'Completar · +1 h 10 min');
      expect(textoCompletar(en, 60), 'Complete · +1 h');
      expect(textoCompletar(pt, 60), 'Completar · +1 h');
    });

    test('Deshacer dice la cantidad y la hora local de la entrada', () {
      // 14:05 en la hora local de la máquina, guardado en UTC como el backend.
      final creado = DateTime(2026, 11, 15, 14, 5).toUtc();
      Registro r(int cantidad, {DateTime? creadoEn}) => Registro(
        registroId: 1,
        fecha: '2026-11-15',
        cantidad: cantidad,
        creadoEn: creadoEn,
      );
      expect(
        etiquetaDeshacer(es, r(20, creadoEn: creado), locale: 'es'),
        'Deshacer +20 min (14:05)',
      );
      expect(
        etiquetaDeshacer(pt, r(20, creadoEn: creado), locale: 'pt'),
        'Desfazer +20 min (14:05)',
      );
      expect(
        etiquetaDeshacer(es, r(90, creadoEn: creado), locale: 'es'),
        'Deshacer +1 h 30 min (14:05)',
      );
      // En inglés, el formato de hora de intl: «2:05 PM».
      final horaEn = DateFormat.jm('en').format(DateTime(2026, 11, 15, 14, 5));
      expect(horaEn, contains('2:05'));
      expect(
        etiquetaDeshacer(en, r(20, creadoEn: creado), locale: 'en'),
        'Undo +20 min ($horaEn)',
      );
    });

    test('Deshacer sin hora dice la cantidad, y sin entrada, nada más', () {
      expect(
        etiquetaDeshacer(
          es,
          const Registro(registroId: 1, fecha: '2026-11-15', cantidad: 20),
          locale: 'es',
        ),
        'Deshacer la última entrada (20 min)',
      );
      expect(
        etiquetaDeshacer(es, null, locale: 'es'),
        'Deshacer la última entrada',
      );
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
      // Un cambio que no es de minutos, un miércoles: mañana es jueves.
      expect(
        avisoAplicaDesde(
          es,
          aplicaDesde: DateTime(2026, 11, 19),
          hoy: DateTime(2026, 11, 18),
          locale: 'es',
        ),
        es.habAplicaManana,
      );
    });

    test('en domingo, un cambio de días que vale el lunes dice el lunes', () {
      // Domingo 15: el cambio de días o de frecuencia empieza el lunes 16.
      expect(
        avisoAplicaDesde(
          es,
          aplicaDesde: DateTime(2026, 11, 16),
          hoy: hoy,
          locale: 'es',
        ),
        'El cambio se aplica desde el lunes. Esta semana ya tienes registros '
        'con la meta anterior.',
      );
      // Uno de minutos, el mismo domingo, sigue diciendo mañana.
      expect(
        avisoAplicaDesde(
          es,
          aplicaDesde: DateTime(2026, 11, 16),
          hoy: hoy,
          locale: 'es',
          minutosNuevos: 40,
        ),
        es.habAplicaMinutosManana(40),
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
