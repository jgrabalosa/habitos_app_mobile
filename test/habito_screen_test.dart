import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitos_app_mobile/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:habitos_app_mobile/models/habito.dart';
import 'package:habitos_app_mobile/models/objetivo_programado.dart';
import 'package:habitos_app_mobile/models/plantilla_habito.dart';
import 'package:habitos_app_mobile/screens/habito_screen.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final cargarCategoriasOriginal = HabitoScreen.cargarCategorias;
  final crearOriginal = HabitoScreen.crearHabito;
  final actualizarOriginal = HabitoScreen.actualizarHabito;
  final cargarProgramadoOriginal = HabitoScreen.cargarObjetivoProgramado;
  final anularOriginal = HabitoScreen.anularObjetivoProgramado;

  final categorias = [
    {'categoriaId': 2, 'codigo': 'CAT_ESTUDIO', 'nombre': 'Estudio'},
  ];

  setUp(() {
    // Sin red: las categorías son las del test.
    HabitoScreen.cargarCategorias = (_) async => categorias;
    HabitoScreen.cargarObjetivoProgramado = (_) async => null;
  });

  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    HabitoScreen.cargarCategorias = cargarCategoriasOriginal;
    HabitoScreen.crearHabito = crearOriginal;
    HabitoScreen.actualizarHabito = actualizarOriginal;
    HabitoScreen.cargarObjetivoProgramado = cargarProgramadoOriginal;
    HabitoScreen.anularObjetivoProgramado = anularOriginal;
  });

  Widget montar(Widget child) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: const Locale('es'),
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      ...NordayCoreLocalizations.localizationsDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  /// Abre el formulario como lo abre la lista: un push que espera un bool.
  /// [resultado] recibe lo que devuelve el push cuando la pantalla se cierra.
  Future<void> abrirFormulario(
    WidgetTester tester,
    List<bool?> resultado, {
    Habito? habito,
    ObjetivoProgramado? programado,
    PlantillaHabito? plantilla,
  }) async {
    await tester.pumpWidget(
      montar(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado.add(
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HabitoScreen(
                          usuarioId: 7,
                          habito: habito,
                          objetivoProgramado: programado,
                          plantilla: plantilla,
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  /// Escribe el nombre y apaga el recordatorio: con recordatorio activo y sin
  /// hora el formulario da error antes de llamar a nada.
  Future<void> rellenar(WidgetTester tester, String nombre) async {
    await tester.enterText(find.byType(TextField).first, nombre);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
  }

  Future<void> guardar(WidgetTester tester, AppLocalizations l) async {
    final boton = find.widgetWithText(ElevatedButton, l.habBotonCrear);
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  testWidgets('guardar un hábito nuevo devuelve true y cierra la pantalla', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    var llamadas = 0;
    HabitoScreen.crearHabito =
        (
          String nombre,
          String descripcion,
          String frecuencia,
          int meta,
          int usuarioId,
          int? categoriaId, {
          String? diasSemana,
          bool recordatorioActivo = true,
          String? recordatorioHora,
          String? unidad,
          int? minutosObjetivo,
        }) async {
          llamadas++;
          return <String>[];
        };

    final resultado = <bool?>[];
    await abrirFormulario(tester, resultado);
    await rellenar(tester, 'Meditar');
    await guardar(tester, l);

    expect(llamadas, 1);
    expect(resultado, [true]);
    expect(find.byType(HabitoScreen), findsNothing);
  });

  testWidgets(
    'si el servidor falla, no se cierra, muestra el error y no devuelve true',
    (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      HabitoScreen.crearHabito =
          (
            String nombre,
            String descripcion,
            String frecuencia,
            int meta,
            int usuarioId,
            int? categoriaId, {
            String? diasSemana,
            bool recordatorioActivo = true,
            String? recordatorioHora,
            String? unidad,
            int? minutosObjetivo,
          }) async {
            throw Exception('fallo de prueba');
          };

      final resultado = <bool?>[];
      await abrirFormulario(tester, resultado);
      await rellenar(tester, 'Meditar');
      await guardar(tester, l);

      expect(resultado, isEmpty);
      expect(find.byType(HabitoScreen), findsOneWidget);
      expect(find.text(l.habErrorCrear), findsOneWidget);
    },
  );

  testWidgets('nombre vacío: no llama a la red y avisa del nombre', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('es'));
    var llamadas = 0;
    HabitoScreen.crearHabito =
        (
          String nombre,
          String descripcion,
          String frecuencia,
          int meta,
          int usuarioId,
          int? categoriaId, {
          String? diasSemana,
          bool recordatorioActivo = true,
          String? recordatorioHora,
          String? unidad,
          int? minutosObjetivo,
        }) async {
          llamadas++;
          return <String>[];
        };

    final resultado = <bool?>[];
    await abrirFormulario(tester, resultado);
    await rellenar(tester, '');
    await guardar(tester, l);

    expect(llamadas, 0);
    expect(resultado, isEmpty);
    expect(find.text(l.habNombreObligatorio), findsOneWidget);
  });

  group('desde una plantilla', () {
    const canal = MethodChannel('flutter.baseflow.com/permissions/methods');
    const denegado = 0;
    const concedido = 1;

    /// Lo que recibe el falso de crear: el body que iría a la red.
    late Map<String, Object?> creado;
    late int estadoPermiso;
    late int consultasPermiso;
    late Duration retrasoPermiso;

    PlantillaHabito plantilla(String id) =>
        plantillasHabito.firstWhere((p) => p.id == id);

    setUp(() {
      creado = {};
      estadoPermiso = denegado;
      consultasPermiso = 0;
      retrasoPermiso = Duration.zero;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            if (call.method == 'checkPermissionStatus') {
              consultasPermiso++;
              if (retrasoPermiso > Duration.zero) {
                await Future<void>.delayed(retrasoPermiso);
              }
              return estadoPermiso;
            }
            if (call.method == 'shouldShowRequestPermissionRationale') {
              return false;
            }
            return null;
          });
      HabitoScreen.crearHabito =
          (
            String nombre,
            String descripcion,
            String frecuencia,
            int meta,
            int usuarioId,
            int? categoriaId, {
            String? diasSemana,
            bool recordatorioActivo = true,
            String? recordatorioHora,
            String? unidad,
            int? minutosObjetivo,
          }) async {
            creado = {
              'nombre': nombre,
              'frecuencia': frecuencia,
              'meta': meta,
              'diasSemana': diasSemana,
              'recordatorioActivo': recordatorioActivo,
              'recordatorioHora': recordatorioHora,
              'unidad': unidad,
              'minutosObjetivo': minutosObjetivo,
            };
            return <String>[];
          };
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, null);
    });

    testWidgets('«Un día sin alcohol» trae el aviso encendido a las 22:30 y '
        'se guarda sin tocar la hora', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      estadoPermiso = concedido;
      final resultado = <bool?>[];
      await abrirFormulario(
        tester,
        resultado,
        plantilla: plantilla('diaSinAlcohol'),
      );

      final contexto = tester.element(find.byType(HabitoScreen));
      final hora = const TimeOfDay(hour: 22, minute: 30).format(contexto);
      expect(find.text(l.habALas(hora)), findsOneWidget);
      await guardar(tester, l);

      expect(find.text(l.habHoraObligatoria), findsNothing);
      expect(creado['nombre'], 'Un día sin alcohol');
      expect(creado['recordatorioActivo'], isTrue);
      expect(creado['recordatorioHora'], '22:30');
      expect(resultado, [true]);
    });

    testWidgets('con el permiso ya dado, guardar no pregunta nada', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      estadoPermiso = concedido;
      final resultado = <bool?>[];
      await abrirFormulario(
        tester,
        resultado,
        plantilla: plantilla('diaSinAlcohol'),
      );
      await guardar(tester, l);

      expect(find.text(l.permisoTitulo), findsNothing);
      expect(resultado, [true]);
    });

    testWidgets('sin el permiso, guardar lo pide; con «Ahora no» el hábito se '
        'guarda igual', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      final resultado = <bool?>[];
      await abrirFormulario(
        tester,
        resultado,
        plantilla: plantilla('diaSinAlcohol'),
      );
      await guardar(tester, l);

      expect(find.text(l.permisoTitulo), findsOneWidget);
      expect(creado, isEmpty);

      await tester.tap(find.text(l.permisoAhoraNo));
      await tester.pumpAndSettle();

      expect(creado['recordatorioHora'], '22:30');
      expect(resultado, [true]);
    });

    testWidgets('un doble toque en «Crear» no crea el hábito dos veces', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      estadoPermiso = concedido;
      // El permiso tarda en contestar: el segundo toque llega mientras tanto.
      retrasoPermiso = const Duration(milliseconds: 200);
      var llamadas = 0;
      final crear = HabitoScreen.crearHabito;
      HabitoScreen.crearHabito =
          (
            String nombre,
            String descripcion,
            String frecuencia,
            int meta,
            int usuarioId,
            int? categoriaId, {
            String? diasSemana,
            bool recordatorioActivo = true,
            String? recordatorioHora,
            String? unidad,
            int? minutosObjetivo,
          }) {
            llamadas++;
            return crear(
              nombre,
              descripcion,
              frecuencia,
              meta,
              usuarioId,
              categoriaId,
              diasSemana: diasSemana,
              recordatorioActivo: recordatorioActivo,
              recordatorioHora: recordatorioHora,
              unidad: unidad,
              minutosObjetivo: minutosObjetivo,
            );
          };
      await abrirFormulario(tester, [], plantilla: plantilla('diaSinAlcohol'));
      final boton = find.widgetWithText(ElevatedButton, l.habBotonCrear);
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.tap(boton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(llamadas, 1);
    });

    testWidgets('con el aviso apagado, guardar no pregunta por el permiso', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      final resultado = <bool?>[];
      await abrirFormulario(
        tester,
        resultado,
        plantilla: plantilla('diaSinAlcohol'),
      );
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await guardar(tester, l);

      expect(find.text(l.permisoTitulo), findsNothing);
      expect(creado['recordatorioActivo'], isFalse);
      expect(resultado, [true]);
    });

    testWidgets('«Llamar a alguien querido» se guarda como semanal flexible '
        'de 2 días', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      estadoPermiso = concedido;
      await abrirFormulario(tester, [], plantilla: plantilla('llamarQuerido'));
      await guardar(tester, l);

      expect(creado['frecuencia'], 'SEMANAL');
      expect(creado['meta'], 2);
      expect(creado['diasSemana'], isNull);
      expect(creado['recordatorioHora'], '19:30');
    });

    testWidgets('«Caminar» se guarda de minutos: diario, 30 min', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      estadoPermiso = concedido;
      await abrirFormulario(tester, [], plantilla: plantilla('caminar'));
      await guardar(tester, l);

      expect(creado['frecuencia'], 'DIARIO');
      expect(creado['unidad'], 'MINUTOS');
      expect(creado['minutosObjetivo'], 30);
      expect(creado['recordatorioHora'], '18:00');
    });

    testWidgets(
      'desde cero, el aviso sigue sin hora y la hora es obligatoria',
      (tester) async {
        final l = await AppLocalizations.delegate.load(const Locale('es'));
        await abrirFormulario(tester, []);
        await tester.enterText(find.byType(TextField).first, 'Nadar');
        await guardar(tester, l);

        expect(find.text(l.habHoraObligatoria), findsOneWidget);
        expect(creado, isEmpty);
        expect(consultasPermiso, 0);
      },
    );
  });

  group('hábitos de minutos', () {
    /// Lo que recibe el falso de crear: el body que iría a la red.
    late Map<String, Object?> creado;

    setUp(() {
      creado = {};
      HabitoScreen.crearHabito =
          (
            String nombre,
            String descripcion,
            String frecuencia,
            int meta,
            int usuarioId,
            int? categoriaId, {
            String? diasSemana,
            bool recordatorioActivo = true,
            String? recordatorioHora,
            String? unidad,
            int? minutosObjetivo,
          }) async {
            creado = {
              'frecuencia': frecuencia,
              'meta': meta,
              'unidad': unidad,
              'minutosObjetivo': minutosObjetivo,
            };
            return <String>[];
          };
    });

    Habito habitoMinutos({int minutos = 30}) => Habito(
      habitoId: 3,
      nombre: 'Leer',
      frecuencia: 'DIARIO',
      meta: 1,
      activo: true,
      recordatorioActivo: false,
      unidad: UnidadHabito.minutos,
      minutosObjetivo: minutos,
    );

    testWidgets('uno de veces se crea sin campos de minutos, como siempre', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirFormulario(tester, []);
      await rellenar(tester, 'Beber agua');
      await guardar(tester, l);
      expect(creado['unidad'], isNull);
      expect(creado['minutosObjetivo'], isNull);
    });

    testWidgets('Minutos con la meta rápida de 15: diario, 1 día, 15 min', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirFormulario(tester, []);
      await rellenar(tester, 'Leer');
      await tester.ensureVisible(find.text(l.habUnidadMinutos));
      await tester.tap(find.text(l.habUnidadMinutos));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('15 min'));
      await tester.tap(find.text('15 min'));
      await tester.pumpAndSettle();
      expect(find.text('15 min cada día'), findsOneWidget);
      await guardar(tester, l);

      expect(creado, {
        'frecuencia': 'DIARIO',
        'meta': 1,
        'unidad': 'MINUTOS',
        'minutosObjetivo': 15,
      });
    });

    testWidgets('de veces diario con meta 8 a minutos semanal: 7 días', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirFormulario(tester, []);
      await rellenar(tester, 'Correr');
      // Diario de veces con meta 8: siete toques al «+».
      final mas = find.widgetWithIcon(IconButton, LucideIcons.plus);
      await tester.ensureVisible(mas);
      for (var i = 0; i < 7; i++) {
        await tester.tap(mas);
        await tester.pump();
      }
      expect(find.text('8 veces al día'), findsOneWidget);

      await tester.ensureVisible(find.text(l.habUnidadMinutos));
      await tester.tap(find.text(l.habUnidadMinutos));
      await tester.pumpAndSettle();
      // Diario de minutos: no hay objetivo de veces que enseñar.
      expect(find.textContaining('8 veces'), findsNothing);

      await tester.ensureVisible(find.text(l.frecDiario));
      await tester.tap(find.text(l.frecDiario));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.frecSemanal).last);
      await tester.pumpAndSettle();

      expect(find.text('7 días por semana'), findsOneWidget);
      // Y no deja pasar de 7.
      final masSemanal = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, LucideIcons.plus),
      );
      expect(masSemanal.onPressed, isNull);

      await guardar(tester, l);
      expect(creado['frecuencia'], 'SEMANAL');
      expect(creado['meta'], 7);
      expect(creado['unidad'], 'MINUTOS');
    });

    testWidgets('un semanal de veces cuenta días por semana', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirFormulario(tester, []);
      await rellenar(tester, 'Correr');
      expect(find.text('1 vez al día'), findsOneWidget);

      await tester.ensureVisible(find.text(l.frecDiario));
      await tester.tap(find.text(l.frecDiario));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.frecSemanal).last);
      await tester.pumpAndSettle();
      expect(find.text('1 día por semana'), findsOneWidget);

      final mas = find.widgetWithIcon(IconButton, LucideIcons.plus);
      await tester.ensureVisible(mas);
      await tester.tap(mas);
      await tester.pump();
      await tester.tap(mas);
      await tester.pump();
      expect(find.text('3 días por semana'), findsOneWidget);
    });

    /// Un alta de minutos con el formulario ya en «Minutos».
    Future<AppLocalizations> altaDeMinutos(WidgetTester tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirFormulario(tester, []);
      await rellenar(tester, 'Leer');
      await tester.ensureVisible(find.text(l.habUnidadMinutos));
      await tester.tap(find.text(l.habUnidadMinutos));
      await tester.pumpAndSettle();
      return l;
    }

    Future<void> abrirRuedas(
      WidgetTester tester, {
      String chip = 'Otra…',
    }) async {
      final otra = find.widgetWithText(ChoiceChip, chip);
      await tester.ensureVisible(otra);
      await tester.tap(otra);
      await tester.pumpAndSettle();
    }

    /// Mueve una rueda [pasos] posiciones hacia abajo en la lista (+) o hacia
    /// arriba (−). Cada posición mide 48.
    Future<void> girar(WidgetTester tester, String rueda, int pasos) async {
      await tester.drag(find.byKey(ValueKey(rueda)), Offset(0, -48.0 * pasos));
      await tester.pumpAndSettle();
    }

    Future<void> listo(WidgetTester tester) async {
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'los chips son 10, 15, 30 min, 1 h y 2 h, y el de 2 h guarda 120',
      (tester) async {
        final l = await altaDeMinutos(tester);
        for (final texto in ['10 min', '15 min', '30 min', '1 h', '2 h']) {
          expect(find.widgetWithText(ChoiceChip, texto), findsOneWidget);
        }
        // Cinco metas más «Otra…».
        expect(find.byType(ChoiceChip), findsNWidgets(6));
        await tester.ensureVisible(find.text('2 h'));
        await tester.tap(find.text('2 h'));
        await tester.pumpAndSettle();
        expect(find.text('2 h cada día'), findsOneWidget);
        await guardar(tester, l);
        expect(creado['minutosObjetivo'], 120);
      },
    );

    testWidgets('«Otra…», 1 h y 30 min, «Listo»: se guarda 90', (tester) async {
      final l = await altaDeMinutos(tester);
      await abrirRuedas(tester);
      expect(find.text('Tiempo por día'), findsOneWidget);
      await girar(tester, 'rueda-horas', 1);
      await listo(tester);

      expect(
        find.widgetWithText(ChoiceChip, 'Otra: 1 h 30 min'),
        findsOneWidget,
      );
      expect(find.text('1 h 30 min cada día'), findsOneWidget);
      await guardar(tester, l);
      expect(creado['minutosObjetivo'], 90);
    });

    testWidgets('si la cifra coincide con un chip, se marca ese chip', (
      tester,
    ) async {
      await altaDeMinutos(tester);
      await abrirRuedas(tester);
      await girar(tester, 'rueda-horas', 1);
      await girar(tester, 'rueda-minutos-1', -6);
      await listo(tester);

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '1 h'),
      );
      expect(chip.selected, isTrue);
      final otra = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Otra…'),
      );
      expect(otra.selected, isFalse);
    });

    testWidgets('con 10 h los minutos solo pueden ser 0', (tester) async {
      final l = await altaDeMinutos(tester);
      await abrirRuedas(tester);
      await girar(tester, 'rueda-horas', 10);
      await listo(tester);

      expect(find.widgetWithText(ChoiceChip, 'Otra: 10 h'), findsOneWidget);
      await guardar(tester, l);
      expect(creado['minutosObjetivo'], 600);
    });

    testWidgets('con 0 h no se puede elegir 0 min', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      final guardados = <int?>[];
      HabitoScreen.actualizarHabito =
          (
            int habitoId,
            String nombre,
            String descripcion,
            String frecuencia,
            int meta,
            int usuarioId,
            int? categoriaId, {
            String? diasSemana,
            bool recordatorioActivo = true,
            String? recordatorioHora,
            String? unidad,
            int? minutosObjetivo,
          }) async {
            guardados.add(minutosObjetivo);
            return null;
          };
      await abrirFormulario(tester, [], habito: habitoMinutos(minutos: 60));
      await abrirRuedas(tester);
      // De 1 h 0 min a 0 h: los minutos pasan a 5, nunca 0 h 0 min.
      await girar(tester, 'rueda-horas', -1);
      await listo(tester);

      expect(find.widgetWithText(ChoiceChip, 'Otra: 5 min'), findsOneWidget);
      final boton = find.widgetWithText(ElevatedButton, l.habBotonActualizar);
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(guardados, [5]);
    });

    testWidgets('editar un hábito de 22 min abre la rueda en 0 h 22 min y, sin '
        'tocar, guarda 22', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      final guardados = <int?>[];
      HabitoScreen.actualizarHabito =
          (
            int habitoId,
            String nombre,
            String descripcion,
            String frecuencia,
            int meta,
            int usuarioId,
            int? categoriaId, {
            String? diasSemana,
            bool recordatorioActivo = true,
            String? recordatorioHora,
            String? unidad,
            int? minutosObjetivo,
          }) async {
            guardados.add(minutosObjetivo);
            return null;
          };
      await abrirFormulario(tester, [], habito: habitoMinutos(minutos: 22));
      expect(find.widgetWithText(ChoiceChip, 'Otra: 22 min'), findsOneWidget);

      await abrirRuedas(tester, chip: 'Otra: 22 min');
      // El resultado entero, ya con el 22 elegido.
      expect(find.text('22 min'), findsOneWidget);
      await listo(tester);
      expect(find.widgetWithText(ChoiceChip, 'Otra: 22 min'), findsOneWidget);

      final boton = find.widgetWithText(ElevatedButton, l.habBotonActualizar);
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(guardados, [22]);
    });

    testWidgets('cerrar la hoja sin «Listo» no cambia la meta', (tester) async {
      await altaDeMinutos(tester);
      await abrirRuedas(tester);
      await girar(tester, 'rueda-horas', 3);
      // Tocar fuera de la hoja la cierra.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Tiempo por día'), findsNothing);
      expect(find.text('30 min cada día'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Otra…'), findsOneWidget);
    });

    testWidgets('las ruedas se leen con su unidad: «1 hora», «30 minutos»', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await altaDeMinutos(tester);
      await abrirRuedas(tester);
      await girar(tester, 'rueda-horas', 1);

      expect(find.bySemanticsLabel('1 hora'), findsOneWidget);
      expect(find.bySemanticsLabel('30 minutos'), findsOneWidget);
      // Y el resultado entero.
      expect(find.bySemanticsLabel('1 h 30 min'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('editando uno de minutos, «Veces» no se ofrece', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      await abrirFormulario(tester, [], habito: habitoMinutos());
      final segmento = tester.widget<SegmentedButton<UnidadHabito>>(
        find.byType(SegmentedButton<UnidadHabito>),
      );
      expect(
        segmento.segments
            .firstWhere((s) => s.value == UnidadHabito.veces)
            .enabled,
        isFalse,
      );
      expect(find.text(l.habUnidadSinVuelta), findsOneWidget);
    });

    testWidgets('si el cambio vale desde mañana, se avisa con los minutos', (
      tester,
    ) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      final hoy = DateTime.now();
      HabitoScreen.actualizarHabito =
          (
            int habitoId,
            String nombre,
            String descripcion,
            String frecuencia,
            int meta,
            int usuarioId,
            int? categoriaId, {
            String? diasSemana,
            bool recordatorioActivo = true,
            String? recordatorioHora,
            String? unidad,
            int? minutosObjetivo,
          }) async => DateTime(hoy.year, hoy.month, hoy.day + 1);

      final resultado = <bool?>[];
      await abrirFormulario(tester, resultado, habito: habitoMinutos());
      // La meta rápida de 60 se lee en horas.
      await tester.ensureVisible(find.text('1 h'));
      await tester.tap(find.text('1 h'));
      await tester.pumpAndSettle();
      expect(find.text('1 h cada día'), findsOneWidget);
      final boton = find.widgetWithText(ElevatedButton, l.habBotonActualizar);
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(resultado, [true]);
      expect(
        find.text(
          'El objetivo de 1 h se aplica desde mañana. Hoy ya tienes registros '
          'con la meta anterior.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('el cambio programado se ve y se puede anular', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('es'));
      final anulados = <int>[];
      HabitoScreen.anularObjetivoProgramado = (id) async => anulados.add(id);
      final hoy = DateTime.now();
      final programado = ObjetivoProgramado(
        desde: DateTime(hoy.year, hoy.month, hoy.day + 1),
        unidad: UnidadHabito.minutos,
        frecuencia: 'DIARIO',
        meta: 1,
        minutosObjetivo: 40,
      );

      final resultado = <bool?>[];
      await abrirFormulario(
        tester,
        resultado,
        habito: habitoMinutos(),
        programado: programado,
      );
      expect(find.text(l.habProgramadoTitulo), findsOneWidget);
      expect(find.text('Desde mañana: 40 min'), findsOneWidget);

      await tester.tap(find.text(l.habProgramadoAnular));
      await tester.pumpAndSettle();
      expect(anulados, [3]);
      expect(find.text(l.habProgramadoTitulo), findsNothing);

      // Salir sin guardar avisa igual de que algo ha cambiado.
      final NavigatorState nav = tester.state(find.byType(Navigator));
      nav.maybePop();
      await tester.pumpAndSettle();
      expect(resultado, [true]);
    });
  });
}
