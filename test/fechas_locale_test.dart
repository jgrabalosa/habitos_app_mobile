import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
    expect(DateFormat.yMMMM('es').format(fecha).toLowerCase(), contains('junio'));
    expect(DateFormat.yMMMM('en').format(fecha).toLowerCase(), contains('june'));
    expect(DateFormat.yMMMM('pt').format(fecha).toLowerCase(), contains('junho'));

    expect(DateFormat.MMMMd('es').format(fecha).toLowerCase(), contains('junio'));
    expect(DateFormat.MMMMd('en').format(fecha).toLowerCase(), contains('june'));
    expect(DateFormat.MMMMd('pt').format(fecha).toLowerCase(), contains('junho'));
  });
}
