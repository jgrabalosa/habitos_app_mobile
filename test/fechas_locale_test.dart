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
    expect(DateFormat.yMMMM('es').format(fecha).toLowerCase(), contains('junio'));
    expect(DateFormat.yMMMM('en').format(fecha).toLowerCase(), contains('june'));
    expect(DateFormat.yMMMM('pt').format(fecha).toLowerCase(), contains('junho'));

    expect(DateFormat.MMMMd('es').format(fecha).toLowerCase(), contains('junio'));
    expect(DateFormat.MMMMd('en').format(fecha).toLowerCase(), contains('june'));
    expect(DateFormat.MMMMd('pt').format(fecha).toLowerCase(), contains('junho'));
  });

  // Lo que ve el usuario, en cadenas literales. Decidido el 10-sep-2026:
  // la cabecera de hoy va sin día de la semana; la de otro día, con él y en
  // mayúscula. Si esto falla, o cambió la decisión o cambió intl: no se
  // ajusta el esperado sin decidirlo.
  final miercoles9Sep = DateTime(2026, 9, 9);
  const cabeceras = {
    'es': (
      textoHoy: 'Hoy',
      hoy: 'Hoy, 9 de septiembre',
      otroDia: 'Miércoles, 9 de septiembre',
    ),
    'en': (
      textoHoy: 'Today',
      hoy: 'Today, September 9',
      otroDia: 'Wednesday, September 9',
    ),
    'pt': (
      textoHoy: 'Hoje',
      hoy: 'Hoje, 9 de setembro',
      otroDia: 'Quarta-feira, 9 de setembro',
    ),
  };

  test('la cabecera de hoy no lleva día de la semana', () {
    cabeceras.forEach((locale, c) {
      expect(
        formatearTituloDelDia(
          fecha: miercoles9Sep,
          locale: locale,
          textoHoy: c.textoHoy,
          viendoHoy: true,
        ),
        c.hoy,
        reason: locale,
      );
    });
  });

  test('la cabecera de otro día lleva día de la semana y mayúscula', () {
    cabeceras.forEach((locale, c) {
      expect(
        formatearTituloDelDia(
          fecha: miercoles9Sep,
          locale: locale,
          textoHoy: c.textoHoy,
          viendoHoy: false,
        ),
        c.otroDia,
        reason: locale,
      );
    });
  });
}
