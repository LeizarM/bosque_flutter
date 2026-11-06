import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/data/models/hex_aprobador_model.dart';
import 'package:bosque_flutter/data/models/hex_asignable_model.dart';
import 'package:bosque_flutter/data/models/hex_asignacion_model.dart';
import 'package:bosque_flutter/data/models/hex_vista_marcacion_model.dart';
import 'package:bosque_flutter/data/models/hex_encargado_opcion_model.dart';
import 'package:bosque_flutter/data/models/hex_comida_model.dart';
import 'package:bosque_flutter/data/models/hex_configuracion_evento_model.dart';
import 'package:bosque_flutter/data/models/hex_leyenda_codigos_model.dart';
import 'package:bosque_flutter/data/models/hex_parametro_clave_model.dart';
import 'package:bosque_flutter/data/models/hex_parametro_model.dart';
import 'package:bosque_flutter/data/models/hex_planilla_anexo_model.dart';
import 'package:bosque_flutter/data/models/hex_planilla_detalle_model.dart';
import 'package:bosque_flutter/data/models/hex_planilla_empleado_model.dart';
import 'package:bosque_flutter/data/models/hex_planilla_model.dart';
import 'package:bosque_flutter/data/models/hex_planilla_previa_model.dart';
import 'package:bosque_flutter/data/models/hex_rama_empleado_model.dart';
import 'package:bosque_flutter/data/models/hex_reporte_evento_model.dart';
import 'package:bosque_flutter/data/models/hex_reporte_linea_model.dart';
import 'package:bosque_flutter/data/models/hex_reporte_model.dart';
import 'package:bosque_flutter/data/models/hex_requisito_marca_model.dart';
import 'package:bosque_flutter/data/models/hex_roles_model.dart';
import 'package:bosque_flutter/data/models/hex_tramo_model.dart';
import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';

