import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:habitos_app_mobile/screens/dashboard_screen.dart';

/// Comprueba que los formatos de fecha realmente cambian con el idioma.
/// Si hiciera falta initializeDateFormatting, sin él estos asserts fallarían.
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  final fecha = DateTime(2026, 6, 3); // miércoles 3 de junio de 2026

  test('MMMMEEEEd cambia con el locale', () {
    final es = DateFormat.MMMMEEEEd('es').format(fecha);
    final en = DateFormat.MMMMEEEEd('en').format(fecha);
    final pt = DateFormat.MMMMEEEEd('pt').format(fecha);

    expect(es.toLowerCase(), contains('junio'));
    expect(en.toLowerCase(), contains('june'));
    expect(pt.toLowerCase(), contains('junho'));
    expect({es, en, pt}.length, 3, reason: 'los tres deben diferir');
  });

  test('yMMMM y MMMMd cambian con el locale', () {
    expect(
      DateFormat.yMMMM('es').format(fecha).toLowerCase(),
      contains('junio'),
    );
    expect(
      DateFormat.yMMMM('en').format(fecha).toLowerCase(),
      contains('june'),
    );
    expect(
      DateFormat.yMMMM('pt').format(fecha).toLowerCase(),
      contains('junho'),
    );

    expect(
      DateFormat.MMMMd('es').format(fecha).toLowerCase(),
      contains('junio'),
    );
    expect(
      DateFormat.MMMMd('en').format(fecha).toLowerCase(),
      contains('june'),
    );
    expect(
      DateFormat.MMMMd('pt').format(fecha).toLowerCase(),
      contains('junho'),
    );
  });

  test('lunesDeLaSemanaDe devuelve el lunes de la semana ISO', () {
    expect(lunesDeLaSemanaDe(DateTime(2026, 9, 9)), DateTime(2026, 9, 7));
    expect(lunesDeLaSemanaDe(DateTime(2026, 9, 7)), DateTime(2026, 9, 7));
    expect(lunesDeLaSemanaDe(DateTime(2026, 9, 13)), DateTime(2026, 9, 7));
  });

  test('lunesDeLaSemanaDe cruza el mes correctamente', () {
    expect(lunesDeLaSemanaDe(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
  });

  test('isoDeSemanaDesplazadaDevuelveNullSinHoyDelServidor', () {
    expect(isoDeSemanaDesplazada(null, 0), null);
    expect(isoDeSemanaDesplazada(null, -1), null);
    expect(isoDeSemanaDesplazada(null, 1), null);
  });

  test('isoDeSemanaDesplazadaCuentaSemanasDesdeElHoyDado', () {
    expect(isoDeSemanaDesplazada('2026-09-12', 0), '2026-09-12');
    expect(isoDeSemanaDesplazada('2026-09-12', -1), '2026-09-05');
    expect(isoDeSemanaDesplazada('2026-09-12', 1), '2026-09-19');
    expect(isoDeSemanaDesplazada('2026-11-01', -1), '2026-10-25');
  });

  test('esAnteriorALaSemanaEnCurso compara contra el lunes de hoy', () {
    final hoy = DateTime(2026, 9, 9); // miércoles

    expect(esAnteriorALaSemanaEnCurso(DateTime(2026, 9, 6), hoy), true);
    expect(esAnteriorALaSemanaEnCurso(DateTime(2026, 9, 7), hoy), false);
    expect(esAnteriorALaSemanaEnCurso(DateTime(2026, 9, 9), hoy), false);
    expect(esAnteriorALaSemanaEnCurso(DateTime(2026, 9, 10), hoy), false);
  });
}
