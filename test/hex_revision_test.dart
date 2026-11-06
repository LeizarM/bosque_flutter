import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/hex_asignacion_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_revision_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_dialogos_revision.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// La confirmación de presencia que acompaña al visto bueno, tal cual.
const String _textoVistoBueno =
    'Al dar el visto bueno confirmas que el empleado estuvo trabajando en la '
    'sucursal durante estas horas. Tu firma queda registrada.';

/// «Revisión de encargado»: la bandeja de su sucursal, acciones por banderas
/// del SP y por botón, corrección de hora (con salida pasada la medianoche),
/// visto bueno, rechazo, filtros, anchos y teclado abierto.
void main() {
  setUpAll(cargarFuentesHex);

  late HexReporteFalso repo;
  late HexAsignacionFalso asignacion;

  setUp(() {
    asignacion = HexAsignacionFalso();
    repo = HexReporteFalso();
    repo.programar('bandejaEncargado', [
      (filas: bandejaRevision, total: bandejaRevision.length),
    ]);
  });

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  List<Override> anulaciones() => [
    hexReporteRepositoryProvider.overrideWithValue(repo),
    hexAsignacionRepositoryProvider.overrideWithValue(asignacion),
  ];

  Future<void> montar(
    WidgetTester t, {
    double ancho = 1400,
    Set<String>? botones,
  }) async {
    await montarHex(
      t,
      const HexRevisionScreen(),
      ancho: ancho,
      botones: botones,
      overrides: anulaciones(),
    );
    await esperar(t);
  }

  Finder enDialogo(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

  Finder campoDelDialogo() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );

  FiltroReportesHex ultimoFiltro() =>
      repo.argumentosDe('bandejaEncargado').last['filtro']!
          as FiltroReportesHex;

  /// El desplazamiento de la pantalla (el único vertical en el angosto).
  Finder pagina() =>
      find
          .ancestor(
            of: find.text('Revisión de encargado'),
            matching: find.byType(Scrollable),
          )
          .first;

  bool esVertical(Widget w) =>
      (w is ScrollView && w.scrollDirection == Axis.vertical) ||
      (w is SingleChildScrollView && w.scrollDirection == Axis.vertical);

  bool esLateral(Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.horizontal;

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

  /// Toca el botón a la vista de la tarjeta de [empleado] (teléfono).
  Future<void> desdeElBoton(
    WidgetTester t,
    String empleado,
    String texto,
  ) async {
    final tarjeta = find.ancestor(
      of: find.text(empleado),
      matching: find.byType(Card),
    );
    final boton = find.descendant(of: tarjeta, matching: find.text(texto));
    await t.ensureVisible(boton);
    await esperar(t, 1);
    await t.tap(boton);
    await esperar(t, 2);
  }

  /// Escribe [hora]:[minuto] en el reloj del [extremo] («inicio» o «fin»).
  Future<void> elegirHoraHex(
    WidgetTester t,
    String extremo, {
    required String hora,
    required String minuto,
  }) async {
    await t.tap(find.byTooltip('Hora del $extremo'));
    await esperar(t, 2);
    await t.tap(find.byIcon(Icons.keyboard_outlined));
    await esperar(t, 1);
    final campos = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await t.enterText(campos.at(0), hora);
    await t.enterText(campos.at(1), minuto);
    await t.tap(find.text('Aceptar'));
    await esperar(t, 2);
  }

  /// Elige [dia] en el calendario y [hora]:[minuto] en el reloj del fin.
  Future<void> elegirFinHex(
    WidgetTester t, {
    required String dia,
    required String hora,
    required String minuto,
  }) async {
    await t.tap(find.byTooltip('Día del fin'));
    await esperar(t, 2);
    await t.tap(find.text(dia));
    await t.tap(find.text('Aceptar'));
    await esperar(t, 2);
    await elegirHoraHex(t, 'fin', hora: hora, minuto: minuto);
  }

  group('roles', () {
    testWidgets('sin rol de aprobador muestra el aviso y no la lista', (
      t,
    ) async {
      repo.programar('misRoles', [const HexRolesEntity()]);
      await montar(t);
      expect(find.text('No tienes el rol de encargado'), findsOneWidget);
      expect(
        find.text(
          'Pide a RRHH que te lo asigne en «Horas extra: aprobadores»: '
          'cubre toda tu rama del organigrama.',
        ),
        findsOneWidget,
      );
      expect(repo.vecesDe('bandejaEncargado'), 0);
      expect(find.text('Empleado'), findsNothing);
      expect(find.text('Leyenda de códigos'), findsNothing);
      await cerrar(t);
    });

    testWidgets('el jefe sin rol de encargado va a Aprobación de área', (
      t,
    ) async {
      repo
        ..programar('misRoles', [const HexRolesEntity(esJefe: true)])
        ..programar('bandejaEncargado', [
          (filas: <HexReporteEntity>[], total: 0),
        ]);
      await montar(t, ancho: 390);
      expect(repo.vecesDe('bandejaEncargado'), 1);
      expect(find.text('No tienes el rol de encargado'), findsOneWidget);
      expect(find.textContaining('«Aprobación de área»'), findsOneWidget);
      expect(find.textContaining('apruebas directo'), findsOneWidget);
      expect(find.text('No hay reportes por revisar'), findsNothing);
      await cerrar(t);
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
      expect(repo.vecesDe('bandejaEncargado'), 0);
      await cerrar(t);

      repo = HexReporteFalso()..programar('bandejaEncargado', [sinPermiso]);
      await montar(t, ancho: 390);
      expect(find.text('No tienes permiso'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('acciones', () {
    testWidgets('las acciones salen de las banderas del SP y de los botones', (
      t,
    ) async {
      await montar(t);
      // 202 tiene la salida pendiente: el SP no permite el visto bueno.
      expect(find.byTooltip('Ver detalle'), findsNWidgets(3));
      expect(find.byTooltip('Corregir hora'), findsNWidgets(3));
      expect(find.byTooltip('Visto bueno'), findsNWidgets(2));
      expect(find.byTooltip('Rechazar'), findsNWidgets(3));
      await cerrar(t);

      await montar(t, botones: {BotonHex.vistoBueno, BotonHex.rechazar});
      expect(find.byTooltip('Corregir hora'), findsNothing);
      expect(find.byTooltip('Visto bueno'), findsNWidgets(2));
      expect(find.byTooltip('Rechazar'), findsNWidgets(3));
      expect(find.byTooltip('Ver detalle'), findsNWidgets(3));
      await cerrar(t);
    });

    testWidgets('en el teléfono el menú de la tarjeta respeta las banderas', (
      t,
    ) async {
      await montar(t, ancho: 390);
      await t.scrollUntilVisible(
        find.text('Condori Huanca María Fernanda'),
        150,
        scrollable: pagina(),
      );
      final tarjeta = find.ancestor(
        of: find.text('Condori Huanca María Fernanda'),
        matching: find.byType(Card),
      );
      await t.tap(
        find.descendant(of: tarjeta, matching: find.byIcon(Icons.more_vert)),
      );
      await esperar(t, 2);
      expect(find.text('Corregir hora'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      expect(find.text('Visto bueno'), findsNothing);
      await t.tapAt(const Offset(5, 5));
      await esperar(t, 2);
      await cerrar(t);
    });

    testWidgets(
      'corregir el fin después de medianoche manda el día siguiente',
      (t) async {
        const motivo = 'El biométrico tomó la marca del turno anterior.';
        await montar(t);
        final lecturas = repo.vecesDe('bandejaEncargado');
        await t.tap(find.byTooltip('Corregir hora').first);
        await esperar(t, 2);
        expect(enDialogo('Corregir hora'), findsOneWidget);
        await elegirFinHex(t, dia: '24', hora: '01', minuto: '30');
        expect(enDialogo('Día siguiente a la jornada'), findsOneWidget);
        expect(enDialogo('24/10/2026'), findsOneWidget);
        expect(enDialogo('01:30'), findsOneWidget);
        await t.enterText(campoDelDialogo(), motivo);
        await t.tap(enDialogo('Corregir'));
        await esperar(t, 3);
        expect(repo.argumentosDe('corregirHora').single, {
          'idReporte': BigInt.from(201),
          'inicio': null,
          'fin': DateTime(2026, 10, 24, 1, 30),
          'observacion': motivo,
        });
        expect(find.byType(AlertDialog), findsNothing);
        expect(repo.vecesDe('bandejaEncargado'), greaterThan(lecturas));
        await cerrar(t);
      },
    );

    testWidgets('corregir solo el inicio manda el fin nulo', (t) async {
      const motivo = 'Llegó antes por la descarga.';
      await montar(t);
      await t.tap(find.byTooltip('Corregir hora').first);
      await esperar(t, 2);
      await elegirHoraHex(t, 'inicio', hora: '19', minuto: '15');
      expect(enDialogo('Inicio · corregido'), findsOneWidget);
      expect(enDialogo('Fin'), findsOneWidget);
      await t.enterText(campoDelDialogo(), motivo);
      await t.tap(enDialogo('Corregir'));
      await esperar(t, 3);
      expect(repo.argumentosDe('corregirHora').single, {
        'idReporte': BigInt.from(201),
        'inicio': DateTime(2026, 10, 23, 19, 15),
        'fin': null,
        'observacion': motivo,
      });
      await cerrar(t);
    });

    testWidgets('deshacer quita la corrección y sin cambios viaja vacío', (
      t,
    ) async {
      repo.programar('corregirHora', [
        const NegocioHex('Indique la hora de inicio o la de fin que corrige.'),
      ]);
      await montar(t);
      await t.tap(find.byTooltip('Corregir hora').first);
      await esperar(t, 2);
      await elegirHoraHex(t, 'inicio', hora: '19', minuto: '15');
      expect(enDialogo('19:15'), findsOneWidget);
      expect(enDialogo('Deshacer'), findsOneWidget);
      await t.tap(enDialogo('Deshacer'));
      await esperar(t, 1);
      expect(enDialogo('18:00'), findsOneWidget);
      expect(enDialogo('Deshacer'), findsNothing);
      // Sin nada corregido viaja vacío y el SP responde con su mensaje.
      await t.tap(enDialogo('Corregir'));
      await esperar(t, 2);
      expect(repo.argumentosDe('corregirHora').single, {
        'idReporte': BigInt.from(201),
        'inicio': null,
        'fin': null,
        'observacion': '',
      });
      expect(
        find.text('Indique la hora de inicio o la de fin que corrige.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('visto bueno con 409 recarga la bandeja', (t) async {
      const cambio =
          'El reporte ya está con visto bueno: la hora se corrige y el visto '
          'bueno se da solo mientras está reportado.';
      repo.programar('vistoBueno', [const ConflictoHex(cambio)]);
      await montar(t);
      final lecturas = repo.vecesDe('bandejaEncargado');
      await t.tap(find.byTooltip('Visto bueno').first);
      await esperar(t, 2);
      await t.tap(enDialogo('Dar visto bueno'));
      await esperar(t, 3);
      expect(repo.argumentosDe('vistoBueno').single, {
        'idReporte': BigInt.from(201),
        'observacion': null,
      });
      expect(find.text(cambio), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.vecesDe('bandejaEncargado'), greaterThan(lecturas));
      await cerrar(t);
    });

    testWidgets('el visto bueno resume inicio y fin con su origen', (t) async {
      await montar(t);
      await t.tap(find.byTooltip('Visto bueno').first);
      await esperar(t, 2);
      expect(enDialogo('Inicio'), findsOneWidget);
      expect(enDialogo('Del horario'), findsOneWidget);
      expect(enDialogo('Fin'), findsOneWidget);
      expect(enDialogo('Biométrico'), findsOneWidget);
      await t.enterText(campoDelDialogo(), '  Revisado con el supervisor.  ');
      await t.tap(enDialogo('Dar visto bueno'));
      await esperar(t, 3);
      expect(repo.argumentosDe('vistoBueno').single, {
        'idReporte': BigInt.from(201),
        'observacion': 'Revisado con el supervisor.',
      });
      await cerrar(t);
    });

    testWidgets('rechazar sin motivo muestra el mensaje del SP', (t) async {
      const regla = 'Escriba la observación: el motivo del rechazo.';
      repo.programar('rechazarEncargado', [const NegocioHex(regla)]);
      await montar(t);
      await t.tap(find.byTooltip('Rechazar').first);
      await esperar(t, 2);
      expect(find.text('Rechazar reporte'), findsOneWidget);
      await t.tap(enDialogo('Rechazar'));
      await esperar(t, 2);
      expect(find.text(regla), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repo.argumentosDe('rechazarEncargado').single, {
        'idReporte': BigInt.from(201),
        'observacion': '',
      });
      expect(repo.vecesDe('rechazarJefe'), 0);
      await cerrar(t);
    });

    testWidgets('como jefe, rechazar usa el endpoint del jefe', (t) async {
      var recargas = 0;
      await montarHex(
        t,
        Consumer(
          builder:
              (context, ref, _) => Center(
                child: FilledButton(
                  onPressed:
                      () => rechazarHex(
                        context,
                        ref,
                        bandejaRevision.first,
                        comoJefe: true,
                        refrescar: () => recargas++,
                      ),
                  child: const Text('Abrir'),
                ),
              ),
        ),
        overrides: anulaciones(),
      );
      await t.tap(find.text('Abrir'));
      await esperar(t, 2);
      await t.enterText(campoDelDialogo(), 'No corresponde a su turno.');
      await t.tap(enDialogo('Rechazar'));
      await esperar(t, 3);
      expect(repo.argumentosDe('rechazarJefe').single, {
        'idReporte': BigInt.from(201),
        'observacion': 'No corresponde a su turno.',
      });
      expect(repo.vecesDe('rechazarEncargado'), 0);
      expect(recargas, 1);
      await cerrar(t);
    });

    testWidgets('con la escritura en curso el diálogo no se cierra con atrás', (
      t,
    ) async {
      repo.pausa = Completer<void>();
      await montar(t);
      await t.tap(find.byTooltip('Visto bueno').first);
      await esperar(t, 2);
      await t.tap(enDialogo('Dar visto bueno'));
      await esperar(t, 1);
      await t.tap(enDialogo('Dar visto bueno'), warnIfMissed: false);
      await Navigator.of(t.element(find.byType(AlertDialog))).maybePop();
      await esperar(t, 1);
      expect(find.byType(AlertDialog), findsOneWidget);
      repo.pausa!.complete();
      await esperar(t, 3);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.vecesDe('vistoBueno'), 1);
      await cerrar(t);
    });

    testWidgets(
      'si la página queda vacía tras una acción vuelve a la primera',
      (t) async {
        repo.programar('bandejaEncargado', [
          (filas: bandejaRevision, total: 23),
          (filas: [bandejaRevision.first], total: 21),
          (filas: <HexReporteEntity>[], total: 0),
          (filas: bandejaRevision, total: 20),
        ]);
        await montar(t);
        await t.ensureVisible(find.byIcon(Icons.chevron_right));
        await esperar(t, 1);
        await t.tap(find.byIcon(Icons.chevron_right));
        await esperar(t, 3);
        expect(ultimoFiltro().pagina, 2);
        await t.ensureVisible(find.byTooltip('Visto bueno').first);
        await esperar(t, 1);
        await t.tap(find.byTooltip('Visto bueno').first);
        await esperar(t, 2);
        await t.tap(enDialogo('Dar visto bueno'));
        await esperar(t, 4);
        expect(ultimoFiltro().pagina, 1);
        expect(find.text('Mamani Quispe Juan Carlos'), findsOneWidget);
        await cerrar(t);
      },
    );
  });

  group('lista y filtros', () {
    testWidgets('el estado por defecto es REPORTADO y cambia al filtrar', (
      t,
    ) async {
      repo.programar('bandejaEncargado', [
        (filas: bandejaRevision, total: bandejaRevision.length),
        (filas: [vistoBuenoConAviso], total: 1),
      ]);
      await montar(t);
      final primero =
          repo.argumentosDe('bandejaEncargado').first['filtro']!
              as FiltroReportesHex;
      expect(primero.estado, 'REPORTADO');
      expect(primero.pagina, 1);
      await t.tap(find.text('Reportados'));
      await esperar(t, 2);
      await t.tap(find.text('Con visto bueno').last);
      await esperar(t, 3);
      expect(ultimoFiltro().estado, 'VISTO_BUENO');
      expect(ultimoFiltro().pagina, 1);
      // El aviso del biométrico llega fuera de REPORTADO.
      expect(find.text('Aviso de biométrico'), findsOneWidget);
      expect(find.byTooltip('Visto bueno'), findsNothing);
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
      final f = ultimoFiltro();
      expect(f.desde, DateTime(2026, 10, 1));
      expect(f.hasta, DateTime(2026, 10, 15));
      expect(f.pagina, 1);
      expect(find.text('01/10/2026 – 15/10/2026'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('ya no hay filtro de compensación', (t) async {
      await montar(t);
      expect(find.text('Filtra esta página'), findsNothing);
      expect(find.text('Dinero y vacaciones'), findsNothing);
      expect(find.textContaining('vacaci'), findsNothing);
      await cerrar(t);
    });

    testWidgets('la tabla muestra la sucursal y el origen de cada hora', (
      t,
    ) async {
      await montar(t);
      expect(find.text('Planta El Alto'), findsNWidgets(2));
      expect(find.text('Depósito Central'), findsOneWidget);
      expect(find.text('Biométrico'), findsOneWidget);
      expect(find.text('App · con ubicación'), findsOneWidget);
      expect(find.text('Pendiente de biométrico'), findsOneWidget);
      // El mismo orden que la tarjeta: tipo y luego tipo de día.
      expect(find.text('Después del horario · Hábil'), findsOneWidget);
      await t.ensureVisible(find.text('Leyenda de códigos'));
      await esperar(t, 2);
      expect(find.text('H50'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin reportes ni filtros dice que no hay nada por revisar', (
      t,
    ) async {
      repo.programar('bandejaEncargado', [
        (filas: <HexReporteEntity>[], total: 0),
      ]);
      await montar(t, ancho: 390);
      expect(find.text('No hay reportes por revisar'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('rediseño de la bandeja (R6 y R7)', () {
    /// El botón a la vista de la tarjeta de [empleado]: el texto y su ficha.
    Finder botonDe(String empleado, String texto) => find.descendant(
      of: find.ancestor(of: find.text(empleado), matching: find.byType(Card)),
      matching: find.text(texto),
    );

    Future<void> verTarjeta(WidgetTester t, String empleado) async {
      await t.scrollUntilVisible(
        find.text(empleado),
        150,
        scrollable: pagina(),
      );
      await esperar(t, 2);
    }

    testWidgets('la franja «N por revisar» usa el total que manda el SP', (
      t,
    ) async {
      // El SP cuenta 47 aunque la página traiga 3 filas.
      repo.programar('bandejaEncargado', [(filas: bandejaRevision, total: 47)]);
      await montar(t, ancho: 390);
      expect(find.text('47 por revisar'), findsOneWidget);
      expect(find.byIcon(Icons.pending_actions_outlined), findsOneWidget);
      await cerrar(t);

      await montar(t);
      expect(find.text('47 por revisar'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin reportes por revisar no hay franja', (t) async {
      repo.programar('bandejaEncargado', [
        (filas: <HexReporteEntity>[], total: 0),
      ]);
      await montar(t, ancho: 390);
      expect(find.byType(FranjaPorRevisarHex), findsNothing);
      expect(find.text('No hay reportes por revisar'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('la franja solo cuenta lo que espera revisión', (t) async {
      await montar(t);
      expect(find.text('3 por revisar'), findsOneWidget);
      await t.tap(find.text('Reportados'));
      await esperar(t, 2);
      await t.tap(find.text('Aprobados').last);
      await esperar(t, 3);
      expect(ultimoFiltro().estado, 'APROBADO');
      expect(find.byType(FranjaPorRevisarHex), findsNothing);
      await cerrar(t);
    });

    testWidgets('en el teléfono «Dar visto bueno» es un botón de 48 px a la '
        'vista, no está en el menú', (t) async {
      await montar(t, ancho: 390);
      await verTarjeta(t, 'Mamani Quispe Juan Carlos');
      final boton = botonDe('Mamani Quispe Juan Carlos', 'Dar visto bueno');
      expect(boton, findsOneWidget);
      final ficha = find.ancestor(
        of: boton,
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      );
      expect(t.getSize(ficha.first).height, greaterThanOrEqualTo(48));
      // La fila 202 tiene la salida pendiente: no puede recibir el visto bueno.
      expect(
        botonDe('Condori Huanca María Fernanda', 'Dar visto bueno'),
        findsNothing,
      );
      // El menú de la tarjeta conserva el resto de las acciones.
      final tarjeta = find.ancestor(
        of: find.text('Mamani Quispe Juan Carlos'),
        matching: find.byType(Card),
      );
      await t.tap(
        find.descendant(of: tarjeta, matching: find.byIcon(Icons.more_vert)),
      );
      await esperar(t, 2);
      expect(find.text('Corregir hora'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      expect(find.text('Visto bueno'), findsNothing);
      await t.tapAt(const Offset(5, 5));
      await esperar(t, 2);
      await cerrar(t);
    });

    testWidgets('el botón a la vista abre el diálogo con el efecto de firmar', (
      t,
    ) async {
      await montar(t, ancho: 390);
      await desdeElBoton(t, 'Mamani Quispe Juan Carlos', 'Dar visto bueno');
      expect(enDialogo(_textoVistoBueno), findsOneWidget);
      expect(
        enDialogo('Pasa a tu jefe de área; tu firma queda registrada'),
        findsNothing,
      );
      await t.tap(enDialogo('Dar visto bueno'));
      await esperar(t, 3);
      expect(repo.vecesDe('vistoBueno'), 1);
      await cerrar(t);
    });

    testWidgets('sin btnHexVistoBueno no hay botón a la vista ni hueco', (
      t,
    ) async {
      await montar(t, ancho: 390, botones: {BotonHex.rechazar});
      expect(find.text('Dar visto bueno'), findsNothing);
      await cerrar(t);
    });

    testWidgets('el botón a la vista lleva el color del visto bueno', (
      t,
    ) async {
      await montar(t, ancho: 390);
      await verTarjeta(t, 'Mamani Quispe Juan Carlos');
      final cs = Theme.of(t.element(find.byType(Scaffold).first)).colorScheme;
      final boton = t.widget<FilledButton>(
        find
            .ancestor(
              of: botonDe('Mamani Quispe Juan Carlos', 'Dar visto bueno'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            )
            .first,
      );
      expect(boton.style!.backgroundColor!.resolve({}), cs.tertiaryContainer);
      await cerrar(t);
    });

    testWidgets('en la tabla ancha la acción principal dice su texto y en la '
        'compacta solo el ícono', (t) async {
      await montar(t);
      expect(find.text('Dar visto bueno'), findsNWidgets(2));
      expect(find.byTooltip('Visto bueno'), findsNWidgets(2));
      await cerrar(t);

      await montar(t, ancho: 1098);
      expect(find.text('Dar visto bueno'), findsNothing);
      expect(find.byTooltip('Visto bueno'), findsNWidgets(2));
      await cerrar(t);
    });

    testWidgets('rechazar dice el efecto, marca el motivo como obligatorio y '
        'enfoca el campo', (t) async {
      await montar(t, ancho: 390);
      await desdeElMenu(t, 'Mamani Quispe Juan Carlos', 'Rechazar');
      expect(enDialogo('El empleado verá tu motivo'), findsOneWidget);
      expect(enDialogo('Obligatorio.'), findsOneWidget);
      final campo = t.widget<TextField>(campoDelDialogo());
      expect(campo.autofocus, isTrue);
      await cerrar(t);
    });

    testWidgets('corregir la hora dice el efecto y marca la observación como '
        'obligatoria', (t) async {
      await montar(t);
      await t.tap(find.byTooltip('Corregir hora').first);
      await esperar(t, 2);
      expect(
        enDialogo(
          'La hora corregida reemplaza la del biométrico o la de la app',
        ),
        findsOneWidget,
      );
      expect(enDialogo('Obligatorio.'), findsOneWidget);
      expect(t.widget<TextField>(campoDelDialogo()).autofocus, isFalse);
      await cerrar(t);
    });

    testWidgets('el visto bueno deja la observación como opcional', (t) async {
      await montar(t);
      await t.tap(find.byTooltip('Visto bueno').first);
      await esperar(t, 2);
      expect(enDialogo('Opcional.'), findsOneWidget);
      expect(enDialogo('Obligatorio.'), findsNothing);
      await cerrar(t);
    });

    testWidgets('el diálogo cierra el teclado al arrastrar su contenido', (
      t,
    ) async {
      await montar(t, ancho: 390);
      await desdeElMenu(t, 'Mamani Quispe Juan Carlos', 'Rechazar');
      final desplazable = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SingleChildScrollView),
      );
      expect(desplazable, findsOneWidget);
      final comportamiento = ScrollConfiguration.of(t.element(desplazable));
      expect(
        comportamiento.getKeyboardDismissBehavior(t.element(desplazable)),
        ScrollViewKeyboardDismissBehavior.onDrag,
      );
      await cerrar(t);
    });

    testWidgets('abrir el reloj quita el foco del campo de la observación', (
      t,
    ) async {
      await montar(t);
      await t.tap(find.byTooltip('Corregir hora').first);
      await esperar(t, 2);
      final editable = find.descendant(
        of: campoDelDialogo(),
        matching: find.byType(EditableText),
      );
      await t.showKeyboard(campoDelDialogo());
      await esperar(t, 1);
      expect(t.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
      await t.tap(find.byTooltip('Hora del fin'));
      await esperar(t, 2);
      expect(t.widget<EditableText>(editable).focusNode.hasFocus, isFalse);
      await cerrar(t);
    });
  });

  group('barra de estado y vibración', () {
    testWidgets('el desplazamiento es el primario: tocar la barra de estado '
        'en iOS sube al inicio', (t) async {
      await montar(t, ancho: 390);
      verificarControlPrimarioHex(t, HexRevisionScreen);
      await cerrar(t);
    });
  });

  group('anchos', () {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      testWidgets('Revisión a $ancho px sin desbordes', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        // Tabla solo con su ancho mínimo (1040) en la lista, sin el relleno.
        final tabla = ancho - 48 >= 1040;
        expect(find.text('Revisión de encargado'), findsOneWidget);
        expect(find.text('Empleado'), tabla ? findsOneWidget : findsNothing);
        expect(find.text('Filtros'), tabla ? findsNothing : findsOneWidget);
        if (!tabla) {
          await t.tap(find.text('Filtros'));
          await esperar(t, 2);
          expect(find.text('Reportados'), findsOneWidget);
        }
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('a 1098 px (1366 con el menú lateral) la tabla no va de lado', (
      t,
    ) async {
      final errores = capturarErrores();
      await montar(t, ancho: 1098);
      expect(find.text('Acciones'), findsOneWidget);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      // Visto bueno queda a la vista; lo demás, en el menú de la fila.
      expect(find.byTooltip('Visto bueno'), findsNWidgets(2));
      expect(find.byTooltip('Corregir hora'), findsNothing);
      await t.tap(find.byIcon(Icons.more_vert).first);
      await esperar(t, 2);
      expect(find.text('Corregir hora'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      expect(find.text('Ver detalle'), findsOneWidget);
      await t.tapAt(const Offset(5, 5));
      await esperar(t, 2);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    // La lista mide el ancho menos 2 × 24: tabla desde 1040 (1088 px) y las
    // acciones en línea desde 1248 (1296 px), los anchos del kit.
    for (final ancho in [1087.0, 1088.0, 1295.0, 1296.0]) {
      testWidgets('en el borde ($ancho px) nunca va de lado', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        final tabla = ancho >= 1088;
        final enLinea = ancho >= 1296;
        expect(find.text('Acciones'), tabla ? findsOneWidget : findsNothing);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        if (tabla) {
          expect(find.byTooltip('Visto bueno'), findsNWidgets(2));
          expect(
            find.byTooltip('Corregir hora'),
            enLinea ? findsNWidgets(3) : findsNothing,
          );
        }
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    // 964 px: una laptop de 1280 con el menú lateral de 268.
    for (final ancho in [800.0, 964.0]) {
      testWidgets('a $ancho px van tarjetas y Visto bueno se puede tocar', (
        t,
      ) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        expect(find.text('Empleado'), findsNothing);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(find.byWidgetPredicate(esVertical), findsOneWidget);
        // La tarea del día está a la vista en la tarjeta, no en el menú.
        await desdeElBoton(t, 'Mamani Quispe Juan Carlos', 'Dar visto bueno');
        expect(enDialogo('Dar visto bueno'), findsOneWidget);
        await t.tap(enDialogo('Dar visto bueno'));
        await esperar(t, 3);
        expect(repo.vecesDe('vistoBueno'), 1);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    for (final ancho in [390.0, 744.0]) {
      testWidgets('a $ancho px hay un solo desplazamiento vertical', (t) async {
        await montar(t, ancho: ancho);
        expect(find.text('Empleado'), findsNothing);
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
    }

    testWidgets('Revisión al 150 % en 390 px sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await t.scrollUntilVisible(
        find.text('Choque Flores Pedro'),
        150,
        scrollable: pagina(),
      );
      await esperar(t, 2);
      // Corregir y rechazar salen del menú; el visto bueno, del botón a la
      // vista de la tarjeta (también con la letra al 150 %).
      for (final accion in ['Corregir hora', 'Dar visto bueno', 'Rechazar']) {
        if (accion == 'Dar visto bueno') {
          await desdeElBoton(t, 'Choque Flores Pedro', accion);
        } else {
          await desdeElMenu(t, 'Choque Flores Pedro', accion);
        }
        expect(find.byType(AlertDialog), findsOneWidget);
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);
      }
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
            body: const HexRevisionScreen(),
          ),
          ancho: 390,
          overrides: anulaciones(),
        );
        t.view.physicalSize = const Size(390, 741);
        await esperar(t);

        Future<void> teclado(Finder campo) async {
          await t.showKeyboard(campo);
          t.view.viewInsets = const FakeViewPadding(bottom: 336);
          await esperar(t, 3);
          expect(errores, isEmpty, reason: detalle(errores));
          t.view.resetViewInsets();
          FocusManager.instance.primaryFocus?.unfocus();
          await esperar(t, 2);
        }

        // La observación del rechazo.
        await desdeElMenu(t, 'Mamani Quispe Juan Carlos', 'Rechazar');
        await teclado(campoDelDialogo());
        expect(enDialogo('Rechazar').hitTestable(), findsOneWidget);
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);

        // La observación y la hora corregida.
        await desdeElMenu(t, 'Mamani Quispe Juan Carlos', 'Corregir hora');
        await teclado(campoDelDialogo());
        await t.ensureVisible(find.byTooltip('Hora del fin'));
        await esperar(t, 1);
        await t.tap(find.byTooltip('Hora del fin'));
        await esperar(t, 2);
        await t.tap(find.byIcon(Icons.keyboard_outlined));
        await esperar(t, 1);
        // El selector de Flutter va en 24 h y con la letra acotada a 1,4: a
        // 1,5 y con el teclado, su modo de texto desborda 16 px.
        final reloj = MediaQuery.of(t.element(find.byType(TimePickerDialog)));
        expect(reloj.alwaysUse24HourFormat, isTrue);
        expect(
          reloj.textScaler.scale(10),
          closeTo(escala > 1.4 ? 14 : 10, 1e-6),
        );
        await teclado(
          find
              .descendant(
                of: find.byType(TimePickerDialog),
                matching: find.byType(TextField),
              )
              .first,
        );
        await t.tap(find.text('Cancelar').last);
        await esperar(t, 2);
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });
}

/// Con visto bueno y aviso del biométrico: el aviso solo existe fuera de
/// REPORTADO (el SP lo calcula al dar el visto bueno).
final vistoBuenoConAviso = HexReporteEntity(
  idReporte: BigInt.from(204),
  codEmpleado: BigInt.from(23),
  nombreEmpleado: 'Quispe Limachi Rosa',
  fechaJornada: DateTime(2026, 10, 20),
  tipo: 'DESPUES',
  tipoTexto: 'Después del horario',
  tipoDia: 'HABIL',
  tipoDiaTexto: 'Hábil',
  codSucursal: BigInt.one,
  nombreSucursal: 'Planta El Alto',
  inicio: DateTime(2026, 10, 20, 18),
  fin: DateTime(2026, 10, 20, 21),
  origenInicio: 'HORARIO',
  origenFin: 'APP',
  horasPagables: 3,
  montoTotal: 60,
  costoHora: 20,
  estado: 'VISTO_BUENO',
  estadoTexto: 'Con visto bueno',
  avisoBiometrico: true,
  totalFilas: 1,
);

/// La bandeja del encargado (todo REPORTADO): un cruce de medianoche, una
/// salida pendiente (sin visto bueno) de otra sucursal y un inicio ya editado.
final bandejaRevision = <HexReporteEntity>[
  HexReporteEntity(
    idReporte: BigInt.from(201),
    codEmpleado: BigInt.from(20),
    nombreEmpleado: 'Mamani Quispe Juan Carlos',
    fechaJornada: DateTime(2026, 10, 23),
    tipo: 'DESPUES',
    tipoTexto: 'Después del horario',
    tipoDia: 'HABIL',
    tipoDiaTexto: 'Hábil',
    codSucursal: BigInt.one,
    nombreSucursal: 'Planta El Alto',
    inicio: DateTime(2026, 10, 23, 18),
    fin: DateTime(2026, 10, 23, 23),
    origenInicio: 'HORARIO',
    origenFin: 'BIOMETRICO',
    motivo: 'Descarga de bobinas del contenedor 14.',
    horasPagables: 5,
    montoHoras: 115,
    montoComidas: 15,
    montoTotal: 130,
    comidas: 'C',
    costoHora: 20,
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    puedeEditarHora: true,
    puedeVistoBueno: true,
    puedeRechazar: true,
    totalFilas: 3,
  ),
  HexReporteEntity(
    idReporte: BigInt.from(202),
    codEmpleado: BigInt.from(21),
    nombreEmpleado: 'Condori Huanca María Fernanda',
    fechaJornada: DateTime(2026, 10, 25),
    tipo: 'SIN_HORARIO',
    tipoTexto: 'Sin horario',
    tipoDia: 'DOMINGO',
    tipoDiaTexto: 'Domingo',
    codSucursal: BigInt.two,
    nombreSucursal: 'Depósito Central',
    inicio: DateTime(2026, 10, 25, 8),
    origenInicio: 'APP',
    costoHora: 20,
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    puedeEditarHora: true,
    puedeRechazar: true,
    totalFilas: 3,
  ),
  HexReporteEntity(
    idReporte: BigInt.from(203),
    codEmpleado: BigInt.from(22),
    nombreEmpleado: 'Choque Flores Pedro',
    fechaJornada: DateTime(2026, 10, 12),
    tipo: 'ANTES',
    tipoTexto: 'Antes del horario',
    tipoDia: 'FERIADO',
    tipoDiaTexto: 'Feriado',
    codSucursal: BigInt.one,
    nombreSucursal: 'Planta El Alto',
    inicio: DateTime(2026, 10, 12, 5, 30),
    fin: DateTime(2026, 10, 12, 8),
    origenInicio: 'EDITADO',
    origenFin: 'HORARIO',
    horasPagables: 2.5,
    montoHoras: 100,
    montoComidas: 10,
    montoTotal: 110,
    comidas: 'D',
    costoHora: 20,
    esProvisional: true,
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    esEditado: true,
    puedeEditarHora: true,
    puedeVistoBueno: true,
    puedeRechazar: true,
    totalFilas: 3,
  ),
];
