import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/models/hoy.dart';
import 'package:habitos_app_mobile/models/minutos.dart';
import 'package:habitos_app_mobile/models/objetivo_programado.dart';
import 'package:habitos_app_mobile/models/registro.dart';
import 'package:habitos_app_mobile/screens/dashboard_logica.dart';
import 'package:habitos_app_mobile/services/api_service_habitos.dart';
import 'package:habitos_app_mobile/services/clave_envio.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Un hábito tal como lo manda un backend anterior a los minutos: sin
/// `unidad` ni `minutosObjetivo`.
Map<String, dynamic> habitoViejo(int id, String frecuencia, {int meta = 1}) => {
  'habitoId': id,
  'nombre': 'Hábito $id',
  'frecuencia': frecuencia,
  'meta': meta,
  'activo': true,
};

Map<String, dynamic> habitoMinutos(
  int id,
  String frecuencia, {
  int meta = 1,
  int objetivo = 30,
}) => {
  ...habitoViejo(id, frecuencia, meta: meta),
  'unidad': 'MINUTOS',
  'minutosObjetivo': objetivo,
};

/// Una fila de `/hoy` de un hábito de minutos, con los campos nuevos.
FilaHoy filaMinutos({
  String frecuencia = 'DIARIO',
  int hechos = 0,
  int objetivo = 30,
  int completados = 0,
  int meta = 1,
  bool hecho = false,
  List<String> fechas = const [],
}) => FilaHoy.fromJson({
  'habito': habitoMinutos(1, frecuencia, meta: meta, objetivo: objetivo),
  'completados': completados,
  'meta': meta,
  'hecho': hecho,
  'completadoEnFecha': hechos > 0,
  'ritmoNivel': 2,
  'fechasCompletadas': fechas,
  'unidad': 'MINUTOS',
  'minutosHechos': hechos,
  'minutosObjetivo': objetivo,
});

