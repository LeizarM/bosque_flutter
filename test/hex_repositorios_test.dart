import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/repositories/hex_asignacion_impl.dart';
import 'package:bosque_flutter/data/repositories/hex_configuracion_impl.dart';
import 'package:bosque_flutter/data/repositories/hex_planilla_impl.dart';
import 'package:bosque_flutter/data/repositories/hex_reporte_impl.dart';
import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_jornada_pasada_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';

/// Cada método de los tres repositorios del módulo contra el cable: la ruta del
/// contrato, el cuerpo exacto (solo ids y datos, nunca identidad) y la lectura.
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late _Cable cable;
  late HexReporteImpl reportes;
  late HexPlanillaImpl planillas;
  late HexConfiguracionImpl configuracion;
  late HexAsignacionImpl asignaciones;

  setUp(() {
    cable = _Cable();
    reportes = HexReporteImpl();
    planillas = HexPlanillaImpl();
    configuracion = HexConfiguracionImpl();
    asignaciones = HexAsignacionImpl();
    // El cliente es un singleton: sin interceptores (leen el token) y con el
    // adaptador falso. Solo vale para esta prueba.
    reportes.dio.interceptors.clear();
    reportes.dio.httpClientAdapter = cable;
  });

  const posicion = (lat: -17.78, lon: -63.18, precision: 8.5);
  const ok = {'message': 'ok', 'status': 200};

  group('rutas', () {
    test('las 66 rutas del contrato, sin repetir y bajo /horas-extras', () {
      final constantes = <String>[
        AppConstants.hexLeyendaCodigos,
        AppConstants.hexMisReportes,
        AppConstants.hexMarcar,
        AppConstants.hexActualizarReporte,
        AppConstants.hexAnularReporte,
        AppConstants.hexDetalleReporte,
        AppConstants.hexLineasReporte,
        AppConstants.hexReporteTramos,
        AppConstants.hexHistorialReporte,
        AppConstants.hexRequisitosMarca,
        AppConstants.hexMisRoles,
        AppConstants.hexBandejaEncargado,
        AppConstants.hexCorregirHora,
        AppConstants.hexVistoBueno,
        AppConstants.hexRechazarEncargado,
        AppConstants.hexBandejaJefe,
        AppConstants.hexAprobar,
        AppConstants.hexAprobarGrupo,
        AppConstants.hexRechazarJefe,
        AppConstants.hexObservacionBandeja,
        AppConstants.hexPlanillaListar,
        AppConstants.hexPlanillaPendientes,
        AppConstants.hexPlanillaVistaPrevia,
        AppConstants.hexPlanillaVistaPreviaLineas,
        AppConstants.hexPlanillaAvisos,
        AppConstants.hexPlanillaEjecutar,
        AppConstants.hexPlanillaEmpleados,
        AppConstants.hexPlanillaDetalle,
        AppConstants.hexPlanillaLeyenda,
        AppConstants.hexPlanillaPdf,
        AppConstants.hexPlanillaAnular,
        AppConstants.hexParametroListar,
        AppConstants.hexParametroVigencia,
        AppConstants.hexParametroEditarLeyenda,
        AppConstants.hexParametroEliminar,
        AppConstants.hexParametroCatalogo,
        AppConstants.hexParametroDejarDeUsar,
        AppConstants.hexTramoListar,
        AppConstants.hexTramoVigencia,
        AppConstants.hexTramoEditarLeyenda,
        AppConstants.hexTramoEliminar,
        AppConstants.hexComidaListar,
        AppConstants.hexComidaVigencia,
        AppConstants.hexComidaEditarLeyenda,
        AppConstants.hexComidaEliminar,
        AppConstants.hexAprobadorListar,
        AppConstants.hexAprobadorAsignar,
        AppConstants.hexAprobadorCerrar,
        AppConstants.hexAprobadorEliminar,
        AppConstants.hexAprobadorRama,
        AppConstants.hexAprobadorEncargados,
        AppConstants.hexConfiguracionHistorial,
        AppConstants.hexReporteHoy,
        AppConstants.hexAsignables,
        AppConstants.hexAsignar,
        AppConstants.hexQuitarAsignacion,
        AppConstants.hexHistorialAsignacion,
        AppConstants.hexPlanillaPendientesFirma,
        AppConstants.hexPlanillaLote,
        AppConstants.hexPlanillaAnularLote,
        AppConstants.hexComidaPeriodo,
        AppConstants.hexFaltasAsignacion,
        AppConstants.hexTramoMapa,
        AppConstants.hexSimuladorJornada,
        AppConstants.hexJornadasPasadas,
        AppConstants.hexCrearReportePasado,
      ];

      expect(constantes, _rutasDelContrato);
      expect(constantes.toSet().length, 66);
      expect(constantes.every((r) => r.startsWith('/horas-extras/')), isTrue);
    });

    test('las 9 pantallas son las direcciones de tb_vista, sin barra', () {
      expect(
        [
          AppConstants.rutaHexMisHoras,
          AppConstants.rutaHexRevision,
          AppConstants.rutaHexAprobacion,
          AppConstants.rutaHexObservacion,
          AppConstants.rutaHexPlanilla,
          AppConstants.rutaHexAnularPlanilla,
          AppConstants.rutaHexParametros,
          AppConstants.rutaHexAprobadores,
          AppConstants.rutaHexAsignacion,
        ],
        [
          'thexMisHoras/MisHoras',
          'thexRevision/Encargado',
          'thexAprobacion/Area',
          'thexObservacion/Observar',
          'thexPlanilla/Planilla',
          'thexPlanilla/Anular',
          'thexParametros/Parametros',
          'thexParametros/Aprobadores',
          'thexAsignacion/Asignar',
        ],
      );
    });
  });

  group('reporte', () {
    test('marcar manda la posición y nada de identidad', () async {
      cable.responde(201, {'message': 'Entrada registrada.', 'data': 31});
      final r = await reportes.marcar(tipoMarca: 'ENTRADA', posicion: posicion);

      expect(cable.ruta, '/horas-extras/reporte/marcar');
      expect(cable.cuerpo, {
        'tipoMarca': 'ENTRADA',
        'lat': -17.78,
        'lon': -63.18,
        'precision': 8.5,
      });
      expect(r, (id: BigInt.from(31), mensaje: 'Entrada registrada.'));
    });

    test('D37 y D41: marcar no manda confirmado ni motivo', () async {
      cable.responde(201, {'message': 'ok', 'data': 31});
      await reportes.marcar(tipoMarca: 'SALIDA', posicion: posicion);

      expect(cable.cuerpo, {
        'tipoMarca': 'SALIDA',
        'lat': -17.78,
        'lon': -63.18,
        'precision': 8.5,
      });
    });

    test('D37: hoy manda {} y lee el objeto con las banderas', () async {
      cable.responde(200, {
        ...ok,
        'data': {
          'vistaHabilitada': true,
          'textoVista': 'MARIA te asignó horas extra.',
          'fechaJornadaAsignada': '2026-11-05',
          'idAsignacion': 12,
          'puedeMarcarEntrada': 0,
          'textoMarcarEntrada': 'Ya pasó tu hora de entrada.',
          'puedeMarcarSalida': 1,
          'textoMarcarSalida': 'Marca tu salida hasta las 06:00.',
          'horaLimiteSalida': '2026-11-06 06:00:00',
          'motivoAsignacion': 'Inventario de fin de mes',
        },
      });
      final v = await reportes.hoy();

      expect(cable.ruta, '/horas-extras/reporte/hoy');
      expect(cable.cuerpo, <String, dynamic>{});
      expect(v!.vistaHabilitada, isTrue);
      expect(v.puedeMarcarEntrada, isFalse);
      expect(v.puedeMarcarSalida, isTrue);
      expect(v.idAsignacion, BigInt.from(12));
      expect(v.horaLimiteSalida, DateTime(2026, 11, 6, 6));
      expect(v.motivoAsignacion, 'Inventario de fin de mes');

      cable.responde(204, null);
      expect(await reportes.hoy(), isNull);
    });

    test('actualizar manda el id y el motivo, nunca la compensación', () async {
      cable.responde(201, {'message': 'ok', 'data': 12});
      await reportes.actualizar(
        idReporte: BigInt.from(12),
        motivo: 'Descarga de bobinas',
      );

      expect(cable.ruta, '/horas-extras/reporte/actualizar');
      expect(cable.cuerpo, {'idReporte': 12, 'motivo': 'Descarga de bobinas'});
      expect(cable.cuerpo!['idReporte'], isA<int>());
      expect(cable.cuerpo!.containsKey('compensacion'), isFalse);
      expect(cable.cuerpo!.containsKey('confirmado'), isFalse);
    });

    test('actualizar sin motivo manda solo el id', () async {
      cable.responde(201, {'message': 'ok', 'data': 12});
      await reportes.actualizar(idReporte: BigInt.from(12));

      expect(cable.cuerpo, {'idReporte': 12});
    });

    test('anular manda el id y la observación', () async {
      cable.responde(201, {'message': 'Anulado.', 'data': 12});
      await reportes.anular(idReporte: BigInt.from(12), observacion: 'Error');

      expect(cable.ruta, '/horas-extras/reporte/anular');
      expect(cable.cuerpo, {'idReporte': 12, 'observacion': 'Error'});

      await reportes.anular(idReporte: BigInt.from(12));
      expect(cable.cuerpo, {'idReporte': 12});
    });

    test('detalle, líneas e historial piden solo el id', () async {
      cable.responde(200, {
        ...ok,
        'data': {'idReporte': 5, 'nombreEmpleado': 'Ana'},
      });
      final detalle = await reportes.detalle(BigInt.from(5));
      expect(cable.ruta, '/horas-extras/reporte/detalle');
      expect(cable.cuerpo, {'idReporte': 5});
      expect(detalle?.nombreEmpleado, 'Ana');

      cable.responde(200, {
        ...ok,
        'data': [
          {'idReporte': 5, 'concepto': 'TRAMO', 'codigo': 'H25'},
        ],
      });
      final lineas = await reportes.lineas(BigInt.from(5));
      expect(cable.ruta, '/horas-extras/reporte/lineas');
      expect(cable.cuerpo, {'idReporte': 5});
      expect(lineas.single.codigo, 'H25');

      cable.responde(200, {
        ...ok,
        'data': [
          {'idEvento': 9, 'tipo': 'CREADO'},
        ],
      });
      final historial = await reportes.historial(BigInt.from(5));
      expect(cable.ruta, '/horas-extras/reporte/historial');
      expect(cable.cuerpo, {'idReporte': 5});
      expect(historial.single.tipo, 'CREADO');

      cable.responde(204, null);
      expect(await reportes.detalle(BigInt.from(6)), isNull);
      expect(await reportes.lineas(BigInt.from(6)), isEmpty);
    });

    test('tramos manda solo el id y lee los segmentos (D36)', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {
            'orden': 1,
            'horaDesde': '20:30',
            'horaHasta': '21:00',
            'minutos': 30,
            'clase': 'HORA',
            'codigo': 'H50',
          },
        ],
      });
      final tramos = await reportes.tramos(BigInt.from(5));
      expect(cable.ruta, '/horas-extras/reporte/tramos');
      expect(cable.cuerpo, {'idReporte': 5});
      expect(tramos.single.codigo, 'H50');

      cable.responde(204, null);
      expect(await reportes.tramos(BigInt.from(6)), isEmpty);
    });

    test(
      'requisitosMarca manda el cuerpo vacío y lee la lista (D28.1)',
      () async {
        cable.responde(200, {
          ...ok,
          'data': [
            {
              'requisito': 'HORARIO',
              'cumple': 0,
              'bloquea': 1,
              'titulo': 'Horario asignado en el biométrico',
              'detalle':
                  'Pide a RRHH que te asigne un horario en el biométrico',
              'orden': 4,
            },
          ],
        });
        final filas = await reportes.requisitosMarca();
        expect(cable.ruta, '/horas-extras/reporte/requisitos-marca');
        // El actor sale del token: nada de identidad en el cuerpo.
        expect(cable.cuerpo, <String, dynamic>{});
        expect(filas.single.requisito, 'HORARIO');
        expect(filas.single.impideMarcar, isTrue);

        cable.responde(204, null);
        expect(await reportes.requisitosMarca(), isEmpty);
      },
    );

    test('leyendaCodigos y misRoles leen el objeto de data', () async {
      cable.responde(200, {
        ...ok,
        'data': {
          'tramos': [
            {'idTramo': 1, 'codigo': 'H25'},
          ],
          'comidas': [
            {'idComida': 2, 'codigo': 'C'},
          ],
        },
      });
      final leyenda = await reportes.leyendaCodigos();
      expect(cable.ruta, '/horas-extras/leyenda-codigos');
      expect(cable.cuerpo, <String, dynamic>{});
      expect(leyenda?.tramos.single.codigo, 'H25');
      expect(leyenda?.comidas.single.codigo, 'C');

      cable.responde(200, {
        ...ok,
        'data': {'esEncargado': true, 'esJefe': false, 'sucursales': '1,4'},
      });
      final roles = await reportes.misRoles();
      expect(cable.ruta, '/horas-extras/aprobador/mis-roles');
      expect(roles?.esEncargado, isTrue);
      expect(roles?.esObservador, isFalse);
      expect(roles?.sucursales, '1,4');

      // D45: el servidor manda esObservador; sin él la bandera es falsa.
      cable.responde(200, {
        ...ok,
        'data': {'esEncargado': false, 'esJefe': false, 'esObservador': true},
      });
      expect((await reportes.misRoles())?.esObservador, isTrue);

      cable.responde(204, null);
      expect(await reportes.leyendaCodigos(), isNull);
      expect(await reportes.misRoles(), isNull);
    });
  });

  group('páginas', () {
    test('misReportes arma la página con totalFilas', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {'idReporte': 1, 'totalFilas': 37},
          {'idReporte': 2, 'totalFilas': 37},
        ],
      });
      final pagina = await reportes.misReportes((
        desde: DateTime(2026, 10, 1, 8),
        hasta: DateTime(2026, 10, 31),
        estado: 'REPORTADO',
        pagina: 2,
        tamano: 20,
      ));

      expect(cable.ruta, '/horas-extras/reporte/mis-reportes');
      expect(cable.cuerpo, {
        'fechaDesde': '2026-10-01',
        'fechaHasta': '2026-10-31',
        'estado': 'REPORTADO',
        'pagina': 2,
        'tamano': 20,
      });
      expect(pagina.filas.length, 2);
      expect(pagina.total, 37);

      cable.responde(204, null);
      final vacia = await reportes.misReportes(_sinFiltro);
      expect(vacia.filas, isEmpty);
      expect(vacia.total, 0);
      expect(cable.cuerpo, {'pagina': 1, 'tamano': 20});
    });

    test('las dos bandejas usan su ruta y el mismo filtro', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {'idReporte': 1, 'totalFilas': 1},
        ],
      });
      await reportes.bandejaEncargado(_sinFiltro);
      expect(cable.ruta, '/horas-extras/revision/bandeja');

      final jefe = await reportes.bandejaJefe((
        desde: null,
        hasta: null,
        estado: 'VISTO_BUENO',
        pagina: 1,
        tamano: 100,
      ));
      expect(cable.ruta, '/horas-extras/aprobacion/bandeja');
      expect(cable.cuerpo, {
        'estado': 'VISTO_BUENO',
        'pagina': 1,
        'tamano': 100,
      });
      expect(jefe.total, 1);

      // D45: la del observador, con el mismo cuerpo y sin estado = todos.
      final observador = await reportes.bandejaObservador(_sinFiltro);
      expect(cable.ruta, '/horas-extras/observacion/bandeja');
      expect(cable.cuerpo, {'pagina': 1, 'tamano': 20});
      expect(observador.total, 1);
      expect(observador.filas.single.idReporte, BigInt.one);
    });
  });

  group('revisión y aprobación', () {
    test('D43: jornadasPasadas va sin cuerpo y lee la lista del SP', () async {
      cable.responde(200, {
        'message': 'ok',
        'data': [
          {
            'codEmpleado': 101,
            'nombreEmpleado': 'ARANDA VACA LUIS',
            'fechaJornada': '2026-11-01',
            'tipoSugerido': 'SIN_HORARIO',
            'inicioSugerido': null,
            'finSugerido': null,
            'puedeCrear': true,
            'textoRegularizacion': 'Regularización abierta',
          },
        ],
      });
      final l = await reportes.jornadasPasadas();
      expect(cable.ruta, '/horas-extras/revision/pasados');
      expect(cable.cuerpo ?? const {}, isEmpty);
      expect(l.single.codEmpleado, BigInt.from(101));
      expect(l.single.fechaJornada, DateTime(2026, 11, 1));
      expect(l.single.puedeCrear, isTrue);
      expect(l.single.inicioSugerido, isNull);
    });

    test('D43: jornadasPasadas con 204 es una lista vacía', () async {
      cable.responde(204, null);
      expect(await reportes.jornadasPasadas(), isEmpty);
    });

    test('D43: crearReportePasado manda solo empleado, jornada, horas y '
        'justificación', () async {
      cable.responde(201, {'message': 'Reporte creado.', 'data': 88});
      final r = await reportes.crearReportePasado(
        HexReportePasadoEntity(
          codEmpleado: BigInt.from(101),
          fechaJornada: DateTime(2026, 11, 2),
          inicio: DateTime(2026, 11, 2, 18),
          fin: DateTime(2026, 11, 2, 21, 30),
          observacion: 'No marcó por falla del biométrico',
        ),
      );
      expect(cable.ruta, '/horas-extras/revision/crear-pasado');
      expect(cable.cuerpo, {
        'codEmpleado': 101,
        'fechaJornada': '2026-11-02',
        'inicio': '2026-11-02T18:00:00.000',
        'fin': '2026-11-02T21:30:00.000',
        'observacion': 'No marcó por falla del biométrico',
      });
      expect(r.id, BigInt.from(88));
      expect(r.mensaje, 'Reporte creado.');
    });

    test('corregirHora manda el fin sin zona y no manda inicio nulo', () async {
      cable.responde(201, {'message': 'ok', 'data': 12});
      await reportes.corregirHora(
        idReporte: BigInt.from(12),
        fin: DateTime(2026, 10, 24, 1, 30),
        observacion: 'Salió pasada la medianoche',
      );

      expect(cable.ruta, '/horas-extras/revision/corregir-hora');
      expect(cable.cuerpo, {
        'idReporte': 12,
        'fin': '2026-10-24T01:30:00.000',
        'observacion': 'Salió pasada la medianoche',
      });
      expect(cable.cuerpo!.containsKey('inicio'), isFalse);
    });

    test(
      'visto bueno y rechazo del encargado mandan id y observación',
      () async {
        cable.responde(201, {'message': 'ok', 'data': 12});
        await reportes.vistoBueno(idReporte: BigInt.from(12));
        expect(cable.ruta, '/horas-extras/revision/visto-bueno');
        expect(cable.cuerpo, {'idReporte': 12});

        await reportes.rechazarEncargado(
          idReporte: BigInt.from(12),
          observacion: 'Falta sustento',
        );
        expect(cable.ruta, '/horas-extras/revision/rechazar');
        expect(cable.cuerpo, {
          'idReporte': 12,
          'observacion': 'Falta sustento',
        });
      },
    );

    test('aprobar y rechazar del jefe mandan id y observación', () async {
      cable.responde(201, {'message': 'ok', 'data': 12});
      await reportes.aprobar(idReporte: BigInt.from(12), observacion: 'Ok');
      expect(cable.ruta, '/horas-extras/aprobacion/aprobar');
      expect(cable.cuerpo, {'idReporte': 12, 'observacion': 'Ok'});

      await reportes.rechazarJefe(
        idReporte: BigInt.from(12),
        observacion: 'No procede',
      );
      expect(cable.ruta, '/horas-extras/aprobacion/rechazar');
      expect(cable.cuerpo, {'idReporte': 12, 'observacion': 'No procede'});
    });

    test('aprobarGrupo manda codEncargado, anio y mes', () async {
      cable.responde(201, {'message': 'Aprobó 8 reportes.', 'data': 8});
      final r = await reportes.aprobarGrupo(
        codEncargado: BigInt.from(77),
        anio: 2026,
        mes: 10,
      );

      expect(cable.ruta, '/horas-extras/aprobacion/aprobar-grupo');
      expect(cable.cuerpo, {'codEncargado': 77, 'anio': 2026, 'mes': 10});
      expect(r.id, BigInt.from(8));
    });
  });

  group('planilla', () {
    final combinacion = (
      codEmpresa: BigInt.from(2),
      codSucursal: BigInt.from(4),
      anio: 2026,
      mes: 10,
    );
    const cuerpoCombinacion = {
      'codEmpresa': 2,
      'codSucursal': 4,
      'anio': 2026,
      'mes': 10,
    };

    test('listar y pendientes', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {'idPlanilla': 3, 'estado': 'EJECUTADA'},
        ],
      });
      final lista = await planillas.planillas(idPlanilla: BigInt.from(3));
      expect(cable.ruta, '/horas-extras/planilla/listar');
      expect(cable.cuerpo, {'idPlanilla': 3});
      expect(lista.single.estado, 'EJECUTADA');

      await planillas.planillas();
      expect(cable.cuerpo, <String, dynamic>{});

      cable.responde(200, {
        ...ok,
        'data': [
          {'codEmpresa': 2, 'codSucursal': 4, 'anio': 2026, 'mes': 10},
        ],
      });
      final pendientes = await planillas.pendientes();
      expect(cable.ruta, '/horas-extras/planilla/pendientes');
      expect(cable.cuerpo, <String, dynamic>{});
      expect(pendientes.single.mes, 10);
    });

    test('vista previa, líneas y avisos mandan la combinación', () async {
      cable.responde(204, null);
      await planillas.vistaPrevia(combinacion);
      expect(cable.ruta, '/horas-extras/planilla/vista-previa');
      expect(cable.cuerpo, cuerpoCombinacion);

      await planillas.vistaPreviaLineas(combinacion);
      expect(cable.ruta, '/horas-extras/planilla/vista-previa-lineas');
      expect(cable.cuerpo, cuerpoCombinacion);

      await planillas.avisos(combinacion);
      expect(cable.ruta, '/horas-extras/planilla/avisos');
      expect(cable.cuerpo, cuerpoCombinacion);
    });

    test('ejecutar manda la combinación y la observación', () async {
      cable.responde(201, {'message': 'Planilla ejecutada.', 'data': 15});
      final r = await planillas.ejecutar(
        combinacion,
        observacion: 'Cierre de octubre',
      );

      expect(cable.ruta, '/horas-extras/planilla/ejecutar');
      expect(cable.cuerpo, {
        ...cuerpoCombinacion,
        'observacion': 'Cierre de octubre',
      });
      expect(r.id, BigInt.from(15));

      await planillas.ejecutar(combinacion);
      expect(cable.cuerpo, cuerpoCombinacion);
    });

    test('empleados, detalle y leyenda piden la planilla', () async {
      cable.responde(204, null);
      await planillas.empleados(BigInt.from(15));
      expect(cable.ruta, '/horas-extras/planilla/empleados');
      expect(cable.cuerpo, {'idPlanilla': 15});

      await planillas.detalle(BigInt.from(15));
      expect(cable.ruta, '/horas-extras/planilla/detalle');
      expect(cable.cuerpo, {'idPlanilla': 15});

      await planillas.detalle(BigInt.from(15), codEmpleado: BigInt.from(9));
      expect(cable.cuerpo, {'idPlanilla': 15, 'codEmpleado': 9});

      await planillas.leyenda(BigInt.from(15));
      expect(cable.ruta, '/horas-extras/planilla/leyenda');
      expect(cable.cuerpo, {'idPlanilla': 15});
    });

    test('anular manda la planilla y la observación', () async {
      cable.responde(201, {'message': 'Planilla anulada.', 'data': 15});
      await planillas.anular(BigInt.from(15), 'Se ejecutó por error');

      expect(cable.ruta, '/horas-extras/planilla/anular');
      expect(cable.cuerpo, {
        'idPlanilla': 15,
        'observacion': 'Se ejecutó por error',
      });
    });

    test('pdf usa la ruta del contrato y devuelve los bytes', () async {
      cable.responde(200, '%PDF-1.7', tipo: 'application/pdf');
      final bytes = await planillas.pdf(BigInt.from(15));

      expect(cable.ruta, '/horas-extras/planilla/pdf');
      expect(cable.cuerpo, {'idPlanilla': 15});
      expect(utf8.decode(bytes), '%PDF-1.7');
    });

    test('pdf sin planilla (204) lanza SinDatosHex', () async {
      cable.responde(204, null);
      await expectLater(
        planillas.pdf(BigInt.from(99)),
        throwsA(isA<SinDatosHex>()),
      );
    });
  });

  group('configuración', () {
    test('parámetros: listar, vigencia, leyenda y eliminar', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {'idParametro': 1, 'clave': 'DIVISOR_COSTO_HORA'},
        ],
      });
      final lista = await configuracion.parametros(clave: 'DIVISOR_COSTO_HORA');
      expect(cable.ruta, '/horas-extras/parametro/listar');
      expect(cable.cuerpo, {'clave': 'DIVISOR_COSTO_HORA'});
      expect(lista.single.clave, 'DIVISOR_COSTO_HORA');

      cable.responde(201, {'message': 'ok', 'data': 8});
      await configuracion.nuevaVigenciaParametro(
        HexParametroEntity(
          clave: 'DIVISOR_COSTO_HORA',
          valorNumero: 240,
          leyenda: 'Horas del mes',
          vigenteDesde: DateTime(2026, 11),
        ),
      );
      expect(cable.ruta, '/horas-extras/parametro/vigencia');
      expect(cable.cuerpo, {
        'clave': 'DIVISOR_COSTO_HORA',
        'valorNumero': 240.0,
        'leyenda': 'Horas del mes',
        'vigenteDesde': '2026-11-01',
      });

      await configuracion.editarLeyendaParametro(BigInt.from(1), 'Nueva');
      expect(cable.ruta, '/horas-extras/parametro/editar-leyenda');
      expect(cable.cuerpo, {'idParametro': 1, 'leyenda': 'Nueva'});

      await configuracion.eliminarParametro(BigInt.from(1));
      expect(cable.ruta, '/horas-extras/parametro/eliminar');
      expect(cable.cuerpo, {'idParametro': 1});
    });

    test(
      'parámetros: catálogo y dejar de usar desde una fecha (D33)',
      () async {
        cable.responde(200, {
          ...ok,
          'data': [
            {
              'clave': 'FECHA_INICIO_MODULO',
              'nombre': 'Inicio del módulo',
              'obligatorio': 1,
              'tieneVigente': 0,
              'aviso': 'Falta «Inicio del módulo».',
            },
          ],
        });
        final catalogo = await configuracion.catalogoParametros();
        expect(cable.ruta, '/horas-extras/parametro/catalogo');
        expect(cable.cuerpo ?? const {}, isEmpty);
        expect(catalogo.single.aviso, 'Falta «Inicio del módulo».');
        expect(catalogo.single.obligatorio, isTrue);

        cable.responde(201, {'message': 'Deja de usarse.', 'data': 12});
        final r = await configuracion.dejarDeUsarParametro(
          BigInt.from(12),
          DateTime(2026, 11, 10),
        );
        expect(cable.ruta, '/horas-extras/parametro/dejar-de-usar');
        expect(cable.cuerpo, {'idParametro': 12, 'sinUsoDesde': '2026-11-10'});
        expect(r.mensaje, 'Deja de usarse.');
        expect(r.id, BigInt.from(12));
      },
    );

    test('tramos: listar, vigencia completa, leyenda y eliminar', () async {
      cable.responde(204, null);
      await configuracion.tramos(tipoDia: 'HABIL', codigo: 'H25');
      expect(cable.ruta, '/horas-extras/tramo/listar');
      expect(cable.cuerpo, {'tipoDia': 'HABIL', 'codigo': 'H25'});

      cable.responde(201, {'message': 'ok', 'data': 21});
      await configuracion.nuevaVigenciaTramo(
        const HexTramoEntity(
          codigo: 'H25',
          leyenda: 'Hora al 25 %',
          tipoDia: 'HABIL',
          horaDesde: '20:01:00',
          horaHasta: '00:00:00',
          multiplicador: 1.25,
        ).copyWith(vigenteDesde: DateTime(2026, 11, 1)),
      );
      expect(cable.ruta, '/horas-extras/tramo/vigencia');
      expect(cable.cuerpo, {
        'codigo': 'H25',
        'leyenda': 'Hora al 25 %',
        'tipoDia': 'HABIL',
        'horaDesde': '20:01:00',
        'horaHasta': '00:00:00',
        'multiplicador': 1.25,
        'vigenteDesde': '2026-11-01',
      });

      // El reenvío confirmado agrega `confirmado: true` al mismo cuerpo.
      await configuracion.nuevaVigenciaTramo(
        const HexTramoEntity(codigo: 'H25', tipoDia: 'HABIL'),
        confirmado: true,
      );
      expect(cable.cuerpo, {
        'codigo': 'H25',
        'leyenda': '',
        'tipoDia': 'HABIL',
        'multiplicador': 0.0,
        'confirmado': true,
      });

      await configuracion.editarLeyendaTramo(BigInt.from(3), 'Otra');
      expect(cable.ruta, '/horas-extras/tramo/editar-leyenda');
      expect(cable.cuerpo, {'idTramo': 3, 'leyenda': 'Otra'});

      await configuracion.eliminarTramo(BigInt.from(3));
      expect(cable.ruta, '/horas-extras/tramo/eliminar');
      expect(cable.cuerpo, {'idTramo': 3});
    });

    test('mapa de tramos: la propuesta viaja con horas HH:mm:ss', () async {
      cable.responde(200, {
        'data': [
          {
            'tipoDia': 'HABIL',
            'textoTipoDia': 'Días hábiles',
            'orden': 3,
            'desdeMin': 1200,
            'hastaMin': 1201,
            'horaDesde': '20:00',
            'horaHasta': '20:01',
            'clase': 'HUECO',
            'codigo': null,
            'esPropuesto': 0,
            'texto': 'De 20:00 a 20:01 ningún tramo paga.',
          },
        ],
      });
      final mapa = await configuracion.mapaTramos(
        tipoDia: 'HABIL',
        fecha: DateTime(2026, 11, 10),
        codigo: 'H50',
        horaDesde: '20:00',
        horaHasta: '00:00:00',
      );
      expect(cable.ruta, '/horas-extras/tramo/mapa');
      expect(cable.cuerpo, {
        'tipoDia': 'HABIL',
        'codigo': 'H50',
        'horaDesde': '20:00:00',
        'horaHasta': '00:00:00',
        'vigenteDesde': '2026-11-10',
      });
      expect(mapa.single.esProblema, isTrue);
      expect(mapa.single.minutos, 1);
      expect(mapa.single.codigo, isNull);

      // Sin filtros, cuerpo vacío: el SP devuelve los tres tipos de hoy.
      cable.responde(204, null);
      expect(await configuracion.mapaTramos(), isEmpty);
      expect(cable.cuerpo, isEmpty);
    });

    test(
      'simulador: manda la jornada y lee jornada, segmentos y avisos',
      () async {
        cable.responde(200, {
          'data': {
            'jornada': {
              'codEmpleado': 155,
              'nombreEmpleado': 'Manuel',
              'fechaJornada': '2026-11-05',
              'inicioUsado': '2026-11-05 15:00:00',
              'finUsado': '2026-11-05T21:36:00',
              'conAsignacion': true,
              'costoHora': 21,
              'total': '149.40',
            },
            'segmentos': [
              {'orden': 1, 'clase': 'HORA', 'codigo': 'H50', 'monto': 50.4},
            ],
            'avisos': [
              {
                'orden': 1,
                'nivel': 'ERROR',
                'texto': 'Hueco',
                'quien': 'Encargado',
              },
            ],
          },
        });
        final s = await configuracion.simularJornada(
          codEmpleado: BigInt.from(155),
          fechaJornada: DateTime(2026, 11, 5),
          fin: DateTime(2026, 11, 5, 21, 36),
        );
        expect(cable.ruta, '/horas-extras/simulador/jornada');
        expect(cable.cuerpo, {
          'codEmpleado': 155,
          'fechaJornada': '2026-11-05',
          'fin': '2026-11-05T21:36:00.000',
        });
        expect(s.jornada?.codEmpleado, BigInt.from(155));
        expect(s.jornada?.inicioUsado, DateTime(2026, 11, 5, 15));
        expect(s.jornada?.finUsado, DateTime(2026, 11, 5, 21, 36));
        expect(s.jornada?.conAsignacion, isTrue);
        expect(s.jornada?.total, 149.40);
        expect(s.segmentos.single.monto, 50.4);
        expect(s.avisos.single.quien, 'Encargado');

        // 204: sin jornada, no un error.
        cable.responde(204, null);
        final vacia = await configuracion.simularJornada(
          codEmpleado: BigInt.one,
          fechaJornada: DateTime(2026, 11, 5),
        );
        expect(vacia.jornada, isNull);
        expect(vacia.segmentos, isEmpty);
      },
    );

    test('comidas: la leyenda doble no arrastra la simple', () async {
      cable.responde(204, null);
      await configuracion.comidas(codigo: 'C');
      expect(cable.ruta, '/horas-extras/comida/listar');
      expect(cable.cuerpo, {'codigo': 'C'});

      cable.responde(201, {'message': 'ok', 'data': 5});
      await configuracion.editarLeyendaComida(
        BigInt.from(2),
        leyendaDoble: 'Doble cena',
      );
      expect(cable.ruta, '/horas-extras/comida/editar-leyenda');
      expect(cable.cuerpo, {'idComida': 2, 'leyendaDoble': 'Doble cena'});

      await configuracion.nuevaVigenciaComida(
        const HexComidaEntity(
          codigo: 'C',
          leyenda: 'Cena',
          codigoDoble: 'DC',
          leyendaDoble: 'Doble cena',
          monto: 15,
          montoDoble: 30,
        ).copyWith(vigenteDesde: DateTime(2026, 11, 1)),
      );
      expect(cable.ruta, '/horas-extras/comida/vigencia');
      expect(cable.cuerpo, {
        'codigo': 'C',
        'leyenda': 'Cena',
        'codigoDoble': 'DC',
        'leyendaDoble': 'Doble cena',
        'monto': 15.0,
        'montoDoble': 30.0,
        'activo': true,
        'vigenteDesde': '2026-11-01',
        // D40: la doble viaja siempre; los minutos, solo si se escribieron.
        'conDoble': true,
      });

      await configuracion.eliminarComida(BigInt.from(2));
      expect(cable.ruta, '/horas-extras/comida/eliminar');
      expect(cable.cuerpo, {'idComida': 2});
    });

    test('aprobadores: listar, asignar, cerrar y eliminar', () async {
      cable.responde(204, null);
      await configuracion.aprobadores(codEmpleado: BigInt.from(9), nivel: 1);
      expect(cable.ruta, '/horas-extras/aprobador/listar');
      expect(cable.cuerpo, {'codEmpleado': 9, 'nivel': 1});

      cable.responde(201, {'message': 'ok', 'data': 6});
      await configuracion.asignarAprobador(
        HexAprobadorEntity(
          codEmpleadoAprobador: BigInt.from(9),
          nivel: 1,
          vigenteDesde: DateTime(2026, 11),
        ),
      );
      expect(cable.ruta, '/horas-extras/aprobador/asignar');
      expect(cable.cuerpo, {
        'codEmpleadoAprobador': 9,
        'nivel': 1,
        'vigenteDesde': '2026-11-01',
      });

      await configuracion.cerrarAprobador(BigInt.from(6));
      expect(cable.ruta, '/horas-extras/aprobador/cerrar');
      expect(cable.cuerpo, {'idAprobador': 6});

      await configuracion.cerrarAprobador(
        BigInt.from(6),
        vigenteHasta: DateTime(2026, 12, 31),
      );
      expect(cable.cuerpo, {'idAprobador': 6, 'vigenteHasta': '2026-12-31'});

      await configuracion.eliminarAprobador(BigInt.from(6));
      expect(cable.ruta, '/horas-extras/aprobador/eliminar');
      expect(cable.cuerpo, {'idAprobador': 6});
    });

    test('rama: manda solo el aprobador consultado y lee sus filas', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {
            'codEmpleado': 140,
            'nombreEmpleado': 'Choque Flores Mario',
            'cargo': 'Operario de máquina',
            'profundidad': 2,
            'textoFirma': 'Sin aprobador en su rama',
          },
        ],
      });
      final rama = await configuracion.ramaAprobador(BigInt.from(65));
      expect(cable.ruta, '/horas-extras/aprobador/rama');
      expect(cable.cuerpo, {'codEmpleado': 65});
      expect(rama.single.nombreEmpleado, 'Choque Flores Mario');
      expect(rama.single.textoFirma, 'Sin aprobador en su rama');

      cable.responde(204, null);
      expect(await configuracion.ramaAprobador(BigInt.from(65)), isEmpty);
    });

    test('encargados: sin cuerpo y lee las opciones de E (D35)', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {
            'codEmpleado': 191,
            'nombreEmpleado': 'Zeballos Zue Helen Scarlet',
            'cargo': 'SUPERVISOR DE ALMACENES',
            'cantidadRama': 6,
            'jefesActuales': null,
          },
        ],
      });
      final lista = await configuracion.encargadosParaJefe();
      expect(cable.ruta, '/horas-extras/aprobador/encargados');
      expect(cable.cuerpo, isEmpty);
      expect(lista.single.codEmpleado, BigInt.from(191));
      expect(lista.single.cantidadRama, 6);
      expect(lista.single.jefesActuales, isNull);

      cable.responde(204, null);
      expect(await configuracion.encargadosParaJefe(), isEmpty);
    });

    test('asignar jefe manda nivel 2 y sus encargados como enteros', () async {
      cable.responde(201, {'message': 'ok', 'data': 7});
      await configuracion.asignarAprobador(
        HexAprobadorEntity(
          codEmpleadoAprobador: BigInt.from(65),
          nivel: 2,
          codEmpleadosAprobados: [BigInt.from(191), BigInt.from(7)],
          vigenteDesde: DateTime(2026, 11, 4),
          vigenteHasta: DateTime(2026, 12, 31),
        ),
      );
      expect(cable.ruta, '/horas-extras/aprobador/asignar');
      expect(cable.cuerpo, {
        'codEmpleadoAprobador': 65,
        'nivel': 2,
        'codEmpleadosAprobados': [191, 7],
        'vigenteDesde': '2026-11-04',
        'vigenteHasta': '2026-12-31',
      });
    });

    test('historial: una página de la entidad con el total del SP', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {
            'idEvento': 9,
            'entidad': 'TRAMO',
            'accion': 'U',
            'accionTexto': 'Leyenda editada',
            'totalFilas': 45,
          },
        ],
      });
      final pagina = await configuracion.historial((
        entidad: 'TRAMO',
        idRegistro: BigInt.from(2),
        desde: DateTime(2026, 10, 1),
        hasta: DateTime(2026, 10, 31),
        pagina: 2,
        tamano: 20,
      ));
      expect(cable.ruta, '/horas-extras/configuracion/historial');
      expect(cable.cuerpo, {
        'entidad': 'TRAMO',
        'idRegistro': 2,
        'fechaDesde': '2026-10-01',
        'fechaHasta': '2026-10-31',
        'pagina': 2,
        'tamano': 20,
      });
      expect(pagina.total, 45);
      expect(pagina.filas.single.accionTexto, 'Leyenda editada');

      // Sin filtros opcionales solo viajan la entidad y la página; 204 = vacía.
      cable.responde(204, null);
      final vacia = await configuracion.historial((
        entidad: 'PARAMETRO',
        idRegistro: null,
        desde: null,
        hasta: null,
        pagina: 1,
        tamano: 20,
      ));
      expect(cable.cuerpo, {'entidad': 'PARAMETRO', 'pagina': 1, 'tamano': 20});
      expect(vacia.filas, isEmpty);
      expect(vacia.total, 0);
    });
  });

  group('D37 a D40', () {
    test('asignables manda solo la jornada y lee avisos y banderas', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {
            'codEmpleado': 191,
            'nombreEmpleado': 'APAZA',
            'tipoAviso': 'SABADO',
            'aviso': 'A APAZA no le toca trabajar el sábado 07/11/2026',
            'puedeAsignar': 1,
            'puedeQuitar': 0,
            'textoEstado': 'Sin asignar',
          },
        ],
      });
      final filas = await asignaciones.asignables(DateTime(2026, 11, 7));

      expect(cable.ruta, '/horas-extras/asignacion/asignables');
      expect(cable.cuerpo, {'fechaJornada': '2026-11-07'});
      expect(filas.single.puedeAsignar, isTrue);
      expect(filas.single.tipoAviso, 'SABADO');

      await asignaciones.asignables(null);
      expect(cable.cuerpo, <String, dynamic>{});
    });

    test('asignar manda enteros y confirmado solo en el reenvío', () async {
      cable.responde(201, {'message': 'Horas extra asignadas.', 'data': 40});
      final r = await asignaciones.asignar(
        codEmpleados: [BigInt.from(191), BigInt.from(203)],
        fechaJornada: DateTime(2026, 11, 5),
        motivo: 'Inventario',
      );

      expect(cable.ruta, '/horas-extras/asignacion/asignar');
      expect(cable.cuerpo, {
        'codEmpleados': [191, 203],
        'fechaJornada': '2026-11-05',
        'motivo': 'Inventario',
      });
      expect(r.id, BigInt.from(40));

      // D41: el motivo viaja aunque venga vacío; el SP responde con su texto.
      await asignaciones.asignar(
        codEmpleados: [BigInt.from(191)],
        fechaJornada: DateTime(2026, 11, 5),
        motivo: '',
        confirmado: true,
      );
      expect(cable.cuerpo, {
        'codEmpleados': [191],
        'fechaJornada': '2026-11-05',
        'motivo': '',
        'confirmado': true,
      });
    });

    test('asignar con avisos llega como ConfirmacionHex', () async {
      cable.responde(400, {
        'message':
            'MAMANI está de vacaciones. ¿Confirmas que igual le asignas?',
        'confirmable': true,
      });
      await expectLater(
        asignaciones.asignar(
          codEmpleados: [BigInt.from(203)],
          fechaJornada: DateTime(2026, 11, 5),
          motivo: 'Inventario',
        ),
        throwsA(isA<ConfirmacionHex>()),
      );
    });

    test('quitar e historial', () async {
      cable.responde(201, {'message': 'Asignación quitada.', 'data': 12});
      await asignaciones.quitar(idAsignacion: BigInt.from(12));
      expect(cable.ruta, '/horas-extras/asignacion/quitar');
      expect(cable.cuerpo, {'idAsignacion': 12});

      cable.responde(409, {'message': 'La asignación ya se quitó.'});
      await expectLater(
        asignaciones.quitar(idAsignacion: BigInt.from(12), observacion: 'x'),
        throwsA(isA<ConflictoHex>()),
      );

      cable.responde(200, {
        ...ok,
        'data': [
          {'idAsignacion': 12, 'estado': 'ACTIVA', 'totalFilas': 41},
        ],
      });
      final p = await asignaciones.historial((
        desde: DateTime(2026, 11, 1),
        hasta: null,
        estado: 'ACTIVA',
        pagina: 2,
        tamano: 20,
      ));
      expect(cable.ruta, '/horas-extras/asignacion/historial');
      expect(cable.cuerpo, {
        'fechaDesde': '2026-11-01',
        'estado': 'ACTIVA',
        'pagina': 2,
        'tamano': 20,
      });
      expect(p.total, 41);
    });

    test('pendientes de firma, lote, anular lote y PDF del lote', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {
            'idReporte': 5,
            'estado': 'REPORTADO',
            'debeFirmar': 'ROJAS',
            'textoPendiente': 'Espera el visto bueno de ROJAS',
          },
        ],
      });
      final firmas = await planillas.pendientesFirma(loteHex(2026, 10));
      expect(cable.ruta, '/horas-extras/planilla/pendientes-firma');
      expect(cable.cuerpo, {'anio': 2026, 'mes': 10});
      expect(firmas.single.textoPendiente, 'Espera el visto bueno de ROJAS');

      await planillas.vistaPrevia(loteHex(2026, 10));
      expect(cable.cuerpo, {'anio': 2026, 'mes': 10});

      cable.responde(201, {'message': 'Lote ejecutado.', 'data': 7});
      final r = await planillas.ejecutarLote(2026, 10, observacion: 'Octubre');
      expect(cable.ruta, '/horas-extras/planilla/lote');
      expect(cable.cuerpo, {'anio': 2026, 'mes': 10, 'observacion': 'Octubre'});
      expect(r.id, BigInt.from(7));

      await planillas.anularLote(BigInt.from(7), 'Error de haber');
      expect(cable.ruta, '/horas-extras/planilla/anular-lote');
      expect(cable.cuerpo, {'idLote': 7, 'observacion': 'Error de haber'});

      cable.responde(200, '%PDF-1.4', tipo: 'application/pdf');
      final bytes = await planillas.pdfLote(BigInt.from(7));
      expect(cable.ruta, '/horas-extras/planilla/pdf');
      expect(cable.cuerpo, {'idLote': 7});
      expect(bytes, isNotEmpty);

      cable.responde(204, null);
      await expectLater(
        planillas.pdfLote(BigInt.from(7)),
        throwsA(isA<SinDatosHex>()),
      );
    });

    test('comida: período con conDoble, minutos y hasta', () async {
      cable.responde(201, {'message': 'Comida «C» sin doble cena.', 'data': 9});
      await configuracion.periodoComida(
        HexComidaEntity(
          idComida: BigInt.from(3),
          codigo: 'C',
          leyenda: 'Cena',
          monto: 15,
          conDoble: false,
          minutosSimple: 90,
          vigenteDesde: DateTime(2026, 11, 1),
        ),
        hasta: DateTime(2026, 11, 30),
      );

      expect(cable.ruta, '/horas-extras/comida/periodo');
      expect(cable.cuerpo!.containsKey('idComida'), isFalse);
      expect(cable.cuerpo!['codigo'], 'C');
      expect(cable.cuerpo!['conDoble'], false);
      expect(cable.cuerpo!['minutosSimple'], 90);
      expect(cable.cuerpo!.containsKey('minutosDoble'), isFalse);
      expect(cable.cuerpo!['vigenteDesde'], '2026-11-01');
      expect(cable.cuerpo!['vigenteHasta'], '2026-11-30');
    });
  });

  group('adenda D37: sin salida marcada', () {
    test(
      'visto bueno y aprobar mandan confirmado solo en el reenvío',
      () async {
        cable.responde(201, {'message': 'ok', 'data': 12});
        await reportes.vistoBueno(idReporte: BigInt.from(12));
        expect(cable.cuerpo, {'idReporte': 12});
        await reportes.vistoBueno(idReporte: BigInt.from(12), confirmado: true);
        expect(cable.ruta, '/horas-extras/revision/visto-bueno');
        expect(cable.cuerpo, {'idReporte': 12, 'confirmado': true});

        await reportes.aprobar(idReporte: BigInt.from(12), confirmado: true);
        expect(cable.ruta, '/horas-extras/aprobacion/aprobar');
        expect(cable.cuerpo, {'idReporte': 12, 'confirmado': true});
      },
    );

    test('el 100 del visto bueno llega como ConfirmacionHex', () async {
      cable.responde(400, {
        'message': 'Este reporte no tiene salida marcada. ¿Confirmas?',
        'confirmable': true,
      });
      await expectLater(
        reportes.vistoBueno(idReporte: BigInt.from(12)),
        throwsA(isA<ConfirmacionHex>()),
      );
    });

    test('faltas manda solo fechaDesde y lee el texto del SP', () async {
      cable.responde(200, {
        ...ok,
        'data': [
          {
            'idAsignacion': 7,
            'codEmpleado': 191,
            'nombreEmpleado': 'ARANDA VACA',
            'fechaJornada': '2026-10-13',
            'resultado': 'FALTA',
            'avisoResultado': 'ARANDA VACA no marcó salida el 13/10.',
          },
        ],
      });
      final f = await asignaciones.faltas(desde: DateTime(2026, 10, 1));
      expect(cable.ruta, '/horas-extras/asignacion/faltas');
      expect(cable.cuerpo, {'fechaDesde': '2026-10-01'});
      expect(f.single.idAsignacion, BigInt.from(7));
      expect(f.single.resultado, 'FALTA');
      expect(f.single.avisoResultado, 'ARANDA VACA no marcó salida el 13/10.');

      cable.responde(204, null);
      expect(await asignaciones.faltas(), isEmpty);
      expect(cable.cuerpo ?? const {}, isEmpty);
    });
  });

  test('ningún cuerpo lleva la identidad de quien llama', () async {
    cable.responde(204, null);
    final combinacion = (
      codEmpresa: BigInt.one,
      codSucursal: BigInt.one,
      anio: 2026,
      mes: 10,
    );
    final id = BigInt.one;
    final llamadas = <Future<Object?> Function()>[
      () => reportes.marcar(tipoMarca: 'ENTRADA', posicion: posicion),
      () => reportes.actualizar(idReporte: id, motivo: 'x'),
      () => reportes.anular(idReporte: id),
      () => reportes.tramos(id),
      () => reportes.misReportes(_sinFiltro),
      () => reportes.bandejaEncargado(_sinFiltro),
      () => reportes.bandejaJefe(_sinFiltro),
      () => reportes.corregirHora(idReporte: id, observacion: 'x'),
      () => reportes.vistoBueno(idReporte: id),
      () => reportes.rechazarEncargado(idReporte: id, observacion: 'x'),
      () => reportes.aprobar(idReporte: id),
      () => reportes.aprobarGrupo(codEncargado: id, anio: 2026, mes: 10),
      () => reportes.rechazarJefe(idReporte: id, observacion: 'x'),
      () => planillas.ejecutar(combinacion),
      () => planillas.anular(id, 'x'),
      () => reportes.hoy(),
      () => asignaciones.asignables(null),
      () => asignaciones.asignar(
        codEmpleados: [id],
        fechaJornada: DateTime(2026, 11, 5),
        motivo: 'Inventario',
      ),
      () => asignaciones.quitar(idAsignacion: id),
      () => asignaciones.faltas(),
      () => reportes.vistoBueno(idReporte: id, confirmado: true),
      () => reportes.aprobar(idReporte: id, confirmado: true),
      () => asignaciones.historial((
        desde: null,
        hasta: null,
        estado: null,
        pagina: 1,
        tamano: 20,
      )),
      () => planillas.pendientesFirma(loteHex(2026, 10)),
      () => planillas.ejecutarLote(2026, 10),
      () => planillas.anularLote(id, 'x'),
      () => configuracion.asignarAprobador(
        HexAprobadorEntity(codEmpleadoAprobador: id, nivel: 1),
      ),
      () => configuracion.cerrarAprobador(id),
      () => configuracion.catalogoParametros(),
      () => reportes.jornadasPasadas(),
      () => reportes.crearReportePasado(
        HexReportePasadoEntity(
          codEmpleado: id,
          fechaJornada: DateTime(2026, 11, 2),
          inicio: DateTime(2026, 11, 2, 18),
          fin: DateTime(2026, 11, 2, 20),
          observacion: 'x',
        ),
      ),
      () => configuracion.dejarDeUsarParametro(id, DateTime(2026, 11, 10)),
      () => configuracion.historial((
        entidad: 'APROBADOR',
        idRegistro: id,
        desde: null,
        hasta: null,
        pagina: 1,
        tamano: 20,
      )),
    ];
    const prohibidas = {
      'audUsuario',
      'codUsuario',
      'codEmpleadoActor',
      'esGestion',
      'tipoUsuario',
    };

    for (final llamar in llamadas) {
      await llamar();
      final claves = cable.cuerpo?.keys.toSet() ?? <String>{};
      expect(claves.intersection(prohibidas), isEmpty, reason: '$claves');
    }
  });
}

