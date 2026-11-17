import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/services/api_service_habitos.dart';

/// Lo que sale por la red al completar y al crear o editar un hábito. Un
/// hábito de veces tiene que mandar exactamente el mismo body que antes de
/// existir los de minutos: las cadenas de abajo son las que producía el
/// código anterior (`jsonEncode` del mismo mapa, en el mismo orden).
void main() {
  group('completar', () {
    test('un hábito de veces hoy: {"nota":""}, como siempre', () {
      expect(ApiServiceHabitos.cuerpoCompletar(), '{"nota":""}');
    });

    test('un hábito de veces otro día: solo nota y fecha', () {
      expect(
        ApiServiceHabitos.cuerpoCompletar(fecha: '2026-11-12'),
        '{"nota":"","fecha":"2026-11-12"}',
      );
    });

    test('uno de minutos manda minutos como texto, clave y origen', () {
      final body =
          jsonDecode(
                ApiServiceHabitos.cuerpoCompletar(
                  fecha: '2026-11-12',
                  minutos: 25,
                  clave: 'c1',
                  origen: 'MANUAL',
                ),
              )
              as Map<String, dynamic>;
      expect(body, {
        'nota': '',
        'fecha': '2026-11-12',
        'minutos': '25',
        'clave': 'c1',
        'origen': 'MANUAL',
      });
    });
  });

  group('alta y edición', () {
    test('un hábito de veces manda el body de antes, byte a byte', () {
      expect(
        ApiServiceHabitos.cuerpoHabito(
          'Beber agua',
          'Ocho vasos',
          'DIARIO',
          4,
          7,
          2,
          recordatorioActivo: true,
          recordatorioHora: '09:00',
        ),
        '{"nombre":"Beber agua","descripcion":"Ocho vasos",'
        '"frecuencia":"DIARIO","meta":4,"propietario":{"usuarioId":7},'
        '"diasSemana":null,"recordatorioActivo":true,'
        '"recordatorioHora":"09:00","categoriaId":2}',
      );
    });

    test('sin categoría tampoco cambia', () {
      expect(
        ApiServiceHabitos.cuerpoHabito(
          'Leer',
          '',
          'SEMANAL',
          3,
          7,
          null,
          diasSemana: '1,3,5',
          recordatorioActivo: false,
        ),
        '{"nombre":"Leer","descripcion":"","frecuencia":"SEMANAL","meta":3,'
        '"propietario":{"usuarioId":7},"diasSemana":"1,3,5",'
        '"recordatorioActivo":false,"recordatorioHora":null}',
      );
    });

    test('uno de minutos añade unidad y minutosObjetivo', () {
      final body =
          jsonDecode(
                ApiServiceHabitos.cuerpoHabito(
                  'Leer',
                  '',
                  'DIARIO',
                  1,
                  7,
                  null,
                  recordatorioActivo: false,
                  unidad: 'MINUTOS',
                  minutosObjetivo: 30,
                ),
              )
              as Map<String, dynamic>;
      expect(body['unidad'], 'MINUTOS');
      expect(body['minutosObjetivo'], 30);
    });
  });
}
