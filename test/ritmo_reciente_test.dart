import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/models/hoy.dart';
import 'package:habitos_app_mobile/models/ritmo_reciente.dart';
import 'package:habitos_app_mobile/widgets/panel_ritmo.dart';

Habito _habito({DateTime? fechaInicio}) => Habito(
  habitoId: 1,
  nombre: 'Leer',
  frecuencia: 'DIARIO',
  meta: 1,
  activo: true,
  fechaInicio: fechaInicio,
);

void main() {
  group('esRecienEmpezado', () {
    final hoy = DateTime(2026, 10, 25);

    test('sin fecha de alta no es reciente', () {
      expect(esRecienEmpezado(null, hoy), isFalse);
    });

    test('el mismo día del alta es reciente', () {
      expect(esRecienEmpezado(DateTime(2026, 10, 25), hoy), isTrue);
    });

    test('hace 6 días sigue siendo reciente', () {
      expect(esRecienEmpezado(DateTime(2026, 10, 19), hoy), isTrue);
    });

    test('hace 7 días ya se compara con normalidad', () {
      expect(esRecienEmpezado(DateTime(2026, 10, 18), hoy), isFalse);
    });

    test('hace 30 días no es reciente', () {
      expect(esRecienEmpezado(DateTime(2026, 9, 25), hoy), isFalse);
    });

    test('la cuenta no se rompe al cruzar el cambio de hora', () {
      // El 25 de octubre de 2026 cambia la hora: 18 → 25 son siete días.
      expect(
        esRecienEmpezado(DateTime(2026, 10, 18), DateTime(2026, 10, 25)),
        isFalse,
      );
    });
  });

  group('Habito.fromJson con fechaInicio', () {
    Map<String, dynamic> json({Object? fechaInicio, bool conCampo = true}) => {
      'habitoId': 1,
      'nombre': 'Leer',
      'frecuencia': 'DIARIO',
      'meta': 1,
      'activo': true,
      if (conCampo) 'fechaInicio': fechaInicio,
    };

    test('lee la fecha de alta como solo fecha', () {
      final h = Habito.fromJson(json(fechaInicio: '2026-10-19'));
      expect(h.fechaInicio, DateTime(2026, 10, 19));
    });

    test('sin el campo es null', () {
      final h = Habito.fromJson(json(conCampo: false));
      expect(h.fechaInicio, isNull);
    });

    test('con basura es null', () {
      final h = Habito.fromJson(json(fechaInicio: 'ayer'));
      expect(h.fechaInicio, isNull);
    });
  });

  group('recienEmpezadoEnLista', () {
    final hoy = DateTime(2026, 10, 25);

    test('sin hábitos no es reciente', () {
      expect(recienEmpezadoEnLista(const [], hoy), isFalse);
    });

    test('si alguno no trae fecha, no es reciente', () {
      expect(
        recienEmpezadoEnLista([
          _habito(),
          _habito(fechaInicio: DateTime(2026, 10, 24)),
        ], hoy),
        isFalse,
      );
    });

    test('con uno nuevo y uno viejo decide el más antiguo: no es reciente', () {
      expect(
        recienEmpezadoEnLista([
          _habito(fechaInicio: DateTime(2026, 10, 24)),
          _habito(fechaInicio: DateTime(2026, 9, 25)),
        ], hoy),
        isFalse,
      );
    });

    test('si todos son recientes, sí lo es', () {
      expect(
        recienEmpezadoEnLista([
          _habito(fechaInicio: DateTime(2026, 10, 24)),
          _habito(fechaInicio: DateTime(2026, 10, 20)),
        ], hoy),
        isTrue,
      );
    });
  });

  group('causaRitmo con recienEmpezado', () {
    testWidgets('gana a cualquier tendencia', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      for (final t in [null, ...TendenciaRitmo.values]) {
        expect(
          causaRitmo(l, t, recienEmpezado: true),
          l.ritmoRecienEmpezado,
          reason: '$t',
        );
      }
    });

    testWidgets('sin recienEmpezado se mantiene el comportamiento de antes', (
      tester,
    ) async {
      late AppLocalizations l;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(causaRitmo(l, TendenciaRitmo.sube), l.ritmoSube);
      expect(causaRitmo(l, TendenciaRitmo.igual), l.ritmoIgual);
      expect(causaRitmo(l, TendenciaRitmo.baja), l.ritmoBaja);
      expect(causaRitmo(l, null), isNull);
    });
  });
}