const FiltroReportesHex _sinFiltro = (
  desde: null,
  hasta: null,
  estado: null,
  pagina: 1,
  tamano: 20,
);

/// Las 66 rutas de `docs/contrato_api_horas_extras.md` (D36 suma tramos;
/// D37 a D40, hoy, asignación, lote y período de comida; la adenda, faltas).
const _rutasDelContrato = <String>[
  '/horas-extras/leyenda-codigos',
  '/horas-extras/reporte/mis-reportes',
  '/horas-extras/reporte/marcar',
  '/horas-extras/reporte/actualizar',
  '/horas-extras/reporte/anular',
  '/horas-extras/reporte/detalle',
  '/horas-extras/reporte/lineas',
  '/horas-extras/reporte/tramos',
  '/horas-extras/reporte/historial',
  '/horas-extras/reporte/requisitos-marca',
  '/horas-extras/aprobador/mis-roles',
  '/horas-extras/revision/bandeja',
  '/horas-extras/revision/corregir-hora',
  '/horas-extras/revision/visto-bueno',
  '/horas-extras/revision/rechazar',
  '/horas-extras/aprobacion/bandeja',
  '/horas-extras/aprobacion/aprobar',
  '/horas-extras/aprobacion/aprobar-grupo',
  '/horas-extras/aprobacion/rechazar',
  '/horas-extras/observacion/bandeja',
  '/horas-extras/planilla/listar',
  '/horas-extras/planilla/pendientes',
  '/horas-extras/planilla/vista-previa',
  '/horas-extras/planilla/vista-previa-lineas',
  '/horas-extras/planilla/avisos',
  '/horas-extras/planilla/ejecutar',
  '/horas-extras/planilla/empleados',
  '/horas-extras/planilla/detalle',
  '/horas-extras/planilla/leyenda',
  '/horas-extras/planilla/pdf',
  '/horas-extras/planilla/anular',
  '/horas-extras/parametro/listar',
  '/horas-extras/parametro/vigencia',
  '/horas-extras/parametro/editar-leyenda',
  '/horas-extras/parametro/eliminar',
  '/horas-extras/parametro/catalogo',
  '/horas-extras/parametro/dejar-de-usar',
  '/horas-extras/tramo/listar',
  '/horas-extras/tramo/vigencia',
  '/horas-extras/tramo/editar-leyenda',
  '/horas-extras/tramo/eliminar',
  '/horas-extras/comida/listar',
  '/horas-extras/comida/vigencia',
  '/horas-extras/comida/editar-leyenda',
  '/horas-extras/comida/eliminar',
  '/horas-extras/aprobador/listar',
  '/horas-extras/aprobador/asignar',
  '/horas-extras/aprobador/cerrar',
  '/horas-extras/aprobador/eliminar',
  '/horas-extras/aprobador/rama',
  '/horas-extras/aprobador/encargados',
  '/horas-extras/configuracion/historial',
  '/horas-extras/reporte/hoy',
  '/horas-extras/asignacion/asignables',
  '/horas-extras/asignacion/asignar',
  '/horas-extras/asignacion/quitar',
  '/horas-extras/asignacion/historial',
  '/horas-extras/planilla/pendientes-firma',
  '/horas-extras/planilla/lote',
  '/horas-extras/planilla/anular-lote',
  '/horas-extras/comida/periodo',
  '/horas-extras/asignacion/faltas',
  '/horas-extras/tramo/mapa',
  '/horas-extras/simulador/jornada',
  '/horas-extras/revision/pasados',
  '/horas-extras/revision/crear-pasado',
];

/// Responde con lo último indicado en [responde] y guarda lo que recibió.
class _Cable implements HttpClientAdapter {
  ({int estado, Object? cuerpo, String tipo}) _respuesta = (
    estado: 200,
    cuerpo: null,
    tipo: Headers.jsonContentType,
  );
  String? ruta;
  Map<String, dynamic>? cuerpo;

  /// Un [cuerpo] de texto viaja tal cual; cualquier otro, como JSON.
  void responde(
    int estado,
    Object? cuerpo, {
    String tipo = Headers.jsonContentType,
  }) => _respuesta = (estado: estado, cuerpo: cuerpo, tipo: tipo);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final b in requestStream) {
        bytes.addAll(b);
      }
    }
    ruta = options.path;
    cuerpo =
        bytes.isEmpty
            ? null
            : Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
    final r = _respuesta;
    final texto = switch (r.cuerpo) {
      null => '',
      final String s => s,
      final otro => jsonEncode(otro),
    };
    return ResponseBody.fromString(
      texto,
      r.estado,
      headers: {
        Headers.contentTypeHeader: [r.tipo],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