/// Modelos de Horas Extras: leen los alias exactos de cada SP (incluidos
/// `hHS`, `cD`, `mOtros`, `hOtros`) y mandan solo los parámetros del SP.
void main() {
  // Identidad que el backend toma del token: jamás sale en un cuerpo.
  const identidad = {
    'audUsuario',
    'codUsuario',
    'codEmpleadoActor',
    'esGestion',
    'tipoUsuario',
  };

  Map<String, dynamic> reporteJson() => {
    'idReporte': 501,
    'codEmpleado': 77,
    'nombreEmpleado': 'Ana Rojas',
    'fechaJornada': '2026-10-23',
    'tipo': 'DESPUES',
    'tipoTexto': 'Después del horario',
    'tipoDia': 'HABIL',
    'tipoDiaTexto': 'Día hábil',
    'codSucursal': 3,
    'nombreSucursal': 'Planta Norte',
    'inicio': '2026-10-23 18:00:00',
    'fin': '2026-10-23 22:30:00',
    'origenInicio': 'HORARIO',
    'origenFin': null,
    'motivo': 'Cierre de lote',
    'horasPagables': 4.5,
    'montoHoras': 120.5,
    'montoComidas': 30,
    'montoTotal': 150.5,
    'comidas': 'C,DC',
    'costoHora': 12.5,
    'esProvisional': 1,
    'estado': 'REPORTADO',
    'estadoTexto': 'Reportado',
    'esEditado': false,
    'avisoBiometrico': true,
    'puedeAnular': true,
    'puedeEditarMotivo': true,
    'puedeEditarHora': false,
    'puedeVistoBueno': false,
    'puedeAprobar': false,
    'puedeRechazar': true,
    'totalFilas': 37,
  };

  group('Reporte', () {
    test('Reporte.fromJson lee los alias del SP', () {
      final e = HexReporteModel.fromJson(reporteJson()).toEntity();

      expect(e.idReporte, BigInt.from(501));
      expect(e.codEmpleado, BigInt.from(77));
      expect(e.codSucursal, BigInt.from(3));
      expect(e.nombreEmpleado, 'Ana Rojas');
      expect(e.fechaJornada, DateTime(2026, 10, 23));
      expect(e.inicio, DateTime(2026, 10, 23, 18));
      expect(e.fin, DateTime(2026, 10, 23, 22, 30));
      expect(e.origenInicio, 'HORARIO');
      expect(e.origenFin, isNull);
      expect(e.montoComidas, 30.0);
      expect(e.costoHora, 12.5);
      expect(e.esProvisional, isTrue);
      expect(e.avisoBiometrico, isTrue);
      expect(e.puedeAnular, isTrue);
      expect(e.puedeEditarHora, isFalse);
      expect(e.totalFilas, 37);
    });

    test('ignora las claves de compensación si el SP aún las manda', () {
      final j =
          reporteJson()
            ..['compensacion'] = 'VACACIONES'
            ..['compensacionTexto'] = 'Compensa con vacaciones'
            ..['diasVacacion'] = 0.75;
      final e = HexReporteModel.fromJson(j).toEntity();

      expect(e.idReporte, BigInt.from(501));
      expect(e.montoTotal, 150.5);
    });

    test('Reporte trae de quién espera y el motivo del rechazo (D28.2)', () {
      final j =
          reporteJson()
            ..['estado'] = 'RECHAZADO'
            ..['textoPendiente'] = 'Rechazado por Luis Peña'
            ..['motivoRechazo'] = 'La salida real fue a las 18:05.';
      final e = HexReporteModel.fromJson(j).toEntity();

      expect(e.textoPendiente, 'Rechazado por Luis Peña');
      expect(e.motivoRechazo, 'La salida real fue a las 18:05.');
    });

    test('sin las columnas nuevas, o vacías, quedan nulas', () {
      final sin = HexReporteModel.fromJson(reporteJson()).toEntity();
      expect(sin.textoPendiente, isNull);
      expect(sin.motivoRechazo, isNull);

      final vacias =
          HexReporteModel.fromJson(
            reporteJson()
              ..['textoPendiente'] = '  '
              ..['motivoRechazo'] = null,
          ).toEntity();
      expect(vacias.textoPendiente, isNull);
      expect(vacias.motivoRechazo, isNull);
    });

    test('Reporte trae dónde marcó con la app (D30)', () {
      final e =
          HexReporteModel.fromJson(
            reporteJson()
              ..['latInicio'] = -16.500123
              ..['lonInicio'] = -68.150456
              ..['precisionInicio'] = 12.5
              ..['latFin'] = -16.51
              ..['lonFin'] = -68.16
              ..['precisionFin'] = 8,
          ).toEntity();

      expect(e.latInicio, -16.500123);
      expect(e.lonInicio, -68.150456);
      expect(e.precisionInicio, 12.5);
      expect(e.latFin, -16.51);
      expect(e.lonFin, -68.16);
      expect(e.precisionFin, 8.0);
      expect(e.tieneUbicacionInicio, isTrue);
      expect(e.tieneUbicacionFin, isTrue);
      expect(e.tieneUbicacion, isTrue);
    });

    test('Reporte trae la hora de la marca por app (D31)', () {
      final e =
          HexReporteModel.fromJson(
            reporteJson()
              ..['origenInicio'] = 'BIOMETRICO'
              ..['inicioApp'] = '2026-10-23 18:05:00'
              ..['finApp'] = '2026-10-23T22:10:00.000',
          ).toEntity();

      expect(e.inicioApp, DateTime(2026, 10, 23, 18, 5));
      expect(e.finApp, DateTime(2026, 10, 23, 22, 10));
      // La hora efectiva del reporte no se toca.
      expect(e.inicio, DateTime(2026, 10, 23, 18));
      expect(e.origenInicio, 'BIOMETRICO');
    });

    test('sin la hora de app, o con basura, las horas de app quedan nulas', () {
      final sin = HexReporteModel.fromJson(reporteJson()).toEntity();
      expect(sin.inicioApp, isNull);
      expect(sin.finApp, isNull);

      final mal =
          HexReporteModel.fromJson(
            reporteJson()
              ..['inicioApp'] = null
              ..['finApp'] = 'no es una fecha',
          ).toEntity();
      expect(mal.inicioApp, isNull);
      expect(mal.finApp, isNull);
    });

    test(
      'la ubicación tolera número, texto y nulo (BigDecimal del backend)',
      () {
        final e =
            HexReporteModel.fromJson(
              reporteJson()
                ..['latInicio'] = '-16.500123'
                ..['lonInicio'] = ' -68.150456 '
                ..['precisionInicio'] = 12
                ..['latFin'] = null
                ..['lonFin'] = 'no es un número'
                ..['precisionFin'] = '',
            ).toEntity();

        expect(e.latInicio, -16.500123);
        expect(e.lonInicio, -68.150456);
        expect(e.precisionInicio, 12.0);
        expect(e.latFin, isNull);
        expect(e.lonFin, isNull);
        expect(e.precisionFin, isNull);
        expect(e.tieneUbicacionInicio, isTrue);
        expect(e.tieneUbicacionFin, isFalse);
      },
    );

    test(
      'sin las columnas de ubicación, o con una a medias, no hay ubicación',
      () {
        final sin = HexReporteModel.fromJson(reporteJson()).toEntity();
        expect(sin.latInicio, isNull);
        expect(sin.lonFin, isNull);
        expect(sin.tieneUbicacion, isFalse);

        // Un par necesita latitud y longitud.
        final mitad =
            HexReporteModel.fromJson(
              reporteJson()
                ..['latInicio'] = -16.5
                ..['lonFin'] = -68.1,
            ).toEntity();
        expect(mitad.tieneUbicacionInicio, isFalse);
        expect(mitad.tieneUbicacionFin, isFalse);
        expect(mitad.tieneUbicacion, isFalse);
      },
    );

    test(
      'una coordenada fuera de rango o no finita no cuenta como ubicación',
      () {
        for (final malo in [91, -91, double.nan, double.infinity]) {
          final e =
              HexReporteModel.fromJson(
                reporteJson()
                  ..['latInicio'] = malo
                  ..['lonInicio'] = -68.1,
              ).toEntity();
          expect(e.tieneUbicacionInicio, isFalse, reason: '$malo');
        }
        final lon =
            HexReporteModel.fromJson(
              reporteJson()
                ..['latFin'] = -16.5
                ..['lonFin'] = 181,
            ).toEntity();
        expect(lon.tieneUbicacionFin, isFalse);
      },
    );

    test('Reporte de J trae el encargado', () {
      final j =
          reporteJson()
            ..['codEncargado'] = 12
            ..['nombreEncargado'] = 'Luis Peña';
      final e = HexReporteModel.fromJson(j).toEntity();

      expect(e.codEncargado, BigInt.from(12));
      expect(e.nombreEncargado, 'Luis Peña');
    });

    test('fuera de J el encargado es nulo', () {
      final e = HexReporteModel.fromJson(reporteJson()).toEntity();

      expect(e.codEncargado, isNull);
      expect(e.nombreEncargado, isNull);
    });

    test('Reporte.fromJson tolera un JSON vacío con valores neutros', () {
      final e = HexReporteModel.fromJson({}).toEntity();

      expect(e.idReporte, isNull);
      expect(e.nombreEmpleado, '');
      expect(e.inicio, isNull);
      expect(e.montoTotal, isNull);
      // D38: sin dinero a la vista el costo hora también llega nulo.
      expect(e.costoHora, isNull);
      expect(e.puedeAprobar, isFalse);
      expect(e.puedeVerDetalle, isFalse);
      expect(e.verMontos, isFalse);
      expect(e.verHistorial, isFalse);
      expect(e.totalFilas, 0);
    });

    test('cada monto, hora y bandera sale de su propia clave', () {
      // Un valor distinto por clave: cambiar una clave por otra no pasa.
      final e =
          HexReporteModel.fromJson({
            ...reporteJson(),
            'montoHoras': 101.11,
            'montoComidas': 202.22,
            'montoTotal': 303.33,
            'horasPagables': 4.44,
            'costoHora': 6.66,
          }).toEntity();

      expect(e.montoHoras, 101.11);
      expect(e.montoComidas, 202.22);
      expect(e.montoTotal, 303.33);
      expect(e.horasPagables, 4.44);
      expect(e.costoHora, 6.66);
    });

    test('cada bandera puede* sale de su propia clave', () {
      const banderas = [
        'puedeAnular',
        'puedeEditarMotivo',
        'puedeEditarHora',
        'puedeVistoBueno',
        'puedeAprobar',
        'puedeRechazar',
      ];
      for (final activa in banderas) {
        final j = reporteJson();
        for (final b in banderas) {
          j[b] = b == activa;
        }
        final e = HexReporteModel.fromJson(j).toEntity();

        final prendidas = {
          'puedeAnular': e.puedeAnular,
          'puedeEditarMotivo': e.puedeEditarMotivo,
          'puedeEditarHora': e.puedeEditarHora,
          'puedeVistoBueno': e.puedeVistoBueno,
          'puedeAprobar': e.puedeAprobar,
          'puedeRechazar': e.puedeRechazar,
        };
        expect(prendidas.entries.where((x) => x.value).map((x) => x.key), [
          activa,
        ]);
      }
    });
  });

  test('ReporteLinea lee tramo y comida con sus montos', () {
    final e =
        HexReporteLineaModel.fromJson({
          'idReporte': 501,
          'concepto': 'TRAMO',
          'codigo': 'H50',
          'leyenda': 'Hora al 50%',
          'minutos': 90,
          'cantidad': 1.5,
          'multiplicador': 1.5,
          'valorUnitario': 12.5,
          'monto': 28.125,
        }).toEntity();

    expect(e.idReporte, BigInt.from(501));
    expect(e.concepto, 'TRAMO');
    expect(e.minutos, 90);
    expect(e.multiplicador, 1.5);
    expect(e.monto, 28.125);
  });

  test('ReporteLinea de comida no trae minutos ni multiplicador', () {
    final e =
        HexReporteLineaModel.fromJson({
          'idReporte': 501,
          'concepto': 'COMIDA',
          'codigo': 'C',
          'leyenda': 'Cena',
          'minutos': null,
          'cantidad': 1,
          'multiplicador': null,
          'valorUnitario': 15,
          'monto': 15,
        }).toEntity();

    expect(e.minutos, isNull);
    expect(e.multiplicador, isNull);
    expect(e.cantidad, 1.0);
  });

  test('ReporteEvento lee el actor y la hora del evento', () {
    final e =
        HexReporteEventoModel.fromJson({
          'idEvento': 9,
          'tipo': 'EDICION',
          'tipoTexto': 'Hora corregida',
          'codEmpleadoActor': 12,
          'nombreActor': 'Luis Peña',
          'valorAnterior': '18:00',
          'valorNuevo': '18:30',
          'observacion': null,
          'fecha': '2026-10-24 08:15:00',
        }).toEntity();

    expect(e.idEvento, BigInt.from(9));
    expect(e.codEmpleadoActor, BigInt.from(12));
    expect(e.valorNuevo, '18:30');
    expect(e.observacion, isNull);
    expect(e.fecha, DateTime(2026, 10, 24, 8, 15));
  });

  group('D37 a D39', () {
    test('Reporte lee las banderas de visibilidad de D38', () {
      final e =
          HexReporteModel.fromJson({
            'puedeVerDetalle': 1,
            'verMontos': 0,
            'verHistorial': 'true',
            'montoTotal': null,
            'costoHora': null,
          }).toEntity();
      expect(e.puedeVerDetalle, isTrue);
      expect(e.verMontos, isFalse);
      expect(e.verHistorial, isTrue);
      expect(e.montoTotal, isNull);
      expect(e.costoHora, isNull);
    });

    test('ReporteLinea del encargado llega sin dinero (nulos)', () {
      final l =
          HexReporteLineaModel.fromJson({
            'concepto': 'TRAMO',
            'codigo': 'H50',
            'cantidad': 1.5,
            'valorUnitario': null,
            'monto': null,
          }).toEntity();
      expect(l.valorUnitario, isNull);
      expect(l.monto, isNull);
      expect(l.cantidad, 1.5);
    });

    test('VistaMarcacion lee banderas, textos y fechas de reporte/hoy', () {
      final v =
          HexVistaMarcacionModel.fromJson({
            'vistaHabilitada': 0,
            'textoVista': 'Tu encargado no te asignó horas extra para hoy.',
            'puedeMarcarEntrada': 0,
            'textoMarcarEntrada': 'Sin asignación.',
            'puedeMarcarSalida': 0,
            'textoMarcarSalida': 'Sin asignación.',
            'horaLimiteSalida': '2026-11-06 06:00:00',
            'motivoAsignacion': null,
          }).toEntity();
      expect(v.vistaHabilitada, isFalse);
      expect(v.textoVista, 'Tu encargado no te asignó horas extra para hoy.');
      expect(v.puedeMarcarSalida, isFalse);
      expect(v.horaLimiteSalida, DateTime(2026, 11, 6, 6));
      expect(v.idAsignacion, isNull);
      expect(v.motivoAsignacion, isNull);
      expect(
        HexVistaMarcacionModel.fromJson({
          'motivoAsignacion': 'Descarga de contenedor',
        }).toEntity().motivoAsignacion,
        'Descarga de contenedor',
      );
    });

    test('Asignable y Asignacion leen las columnas del contrato', () {
      final a =
          HexAsignableModel.fromJson({
            'codEmpleado': 191,
            'nombreEmpleado': 'APAZA',
            'fechaJornada': '2026-11-07',
            'idAsignacion': 12,
            'estaAsignado': 1,
            'cantidadReportes': 2,
            'tipoAviso': 'SABADO',
            'aviso': 'A APAZA no le toca trabajar el sábado 07/11/2026',
            'puedeAsignar': 0,
            'puedeQuitar': 1,
            'textoEstado': 'Asignado',
            'motivo': 'Inventario de fin de mes',
          }).toEntity();
      expect(a.codEmpleado, BigInt.from(191));
      expect(a.fechaJornada, DateTime(2026, 11, 7));
      expect(a.estaAsignado, isTrue);
      expect(a.cantidadReportes, 2);
      expect(a.puedeAsignar, isFalse);
      expect(a.puedeQuitar, isTrue);
      expect(a.motivo, 'Inventario de fin de mes');

      final h =
          HexAsignacionModel.fromJson({
            'idAsignacion': 12,
            'estado': 'QUITADA',
            'estadoTexto': 'Quitada',
            'fechaAsignacion': '2026-11-04 17:30:00',
            'fechaQuitada': '2026-11-05 08:00:00',
            'nombreQuita': 'ROJAS',
            'puedeQuitar': 0,
            'totalFilas': 41,
            'motivo': 'Descarga de contenedor',
          }).toEntity();
      expect(h.estado, 'QUITADA');
      expect(h.motivo, 'Descarga de contenedor');
      expect(h.fechaQuitada, DateTime(2026, 11, 5, 8));
      expect(h.totalFilas, 41);
    });

    test('planilla: idLote, sucursal en R, A, P y la firma pendiente', () {
      expect(
        HexPlanillaModel.fromJson({'idLote': 7}).toEntity().idLote,
        BigInt.from(7),
      );
      expect(HexPlanillaModel.fromJson({}).toEntity().idLote, isNull);

      final r =
          HexPlanillaEmpleadoModel.fromJson({
            'nombreArea': null,
            'idPlanilla': 3,
            'codSucursal': 23,
            'nombreSucursal': 'CENTRAL',
            'ordenSucursal': 2,
          }).toEntity();
      expect(r.nombreArea, isNull);
      expect(r.codSucursal, BigInt.from(23));
      expect(r.ordenSucursal, 2);

      final d =
          HexPlanillaDetalleModel.fromJson({
            'codSucursal': 23,
            'nombreSucursal': 'CENTRAL',
          }).toEntity();
      expect(d.nombreSucursal, 'CENTRAL');

      final p =
          HexPrevistaEmpleadoModel.fromJson({
            'codEmpresa': 1,
            'codSucursal': 23,
            'nombreSucursal': 'CENTRAL',
          }).toEntity();
      expect(p.codEmpresa, BigInt.one);
      expect(p.nombreSucursal, 'CENTRAL');

      final f =
          HexPlanillaFirmaModel.fromJson({
            'idReporte': 5,
            'estado': 'VISTO_BUENO',
            'debeFirmar': 'ALVARO',
            'textoPendiente': 'Espera la aprobación de ALVARO',
          }).toEntity();
      expect(f.estado, 'VISTO_BUENO');
      expect(f.debeFirmar, 'ALVARO');
    });
  });

  group('ConfiguracionEvento', () {
    test('lee las columnas del contrato con los textos del SP', () {
      final e =
          HexConfiguracionEventoModel.fromJson({
            'idEvento': 31,
            'entidad': 'COMIDA',
            'entidadTexto': 'Comida',
            'idRegistro': 3,
            'descripcion': 'C · Cena',
            'accion': 'U',
            'accionTexto': 'Leyenda editada',
            'campo': 'leyendaDoble',
            'campoTexto': 'Leyenda doble',
            'valorAnterior': 'Cena doble',
            'valorNuevo': 'Doble cena',
            'audUsuario': 7,
            'nombreUsuario': 'Salazar Rivera Jorge',
            'audFecha': '2026-10-24 08:15:00',
            'totalFilas': 45,
          }).toEntity();

      expect(e.idEvento, BigInt.from(31));
      expect(e.entidad, 'COMIDA');
      expect(e.entidadTexto, 'Comida');
      expect(e.idRegistro, BigInt.from(3));
      expect(e.descripcion, 'C · Cena');
      expect(e.accion, 'U');
      expect(e.accionTexto, 'Leyenda editada');
      expect(e.campo, 'leyendaDoble');
      expect(e.campoTexto, 'Leyenda doble');
      expect(e.valorAnterior, 'Cena doble');
      expect(e.valorNuevo, 'Doble cena');
      expect(e.audUsuario, BigInt.from(7));
      expect(e.nombreUsuario, 'Salazar Rivera Jorge');
      expect(e.audFecha, DateTime(2026, 10, 24, 8, 15));
      expect(e.totalFilas, 45);
    });

    test('un cambio de la fila completa hecho por script deja nulos', () {
      final e =
          HexConfiguracionEventoModel.fromJson({
            'idEvento': 1,
            'entidad': 'PARAMETRO',
            'entidadTexto': 'Parámetro',
            'idRegistro': 1,
            'accion': 'N',
            'accionTexto': 'Nueva vigencia',
            'campo': null,
            'valorNuevo': '240',
            'audUsuario': null,
            'nombreUsuario': null,
            'audFecha': '2026-01-01 00:00:00',
            'totalFilas': 1,
          }).toEntity();

      expect(e.campo, isNull);
      expect(e.campoTexto, isNull);
      expect(e.valorAnterior, isNull);
      expect(e.descripcion, isNull);
      expect(e.audUsuario, isNull);
      expect(e.nombreUsuario, isNull);
      expect(HexConfiguracionEventoModel.fromEntity(e).toEntity(), same(e));
    });
  });

  test('Roles lee las banderas y las sucursales', () {
    final e =
        HexRolesModel.fromJson({
          'esEncargado': 1,
          'esJefe': false,
          'sucursales': '1,4',
        }).toEntity();

    expect(e.esEncargado, isTrue);
    expect(e.esJefe, isFalse);
    expect(e.esObservador, isFalse);
    expect(e.sucursales, '1,4');
    // D45: la bandera del observador viene del SP.
    expect(
      HexRolesModel.fromJson({'esObservador': 1}).toEntity().esObservador,
      isTrue,
    );
  });

  group('Parámetro', () {
    Map<String, dynamic> parametroJson() => {
      'idParametro': 4,
      'clave': 'DIVISOR_COSTO_HORA',
      'valorNumero': 240,
      'valorFecha': null,
      'leyenda': 'Divisor del costo hora',
      'vigenteDesde': '2026-01-01',
      'vigenteHasta': null,
      'esVigente': 1,
    };

    test('Parametro.fromJson lee número, vigencia y bandera', () {
      final e = HexParametroModel.fromJson(parametroJson()).toEntity();

      expect(e.idParametro, BigInt.from(4));
      expect(e.valorNumero, 240.0);
      expect(e.valorFecha, isNull);
      expect(e.vigenteDesde, DateTime(2026));
      expect(e.vigenteHasta, isNull);
      expect(e.esVigente, isTrue);
    });

    test('Parametro numérico no manda valorFecha', () {
      final e = HexParametroModel.fromJson(parametroJson()).toEntity();
      final j = HexParametroModel.fromEntity(e).toJson();

      expect(j.containsKey('valorFecha'), isFalse);
      expect(j['valorNumero'], 240.0);
      expect(j['idParametro'], 4);
      expect(j['idParametro'], isA<int>());
      expect(j['vigenteDesde'], '2026-01-01');
    });

    test('Parametro de fecha manda valorFecha como DATE y no valorNumero', () {
      final e = HexParametroEntity(
        clave: 'INICIO_PERIODO',
        valorFecha: DateTime(2026, 11, 1),
        leyenda: 'Inicio',
        vigenteDesde: DateTime(2026, 11, 1),
      );
      final j = HexParametroModel.fromEntity(e).toJson();

      expect(j['valorFecha'], '2026-11-01');
      expect(j.containsKey('valorNumero'), isFalse);
      expect(j.containsKey('idParametro'), isFalse);
    });

    test('Parametro.toJson manda solo los parámetros del SP', () {
      final e = HexParametroModel.fromJson(parametroJson()).toEntity();

      expect(HexParametroModel.fromEntity(e).toJson().keys.toSet(), {
        'idParametro',
        'clave',
        'valorNumero',
        'leyenda',
        'vigenteDesde',
      });
    });

    test('copyWith cambia lo editado y conserva el resto', () {
      final base = HexParametroModel.fromJson(parametroJson()).toEntity();
      final nuevo = base.copyWith(
        valorNumero: 250,
        vigenteDesde: DateTime(2026, 12),
      );

      expect(nuevo.valorNumero, 250.0);
      expect(nuevo.vigenteDesde, DateTime(2026, 12));
      expect(nuevo.clave, 'DIVISOR_COSTO_HORA');
      expect(nuevo.leyenda, 'Divisor del costo hora');
    });

    test('nuevaVigencia conserva el valor y suelta la fila anterior', () {
      final j = parametroJson()..['vigenteHasta'] = '2026-06-30';
      final base = HexParametroModel.fromJson(j).toEntity();
      final nuevo = base.nuevaVigencia();

      expect(nuevo.idParametro, isNull);
      expect(nuevo.vigenteHasta, isNull);
      expect(nuevo.esVigente, isFalse);
      expect(nuevo.clave, 'DIVISOR_COSTO_HORA');
      expect(nuevo.valorNumero, 240.0);
      expect(nuevo.leyenda, 'Divisor del costo hora');
    });

    test('la vigencia nueva no manda el id de la fila anterior', () {
      final base = HexParametroModel.fromJson(parametroJson()).toEntity();
      final nuevo = base.nuevaVigencia().copyWith(
        valorNumero: 250,
        vigenteDesde: DateTime(2026, 12),
      );
      final cuerpo = HexParametroModel.fromEntity(nuevo).toJson();

      expect(cuerpo.containsKey('idParametro'), isFalse);
      expect(cuerpo['valorNumero'], 250.0);
      expect(cuerpo['vigenteDesde'], '2026-12-01');
    });

    test('lee los textos del catálogo y las banderas de D33', () {
      final j =
          parametroJson()
            ..['clave'] = 'MINUTOS_ALERTA_BIOMETRICO'
            ..['nombre'] = 'Tolerancia entre la app y el biométrico'
            ..['descripcion'] = 'Diferencia máxima aceptada.'
            ..['siFalta'] = 'No se comparan la app y el biométrico.'
            ..['valorTexto'] = '15 minutos'
            ..['ejemplo'] = 'Con 15: el encargado ve un aviso.'
            ..['obligatorio'] = 0
            ..['puedeDejarDeUsar'] = 1
            ..['estadoVigencia'] = 'SIN_USO';
      final e = HexParametroModel.fromJson(j).toEntity();

      expect(e.nombre, 'Tolerancia entre la app y el biométrico');
      expect(e.descripcion, 'Diferencia máxima aceptada.');
      expect(e.siFalta, 'No se comparan la app y el biométrico.');
      expect(e.valorTexto, '15 minutos');
      expect(e.ejemplo, 'Con 15: el encargado ve un aviso.');
      expect(e.obligatorio, isFalse);
      expect(e.puedeDejarDeUsar, isTrue);
      expect(e.estadoVigencia, 'SIN_USO');
      // copyWith conserva los textos; toJson sigue sin mandarlos.
      expect(e.copyWith(leyenda: 'x').ejemplo, e.ejemplo);
      expect(HexParametroModel.fromEntity(e).toJson().keys.toSet(), {
        'idParametro',
        'clave',
        'valorNumero',
        'leyenda',
        'vigenteDesde',
      });
    });

    test('sin los campos de D33 quedan nulos y no se puede dejar de usar', () {
      final e = HexParametroModel.fromJson(parametroJson()).toEntity();

      expect(e.nombre, isNull);
      expect(e.valorTexto, isNull);
      expect(e.ejemplo, isNull);
      expect(e.obligatorio, isNull);
      expect(e.puedeDejarDeUsar, isFalse);
    });

    test('ParametroClave.fromJson lee el catálogo y su aviso', () {
      final e =
          HexParametroClaveModel.fromJson({
            'clave': 'FECHA_INICIO_MODULO',
            'nombre': 'Inicio del módulo',
            'tipoValor': 'FECHA',
            'unidad': null,
            'obligatorio': true,
            'descripcion': 'Primera jornada que se puede reportar.',
            'siFalta': 'Nadie puede reportar horas extra.',
            'tieneVigente': 0,
            'aviso': 'Falta «Inicio del módulo»: Registre su valor.',
          }).toEntity();

      expect(e.clave, 'FECHA_INICIO_MODULO');
      expect(e.nombre, 'Inicio del módulo');
      expect(e.tipoValor, 'FECHA');
      expect(e.unidad, isNull);
      expect(e.obligatorio, isTrue);
      expect(e.descripcion, 'Primera jornada que se puede reportar.');
      expect(e.siFalta, 'Nadie puede reportar horas extra.');
      expect(e.tieneVigente, isFalse);
      expect(e.aviso, 'Falta «Inicio del módulo»: Registre su valor.');
      expect(
        HexParametroClaveModel.fromJson({
          'clave': 'X',
          'aviso': '',
        }).entidad.aviso,
        isNull,
      );
    });
  });

  group('Tramo', () {
    Map<String, dynamic> tramoJson() => {
      'idTramo': 11,
      'codigo': 'H50',
      'leyenda': 'Hora al 50%',
      'tipoDia': 'HABIL',
      'horaDesde': '20:01:00',
      'horaHasta': '00:00:00.0000000',
      'multiplicador': 1.5,
      'orden': 2,
      'vigenteDesde': '2026-01-01',
      'vigenteHasta': null,
      'audUsuario': 34,
      'audFecha': '2026-01-01 09:00:00',
      'esVigente': true,
    };

    test('Tramo.fromJson normaliza las horas a HH:mm:ss', () {
      final e = HexTramoModel.fromJson(tramoJson()).toEntity();

      expect(e.idTramo, BigInt.from(11));
      expect(e.horaDesde, '20:01:00');
      expect(e.horaHasta, '00:00:00');
      expect(e.multiplicador, 1.5);
      expect(e.orden, 2);
      expect(e.audUsuario, BigInt.from(34));
      expect(e.audFecha, DateTime(2026, 1, 1, 9));
      expect(e.esVigente, isTrue);
    });

    test('Tramo.toJson manda horas HH:mm:ss y no manda auditoría', () {
      final e = HexTramoModel.fromJson(tramoJson()).toEntity();
      final j = HexTramoModel.fromEntity(e).toJson();

      expect(j['horaDesde'], '20:01:00');
      expect(j['horaHasta'], '00:00:00');
      expect(j['idTramo'], isA<int>());
      expect(j['vigenteDesde'], '2026-01-01');
      expect(j.keys.toSet(), {
        'idTramo',
        'codigo',
        'leyenda',
        'tipoDia',
        'horaDesde',
        'horaHasta',
        'multiplicador',
        'orden',
        'vigenteDesde',
      });
      expect(j.keys, isNot(contains('audUsuario')));
      expect(j.keys, isNot(contains('audFecha')));
      expect(j.keys, isNot(contains('esVigente')));
    });

    test('Tramo.toJson completa HH:mm de un selector de hora', () {
      final e = HexTramoEntity(
        codigo: 'HS',
        leyenda: 'Hora simple',
        tipoDia: 'HABIL',
        horaDesde: '18:00',
        horaHasta: '20:00',
        multiplicador: 1,
        orden: 1,
        vigenteDesde: DateTime(2026, 11),
      );
      final j = HexTramoModel.fromEntity(e).toJson();

      expect(j['horaDesde'], '18:00:00');
      expect(j['horaHasta'], '20:00:00');
    });

    test('Tramo nuevo sin orden no manda la clave y lo asigna el SP', () {
      final e = HexTramoEntity(
        codigo: 'HS',
        leyenda: 'Hora simple',
        tipoDia: 'HABIL',
        horaDesde: '18:00',
        horaHasta: '20:00',
        multiplicador: 1,
        vigenteDesde: DateTime(2026, 11),
      );

      expect(e.orden, isNull);
      expect(
        HexTramoModel.fromEntity(e).toJson().containsKey('orden'),
        isFalse,
      );
    });

    test('Tramo con orden guardado manda el orden', () {
      final e = HexTramoModel.fromJson(tramoJson()).toEntity();

      expect(HexTramoModel.fromEntity(e).toJson()['orden'], 2);
    });

    test('Tramo.fromJson sin orden lo deja nulo', () {
      final e = HexTramoModel.fromJson(tramoJson()..['orden'] = null);

      expect(e.toEntity().orden, isNull);
    });

    test('copyWith cambia lo editado y conserva el resto', () {
      final base = HexTramoModel.fromJson(tramoJson()).toEntity();
      final nuevo = base.copyWith(
        multiplicador: 1.75,
        vigenteDesde: DateTime(2026, 12),
      );

      expect(nuevo.multiplicador, 1.75);
      expect(nuevo.vigenteDesde, DateTime(2026, 12));
      expect(nuevo.codigo, 'H50');
      expect(nuevo.horaHasta, '00:00:00');
      expect(nuevo.orden, 2);
    });

    test('nuevaVigencia conserva los valores y suelta la fila anterior', () {
      final j = tramoJson()..['vigenteHasta'] = '2026-06-30';
      final nuevo = HexTramoModel.fromJson(j).toEntity().nuevaVigencia();

      expect(nuevo.idTramo, isNull);
      expect(nuevo.vigenteHasta, isNull);
      expect(nuevo.esVigente, isFalse);
      expect(nuevo.audUsuario, isNull);
      expect(nuevo.audFecha, isNull);
      expect(nuevo.codigo, 'H50');
      expect(nuevo.horaDesde, '20:01:00');
      expect(nuevo.multiplicador, 1.5);
      expect(nuevo.orden, 2);
    });

    test('la vigencia nueva no manda el id de la fila anterior', () {
      final nuevo = HexTramoModel.fromJson(
        tramoJson(),
      ).toEntity().nuevaVigencia().copyWith(vigenteDesde: DateTime(2026, 12));
      final cuerpo = HexTramoModel.fromEntity(nuevo).toJson();

      expect(cuerpo.containsKey('idTramo'), isFalse);
      expect(cuerpo['vigenteDesde'], '2026-12-01');
    });
  });

  group('Comida', () {
    Map<String, dynamic> comidaJson() => {
      'idComida': 21,
      'codigo': 'C',
      'leyenda': 'Cena',
      'codigoDoble': 'DC',
      'leyendaDoble': 'Doble cena',
      'horaDesde': '20:00:00',
      'horaHasta': '23:59:00',
      'monto': 15,
      'montoDoble': 30.5,
      'activo': 1,
      'orden': 3,
      'vigenteDesde': '2026-01-01',
      'vigenteHasta': '2026-12-31',
      'audUsuario': 34,
      'audFecha': '2026-01-01 09:00:00',
      'esVigente': true,
    };

    test('Comida.fromJson lee códigos, ventana y montos', () {
      final e = HexComidaModel.fromJson(comidaJson()).toEntity();

      expect(e.idComida, BigInt.from(21));
      expect(e.codigoDoble, 'DC');
      expect(e.horaDesde, '20:00:00');
      expect(e.monto, 15.0);
      expect(e.montoDoble, 30.5);
      expect(e.activo, isTrue);
      expect(e.vigenteHasta, DateTime(2026, 12, 31));
    });

    test('Comida.toJson manda solo los parámetros del SP', () {
      final e = HexComidaModel.fromJson(comidaJson()).toEntity();
      final j = HexComidaModel.fromEntity(e).toJson();

      expect(j.keys.toSet(), {
        'idComida',
        'codigo',
        'leyenda',
        'codigoDoble',
        'leyendaDoble',
        'horaDesde',
        'horaHasta',
        'monto',
        'montoDoble',
        'activo',
        'orden',
        'vigenteDesde',
        'conDoble',
      });
      expect(j['activo'], isTrue);
      expect(j['idComida'], isA<int>());
    });

    test(
      'D40: lee conDoble, minutos y textoDuracion; sin columna, con doble',
      () {
        final e =
            HexComidaModel.fromJson({
              ...comidaJson(),
              'conDoble': 0,
              'minutosSimple': 90,
              'minutosDoble': 30,
              'textoDuracion': 'Cena: 1 h 30 min · sin doble cena',
            }).toEntity();
        expect(e.conDoble, isFalse);
        expect(e.minutosSimple, 90);
        expect(e.minutosDoble, 30);
        expect(e.textoDuracion, 'Cena: 1 h 30 min · sin doble cena');

        final j = HexComidaModel.fromEntity(e).toJson();
        expect(j['conDoble'], isFalse);
        expect(j['minutosSimple'], 90);
        expect(j['minutosDoble'], 30);
        expect(j.containsKey('textoDuracion'), isFalse);

        final viejo = HexComidaModel.fromJson(comidaJson()).toEntity();
        expect(viejo.conDoble, isTrue);
        expect(viejo.minutosSimple, isNull);
      },
    );

    test('Comida sin ventana no manda horas', () {
      final j =
          comidaJson()
            ..['horaDesde'] = null
            ..['horaHasta'] = null
            ..['activo'] = false;
      final e = HexComidaModel.fromJson(j).toEntity();
      final cuerpo = HexComidaModel.fromEntity(e).toJson();

      expect(e.horaDesde, isNull);
      expect(cuerpo.containsKey('horaDesde'), isFalse);
      expect(cuerpo.containsKey('horaHasta'), isFalse);
      expect(cuerpo['activo'], isFalse);
    });

    test('una comida nueva nace activa, como en el SP', () {
      const e = HexComidaEntity(codigo: 'A', leyenda: 'Almuerzo');

      expect(e.activo, isTrue);
    });

    test('Comida sin monto no manda monto ni montoDoble', () {
      const e = HexComidaEntity(
        codigo: 'A',
        leyenda: 'Almuerzo',
        codigoDoble: 'DA',
        leyendaDoble: 'Doble almuerzo',
      );
      final cuerpo = HexComidaModel.fromEntity(e).toJson();

      expect(e.monto, isNull);
      expect(e.montoDoble, isNull);
      expect(cuerpo.containsKey('monto'), isFalse);
      expect(cuerpo.containsKey('montoDoble'), isFalse);
    });

    test('Comida con monto cero lo manda: cero no es vacío', () {
      final j =
          comidaJson()
            ..['monto'] = 0
            ..['montoDoble'] = 0;
      final e = HexComidaModel.fromJson(j).toEntity();
      final cuerpo = HexComidaModel.fromEntity(e).toJson();

      expect(cuerpo['monto'], 0.0);
      expect(cuerpo['montoDoble'], 0.0);
    });

    test('Comida.fromJson sin monto lo deja nulo', () {
      final j =
          comidaJson()
            ..['monto'] = null
            ..['montoDoble'] = null;
      final e = HexComidaModel.fromJson(j).toEntity();

      expect(e.monto, isNull);
      expect(e.montoDoble, isNull);
    });

    test('Comida sin orden no manda la clave; con orden guardado, sí', () {
      final sin = HexComidaModel.fromJson(comidaJson()..['orden'] = null);
      final con = HexComidaModel.fromJson(comidaJson());

      expect(sin.toEntity().orden, isNull);
      expect(sin.toJson().containsKey('orden'), isFalse);
      expect(con.toJson()['orden'], 3);
    });

    test('copyWith cambia lo editado y conserva el resto', () {
      final base = HexComidaModel.fromJson(comidaJson()).toEntity();
      final nuevo = base.copyWith(monto: 16, vigenteDesde: DateTime(2027));

      expect(nuevo.monto, 16.0);
      expect(nuevo.vigenteDesde, DateTime(2027));
      expect(nuevo.montoDoble, 30.5);
      expect(nuevo.leyendaDoble, 'Doble cena');
      expect(nuevo.orden, 3);
    });

    test('nuevaVigencia conserva los valores y suelta la fila anterior', () {
      final nuevo =
          HexComidaModel.fromJson(comidaJson()).toEntity().nuevaVigencia();

      expect(nuevo.idComida, isNull);
      expect(nuevo.vigenteHasta, isNull);
      expect(nuevo.esVigente, isFalse);
      expect(nuevo.audUsuario, isNull);
      expect(nuevo.audFecha, isNull);
      expect(nuevo.codigo, 'C');
      expect(nuevo.horaDesde, '20:00:00');
      expect(nuevo.monto, 15.0);
      expect(nuevo.montoDoble, 30.5);
      expect(nuevo.activo, isTrue);
      expect(nuevo.orden, 3);
    });

    test('la vigencia nueva no manda el id de la fila anterior', () {
      final nuevo = HexComidaModel.fromJson(
        comidaJson(),
      ).toEntity().nuevaVigencia().copyWith(vigenteDesde: DateTime(2027));
      final cuerpo = HexComidaModel.fromEntity(nuevo).toJson();

      expect(cuerpo.containsKey('idComida'), isFalse);
      expect(cuerpo['vigenteDesde'], '2027-01-01');
    });
  });

  group('RamaEmpleado', () {
    Map<String, dynamic> ramaJson() => {
      'codEmpleado': 140,
      'nombreEmpleado': 'Choque Flores Mario',
      'codCargo': 140,
      'cargo': 'Operario de máquina',
      'codSucursal': 1,
      'nombreSucursal': 'Planta El Alto',
      'profundidad': 2,
      'vistoBueno': 'Rojas Vargas Luis',
      'aprueba': null,
      'textoFirma': 'Visto bueno: Rojas Vargas Luis',
      'cargoAprobador': 'Jefe comercial y de producción',
      'rutaCargo': 'Responsable de producción › Operario de máquina',
    };

    test('fromJson lee el empleado, su cargo y quién firma', () {
      final e = HexRamaEmpleadoModel.fromJson(ramaJson()).toEntity();

      expect(e.codEmpleado, BigInt.from(140));
      expect(e.nombreEmpleado, 'Choque Flores Mario');
      expect(e.codCargo, BigInt.from(140));
      expect(e.cargo, 'Operario de máquina');
      expect(e.codSucursal, BigInt.one);
      expect(e.nombreSucursal, 'Planta El Alto');
      expect(e.profundidad, 2);
      expect(e.vistoBueno, 'Rojas Vargas Luis');
      expect(e.aprueba, isNull);
      expect(e.textoFirma, 'Visto bueno: Rojas Vargas Luis');
      expect(e.cargoAprobador, 'Jefe comercial y de producción');
      expect(e.rutaCargo, 'Responsable de producción › Operario de máquina');
    });

    test('toJson vuelve con las PK como int y sin nulos', () {
      final e = HexRamaEmpleadoModel.fromJson(ramaJson()).toEntity();
      final j = HexRamaEmpleadoModel.fromEntity(e).toJson();

      expect(j['codEmpleado'], isA<int>());
      expect(j['codSucursal'], 1);
      expect(j.containsKey('aprueba'), isFalse);
      expect(j['textoFirma'], 'Visto bueno: Rojas Vargas Luis');
      expect(j['cargoAprobador'], 'Jefe comercial y de producción');
      expect(j['rutaCargo'], 'Responsable de producción › Operario de máquina');
    });

    test('una fila vacía no rompe', () {
      final e = HexRamaEmpleadoModel.fromJson(const {}).toEntity();

      expect(e.codEmpleado, isNull);
      expect(e.nombreEmpleado, '');
      expect(e.profundidad, 0);
      expect(e.textoFirma, '');
      expect(e.cargoAprobador, isNull);
      expect(e.rutaCargo, isNull);
    });
  });

  group('Aprobador', () {
    Map<String, dynamic> aprobadorJson() => {
      'idAprobador': 8,
      'codEmpleadoAprobador': 12,
      'nombreAprobador': 'Luis Peña',
      'nivel': 1,
      'nivelTexto': 'Encargado',
      'codCargo': 182,
      'cargo': 'Responsable de producción',
      'cantidadRama': 4,
      'avisoCargo': null,
      'vigenteDesde': '2026-02-01',
      'vigenteHasta': null,
      'esVigente': true,
      'aprobadorActivo': 0,
      'audUsuario': 34,
      'audFecha': '2026-02-01 10:00:00',
    };

    test('Aprobador.fromJson lee rol, cargo, rama y vigencia', () {
      final e = HexAprobadorModel.fromJson(aprobadorJson()).toEntity();

      expect(e.idAprobador, BigInt.from(8));
      expect(e.codEmpleadoAprobador, BigInt.from(12));
      expect(e.nivel, 1);
      expect(e.nivelTexto, 'Encargado');
      expect(e.codCargo, BigInt.from(182));
      expect(e.cargo, 'Responsable de producción');
      expect(e.cantidadRama, 4);
      expect(e.avisoCargo, isNull);
      expect(e.vigenteDesde, DateTime(2026, 2));
      expect(e.esVigente, isTrue);
      expect(e.aprobadorActivo, isFalse);
    });

    test('Aprobador.toJson manda solo persona, rol y vigencia', () {
      final e = HexAprobadorEntity(
        codEmpleadoAprobador: BigInt.from(12),
        nivel: 1,
        codCargo: BigInt.from(182),
        cargo: 'Responsable de producción',
        cantidadRama: 4,
        avisoCargo: 'Sin cargo',
        vigenteDesde: DateTime(2026, 11),
      );

      expect(HexAprobadorModel.fromEntity(e).toJson().keys.toSet(), {
        'codEmpleadoAprobador',
        'nivel',
        'vigenteDesde',
      });
    });

    test('Aprobador de nivel 2 no manda sucursal ni encargado (D34)', () {
      final e = HexAprobadorEntity(
        codEmpleadoAprobador: BigInt.from(40),
        nivel: 2,
        vigenteDesde: DateTime(2026, 11),
        vigenteHasta: DateTime(2026, 12, 31),
      );
      final j = HexAprobadorModel.fromEntity(e).toJson();

      expect(j['codEmpleadoAprobador'], isA<int>());
      expect(j['nivel'], 2);
      expect(j['vigenteHasta'], '2026-12-31');
      expect(j.containsKey('codSucursal'), isFalse);
      expect(j.containsKey('codEmpleadoAprobado'), isFalse);
    });

    test('Aprobador de nivel 2 lee su encargado y el alcance (D35)', () {
      final j =
          aprobadorJson()
            ..['nivel'] = 2
            ..['codEmpleadoAprobado'] = 191
            ..['nombreAprobado'] = 'Zeballos Zue Helen Scarlet'
            ..['textoAlcance'] =
                'Aprueba lo que firma Zeballos Zue Helen Scarlet (6 empleados)';
      final e = HexAprobadorModel.fromJson(j).toEntity();

      expect(e.codEmpleadoAprobado, BigInt.from(191));
      expect(e.nombreAprobado, 'Zeballos Zue Helen Scarlet');
      expect(e.textoAlcance, contains('Aprueba lo que firma'));
      // Lo que lee no viaja de vuelta: solo los encargados elegidos.
      final cuerpo = HexAprobadorModel.fromEntity(e).toJson();
      expect(cuerpo.containsKey('codEmpleadoAprobado'), isFalse);
      expect(cuerpo.containsKey('textoAlcance'), isFalse);
    });

    test('Aprobador de nivel 2 manda los encargados como enteros (D35)', () {
      final e = HexAprobadorEntity(
        codEmpleadoAprobador: BigInt.from(65),
        nivel: 2,
        codEmpleadosAprobados: [BigInt.from(191), BigInt.from(7)],
        vigenteDesde: DateTime(2026, 11, 4),
      );

      expect(HexAprobadorModel.fromEntity(e).toJson(), {
        'codEmpleadoAprobador': 65,
        'nivel': 2,
        'codEmpleadosAprobados': [191, 7],
        'vigenteDesde': '2026-11-04',
      });
    });

    test('nuevaVigencia de un jefe conserva su encargado (D35)', () {
      final j =
          aprobadorJson()
            ..['nivel'] = 2
            ..['codEmpleadoAprobado'] = 191;
      final nuevo = HexAprobadorModel.fromJson(j).toEntity().nuevaVigencia();

      expect(nuevo.codEmpleadosAprobados, [BigInt.from(191)]);
      expect(nuevo.codEmpleadoAprobado, BigInt.from(191));
    });

    test('Aprobador sin cargo lee el aviso del SP', () {
      final j =
          aprobadorJson()
            ..['codCargo'] = null
            ..['cargo'] = null
            ..['cantidadRama'] = 0
            ..['avisoCargo'] =
                'Sin cargo vigente en el organigrama: no cubre a nadie.';
      final e = HexAprobadorModel.fromJson(j).toEntity();

      expect(e.codCargo, isNull);
      expect(e.cantidadRama, 0);
      expect(
        e.avisoCargo,
        'Sin cargo vigente en el organigrama: no cubre a nadie.',
      );
    });

    test('copyWith conserva el resto', () {
      final base = HexAprobadorModel.fromJson(aprobadorJson()).toEntity();
      final nuevo = base.copyWith(vigenteHasta: DateTime(2026, 12, 31));

      expect(nuevo.vigenteHasta, DateTime(2026, 12, 31));
      expect(nuevo.nombreAprobador, 'Luis Peña');
      expect(nuevo.cargo, 'Responsable de producción');
      expect(nuevo.cantidadRama, 4);
    });

    test('nuevaVigencia conserva el rol y suelta la fila anterior', () {
      final j = aprobadorJson()..['vigenteHasta'] = '2026-06-30';
      final nuevo = HexAprobadorModel.fromJson(j).toEntity().nuevaVigencia();

      expect(nuevo.idAprobador, isNull);
      expect(nuevo.vigenteHasta, isNull);
      expect(nuevo.esVigente, isFalse);
      expect(nuevo.audUsuario, isNull);
      expect(nuevo.audFecha, isNull);
      expect(nuevo.codEmpleadoAprobador, BigInt.from(12));
      expect(nuevo.nivel, 1);
      expect(nuevo.codCargo, BigInt.from(182));
    });

    test('la asignación nueva no manda el id ni el cierre anteriores', () {
      final j = aprobadorJson()..['vigenteHasta'] = '2026-06-30';
      final nuevo = HexAprobadorModel.fromJson(
        j,
      ).toEntity().nuevaVigencia().copyWith(vigenteDesde: DateTime(2026, 11));
      final cuerpo = HexAprobadorModel.fromEntity(nuevo).toJson();

      expect(cuerpo.containsKey('idAprobador'), isFalse);
      expect(cuerpo.containsKey('vigenteHasta'), isFalse);
      expect(cuerpo['vigenteDesde'], '2026-11-01');
    });
  });

  group('EncargadoOpcion (D35)', () {
    test('fromJson lee nombre, cargo, rama y jefes actuales', () {
      final e =
          HexEncargadoOpcionModel.fromJson({
            'codEmpleado': 191,
            'nombreEmpleado': 'Zeballos Zue Helen Scarlet',
            'cargo': 'SUPERVISOR DE ALMACENES',
            'cantidadRama': '6',
            'jefesActuales': 'Alvaro Pérez',
          }).toEntity();

      expect(e.codEmpleado, BigInt.from(191));
      expect(e.nombreEmpleado, 'Zeballos Zue Helen Scarlet');
      expect(e.cargo, 'SUPERVISOR DE ALMACENES');
      expect(e.cantidadRama, 6);
      expect(e.jefesActuales, 'Alvaro Pérez');
    });

    test('sin jefes ni cargo quedan nulos y toJson los omite', () {
      final m = HexEncargadoOpcionModel.fromJson({
        'codEmpleado': 7,
        'nombreEmpleado': 'Rojas',
        'jefesActuales': '  ',
      });

      expect(m.toEntity().jefesActuales, isNull);
      expect(m.toEntity().cargo, isNull);
      expect(m.toJson(), {
        'codEmpleado': 7,
        'nombreEmpleado': 'Rojas',
        'cantidadRama': 0,
      });
    });
  });

  test('ningún toJson manda identidad', () {
    final parametro = HexParametroEntity(
      idParametro: BigInt.one,
      clave: 'K',
      valorNumero: 1,
      leyenda: 'L',
      vigenteDesde: DateTime(2026),
    );
    final tramo = HexTramoEntity(
      idTramo: BigInt.one,
      codigo: 'HS',
      leyenda: 'L',
      tipoDia: 'HABIL',
      horaDesde: '18:00:00',
      horaHasta: '20:00:00',
      multiplicador: 1,
      orden: 1,
      vigenteDesde: DateTime(2026),
      audUsuario: BigInt.from(34),
      audFecha: DateTime(2026),
    );
    final comida = HexComidaEntity(
      idComida: BigInt.one,
      codigo: 'C',
      leyenda: 'L',
      audUsuario: BigInt.from(34),
      audFecha: DateTime(2026),
      vigenteDesde: DateTime(2026),
    );
    final aprobador = HexAprobadorEntity(
      idAprobador: BigInt.one,
      codEmpleadoAprobador: BigInt.two,
      nivel: 1,
      vigenteDesde: DateTime(2026),
      audUsuario: BigInt.from(34),
    );

    final cuerpos = [
      HexParametroModel.fromEntity(parametro).toJson(),
      HexTramoModel.fromEntity(tramo).toJson(),
      HexComidaModel.fromEntity(comida).toJson(),
      HexAprobadorModel.fromEntity(aprobador).toJson(),
    ];
    for (final c in cuerpos) {
      expect(c.keys.toSet().intersection(identidad), isEmpty);
    }
  });

  test('LeyendaCodigos anida tramos y comidas vigentes', () {
    final e =
        HexLeyendaCodigosModel.fromJson({
          'tramos': [
            {
              'idTramo': 1,
              'codigo': 'HS',
              'multiplicador': 1,
              'horaDesde': '18:00',
            },
            {'idTramo': 2, 'codigo': 'H50', 'multiplicador': 1.5},
          ],
          'comidas': [
            {'idComida': 5, 'codigo': 'D', 'codigoDoble': 'DD', 'monto': 10},
          ],
        }).toEntity();

    expect(e.tramos.map((t) => t.codigo), ['HS', 'H50']);
    expect(e.tramos.first.horaDesde, '18:00:00');
    expect(e.comidas.single.codigoDoble, 'DD');
    expect(e.comidas.single.monto, 10.0);
  });

  test('LeyendaCodigos sin listas queda vacía', () {
    final e = HexLeyendaCodigosModel.fromJson({}).toEntity();

    expect(e.tramos, isEmpty);
    expect(e.comidas, isEmpty);
  });

  test('Planilla lee totales y anulación', () {
    final e =
        HexPlanillaModel.fromJson({
          'idPlanilla': 7,
          'codEmpresa': 2,
          'anio': 2026,
          'mes': 10,
          'periodoTexto': 'Octubre 2026',
          'codSucursal': 3,
          'nombreSucursal': 'Planta Norte',
          'estado': 'ANULADA',
          'estadoTexto': 'Anulada',
          'fechaEjecucion': '2026-11-02 09:30:00',
          'codEmpleadoEjecutor': 90,
          'nombreEjecutor': 'Rosa Vega',
          'totalHoras': 1200.5,
          'totalComidas': 300,
          'total': 1500.5,
          'cantidadEmpleados': 14,
          'cantidadReportes': 52,
          'motivoAnulacion': 'Error de sucursal',
          'fechaAnulacion': '2026-11-03 10:00:00',
          'codEmpleadoAnulador': 91,
          'nombreAnulador': 'Pedro Ruiz',
        }).toEntity();

    expect(e.idPlanilla, BigInt.from(7));
    expect(e.codEmpresa, BigInt.two);
    expect([e.anio, e.mes], [2026, 10]);
    expect(e.total, 1500.5);
    expect(e.totalComidas, 300.0);
    expect(e.cantidadReportes, 52);
    expect(e.fechaEjecucion, DateTime(2026, 11, 2, 9, 30));
    expect(e.codEmpleadoAnulador, BigInt.from(91));
    expect(e.fechaAnulacion, DateTime(2026, 11, 3, 10));
  });

  test('Planilla ejecutada no trae datos de anulación', () {
    final e =
        HexPlanillaModel.fromJson({
          'idPlanilla': 7,
          'estado': 'EJECUTADA',
        }).toEntity();

    expect(e.motivoAnulacion, isNull);
    expect(e.fechaAnulacion, isNull);
    expect(e.codEmpleadoAnulador, isNull);
  });

  test('PlanillaEmpleado lee hHS, cD y mOtros con esa grafía', () {
    final e =
        HexPlanillaEmpleadoModel.fromJson({
          'hHS': 1.5,
          'cD': 2,
          'mOtros': 3,
        }).toEntity();

    expect(e.hHS, 1.5);
    expect(e.cD, 2);
    expect(e.mOtros, 3.0);
  });

  test(
    'PlanillaEmpleado lee todas las columnas de horas, montos y comidas',
    () {
      final e =
          HexPlanillaEmpleadoModel.fromJson({
            'nombreArea': 'Producción',
            'ordenArea': 2,
            'codEmpleado': 77,
            'nombreEmpleado': 'Ana Rojas',
            'cargo': null,
            'costoHora': 12.5,
            'hHS': 1,
            'mHS': 12.5,
            'hH50': 2,
            'mH50': 37.5,
            'hH100': 3,
            'mH100': 75,
            'hHD': 4,
            'mHD': 100,
            'hHF': 5,
            'mHF': 125,
            'cD': 1,
            'cDD': 2,
            'cA': 3,
            'cDA': 4,
            'cC': 5,
            'cDC': 6,
            'mOtros': 7,
            'totalHoras': 350,
            'totalComidas': 80,
            'total': 430,
          }).toEntity();

      expect(e.nombreArea, 'Producción');
      expect(e.ordenArea, 2);
      expect(e.cargo, isNull);
      expect(e.costoHora, 12.5);
      expect([e.hH50, e.hH100, e.hHD, e.hHF], [2.0, 3.0, 4.0, 5.0]);
      expect(
        [e.mHS, e.mH50, e.mH100, e.mHD, e.mHF],
        [12.5, 37.5, 75, 100, 125],
      );
      expect([e.cD, e.cDD, e.cA, e.cDA, e.cC, e.cDC], [1, 2, 3, 4, 5, 6]);
      expect(e.total, 430.0);
    },
  );

  test('PlanillaEmpleado: cada columna sale de su propia clave', () {
    // Un valor distinto por clave: cambiar una clave por otra no pasa.
    final e =
        HexPlanillaEmpleadoModel.fromJson({
          'ordenArea': 24,
          'costoHora': 23.5,
          'hHS': 1.1,
          'mHS': 2.2,
          'hH50': 3.3,
          'mH50': 4.4,
          'hH100': 5.5,
          'mH100': 6.6,
          'hHD': 7.7,
          'mHD': 8.8,
          'hHF': 9.9,
          'mHF': 10.1,
          'cD': 11,
          'cDD': 12,
          'cA': 13,
          'cDA': 14,
          'cC': 15,
          'cDC': 16,
          'mOtros': 17.7,
          'totalHoras': 18.8,
          'totalComidas': 19.9,
          'total': 20.2,
        }).toEntity();

    expect(
      [e.hHS, e.mHS, e.hH50, e.mH50, e.hH100, e.mH100, e.hHD, e.mHD, e.hHF],
      [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9],
    );
    expect(e.mHF, 10.1);
    expect([e.cD, e.cDD, e.cA, e.cDA, e.cC, e.cDC], [11, 12, 13, 14, 15, 16]);
    expect(e.mOtros, 17.7);
    expect(e.totalHoras, 18.8);
    expect(e.totalComidas, 19.9);
    expect(e.total, 20.2);
    expect(e.costoHora, 23.5);
    expect(e.ordenArea, 24);
  });

  test('PlanillaDetalle lee hOtros', () {
    final e =
        HexPlanillaDetalleModel.fromJson({
          'codEmpleado': 77,
          'nombreEmpleado': 'Ana Rojas',
          'nombreArea': 'Producción',
          'idReporte': 501,
          'fechaJornada': '2026-10-23',
          'tipo': 'DESPUES',
          'tipoTexto': 'Después',
          'tipoDia': null,
          'motivo': null,
          'inicio': '2026-10-23 18:00:00',
          'fin': '2026-10-24 01:30:00',
          'origenInicio': 'HORARIO',
          'origenFin': 'APP',
          'esPeriodoAnterior': 1,
          'haberBasico': 3000,
          'codPlanillaSueldo': 15,
          'divisor': 240,
          'costoHora': 12.5,
          'hHS': 2,
          'hH50': 1.5,
          'hH100': 0,
          'hHD': 0,
          'hHF': 0,
          'hOtros': 0.5,
          'comidas': 'C,DC',
          'montoHoras': 60,
          'montoComidas': 45,
          'total': 105,
        }).toEntity();

    expect(e.hOtros, 0.5);
    expect(e.hHS, 2.0);
    expect(e.hH50, 1.5);
    expect(e.codPlanillaSueldo, BigInt.from(15));
    expect(e.divisor, 240.0);
    expect(e.haberBasico, 3000.0);
    expect(e.esPeriodoAnterior, isTrue);
    expect(e.fin, DateTime(2026, 10, 24, 1, 30));
    expect(e.tipoDia, isNull);
    expect(e.comidas, 'C,DC');
  });

  test('PlanillaDetalle lee el origen de cada hora en texto', () {
    final e =
        HexPlanillaDetalleModel.fromJson({
          'idReporte': 501,
          'origenInicio': 'HORARIO',
          'origenFin': 'EDITADO',
          'origenInicioTexto': 'Horario',
          'origenFinTexto': 'Editado por el encargado',
        }).toEntity();

    expect(e.origenInicio, 'HORARIO');
    expect(e.origenFin, 'EDITADO');
    expect(e.origenInicioTexto, 'Horario');
    expect(e.origenFinTexto, 'Editado por el encargado');

    final sinTexto = HexPlanillaDetalleModel.fromJson({'idReporte': 502});
    expect(sinTexto.toEntity().origenInicioTexto, '');
    expect(sinTexto.toEntity().origenFinTexto, '');
  });

  test('Pendiente identifica la combinación de la planilla', () {
    final e =
        HexPendienteModel.fromJson({
          'codEmpresa': 2,
          'codSucursal': 3,
          'nombreSucursal': null,
          'anio': 2026,
          'mes': 10,
          'cantidadReportes': 52,
        }).toEntity();

    expect(e.codEmpresa, BigInt.two);
    expect(e.codSucursal, BigInt.from(3));
    expect(e.nombreSucursal, isNull);
    expect([e.anio, e.mes, e.cantidadReportes], [2026, 10, 52]);
  });

  test('PrevistaEmpleado lee montos y avisos', () {
    final e =
        HexPrevistaEmpleadoModel.fromJson({
          'codEmpleado': 77,
          'nombreEmpleado': 'Ana Rojas',
          'nombreArea': null,
          'montoHoras': 200.25,
          'montoComidas': 45,
          'total': 245.25,
          'esProvisional': true,
          'cantidadReportes': 4,
          'tieneAvisoBiometrico': 1,
          'tienePeriodoAnterior': 0,
        }).toEntity();

    expect(e.montoHoras, 200.25);
    expect(e.total, 245.25);
    expect(e.esProvisional, isTrue);
    expect(e.tieneAvisoBiometrico, isTrue);
    expect(e.tienePeriodoAnterior, isFalse);
    expect(e.nombreArea, isNull);
  });

  test('PrevistaLinea lee la línea con su haber, divisor y origen', () {
    final e =
        HexPrevistaLineaModel.fromJson({
          'idReporte': 501,
          'codEmpleado': 77,
          'nombreEmpleado': 'Ana Rojas',
          'fechaJornada': '2026-10-23',
          'tipo': 'DESPUES',
          'tipoDia': 'HABIL',
          'inicio': '2026-10-23 18:00:00',
          'fin': '2026-10-23 20:00:00',
          'origenInicio': 'HORARIO',
          'origenFin': 'BIOMETRICO',
          'esPeriodoAnterior': false,
          'esProvisional': false,
          'avisoBiometrico': true,
          'haberBasico': 3000,
          'codPlanillaSueldo': null,
          'divisor': 240,
          'costoHora': 12.5,
          'concepto': 'TRAMO',
          'codigo': 'HS',
          'leyenda': 'Hora simple',
          'minutos': 120,
          'cantidad': 2,
          'multiplicador': 1,
          'valorUnitario': 12.5,
          'monto': 25,
        }).toEntity();

    expect(e.idReporte, BigInt.from(501));
    expect(e.origenFin, 'BIOMETRICO');
    expect(e.avisoBiometrico, isTrue);
    expect(e.codPlanillaSueldo, isNull);
    expect(e.divisor, 240.0);
    expect(e.minutos, 120);
    expect(e.monto, 25.0);
  });

  test('PrevistaLinea: cada cifra sale de su propia clave', () {
    // Un valor distinto por clave: cambiar una clave por otra no pasa.
    final e =
        HexPrevistaLineaModel.fromJson({
          'haberBasico': 3001.01,
          'codPlanillaSueldo': 8801,
          'divisor': 241.5,
          'costoHora': 12.25,
          'minutos': 91,
          'cantidad': 2.5,
          'multiplicador': 1.75,
          'valorUnitario': 13.5,
          'monto': 33.75,
        }).toEntity();

    expect(e.haberBasico, 3001.01);
    expect(e.codPlanillaSueldo, BigInt.from(8801));
    expect(e.divisor, 241.5);
    expect(e.costoHora, 12.25);
    expect(e.minutos, 91);
    expect(e.cantidad, 2.5);
    expect(e.multiplicador, 1.75);
    expect(e.valorUnitario, 13.5);
    expect(e.monto, 33.75);
  });

  test('PrevistaLinea: cada bandera sale de su propia clave', () {
    final e =
        HexPrevistaLineaModel.fromJson({
          'esPeriodoAnterior': true,
          'esProvisional': false,
          'avisoBiometrico': false,
        }).toEntity();

    expect(
      [e.esPeriodoAnterior, e.esProvisional, e.avisoBiometrico],
      [true, false, false],
    );
  });

  test('Aviso lee el tipo y el detalle', () {
    final e =
        HexAvisoModel.fromJson({
          'idReporte': 501,
          'codEmpleado': 77,
          'nombreEmpleado': 'Ana Rojas',
          'fechaJornada': '2026-10-23',
          'tipoAviso': 'SIN_HABER',
          'detalle': 'No tiene haber básico',
        }).toEntity();

    expect(e.tipoAviso, 'SIN_HABER');
    expect(e.detalle, 'No tiene haber básico');
    expect(e.fechaJornada, DateTime(2026, 10, 23));
  });

  test('CodigoLeyenda de comida puede no traer multiplicador', () {
    final e =
        HexCodigoLeyendaModel.fromJson({
          'concepto': 'COMIDA',
          'codigo': 'D',
          'leyenda': 'Desayuno',
          'multiplicador': null,
          'valorUnitario': 10,
        }).toEntity();

    expect(e.concepto, 'COMIDA');
    expect(e.multiplicador, isNull);
    expect(e.valorUnitario, 10.0);
  });

  group('RequisitoMarca', () {
    test('fromJson lee las columnas de p_list_thex_Reporte S', () {
      final e =
          HexRequisitoMarcaModel.fromJson({
            'requisito': 'INICIO',
            'cumple': true,
            'bloquea': 1,
            'titulo': 'Módulo iniciado',
            'detalle': 'El módulo empieza el 01/11/2026',
            'orden': 3,
          }).toEntity();

      expect(e.requisito, 'INICIO');
      expect(e.cumple, isTrue);
      expect(e.bloquea, isTrue);
      expect(e.titulo, 'Módulo iniciado');
      expect(e.detalle, 'El módulo empieza el 01/11/2026');
      expect(e.orden, 3);
      expect(e.impideMarcar, isFalse);
    });

    test('solo impide marcar si no se cumple y bloquea', () {
      HexRequisitoMarcaModel m(Object cumple, Object bloquea) =>
          HexRequisitoMarcaModel.fromJson({
            'cumple': cumple,
            'bloquea': bloquea,
          });
      expect(m(0, 1).toEntity().impideMarcar, isTrue);
      expect(m(0, 0).toEntity().impideMarcar, isFalse);
      expect(m('1', '1').toEntity().impideMarcar, isFalse);
    });

    test('tolera un JSON vacío y vuelve igual por toJson', () {
      final vacio = HexRequisitoMarcaModel.fromJson({}).toEntity();
      expect(vacio.requisito, '');
      expect(vacio.cumple, isFalse);
      expect(vacio.orden, 0);

      final j = {
        'requisito': 'CARGO',
        'cumple': false,
        'bloquea': true,
        'titulo': 'Cargo con sucursal',
        'detalle': 'Pide a RRHH que asigne tu cargo a una sucursal',
        'orden': 2,
      };
      final ida = HexRequisitoMarcaModel.fromJson(j).toEntity();
      expect(HexRequisitoMarcaModel.fromEntity(ida).toJson(), j);
    });
  });

  group('Vigencia que calcula el SP (D28.3)', () {
    final parametro = <String, dynamic>{
      'idParametro': 1,
      'clave': 'DIVISOR_COSTO_HORA',
      'valorNumero': 240,
      'leyenda': 'Divisor del costo hora',
      'vigenteDesde': '2026-01-01',
      'esVigente': 1,
    };
    final tramo = <String, dynamic>{
      'idTramo': 2,
      'codigo': 'H50',
      'leyenda': 'Hora al 50 %',
      'tipoDia': 'HABIL',
      'horaDesde': '20:00:00',
      'horaHasta': '00:00:00',
      'multiplicador': 1.5,
      'orden': 2,
      'vigenteDesde': '2026-01-01',
      'esVigente': 1,
    };
    final comida = <String, dynamic>{
      'idComida': 3,
      'codigo': 'C',
      'leyenda': 'Cena',
      'codigoDoble': 'CC',
      'leyendaDoble': 'Doble cena',
      'monto': 15,
      'montoDoble': 30,
      'activo': 1,
      'orden': 3,
      'vigenteDesde': '2026-01-01',
      'esVigente': 1,
    };

    Map<String, dynamic> conVigencia(Map<String, dynamic> base) => {
      ...base,
      'estadoVigencia': 'PROGRAMADA',
      'textoVigencia': 'Empieza a regir el 01/03/2027',
    };

    test('el parámetro lee estadoVigencia y textoVigencia', () {
      final e = HexParametroModel.fromJson(conVigencia(parametro)).toEntity();
      expect(e.estadoVigencia, 'PROGRAMADA');
      expect(e.textoVigencia, 'Empieza a regir el 01/03/2027');
    });

    test('el tramo lee estadoVigencia y textoVigencia', () {
      final e = HexTramoModel.fromJson(conVigencia(tramo)).toEntity();
      expect(e.estadoVigencia, 'PROGRAMADA');
      expect(e.textoVigencia, 'Empieza a regir el 01/03/2027');
    });

    test('la comida lee estadoVigencia y textoVigencia', () {
      final e = HexComidaModel.fromJson(conVigencia(comida)).toEntity();
      expect(e.estadoVigencia, 'PROGRAMADA');
      expect(e.textoVigencia, 'Empieza a regir el 01/03/2027');
    });

    test('si no llegan, o llegan vacíos, quedan nulos', () {
      final p = HexParametroModel.fromJson(parametro).toEntity();
      final t = HexTramoModel.fromJson(tramo).toEntity();
      final c = HexComidaModel.fromJson(comida).toEntity();
      expect(p.estadoVigencia, isNull);
      expect(p.textoVigencia, isNull);
      expect(t.estadoVigencia, isNull);
      expect(t.textoVigencia, isNull);
      expect(c.estadoVigencia, isNull);
      expect(c.textoVigencia, isNull);

      final vacio = {'estadoVigencia': '  ', 'textoVigencia': ''};
      expect(
        HexParametroModel.fromJson({
          ...parametro,
          ...vacio,
        }).toEntity().textoVigencia,
        isNull,
      );
      expect(
        HexTramoModel.fromJson({...tramo, ...vacio}).toEntity().estadoVigencia,
        isNull,
      );
    });

    test('no viajan al guardar: los calcula el servidor', () {
      final p = HexParametroModel.fromJson(conVigencia(parametro)).toEntity();
      final t = HexTramoModel.fromJson(conVigencia(tramo)).toEntity();
      final c = HexComidaModel.fromJson(conVigencia(comida)).toEntity();
      for (final j in [
        HexParametroModel.fromEntity(p).toJson(),
        HexTramoModel.fromEntity(t).toJson(),
        HexComidaModel.fromEntity(c).toJson(),
      ]) {
        expect(j.containsKey('estadoVigencia'), isFalse);
        expect(j.containsKey('textoVigencia'), isFalse);
      }
    });

    test('copyWith conserva la vigencia y una vigencia nueva la suelta', () {
      final p = HexParametroModel.fromJson(conVigencia(parametro)).toEntity();
      expect(p.copyWith(leyenda: 'Otra').textoVigencia, p.textoVigencia);
      expect(p.nuevaVigencia().estadoVigencia, isNull);
      expect(p.nuevaVigencia().textoVigencia, isNull);
    });
  });
}