void main() {
  group('Habito: campos nuevos y backend viejo', () {
    test('sin unidad ni minutos (backend viejo) es un hábito de veces', () {
      final h = Habito.fromJson(habitoViejo(1, 'DIARIO', meta: 3));
      expect(h.unidad, UnidadHabito.veces);
      expect(h.esMinutos, isFalse);
      expect(h.minutosObjetivo, isNull);
      expect(h.meta, 3);
    });

    test('con MINUTOS lee la unidad y los minutos por día', () {
      final h = Habito.fromJson(habitoMinutos(1, 'DIARIO', objetivo: 45));
      expect(h.unidad, UnidadHabito.minutos);
      expect(h.minutosObjetivo, 45);
    });

    test('una unidad desconocida cae a veces', () {
      final h = Habito.fromJson({
        ...habitoViejo(1, 'DIARIO'),
        'unidad': 'PASOS',
      });
      expect(h.unidad, UnidadHabito.veces);
    });

    test('codigoUnidad devuelve lo que espera el backend', () {
      expect(codigoUnidad(UnidadHabito.veces), 'VECES');
      expect(codigoUnidad(UnidadHabito.minutos), 'MINUTOS');
    });
  });

  group('FilaHoy de minutos', () {
    test('una fila de backend viejo es de veces y no tiene minutos', () {
      final f = FilaHoy.fromJson({
        'habito': habitoViejo(1, 'DIARIO', meta: 4),
        'completados': 3,
        'meta': 4,
        'hecho': false,
      });
      expect(f.esMinutos, isFalse);
      expect(f.minutosHechos, 0);
      expect(f.minutosObjetivo, isNull);
      expect(f.fraccion, 0.75);
    });

    test('sin unidad en la fila, manda la del hábito', () {
      final f = FilaHoy.fromJson({
        'habito': habitoMinutos(1, 'DIARIO', objetivo: 20),
        'completados': 0,
        'meta': 1,
      });
      expect(f.esMinutos, isTrue);
      expect(f.minutosObjetivo, 20);
    });

    test('20 de 30: progreso parcial y sin hacer', () {
      final f = filaMinutos(hechos: 20);
      expect(f.fraccionDia, closeTo(2 / 3, 1e-9));
      expect(f.fraccion, closeTo(2 / 3, 1e-9));
      expect(f.diaHechoMinutos, isFalse);
    });

    test('30 de 30: hecho', () {
      final f = filaMinutos(hechos: 30, completados: 1, hecho: true);
      expect(f.fraccionDia, 1.0);
      expect(f.diaHechoMinutos, isTrue);
    });

    test('43 de 30: pasada la meta, el progreso no pasa de 1', () {
      final f = filaMinutos(hechos: 43, completados: 1, hecho: true);
      expect(f.fraccionDia, 1.0);
      expect(f.diaHechoMinutos, isTrue);
      expect(f.minutosHechos, 43);
    });

    test('conMinutos: sumar sin llegar no hace el día', () {
      final f = filaMinutos(
        hechos: 10,
      ).conMinutos(15, delDia: true, fecha: '2026-11-15');
      expect(f.minutosHechos, 25);
      expect(f.hecho, isFalse);
      expect(f.completados, 0);
      expect(f.fechasCompletadas, isEmpty);
    });

    test('conMinutos: llegar al objetivo hace el día y cuenta un día', () {
      final f = filaMinutos(
        hechos: 20,
      ).conMinutos(15, delDia: true, fecha: '2026-11-15');
      expect(f.minutosHechos, 35);
      expect(f.hecho, isTrue);
      expect(f.completados, 1);
      expect(f.fechasCompletadas, {'2026-11-15'});
    });

    test('conMinutos: sumar con el día ya hecho no cuenta otro día', () {
      final f = filaMinutos(
        hechos: 30,
        completados: 1,
        hecho: true,
        fechas: ['2026-11-15'],
      ).conMinutos(13, delDia: true, fecha: '2026-11-15');
      expect(f.minutosHechos, 43);
      expect(f.completados, 1);
      expect(f.hecho, isTrue);
    });

    test('conMinutos: deshacer por debajo del objetivo quita el día', () {
      final f = filaMinutos(
        hechos: 35,
        completados: 1,
        hecho: true,
        fechas: ['2026-11-15'],
      ).conMinutos(-15, delDia: true, fecha: '2026-11-15');
      expect(f.minutosHechos, 20);
      expect(f.completados, 0);
      expect(f.hecho, isFalse);
      expect(f.fechasCompletadas, isEmpty);
    });

    test('conMinutos: no baja de cero', () {
      final f = filaMinutos(
        hechos: 5,
      ).conMinutos(-30, delDia: true, fecha: '2026-11-15');
      expect(f.minutosHechos, 0);
    });

    test('semanal en Esta semana: cuenta al llegar a los días de la meta', () {
      final f = filaMinutos(
        frecuencia: 'SEMANAL',
        meta: 3,
        completados: 2,
        objetivo: 60,
        hechos: 30,
      ).conMinutos(30, delDia: false, fecha: '2026-11-15');
      expect(f.completados, 3);
      expect(f.hecho, isTrue);
    });

    test('semanal en Esta semana: un día hecho que no llega a la meta', () {
      final f = filaMinutos(
        frecuencia: 'SEMANAL',
        meta: 3,
        completados: 0,
        objetivo: 60,
      ).conMinutos(60, delDia: false, fecha: '2026-11-15');
      expect(f.completados, 1);
      expect(f.hecho, isFalse);
      expect(f.diaHechoMinutos, isTrue);
    });

    test('conPasos de un hábito de veces sigue igual y conserva la unidad', () {
      final f = FilaHoy.fromJson({
        'habito': habitoViejo(1, 'DIARIO', meta: 2),
        'completados': 1,
        'meta': 2,
      }).conPasos(1, delDia: true, fecha: '2026-11-15');
      expect(f.completados, 2);
      expect(f.hecho, isTrue);
      expect(f.esMinutos, isFalse);
    });

    test('avanceDelDia cuenta los minutos a medias', () {
      final veces = FilaHoy.fromJson({
        'habito': habitoViejo(2, 'DIARIO'),
        'completados': 1,
        'meta': 1,
        'hecho': true,
      });
      expect(avanceDelDia([filaMinutos(hechos: 15), veces]), 0.75);
    });
  });

  group('el campo libre del panel suma', () {
    test('envía la cifra tal cual', () {
      final r = minutosAEnviar('25');
      expect(r.minutos, 25);
      expect(r.error, isNull);
    });

    test('fuera de 1-600 no se envía', () {
      expect(minutosAEnviar('0').error, ErrorMinutos.fueraDeRango);
      expect(minutosAEnviar('601').error, ErrorMinutos.fueraDeRango);
      expect(minutosAEnviar('600').minutos, 600);
    });

    test('sin número, vacío', () {
      expect(minutosAEnviar('').error, ErrorMinutos.vacio);
    });
  });

  group('Completar y botones rápidos del panel', () {
    test('Completar envía exactamente lo que falta', () {
      expect(minutosParaCompletar(20, 30), 10);
      expect(minutosParaCompletar(0, 90), 90);
      expect(minutosParaCompletar(29, 30), 1);
    });

    test('con la meta cumplida, o sin objetivo, no hay Completar', () {
      expect(minutosParaCompletar(30, 30), isNull);
      expect(minutosParaCompletar(43, 30), isNull);
      expect(minutosParaCompletar(10, null), isNull);
      expect(minutosParaCompletar(10, 0), isNull);
    });

    test('mientras falta, solo los menores estrictos que lo que falta', () {
      expect(sumasRapidasVisibles(10, 30), [5, 15]);
      expect(sumasRapidasVisibles(20, 30), [5]);
      expect(sumasRapidasVisibles(15, 30), [5]);
      expect(sumasRapidasVisibles(25, 30), isEmpty);
      expect(sumasRapidasVisibles(0, 31), [5, 15, 30]);
      expect(sumasRapidasVisibles(0, 30), [5, 15]);
    });

    test('con la meta cumplida o sin objetivo, los tres para sumar de más', () {
      expect(sumasRapidasVisibles(30, 30), [5, 15, 30]);
      expect(sumasRapidasVisibles(43, 30), [5, 15, 30]);
      expect(sumasRapidasVisibles(0, null), [5, 15, 30]);
    });
  });

  group('objetivo de minutos', () {
    test('objetivo de minutos válido entre 1 y 600', () {
      expect(objetivoMinutosValido(null), isFalse);
      expect(objetivoMinutosValido(0), isFalse);
      expect(objetivoMinutosValido(1), isTrue);
      expect(objetivoMinutosValido(600), isTrue);
      expect(objetivoMinutosValido(601), isFalse);
    });
  });

  group('cuándo aplica un cambio', () {
    // Domingo 15 de noviembre de 2026.
    final hoy = DateTime(2026, 11, 15);

    test('hoy o antes: ya vale', () {
      expect(cuandoAplica(DateTime(2026, 11, 15), hoy), CuandoAplica.hoy);
      expect(cuandoAplica(DateTime(2026, 11, 1), hoy), CuandoAplica.hoy);
    });

    test('mañana gana aunque mañana sea lunes', () {
      expect(cuandoAplica(DateTime(2026, 11, 16), hoy), CuandoAplica.manana);
    });

    test('el lunes que viene', () {
      final miercoles = DateTime(2026, 11, 18);
      expect(
        cuandoAplica(DateTime(2026, 11, 23), miercoles),
        CuandoAplica.lunes,
      );
    });

    test('un lunes de más allá de una semana se dice con fecha', () {
      expect(
        cuandoAplica(DateTime(2026, 11, 30), DateTime(2026, 11, 18)),
        CuandoAplica.otraFecha,
      );
    });

    test('otro día que no es mañana ni lunes, con fecha', () {
      expect(cuandoAplica(DateTime(2026, 11, 20), hoy), CuandoAplica.otraFecha);
    });

    test('la hora no cuenta', () {
      expect(
        cuandoAplica(DateTime(2026, 11, 16), DateTime(2026, 11, 15, 23, 59)),
        CuandoAplica.manana,
      );
    });
  });

  group('respuestas del backend', () {
    test('aplicaDesde se lee del JSON del PUT', () {
      expect(
        ApiServiceHabitos.leerAplicaDesde(
          '{"mensaje":"ok","aplicaDesde":"2026-11-16"}',
        ),
        DateTime(2026, 11, 16),
      );
    });

    test('sin aplicaDesde, o con cuerpo de texto (backend viejo), null', () {
      expect(ApiServiceHabitos.leerAplicaDesde('{"mensaje":"ok"}'), isNull);
      expect(
        ApiServiceHabitos.leerAplicaDesde('Hábito actualizado correctamente'),
        isNull,
      );
      expect(ApiServiceHabitos.leerAplicaDesde(''), isNull);
    });

    test('completar con campos de minutos', () {
      final r = ApiServiceHabitos.leerCompletado({
        'logrosOtorgados': ['X'],
        'puntosGanados': 12,
        'registroId': 9,
        'minutosDia': 45,
        'minutosObjetivo': 30,
        'diaHecho': true,
      });
      expect(r['logros'], ['X']);
      expect(r['minutosDia'], 45);
      expect(r['minutosObjetivo'], 30);
      expect(r['diaHecho'], isTrue);
    });

    test('completar de un backend viejo trae los minutos por defecto', () {
      final r = ApiServiceHabitos.leerCompletado({
        'puntosGanados': 25,
        'registroId': 3,
      });
      expect(r['logros'], isEmpty);
      expect(r['minutosDia'], 0);
      expect(r['minutosObjetivo'], isNull);
      expect(r['diaHecho'], isFalse);
      expect(r['puntosExtraSemana'], 0);
    });

    test('un registro sin cantidad ni origen es 1 y MANUAL', () {
      final r = Registro.fromJson({'registroId': 4, 'fecha': '2026-11-15'});
      expect(r.cantidad, 1);
      expect(r.origen, 'MANUAL');
    });

    test('un registro de minutos trae su cantidad y su origen', () {
      final r = Registro.fromJson({
        'registroId': 4,
        'fecha': '2026-11-15',
        'cantidad': 25,
        'origen': 'ENFOQUE',
      });
      expect(r.cantidad, 25);
      expect(r.origen, 'ENFOQUE');
    });

    test('creadoEn llega en UTC sin zona y se lee como UTC', () {
      final r = Registro.fromJson({
        'registroId': 4,
        'fecha': '2026-11-15',
        'creadoEn': '2026-11-15T13:05:07.123456',
      });
      expect(r.creadoEn, DateTime.utc(2026, 11, 15, 13, 5, 7, 123, 456));
      expect(r.creadoEn!.isUtc, isTrue);
    });

    test('creadoEn con zona se respeta, y sin él o ilegible es null', () {
      final conZona = Registro.fromJson({
        'registroId': 4,
        'fecha': '2026-11-15',
        'creadoEn': '2026-11-15T14:05:00+01:00',
      });
      expect(conZona.creadoEn, DateTime.utc(2026, 11, 15, 13, 5));
      expect(
        Registro.fromJson({'registroId': 4, 'fecha': '2026-11-15'}).creadoEn,
        isNull,
      );
      expect(
        Registro.fromJson({
          'registroId': 4,
          'fecha': '2026-11-15',
          'creadoEn': 'ayer',
        }).creadoEn,
        isNull,
      );
    });

    test('el último registro de un día es el de id más alto de ese día', () {
      final registros = [
        const Registro(registroId: 3, fecha: '2026-11-15', cantidad: 10),
        const Registro(registroId: 7, fecha: '2026-11-15', cantidad: 15),
        const Registro(registroId: 9, fecha: '2026-11-14', cantidad: 5),
      ];
      expect(ultimoRegistroDe(registros, '2026-11-15')!.registroId, 7);
      expect(ultimoRegistroDe(registros, '2026-11-13'), isNull);
    });

    test('objetivo programado: se lee, y sin él o sin fecha es null', () {
      final p = ObjetivoProgramado.deJson({
        'desde': '2026-11-23',
        'unidad': 'MINUTOS',
        'frecuencia': 'SEMANAL',
        'meta': 4,
        'minutosObjetivo': 40,
        'diasSemana': null,
      })!;
      expect(p.desde, DateTime(2026, 11, 23));
      expect(p.unidad, UnidadHabito.minutos);
      expect(p.meta, 4);
      expect(p.minutosObjetivo, 40);
      expect(ObjetivoProgramado.deJson(null), isNull);
      expect(ObjetivoProgramado.deJson({'meta': 4}), isNull);
    });
  });

  group('calendario del detalle', () {
    test('hecho lo decide el servidor, no la cuenta de minutos', () {
      // 20 min con `completado`: ese día el objetivo era 20 (hoy es 30).
      final d = leerDiaCalendarioMinutos({
        'fecha': '2026-11-10',
        'completado': true,
        'minutos': 20,
        'minutosObjetivo': 20,
      }, objetivoActual: 30)!;
      expect(d.nivel, NivelDiaMinutos.hecho);
      expect(d.minutos, 20);
      expect(d.objetivo, 20);
    });

    test('a medias: minutos sin completar, con el objetivo de ese día', () {
      final d = leerDiaCalendarioMinutos({
        'fecha': '2026-11-10',
        'completado': false,
        'minutos': 20,
        'minutosObjetivo': 45,
      }, objetivoActual: 30)!;
      expect(d.nivel, NivelDiaMinutos.parcial);
      expect(d.objetivo, 45);
    });

    test('muchos minutos sin completado del servidor siguen a medias', () {
      final d = leerDiaCalendarioMinutos({
        'completado': false,
        'minutos': 90,
        'minutosObjetivo': 120,
      }, objetivoActual: 30)!;
      expect(d.nivel, NivelDiaMinutos.parcial);
    });

    test('sin minutosObjetivo del día, el de hoy como caída', () {
      final d = leerDiaCalendarioMinutos({
        'completado': false,
        'minutos': 10,
      }, objetivoActual: 30)!;
      expect(d.objetivo, 30);
    });

    test('sin minutos ni completado, vacío', () {
      final d = leerDiaCalendarioMinutos({
        'completado': false,
        'minutos': 0,
        'minutosObjetivo': 30,
      }, objetivoActual: 30)!;
      expect(d.nivel, NivelDiaMinutos.vacio);
    });

    test('sin minutos (día de veces o backend viejo) no es día de minutos', () {
      expect(
        leerDiaCalendarioMinutos({
          'fecha': '2026-11-01',
          'completado': true,
          'veces': 2,
          'minutosObjetivo': null,
        }, objetivoActual: 30),
        isNull,
      );
    });
  });

  group('días por semana en minutos', () {
    test('en minutos, entre 1 y 7; en veces no se toca', () {
      expect(metaParaUnidad(8, UnidadHabito.minutos), 7);
      expect(metaParaUnidad(0, UnidadHabito.minutos), 1);
      expect(metaParaUnidad(4, UnidadHabito.minutos), 4);
      expect(metaParaUnidad(8, UnidadHabito.veces), 8);
    });
  });

  group('envíos sin respuesta clara', () {
    test('timeout, sin conexión, 5xx y respuesta ilegible son inciertos', () {
      for (final tipo in [
        TipoErrorApi.timeout,
        TipoErrorApi.sinConexion,
        TipoErrorApi.servidor,
        TipoErrorApi.respuestaInesperada,
      ]) {
        expect(
          esResultadoIncierto(ApiException(tipo)),
          isTrue,
          reason: '$tipo',
        );
      }
      expect(esResultadoIncierto(Exception('x')), isTrue);
    });

    test('un 4xx es una respuesta clara: no se registró nada', () {
      expect(
        esResultadoIncierto(
          const ApiException(TipoErrorApi.peticionInvalida, codigoEstado: 409),
        ),
        isFalse,
      );
      expect(
        esResultadoIncierto(const ApiException(TipoErrorApi.noAutorizado)),
        isFalse,
      );
    });
  });

  group('Analytics de minutos', () {
    test('cuenta solo la entrada que deja el día hecho', () {
      expect(entradaDejaDiaHecho(filaMinutos(hechos: 20), 5), isFalse);
      expect(entradaDejaDiaHecho(filaMinutos(hechos: 20), 10), isTrue);
      expect(entradaDejaDiaHecho(filaMinutos(hechos: 20), 25), isTrue);
      // Ya hecho: lo de por encima de la meta no cuenta.
      expect(
        entradaDejaDiaHecho(
          filaMinutos(hechos: 30, completados: 1, hecho: true),
          15,
        ),
        isFalse,
      );
    });
  });

  group('Hoy: el anillo de minutos', () {
    test('responde con el día hecho, pero no con la pista ni apagado', () {
      expect(minutosTocables(habilitado: true, pistaActiva: false), isTrue);
      expect(minutosTocables(habilitado: true, pistaActiva: true), isFalse);
      expect(minutosTocables(habilitado: false, pistaActiva: false), isFalse);
    });
  });

  group('clave de cada envío', () {
    test('es un UUID v4 y cada una es nueva', () {
      final v4 = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      final claves = {for (var i = 0; i < 200; i++) nuevaClave()};
      expect(claves, hasLength(200));
      expect(claves.every(v4.hasMatch), isTrue);
    });
  });

  group('rueda de la meta', () {
    test('las metas rápidas son 10, 15, 30, 1 h y 2 h', () {
      expect(metasRapidasMinutos, [10, 15, 30, 60, 120]);
    });

    test('de 5 en 5, con 0 solo si hay horas', () {
      expect(minutosDeRueda(1), [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]);
      expect(minutosDeRueda(0).first, 5);
      expect(minutosDeRueda(0).last, 55);
    });

    test('con 10 h, solo 0: el máximo es 600', () {
      expect(minutosDeRueda(10), [0]);
    });

    test('una meta que no es múltiplo de 5 se incluye en su hora', () {
      expect(minutosDeRueda(0, existente: 7), contains(7));
      expect(minutosDeRueda(0, existente: 3).first, 3);
      expect(minutosDeRueda(1, existente: 82), contains(22));
      // En otra hora no aparece.
      expect(minutosDeRueda(2, existente: 82), isNot(contains(22)));
    });

    test('el minuto más cercano; si empatan, el menor', () {
      expect(minutoMasCercano([5, 10, 15], 0), 5);
      expect(minutoMasCercano([0], 35), 0);
      expect(minutoMasCercano([0, 5, 10], 7), 5);
    });
  });
}
