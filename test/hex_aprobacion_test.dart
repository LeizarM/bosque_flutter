import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_aprobacion_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_grupos_aprobacion.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// La confirmación de presencia que acompaña al visto bueno, tal cual.
const String _textoVistoBueno =
    'Al dar el visto bueno confirmas que el empleado estuvo trabajando en la '
    'sucursal durante estas horas. Tu firma queda registrada.';

/// «Aprobación de área»: grupos por encargado y mes con «Aprobar todo», la
/// aprobación y el rechazo por fila, el visto bueno de reemplazo desde
/// «Reportados de encargados», filtros, anchos y teclado abierto.
void main() {
  setUpAll(cargarFuentesHex);

  late _JefeFalso repo;

  setUp(() => repo = _JefeFalso());

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  List<Override> anulaciones() => [
    hexReporteRepositoryProvider.overrideWithValue(repo),
  ];

  Future<void> montar(
    WidgetTester t, {
    double ancho = 1400,
    Set<String>? botones,
  }) async {
    await montarHex(
      t,
      const HexAprobacionScreen(),
      ancho: ancho,
      botones: botones,
      overrides: anulaciones(),
    );
    await esperar(t);
  }

  Finder enDialogo(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

  Finder botonDelDialogo(String texto) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(FilledButton, texto),
  );

  Finder campoDelDialogo() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );

  FiltroReportesHex ultimoFiltro() =>
      repo.argumentosDe('bandejaJefe').last['filtro']! as FiltroReportesHex;

  /// El «Aprobar todo» de la cabecera del grupo que dice [titulo].
  Finder aprobarTodoDe(String titulo) => find.descendant(
    of: find.ancestor(
      of: find.text(titulo),
      matching: find.byType(CabeceraGrupoHex),
    ),
    matching: find.widgetWithText(FilledButton, 'Aprobar todo'),
  );

  /// El desplazamiento de la pantalla (el único vertical en el angosto).
  Finder pagina() =>
      find
          .ancestor(
            of: find.text('Aprobación de área'),
            matching: find.byType(Scrollable),
          )
          .first;

  bool esVertical(Widget w) =>
      (w is ScrollView && w.scrollDirection == Axis.vertical) ||
      (w is SingleChildScrollView && w.scrollDirection == Axis.vertical);

  bool esLateral(Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.horizontal;

  /// El segmento de los que aún no tienen visto bueno.
  Finder segmentoReportados() => find.text('Sin visto bueno aún');

  Future<void> irAReportados(WidgetTester t) async {
    await t.tap(segmentoReportados());
    await esperar(t, 3);
  }

  /// Abre el menú de la tarjeta de [empleado] (teléfono) y toca [accion].
  Future<void> desdeElMenu(
    WidgetTester t,
    String empleado,
    String accion,
  ) async {
    final tarjeta = find.ancestor(
      of: find.text(empleado),
      matching: find.byType(Card),
    );
    // La tarea del día está a la vista en la tarjeta: se toca el botón.
    final principal = switch (accion) {
      'Aprobar' => 'Aprobar',
      'Visto bueno' => 'Dar visto bueno',
      _ => null,
    };
    if (principal != null) {
      final boton = find.descendant(
        of: tarjeta,
        matching: find.text(principal),
      );
      await t.ensureVisible(boton);
      await esperar(t, 1);
      await t.tap(boton);
      await esperar(t, 2);
      return;
    }
    final menu = find.descendant(
      of: tarjeta,
      matching: find.byIcon(Icons.more_vert),
    );
    await t.ensureVisible(menu);
    await esperar(t, 1);
    await t.tap(menu);
    await esperar(t, 2);
    await t.tap(find.text(accion).last);
    await esperar(t, 2);
  }

  group('agruparHex', () {
    HexReporteEntity fila(
      int id,
      BigInt encargado,
      String nombre,
      DateTime d,
    ) => HexReporteEntity(
      idReporte: BigInt.from(id),
      fechaJornada: d,
      codEncargado: encargado,
      nombreEncargado: nombre,
    );

    test('agruparHex separa por encargado y por mes', () {
      final b = BigInt.from(7);
      final c = BigInt.from(8);
      final grupos = agruparHex([
        fila(1, b, 'Rojas Vargas Luis', DateTime(2026, 10, 23)),
        fila(2, b, 'Rojas Vargas Luis', DateTime(2026, 9, 28)),
        fila(3, c, 'Torrez Aliaga Ana', DateTime(2026, 10, 15)),
      ]);
      expect(
        [for (final g in grupos) (g.codEncargado, g.anio, g.mes)],
        [(b, 2026, 10), (b, 2026, 9), (c, 2026, 10)],
      );
      expect(grupos.first.nombreEncargado, 'Rojas Vargas Luis');
      expect(grupos.first.periodo, 'octubre de 2026');
      expect([for (final g in grupos) g.reportes.length], [1, 1, 1]);
    });

    test('junta filas sueltas del mismo grupo y ordena por nombre', () {
      final b = BigInt.from(7);
      final c = BigInt.from(8);
      final grupos = agruparHex([
        fila(1, c, 'Torrez Aliaga Ana', DateTime(2026, 10, 30)),
        fila(2, b, 'Rojas Vargas Luis', DateTime(2026, 10, 23)),
        fila(3, b, 'Rojas Vargas Luis', DateTime(2026, 9, 28)),
        fila(4, b, 'Rojas Vargas Luis', DateTime(2026, 10, 2)),
      ]);
      expect(
        [
          for (final g in grupos)
            [for (final r in g.reportes) r.idReporte!.toInt()],
        ],
        [
          [2, 4],
          [3],
          [1],
        ],
      );
      expect(agruparHex(const []), isEmpty);
    });

    test('sin encargado o sin jornada no hay Aprobar todo', () {
      final aprobable = HexReporteEntity(
        idReporte: BigInt.one,
        fechaJornada: DateTime(2026, 10, 23),
        codEncargado: BigInt.from(7),
        puedeAprobar: true,
      );
      expect(agruparHex([aprobable]).single.puedeAprobarTodo, isTrue);
      final sinEncargado = HexReporteEntity(
        idReporte: BigInt.two,
        fechaJornada: DateTime(2026, 10, 23),
        puedeAprobar: true,
      );
      final sinJornada = HexReporteEntity(
        idReporte: BigInt.from(3),
        codEncargado: BigInt.from(7),
        puedeAprobar: true,
      );
      for (final fila in [sinEncargado, sinJornada]) {
        final grupo = agruparHex([fila]).single;
        expect(grupo.reportes, [fila]);
        expect(grupo.puedeAprobarTodo, isFalse);
      }
    });
  });

  group('roles', () {
    testWidgets('sin roles de jefe avisa y no pide la bandeja', (t) async {
      for (final roles in [
        const HexRolesEntity(),
        const HexRolesEntity(esEncargado: true, sucursales: '1'),
      ]) {
        repo = _JefeFalso()..programar('misRoles', [roles]);
        await montar(t);
        expect(find.text('No tienes el rol de jefe de área'), findsOneWidget);
        expect(
          find.text(
            'Pide a RRHH que te lo asigne en «Horas extra: aprobadores»: '
            'cubre toda tu rama del organigrama.',
          ),
          findsOneWidget,
        );
        expect(repo.vecesDe('bandejaJefe'), 0);
        expect(find.text('Con visto bueno'), findsNothing);
        expect(find.text('Leyenda de códigos'), findsNothing);
        await cerrar(t);
      }
    });

    testWidgets('un 403 en los roles o en la bandeja dice No tienes permiso', (
      t,
    ) async {
      const sinPermiso = SinPermisoHex(
        'No tienes los permisos necesarios para realizar esta acción.',
      );
      repo.programar('misRoles', [sinPermiso]);
      await montar(t);
      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(repo.vecesDe('bandejaJefe'), 0);
      await cerrar(t);

      repo = _JefeFalso()..programar('bandejaJefe', [sinPermiso]);
      await montar(t, ancho: 390);
      expect(find.text('No tienes permiso'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('aprobar todo', () {
    const grupoOctubre = 'Rojas Vargas Luis — octubre de 2026 · 2 reportes';

    testWidgets(
      'aprobar todo manda el grupo y avisa que incluye lo que no se ve',
      (t) async {
        const resultado =
            'Se aprobaron 5 reportes con visto bueno de Rojas Vargas Luis de '
            'octubre de 2026.';
        repo.programar('aprobarGrupo', [
          (id: BigInt.from(5), mensaje: resultado),
        ]);
        await montar(t);
        final lecturas = repo.vecesDe('bandejaJefe');
        expect(find.text(grupoOctubre), findsOneWidget);
        await t.tap(aprobarTodoDe(grupoOctubre));
        await esperar(t, 2);
        final texto = t.widget<Text>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('también los que no se ven'),
          ),
        );
        // Sin filtros basta el texto del brief, tal cual.
        expect(
          texto.data,
          'Se aprobarán todos los reportes con visto bueno de Rojas Vargas '
          'Luis de octubre de 2026 que puedes firmar, también los que no se '
          'ven en esta página.',
        );
        expect(repo.vecesDe('aprobarGrupo'), 0);
        await t.tap(botonDelDialogo('Aprobar todo'));
        await esperar(t, 3);
        // El grupo (encargado, año y mes), no la lista que se ve.
        expect(repo.argumentosDe('aprobarGrupo').single, {
          'codEncargado': BigInt.from(7),
          'anio': 2026,
          'mes': 10,
          'observacion': null,
        });
        expect(find.text(resultado), findsOneWidget);
        expect(repo.vecesDe('bandejaJefe'), greaterThan(lecturas));
        await cerrar(t);
      },
    );

    testWidgets(
      'con filtros, el diálogo dice que no limitan lo que se aprueba',
      (t) async {
        await montar(t);
        await t.tap(find.text('Todas las fechas'));
        await esperar(t, 2);
        await t.enterText(find.widgetWithText(TextField, 'Desde'), '01102026');
        await t.enterText(find.widgetWithText(TextField, 'Hasta'), '15102026');
        await t.pump();
        await t.tap(find.text('Aplicar'));
        await esperar(t, 3);
        // El grupo se arma con lo que mandó el servidor: el filtro no lo cambia.
        expect(find.text(grupoOctubre), findsOneWidget);
        await t.tap(aprobarTodoDe(grupoOctubre));
        await esperar(t, 2);
        expect(
          enDialogo(
            'Se aprobarán todos los reportes con visto bueno de Rojas Vargas '
            'Luis de octubre de 2026 que puedes firmar, también los que no se '
            'ven en esta página.\n\n'
            'El filtro de fecha no limita esta acción: se aprueba todo octubre '
            'de 2026 de Rojas Vargas Luis.',
          ),
          findsOneWidget,
        );
        await t.tap(botonDelDialogo('Aprobar todo'));
        await esperar(t, 3);
        expect(repo.argumentosDe('aprobarGrupo').single, {
          'codEncargado': BigInt.from(7),
          'anio': 2026,
          'mes': 10,
          'observacion': null,
        });
        await cerrar(t);
      },
    );

    testWidgets('un 409 al aprobar todo avisa y recarga una sola vez', (
      t,
    ) async {
      const cambio = 'Los reportes cambiaron mientras los revisabas.';
      repo.programar('aprobarGrupo', [const ConflictoHex(cambio)]);
      await montar(t);
      final lecturas = repo.vecesDe('bandejaJefe');
      await t.tap(aprobarTodoDe(grupoOctubre));
      await esperar(t, 2);
      await t.tap(botonDelDialogo('Aprobar todo'));
      await esperar(t, 3);
      expect(find.text(cambio), findsOneWidget);
      expect(repo.vecesDe('bandejaJefe'), lecturas + 1);
      await cerrar(t);
    });

    testWidgets('si el SP no manda texto se muestra la cantidad aprobada', (
      t,
    ) async {
      repo.programar('aprobarGrupo', [(id: BigInt.from(3), mensaje: '')]);
      await montar(t);
      await t.tap(aprobarTodoDe(grupoOctubre));
      await esperar(t, 2);
      await t.tap(botonDelDialogo('Aprobar todo'));
      await esperar(t, 3);
      expect(find.text('Reportes aprobados: 3.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('si no confirma no aprueba nada', (t) async {
      await montar(t);
      await t.tap(aprobarTodoDe(grupoOctubre));
      await esperar(t, 2);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      expect(repo.vecesDe('aprobarGrupo'), 0);
      // Se puede volver a abrir.
      await t.tap(aprobarTodoDe(grupoOctubre));
      await esperar(t, 2);
      expect(find.byType(AlertDialog), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin nada aprobable muestra el texto del SP y recarga', (
      t,
    ) async {
      const regla =
          'No hay reportes con visto bueno de Rojas Vargas Luis en octubre de '
          '2026 que usted pueda aprobar. Hay 2 que no puede firmar: revíselos '
          'uno por uno.';
      repo.programar('aprobarGrupo', [const NegocioHex(regla)]);
      await montar(t);
      final lecturas = repo.vecesDe('bandejaJefe');
      await t.tap(aprobarTodoDe(grupoOctubre));
      await esperar(t, 2);
      await t.tap(botonDelDialogo('Aprobar todo'));
      await esperar(t, 3);
      expect(find.text(regla), findsOneWidget);
      expect(repo.vecesDe('bandejaJefe'), greaterThan(lecturas));
      await cerrar(t);
    });

    testWidgets('un 403 al aprobar todo dice que no tienes permiso', (t) async {
      repo.programar('aprobarGrupo', [
        const SinPermisoHex('No tienes los permisos necesarios.'),
      ]);
      await montar(t);
      await t.tap(aprobarTodoDe(grupoOctubre));
      await esperar(t, 2);
      await t.tap(botonDelDialogo('Aprobar todo'));
      await esperar(t, 3);
      expect(find.text('No tienes permiso para esta acción.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('doble toque: una confirmación y un solo pedido', (t) async {
      repo.pausa = Completer<void>();
      await montar(t);
      // Dos activaciones antes de redibujar (un toque real lo absorbe el
      // Navigator al abrir el diálogo; el teclado no).
      final alTocar =
          t.widget<FilledButton>(aprobarTodoDe(grupoOctubre)).onPressed!;
      alTocar();
      alTocar();
      await esperar(t, 2);
      expect(find.byType(AlertDialog), findsOneWidget);
      await t.tap(botonDelDialogo('Aprobar todo'));
      await esperar(t, 2);
      expect(find.byType(AlertDialog), findsNothing);
      // En curso: el del grupo espera y los demás quedan deshabilitados.
      final botones = find.descendant(
        of: find.byType(CabeceraGrupoHex),
        matching: find.byType(FilledButton),
      );
      expect(botones, findsNWidgets(2));
      for (final boton in t.widgetList<FilledButton>(botones)) {
        expect(boton.onPressed, isNull);
      }
      expect(find.text('Aprobando…'), findsOneWidget);
      await t.tap(botones.last, warnIfMissed: false);
      await esperar(t, 1);
      expect(find.byType(AlertDialog), findsNothing);
      repo.pausa!.complete();
      await esperar(t, 3);
      expect(repo.vecesDe('aprobarGrupo'), 1);
      await cerrar(t);
    });

    testWidgets('sin btnHexAprobarGrupo no aparece Aprobar todo', (t) async {
      await montar(t, botones: {BotonHex.aprobar, BotonHex.rechazarJefe});
      expect(find.text(grupoOctubre), findsOneWidget);
      expect(find.text('Aprobar todo'), findsNothing);
      expect(find.byTooltip('Aprobar'), findsNWidgets(3));
      await cerrar(t);

      // Con el botón: solo en los grupos que tienen algo que el SP deja aprobar.
      await montar(t, botones: {BotonHex.aprobarGrupo});
      expect(find.text('Aprobar todo'), findsNWidgets(2));
      expect(
        aprobarTodoDe('Rojas Vargas Luis — septiembre de 2026 · 1 reporte'),
        findsNothing,
      );
      expect(find.byTooltip('Aprobar'), findsNothing);
      await cerrar(t);
    });
  });

  group('por fila', () {
    testWidgets('las acciones salen de las banderas del SP y de los botones', (
      t,
    ) async {
      await montar(t);
      // 303 no la deja aprobar el SP.
      expect(find.byTooltip('Ver detalle'), findsNWidgets(4));
      expect(find.byTooltip('Aprobar'), findsNWidgets(3));
      expect(find.byTooltip('Rechazar'), findsNWidgets(4));
      expect(find.byTooltip('Visto bueno'), findsNothing);
      expect(find.byTooltip('Corregir hora'), findsNothing);
      await irAReportados(t);
      // 402 tiene la salida pendiente: sin visto bueno.
      expect(find.byTooltip('Visto bueno'), findsOneWidget);
      expect(find.byTooltip('Corregir hora'), findsNWidgets(2));
      expect(find.byTooltip('Rechazar'), findsNWidgets(2));
      expect(find.byTooltip('Aprobar'), findsNothing);
      await cerrar(t);

      await montar(t, botones: {BotonHex.aprobar});
      expect(find.byTooltip('Aprobar'), findsNWidgets(3));
      expect(find.byTooltip('Rechazar'), findsNothing);
      await irAReportados(t);
      expect(find.byTooltip('Visto bueno'), findsNothing);
      expect(find.byTooltip('Corregir hora'), findsNothing);
      await cerrar(t);
    });

    testWidgets('aprobar una fila resume el reporte y llama a aprobar', (
      t,
    ) async {
      await montar(t);
      final lecturas = repo.vecesDe('bandejaJefe');
      // 302: el biométrico registra otra hora que la del reporte.
      await t.tap(find.byTooltip('Aprobar').at(1));
      await esperar(t, 2);
      expect(enDialogo('Aprobar reporte'), findsOneWidget);
      expect(enDialogo('Condori Huanca María Fernanda'), findsOneWidget);
      expect(find.textContaining('vacaci'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('El biométrico registra otra hora'),
        ),
        findsOneWidget,
      );
      await t.enterText(campoDelDialogo(), '  Conforme.  ');
      await t.tap(botonDelDialogo('Aprobar'));
      await esperar(t, 3);
      expect(repo.argumentosDe('aprobar').single, {
        'idReporte': BigInt.from(302),
        'observacion': 'Conforme.',
      });
      expect(repo.vecesDe('vistoBueno'), 0);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.vecesDe('bandejaJefe'), greaterThan(lecturas));
      await cerrar(t);
    });

    testWidgets('reemplazo: visto bueno desde Reportados llama a vistoBueno', (
      t,
    ) async {
      await montar(t);
      await irAReportados(t);
      expect(ultimoFiltro().estado, 'REPORTADO');
      expect(ultimoFiltro().pagina, 1);
      final lecturas = repo.vecesDe('bandejaJefe');
      await t.tap(find.byTooltip('Visto bueno'));
      await esperar(t, 2);
      expect(enDialogo('Dar visto bueno'), findsOneWidget);
      await t.tap(botonDelDialogo('Dar visto bueno'));
      await esperar(t, 3);
      expect(repo.argumentosDe('vistoBueno').single, {
        'idReporte': BigInt.from(401),
        'observacion': null,
      });
      expect(repo.vecesDe('aprobar'), 0);
      expect(repo.vecesDe('bandejaJefe'), greaterThan(lecturas));
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('aprobación directa (D34): un REPORTADO con puedeAprobar se '
          've y se aprueba a $ancho px', (t) async {
        // Sin encargado en la rama: el SP manda puedeAprobar en un REPORTADO
        // y ningún visto bueno. La app sigue la bandera, no el estado.
        final directo = HexReporteEntity(
          idReporte: BigInt.from(501),
          codEmpleado: BigInt.from(501),
          nombreEmpleado: 'Vargas Ruiz Eva',
          fechaJornada: DateTime(2026, 11, 2),
          tipo: 'DESPUES',
          tipoTexto: 'Después del horario',
          tipoDia: 'HABIL',
          tipoDiaTexto: 'Hábil',
          nombreSucursal: 'Almacén Central',
          inicio: DateTime(2026, 11, 2, 18),
          fin: DateTime(2026, 11, 2, 22),
          origenInicio: 'HORARIO',
          origenFin: 'BIOMETRICO',
          horasPagables: 2,
          montoTotal: 70,
          estado: 'REPORTADO',
          estadoTexto: 'Reportado',
          textoPendiente:
              'Falta la aprobación directa de Paredes Limachi Rosa.',
          puedeAprobar: true,
          puedeEditarHora: true,
          puedeRechazar: true,
        );
        repo.programar('bandejaJefe', [
          (filas: bandejaAprobacion, total: bandejaAprobacion.length),
          (filas: [directo], total: 1),
        ]);
        await montar(t, ancho: ancho);
        await irAReportados(t);
        expect(ultimoFiltro().estado, 'REPORTADO');
        expect(find.text('Vargas Ruiz Eva'), findsOneWidget);
        if (ancho > 1000) {
          expect(find.byTooltip('Aprobar'), findsOneWidget);
          expect(find.byTooltip('Visto bueno'), findsNothing);
          await t.tap(find.byTooltip('Aprobar'));
        } else {
          final tarjeta = find.ancestor(
            of: find.text('Vargas Ruiz Eva'),
            matching: find.byType(Card),
          );
          expect(
            find.descendant(
              of: tarjeta,
              matching: find.text('Dar visto bueno'),
            ),
            findsNothing,
          );
          await desdeElMenu(t, 'Vargas Ruiz Eva', 'Aprobar');
        }
        await esperar(t, 2);
        expect(enDialogo('Aprobar reporte'), findsOneWidget);
        await t.tap(botonDelDialogo('Aprobar'));
        await esperar(t, 3);
        expect(repo.argumentosDe('aprobar').single, {
          'idReporte': BigInt.from(501),
          'observacion': null,
        });
        expect(repo.vecesDe('vistoBueno'), 0);
        await cerrar(t);
      });
    }

    testWidgets('adenda D37: la aprobación directa sin salida marcada muestra '
        'el aviso, confirma el 100 y reenvía con confirmado', (t) async {
      const aviso =
          'VARGAS RUIZ no marcó salida: el reporte termina a las 08:00 del '
          '03/11, su hora de entrada. Verifícalo antes de dar el visto bueno.';
      const pregunta =
          'Este reporte no tiene salida marcada (termina en su entrada del '
          '03/11 08:00). ¿Confirmas la aprobación sin corregir la hora?';
      final directo = HexReporteEntity(
        idReporte: BigInt.from(502),
        codEmpleado: BigInt.from(502),
        nombreEmpleado: 'Vargas Ruiz Eva',
        fechaJornada: DateTime(2026, 11, 2),
        tipo: 'DESPUES',
        tipoTexto: 'Después del horario',
        tipoDia: 'HABIL',
        tipoDiaTexto: 'Hábil',
        nombreSucursal: 'Almacén Central',
        inicio: DateTime(2026, 11, 2, 18),
        fin: DateTime(2026, 11, 3, 8),
        origenInicio: 'HORARIO',
        origenFin: 'HORARIO',
        horasPagables: 12,
        estado: 'REPORTADO',
        estadoTexto: 'Reportado',
        puedeAprobar: true,
        puedeRechazar: true,
        sinSalidaMarcada: true,
        avisoSalida: aviso,
      );
      repo.programar('bandejaJefe', [
        (filas: bandejaAprobacion, total: bandejaAprobacion.length),
        (filas: [directo], total: 1),
      ]);
      repo.programar('aprobar', [
        const ConfirmacionHex(pregunta),
        (id: BigInt.from(502), mensaje: 'Reporte aprobado.'),
      ]);
      final errores = capturarErrores();
      await montar(t);
      await irAReportados(t);
      expect(find.text('Sin salida marcada'), findsOneWidget);
      await t.tap(find.byTooltip('Aprobar'));
      await esperar(t, 2);
      expect(enDialogo(aviso), findsOneWidget);
      await t.tap(botonDelDialogo('Aprobar'));
      await esperar(t, 3);
      expect(find.text(pregunta), findsOneWidget);
      await t.tap(find.text('Confirmar'));
      await esperar(t, 3);
      expect(repo.argumentosDe('aprobar'), [
        {'idReporte': BigInt.from(502), 'observacion': null},
        {
          'idReporte': BigInt.from(502),
          'observacion': null,
          'confirmado': true,
        },
      ]);
      expect(find.byType(AlertDialog), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('reemplazo: corregir hora desde Reportados', (t) async {
      await montar(t);
      await irAReportados(t);
      await t.tap(find.byTooltip('Corregir hora').first);
      await esperar(t, 2);
      expect(enDialogo('Corregir hora'), findsOneWidget);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      expect(find.byType(AlertDialog), findsNothing);
      await cerrar(t);
    });

    testWidgets(
      'rechazar en cualquiera de los dos segmentos usa rechazarJefe',
      (t) async {
        await montar(t);
        await t.tap(find.byTooltip('Rechazar').first);
        await esperar(t, 2);
        await t.enterText(campoDelDialogo(), 'Horas sin respaldo.');
        await t.tap(botonDelDialogo('Rechazar'));
        await esperar(t, 3);
        await irAReportados(t);
        await t.tap(find.byTooltip('Rechazar').first);
        await esperar(t, 2);
        await t.enterText(campoDelDialogo(), 'No corresponde a su turno.');
        await t.tap(botonDelDialogo('Rechazar'));
        await esperar(t, 3);
        expect(repo.argumentosDe('rechazarJefe'), [
          {'idReporte': BigInt.from(301), 'observacion': 'Horas sin respaldo.'},
          {
            'idReporte': BigInt.from(401),
            'observacion': 'No corresponde a su turno.',
          },
        ]);
        expect(repo.vecesDe('rechazarEncargado'), 0);
        await cerrar(t);
      },
    );

    testWidgets('rechazar sin motivo deja el diálogo con el texto del SP', (
      t,
    ) async {
      const regla = 'Escriba la observación: el motivo del rechazo.';
      repo.programar('rechazarJefe', [const NegocioHex(regla)]);
      await montar(t);
      await t.tap(find.byTooltip('Rechazar').first);
      await esperar(t, 2);
      await t.tap(botonDelDialogo('Rechazar'));
      await esperar(t, 2);
      expect(find.text(regla), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await cerrar(t);
    });
  });

  group('lista y filtros', () {
    testWidgets('por defecto pide VISTO_BUENO de a 100 y agrupa', (t) async {
      await montar(t);
      final f =
          repo.argumentosDe('bandejaJefe').first['filtro']!
              as FiltroReportesHex;
      expect(f.estado, 'VISTO_BUENO');
      expect(f.tamano, 100);
      expect(f.pagina, 1);
      expect(
        find.text('Rojas Vargas Luis — octubre de 2026 · 2 reportes'),
        findsOneWidget,
      );
      expect(
        find.text('Rojas Vargas Luis — septiembre de 2026 · 1 reporte'),
        findsOneWidget,
      );
      expect(
        find.text('Torrez Aliaga Ana — octubre de 2026 · 1 reporte'),
        findsOneWidget,
      );
      await irAReportados(t);
      expect(find.byType(CabeceraGrupoHex), findsNothing);
      await cerrar(t);
    });

    testWidgets('el rango de fechas llega al filtro de la bandeja', (t) async {
      await montar(t);
      await t.tap(find.text('Todas las fechas'));
      await esperar(t, 2);
      await t.enterText(find.widgetWithText(TextField, 'Desde'), '01102026');
      await t.enterText(find.widgetWithText(TextField, 'Hasta'), '15102026');
      await t.pump();
      await t.tap(find.text('Aplicar'));
      await esperar(t, 3);
      expect(ultimoFiltro().desde, DateTime(2026, 10, 1));
      expect(ultimoFiltro().hasta, DateTime(2026, 10, 15));
      // El rango sigue al cambiar de segmento.
      await irAReportados(t);
      expect(ultimoFiltro().desde, DateTime(2026, 10, 1));
      expect(ultimoFiltro().estado, 'REPORTADO');
      await cerrar(t);
    });

    testWidgets('ya no hay filtro de compensación y todo se agrupa', (t) async {
      await montar(t);
      expect(find.text('Filtra esta página'), findsNothing);
      expect(find.text('Dinero y vacaciones'), findsNothing);
      expect(find.byTooltip('Ver detalle'), findsNWidgets(4));
      expect(find.byType(CabeceraGrupoHex), findsNWidgets(3));
      expect(find.textContaining('vacaci'), findsNothing);
      await cerrar(t);
    });

    testWidgets('sin reportes ni filtros dice que no hay nada por aprobar', (
      t,
    ) async {
      repo.programar('bandejaJefe', [(filas: <HexReporteEntity>[], total: 0)]);
      await montar(t, ancho: 390);
      expect(find.text('No hay reportes por aprobar'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('si la página queda vacía tras aprobar vuelve a la primera', (
      t,
    ) async {
      repo.programar('bandejaJefe', [
        (filas: bandejaAprobacion, total: 104),
        (filas: [bandejaAprobacion.first], total: 101),
        (filas: <HexReporteEntity>[], total: 0),
        (filas: bandejaAprobacion, total: 100),
      ]);
      await montar(t);
      await t.ensureVisible(find.byIcon(Icons.chevron_right));
      await esperar(t, 1);
      await t.tap(find.byIcon(Icons.chevron_right));
      await esperar(t, 3);
      expect(ultimoFiltro().pagina, 2);
      await t.ensureVisible(find.byTooltip('Aprobar').first);
      await esperar(t, 1);
      await t.tap(find.byTooltip('Aprobar').first);
      await esperar(t, 2);
      await t.tap(botonDelDialogo('Aprobar'));
      await esperar(t, 4);
      expect(ultimoFiltro().pagina, 1);
      expect(find.text('Choque Flores Pedro'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('rediseño de la bandeja (R6 y R7)', () {
    testWidgets(
      'la franja usa el total del SP y cambia de verbo por segmento',
      (t) async {
        repo.programar('bandejaJefe', [(filas: bandejaAprobacion, total: 120)]);
        await montar(t, ancho: 390);
        expect(find.text('120 por aprobar'), findsOneWidget);
        await irAReportados(t);
        expect(find.text('120 por revisar'), findsOneWidget);
        expect(find.text('120 por aprobar'), findsNothing);
        await cerrar(t);
      },
    );

    testWidgets('sin reportes no hay franja', (t) async {
      repo.programar('bandejaJefe', [(filas: <HexReporteEntity>[], total: 0)]);
      await montar(t, ancho: 390);
      expect(find.byType(FranjaPorRevisarHex), findsNothing);
      await cerrar(t);
    });

    testWidgets('en el teléfono «Aprobar» es un botón verde a la vista', (
      t,
    ) async {
      await montar(t, ancho: 390);
      final tarjeta = find.ancestor(
        of: find.text('Mamani Quispe Juan Carlos'),
        matching: find.byType(Card),
      );
      final boton = find.descendant(
        of: tarjeta,
        matching: find.text('Aprobar'),
      );
      expect(boton, findsOneWidget);
      final cs = Theme.of(t.element(find.byType(Scaffold).first)).colorScheme;
      final ficha = t.widget<FilledButton>(
        find
            .ancestor(
              of: boton,
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            )
            .first,
      );
      expect(
        ficha.style!.backgroundColor!.resolve({}),
        HexColores.desde(cs).exitoContenedor,
      );
      expect(t.getSize(find.byWidget(ficha)).height, greaterThanOrEqualTo(48));
      await t.ensureVisible(boton);
      await esperar(t, 1);
      await t.tap(boton);
      await esperar(t, 2);
      expect(enDialogo('Queda listo para la planilla de RRHH'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('en Sin visto bueno aún el botón a la vista es «Dar visto '
        'bueno»', (t) async {
      await montar(t, ancho: 390);
      await irAReportados(t);
      expect(find.text('Dar visto bueno'), findsWidgets);
      expect(find.text('Aprobar'), findsNothing);
      await desdeElMenu(t, 'Mamani Quispe Juan Carlos', 'Visto bueno');
      expect(enDialogo(_textoVistoBueno), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('en la tabla ancha «Aprobar» lleva ícono y texto', (t) async {
      await montar(t);
      expect(find.text('Aprobar'), findsNWidgets(3));
      expect(find.byTooltip('Aprobar'), findsNWidgets(3));
      await cerrar(t);
    });

    testWidgets('la explicación de cada segmento está siempre a la vista', (
      t,
    ) async {
      for (final ancho in [390.0, 1400.0]) {
        await montar(t, ancho: ancho);
        expect(find.byType(ExplicacionBandejaHex), findsOneWidget);
        expect(
          find.textContaining('Con visto bueno: los reportes'),
          findsOneWidget,
        );
        await cerrar(t);
      }
    });
  });

  group('barra de estado y vibración', () {
    testWidgets('el desplazamiento es el primario: tocar la barra de estado '
        'en iOS sube al inicio', (t) async {
      await montar(t, ancho: 390);
      verificarControlPrimarioHex(t, HexAprobacionScreen);
      await cerrar(t);
    });

    testWidgets('elegir un segmento vibra con un toque de selección', (
      t,
    ) async {
      final vibraciones = capturarVibracionesHex();
      await montar(t, ancho: 390);
      await irAReportados(t);
      expect(vibraciones, contains('selectionClick'));
      await cerrar(t);
    });
  });

  group('anchos', () {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      testWidgets('Aprobación a $ancho px sin desbordes', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        // Tabla solo con su ancho mínimo (1040) en la lista, sin el relleno.
        final tabla = ancho - 48 >= 1040;
        expect(find.text('Aprobación de área'), findsOneWidget);
        expect(find.text('Empleado'), tabla ? findsOneWidget : findsNothing);
        expect(find.text('Filtros'), tabla ? findsNothing : findsOneWidget);
        expect(
          find.text('Rojas Vargas Luis — octubre de 2026 · 2 reportes'),
          findsOneWidget,
        );
        if (!tabla) {
          await t.tap(find.text('Filtros'));
          await esperar(t, 2);
          expect(find.text('Todas las fechas'), findsOneWidget);
        }
        await irAReportados(t);
        expect(find.text('Mamani Quispe Juan Carlos'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    // La lista mide el ancho menos 2 × 24 de relleno: 1039 y 1040.
    for (final ancho in [1087.0, 1088.0]) {
      testWidgets('en el borde de la tabla ($ancho px) nunca va de lado', (
        t,
      ) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        final tabla = ancho >= 1088;
        expect(find.text('Empleado'), tabla ? findsOneWidget : findsNothing);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        if (tabla) {
          // Aprobar queda a la vista; lo demás, en el menú de la fila.
          expect(find.byTooltip('Aprobar'), findsNWidgets(3));
          expect(find.byTooltip('Rechazar'), findsNothing);
        }
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    // 964 px: una laptop de 1280 con el menú lateral de 268.
    testWidgets('a 964 px van tarjetas y Aprobar todo se puede tocar', (
      t,
    ) async {
      final errores = capturarErrores();
      await montar(t, ancho: 964);
      expect(find.text('Empleado'), findsNothing);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      expect(find.byWidgetPredicate(esVertical), findsOneWidget);
      await desdeElMenu(t, 'Mamani Quispe Juan Carlos', 'Aprobar');
      expect(enDialogo('Aprobar reporte'), findsOneWidget);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      final boton = find.widgetWithText(FilledButton, 'Aprobar todo').first;
      await t.ensureVisible(boton);
      await esperar(t, 1);
      await t.tap(boton);
      await esperar(t, 2);
      await t.tap(botonDelDialogo('Aprobar todo'));
      await esperar(t, 3);
      expect(repo.vecesDe('aprobarGrupo'), 1);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('a 1400 px las acciones van en línea', (t) async {
      await montar(t);
      expect(find.byTooltip('Aprobar'), findsNWidgets(3));
      expect(find.byTooltip('Rechazar'), findsNWidgets(4));
      expect(find.byIcon(Icons.more_vert), findsNothing);
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('a $ancho px los segmentos dicen qué son y la explicación '
          'está a la vista', (t) async {
        await montar(t, ancho: ancho);
        final segmentos = find.byType(SegmentedButton<String>);
        expect(
          find.descendant(
            of: segmentos,
            matching: find.text('Con visto bueno'),
          ),
          findsOneWidget,
        );
        expect(segmentoReportados(), findsOneWidget);
        expect(find.text('Reportados'), findsNothing);
        expect(
          find.textContaining('los reportes que tus encargados ya revisaron'),
          findsOneWidget,
        );
        await irAReportados(t);
        expect(ultimoFiltro().estado, 'REPORTADO');
        expect(
          find.textContaining('los reportes de tu rama que todavía no'),
          findsOneWidget,
        );
        expect(
          find.textContaining('entre tú y el empleado, los apruebas directo'),
          findsOneWidget,
        );
        expect(find.textContaining('ya revisaron'), findsNothing);
        await cerrar(t);
      });
    }

    testWidgets('a 390 px hay un solo desplazamiento vertical', (t) async {
      await montar(t, ancho: 390);
      expect(find.byWidgetPredicate(esVertical), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Mamani Quispe Juan Carlos'),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      await cerrar(t);
    });

    testWidgets('Aprobación al 150 % en 390 px sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await t.scrollUntilVisible(
        find.text('Quispe Limachi Rosa'),
        150,
        scrollable: pagina(),
      );
      await esperar(t, 2);
      for (final accion in ['Aprobar', 'Rechazar']) {
        await desdeElMenu(t, 'Quispe Limachi Rosa', accion);
        expect(find.byType(AlertDialog), findsOneWidget);
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);
      }
      final boton = find.widgetWithText(FilledButton, 'Aprobar todo').last;
      await t.ensureVisible(boton);
      await esperar(t, 1);
      await t.tap(boton);
      await esperar(t, 2);
      expect(find.byType(AlertDialog), findsOneWidget);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await t.scrollUntilVisible(
        segmentoReportados(),
        -150,
        scrollable: pagina(),
      );
      await irAReportados(t);
      await desdeElMenu(t, 'Mamani Quispe Juan Carlos', 'Visto bueno');
      expect(find.byType(AlertDialog), findsOneWidget);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    for (final escala in [1.0, 1.5]) {
      testWidgets('con el teclado abierto en 390x741 y AppBar al $escala', (
        t,
      ) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montarHex(
          t,
          Scaffold(
            appBar: AppBar(title: const Text('Bosque')),
            body: const HexAprobacionScreen(),
          ),
          ancho: 390,
          overrides: anulaciones(),
        );
        t.view.physicalSize = const Size(390, 741);
        await esperar(t);

        Future<void> teclado(String accion, String boton) async {
          await desdeElMenu(t, 'Mamani Quispe Juan Carlos', accion);
          await t.showKeyboard(campoDelDialogo());
          t.view.viewInsets = const FakeViewPadding(bottom: 336);
          await esperar(t, 3);
          await t.enterText(campoDelDialogo(), 'Revisado con el encargado.');
          await esperar(t, 1);
          expect(errores, isEmpty, reason: detalle(errores));
          expect(botonDelDialogo(boton).hitTestable(), findsOneWidget);
          t.view.resetViewInsets();
          FocusManager.instance.primaryFocus?.unfocus();
          await esperar(t, 2);
          await t.tap(enDialogo('Cancelar'));
          await esperar(t, 2);
        }

        await teclado('Aprobar', 'Aprobar');
        await teclado('Rechazar', 'Rechazar');
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });
}

/// La bandeja del jefe responde por estado, como el SP J. Lo que la prueba
/// programa (una página o un error) manda sobre esto.
class _JefeFalso extends HexReporteFalso {
  final Set<String> _programados = {};

  @override
  void programar(String metodo, List<Object?> respuestas) {
    _programados.add(metodo);
    super.programar(metodo, respuestas);
  }

  @override
  Future<PaginaHex<HexReporteEntity>> bandejaJefe(FiltroReportesHex f) async {
    final programada = await super.bandejaJefe(f);
    if (_programados.contains('bandejaJefe')) return programada;
    final filas = [
      for (final r in [...bandejaAprobacion, ...reportadosDeEncargados])
        if (r.estado == f.estado) r,
    ];
    return (filas: filas, total: filas.length);
  }
}

final BigInt _rojas = BigInt.from(7);
final BigInt _torrez = BigInt.from(8);

HexReporteEntity _reporte({
  required int id,
  required String empleado,
  required DateTime jornada,
  required BigInt encargado,
  required String nombreEncargado,
  required String estado,
  DateTime? fin,
  bool puedeAprobar = false,
  bool puedeVistoBueno = false,
  bool puedeEditarHora = false,
  bool avisoBiometrico = false,
}) {
  return HexReporteEntity(
    idReporte: BigInt.from(id),
    codEmpleado: BigInt.from(id),
    nombreEmpleado: empleado,
    fechaJornada: jornada,
    tipo: 'DESPUES',
    tipoTexto: 'Después del horario',
    tipoDia: 'HABIL',
    tipoDiaTexto: 'Hábil',
    codSucursal: BigInt.one,
    nombreSucursal: 'Planta El Alto',
    inicio: jornada.add(const Duration(hours: 18)),
    fin: fin,
    origenInicio: 'HORARIO',
    origenFin: fin == null ? null : 'BIOMETRICO',
    horasPagables: fin == null ? null : 5,
    montoTotal: fin == null ? null : 130,
    comidas: fin == null ? null : 'C',
    costoHora: 20,
    estado: estado,
    estadoTexto: estado == 'VISTO_BUENO' ? 'Con visto bueno' : 'Reportado',
    avisoBiometrico: avisoBiometrico,
    puedeAprobar: puedeAprobar,
    puedeVistoBueno: puedeVistoBueno,
    puedeEditarHora: puedeEditarHora,
    puedeRechazar: true,
    codEncargado: encargado,
    nombreEncargado: nombreEncargado,
  );
}

/// Con visto bueno, como los ordena el SP (jornada más reciente primero): dos
/// de Rojas en octubre, uno de Torrez en octubre y uno de Rojas en septiembre
/// que el jefe no puede firmar.
final bandejaAprobacion = <HexReporteEntity>[
  _reporte(
    id: 301,
    empleado: 'Mamani Quispe Juan Carlos',
    jornada: DateTime(2026, 10, 23),
    fin: DateTime(2026, 10, 23, 23),
    encargado: _rojas,
    nombreEncargado: 'Rojas Vargas Luis',
    estado: 'VISTO_BUENO',
    puedeAprobar: true,
  ),
  _reporte(
    id: 302,
    empleado: 'Condori Huanca María Fernanda',
    jornada: DateTime(2026, 10, 20),
    fin: DateTime(2026, 10, 20, 21),
    encargado: _rojas,
    nombreEncargado: 'Rojas Vargas Luis',
    estado: 'VISTO_BUENO',
    avisoBiometrico: true,
    puedeAprobar: true,
  ),
  _reporte(
    id: 304,
    empleado: 'Quispe Limachi Rosa',
    jornada: DateTime(2026, 10, 15),
    fin: DateTime(2026, 10, 15, 22),
    encargado: _torrez,
    nombreEncargado: 'Torrez Aliaga Ana',
    estado: 'VISTO_BUENO',
    puedeAprobar: true,
  ),
  _reporte(
    id: 303,
    empleado: 'Choque Flores Pedro',
    jornada: DateTime(2026, 9, 28),
    fin: DateTime(2026, 9, 28, 20),
    encargado: _rojas,
    nombreEncargado: 'Rojas Vargas Luis',
    estado: 'VISTO_BUENO',
  ),
];

/// Reportados que el jefe puede firmar como reemplazo del encargado; el 402
/// tiene la salida pendiente y el SP no deja dar el visto bueno.
final reportadosDeEncargados = <HexReporteEntity>[
  _reporte(
    id: 401,
    empleado: 'Mamani Quispe Juan Carlos',
    jornada: DateTime(2026, 10, 27),
    fin: DateTime(2026, 10, 27, 22),
    encargado: _rojas,
    nombreEncargado: 'Rojas Vargas Luis',
    estado: 'REPORTADO',
    puedeVistoBueno: true,
    puedeEditarHora: true,
  ),
  _reporte(
    id: 402,
    empleado: 'Torrico Mendoza Raúl',
    jornada: DateTime(2026, 10, 26),
    encargado: _torrez,
    nombreEncargado: 'Torrez Aliaga Ana',
    estado: 'REPORTADO',
    puedeEditarHora: true,
  ),
];
