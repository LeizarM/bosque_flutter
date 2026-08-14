import 'package:bosque_flutter/data/models/abono_dias_model.dart';
import 'package:bosque_flutter/data/models/desglose_saldo_model.dart';
import 'package:bosque_flutter/data/models/ficha_saldo_model.dart';
import 'package:bosque_flutter/data/models/nomina_permiso_model.dart';
import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/data/models/simulacion_colectiva_model.dart';
import 'package:bosque_flutter/data/models/simulacion_permiso_model.dart';
import 'package:bosque_flutter/data/models/vacacion_asignada_model.dart';
import 'package:bosque_flutter/domain/entities/abono_dias_entity.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo único no trivial de estos modelos es aguantar lo que de verdad manda el
/// backend, que no es el JSON de ejemplo del plan.
///
/// **El caso que rompe:** SQL Server guarda los días como `float`, y un float
/// sin decimales viaja como `12`, no como `12.0`. Con `as double` eso revienta
/// en runtime — y revienta para el empleado que tiene los días redondos, o sea
/// para la mayoría, mientras que el de 12,5 anda bien. Es el bug que pasa las
/// pruebas manuales y aparece en producción.
void main() {
  group('FichaSaldoModel.fromJson', () {
    test('acepta enteros donde el contrato dice decimal', () {
      final f =
          FichaSaldoModel.fromJson(const {
            'codEmpleado': 130,
            'diasNoUsados': 12, // int, no 12.0
            'diasAbonados': 2.5, // double
            'totalDias': 0,
          }).toEntity();

      expect(f.diasNoUsados, 12.0);
      expect(f.diasAbonados, 2.5);
      expect(f.codEmpleado, 130);
    });

    test('un JSON vacío no revienta: todo cae en su valor neutro', () {
      final f = FichaSaldoModel.fromJson(const {}).toEntity();

      expect(f.diasNoUsados, 0.0);
      expect(f.datoEmpleado, '');
      expect(f.relacionVigenteDesde, isNull);
      // D0: sin dato se asume que no hay historia anterior, así que la pantalla
      // no rotula un alcance que no puede probar.
      expect(f.tieneRelacionesAnteriores, isFalse);
      expect(f.movimientosFueraDeRelacionVigente, 0);
    });

    test("'Sin Asignar' es un dato, no una fecha faltante", () {
      expect(
        FichaSaldoModel.fromJson(const {
          'datoFechaBeneficio': 'Sin Asignar',
        }).toEntity().tieneFechaBeneficio,
        isFalse,
      );
      expect(
        FichaSaldoModel.fromJson(const {
          'datoFechaBeneficio': '01/03/2015',
        }).toEntity().tieneFechaBeneficio,
        isTrue,
      );
    });

    test('el saldo negativo se reconoce (se pinta con colorScheme.error)', () {
      expect(
        FichaSaldoModel.fromJson(const {
          'totalDias': -3,
        }).toEntity().saldoNegativo,
        isTrue,
      );
    });
  });

  group('DesgloseSaldoModel.fromJson', () {
    test('mapea los tramos y conserva la etiqueta del SP tal cual', () {
      final d =
          DesgloseSaldoModel.fromJson(const {
            'codEmpleado': 130,
            'datoAnios': 11,
            'fecIniPenUl': '2025-02-28',
            'desgloseAplicable': true,
            'tieneFechaBeneficio': true,
            'tramos': [
              {
                'clave': 'SALDO_PENULTIMO',
                'etiqueta':
                    'Saldo hasta el penultimo año cumplido (28/02/2025)',
                'monto': 8, // int, no 8.0
                'montoTxt': '8 días',
                'signo': 'DEBE',
                'tieneDetalle': false,
              },
              {
                'clave': 'ACUMULADA',
                'etiqueta': 'Vacación acumulada …',
                'monto': 12.9,
                'signo': 'INFO',
              },
            ],
            'montoTotal': 12.5,
          }).toEntity();

      expect(d.tramos.length, 2);
      expect(d.tramos.first.monto, 8.0);
      expect(
        d.tramos.first.etiqueta,
        'Saldo hasta el penultimo año cumplido (28/02/2025)',
      );
      // D1: el tramo de duodécimas no suma, y el contrato lo dice.
      expect(d.tramos.last.esInformativo, isTrue);
      expect(d.fecIniPenUl, DateTime(2025, 2, 28));
    });

    test('sin tramos y sin flags queda del lado seguro', () {
      final d = DesgloseSaldoModel.fromJson(const {}).toEntity();

      expect(d.tramos, isEmpty);
      // D2: sin flag NO se pintan los 5 tramos.
      expect(d.desgloseAplicable, isFalse);
      // Sin flag la pantalla avisa que puede faltar la fecha de beneficio.
      expect(d.tieneFechaBeneficio, isFalse);
      expect(d.montoTotal, 0.0);
    });

    test('un tramo sin signo se trata como informativo, no como DEBE', () {
      final d =
          DesgloseSaldoModel.fromJson(const {
            'tramos': [
              {'clave': 'X', 'monto': 5},
            ],
          }).toEntity();

      expect(d.tramos.single.signo, 'INFO');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // ESCRITURAS (Fase 2)
  // ═════════════════════════════════════════════════════════════════════════
  //
  // Estas reglas no las sostiene nadie más: los tres SP de escritura no validan
  // absolutamente nada —aceptan días negativos, fechas de 1900 y una ACCIÓN
  // desconocida que no hace nada y tampoco falla—, así que lo único que separa
  // un formulario mal llenado de una fila incobrable es esto y su gemelo de
  // Java. Los dos umbrales son DISTINTOS a propósito y es el error fácil del
  // módulo: cero días asignados es válido, cero días abonados no.

  group('VacacionAsignadaModel', () {
    test('la fila sintética del SP se reconoce como alta', () {
      // Así llega un aniversario sin registro: id 0, días 0 y motivo vacío.
      final v =
          VacacionAsignadaModel.fromJson(const {
            'codVacacionAsignada': 0,
            'codEmpleado': 130,
            'codRelEmplEmpr': 500,
            'diasAsignados': 0,
            'motivo': '',
            'fecha': '2026-08-31',
          }).toEntity();

      expect(v.esSintetica, isTrue);
      expect(v.fecha, DateTime(2026, 8, 31));
    });

    test('cero días es válido: 446 filas de la tabla valen eso', () {
      final v = const VacacionAsignadaEntity(
        codVacacionAsignada: 0,
        codEmpleado: 130,
        codRelEmplEmpr: 500,
        diasAsignados: 0,
        motivo: 'No le corresponde este año',
      );

      expect(v.problema, isNull);
    });

    test('un motivo más largo que la columna se para acá, no en el SP', () {
      final v = const VacacionAsignadaEntity(
        codVacacionAsignada: 0,
        codEmpleado: 130,
        codRelEmplEmpr: 500,
        diasAsignados: 15,
        motivo: '',
      );

      expect(v.copyWith(motivo: 'a' * 301).problema, contains('300'));
      expect(v.copyWith(motivo: 'a' * 300).problema, isNull);
      // Sin motivo no se puede guardar: la columna es NOT NULL y el INSERT
      // reventaría con un error de SQL crudo.
      expect(v.problema, isNotNull);
    });

    test('sin relación laboral no se guarda', () {
      expect(
        const VacacionAsignadaEntity(
          codVacacionAsignada: 0,
          codEmpleado: 130,
          codRelEmplEmpr: 0,
          diasAsignados: 15,
          motivo: 'Vacación 2026',
        ).problema,
        contains('relación'),
      );
    });

    test('copyWith no puede mover la fila de empleado ni de relación', () {
      final v = const VacacionAsignadaEntity(
        codVacacionAsignada: 77,
        codEmpleado: 130,
        codRelEmplEmpr: 500,
        diasAsignados: 15,
        motivo: 'Original',
      ).copyWith(diasAsignados: 20, motivo: 'Corregido');

      expect(v.codEmpleado, 130);
      expect(v.codRelEmplEmpr, 500);
      expect(v.codVacacionAsignada, 77);
      expect(v.diasAsignados, 20);
    });

    test('toJson manda la fecha como día y no firma por el usuario', () {
      final j =
          VacacionAsignadaModel(
            VacacionAsignadaEntity(
              codVacacionAsignada: 0,
              codEmpleado: 130,
              codRelEmplEmpr: 500,
              diasAsignados: 15,
              motivo: '  Vacación 2026  ',
              fecha: DateTime(2026, 8, 31),
            ),
          ).toJson();

      // `date` del otro lado: con la hora, un reloj corrido cambia de
      // aniversario.
      expect(j['fecha'], '2026-08-31');
      expect(j['motivo'], 'Vacación 2026');
      // D4: la identidad sale del token. Un audUsuario acá sería una firma que
      // se puede tipear.
      expect(j.containsKey('audUsuarioI'), isFalse);
      expect(j.containsKey('audFechaI'), isFalse);
    });
  });

  group('AbonoDiasModel', () {
    test('acepta el float que SQL manda como entero', () {
      final a =
          AbonoDiasModel.fromJson(const {
            'codAbonoDias': 12,
            'codEmpleado': 124,
            'diasAbonados': 1, // int, no 1.0
            'totalDias': 21.5,
            'fila': 3,
          }).toEntity();

      expect(a.diasAbonados, 1.0);
      expect(a.totalDias, 21.5);
      expect(a.esAlta, isFalse);
    });

    test('acá el cero NO es válido, al revés que en la vacación asignada', () {
      final a = AbonoDiasEntity(
        codAbonoDias: 0,
        codEmpleado: 124,
        codRelEmplEmpr: 500,
        diasAbonados: 0,
        motivo: 'Compensación',
        fecha: DateTime(2026, 8, 12),
      );

      expect(a.problema, isNotNull);
      expect(a.copyWith(diasAbonados: 0.5).problema, isNull);
    });

    test('el motivo se corta en 50 y no en 300: es otra columna', () {
      final a = AbonoDiasEntity(
        codAbonoDias: 0,
        codEmpleado: 124,
        codRelEmplEmpr: 500,
        diasAbonados: 1,
        motivo: '',
        fecha: DateTime(2026, 8, 12),
      );

      // El caso real: 54 caracteres, que el SP trunca o hace fallar.
      expect(
        a
            .copyWith(motivo: 'Compensación por inventario del 21 de septiembre')
            .problema,
        isNull,
      );
      expect(a.copyWith(motivo: 'a' * 51).problema, contains('50'));
    });

    test('sin fecha no se guarda: la columna es NOT NULL', () {
      expect(
        const AbonoDiasEntity(
          codAbonoDias: 0,
          codEmpleado: 124,
          codRelEmplEmpr: 500,
          diasAbonados: 1,
          motivo: 'Compensación',
        ).problema,
        isNotNull,
      );
    });
  });

  group('SimulacionColectivaModel.fromJson', () {
    test('el padrón, que no manda el flag, entra entero', () {
      final s =
          SimulacionColectivaModel.fromJson(const {
            'codEmpleado': 48,
            'datoEmpleado': 'PEREZ PEREZ JUAN',
            'codRelEmplEmpr': 500,
            'codSucursal': 2,
          }).toEntity();

      expect(s.entra, isTrue);
      expect(s.dias, 0.0);
    });

    test('la simulación puede dar días distintos y excluir a alguien', () {
      // El caso que obliga a simular: los feriados son por sucursal, así que
      // «5 días para todos» no es cierto.
      final s =
          SimulacionColectivaModel.fromJson(const {
            'codEmpleado': 48,
            'dias': 4.5,
            'diasTxt': '4,5 días',
            'entra': false,
            'detalle': 'Ya tiene vacación en ese rango',
          }).toEntity();

      expect(s.dias, 4.5);
      expect(s.entra, isFalse);
      expect(s.detalle, isNotEmpty);
    });
  });

  group('NominaPermisoModel.fromJson', () {
    test('la fila del kardex, con los días como entero', () {
      final p =
          NominaPermisoModel.fromJson(const {
            'codPermiso': 8462,
            'tipoPermiso': 'vac',
            'datoTipoPermiso': 'Vacación',
            'desde': '2026-08-17T08:00:00',
            'hasta': '2026-08-20T10:00:00',
            'cantidadDias': 3, // int, no 3.0 — es el caso que revienta
            'horas': 26,
            'motivo': 'Vacación anual',
          }).toEntity();

      expect(p.dias, 3.0);
      expect(p.horas, 26.0);
      expect(p.desde, DateTime(2026, 8, 17, 8));
      expect(p.datoTipoPermiso, 'Vacación');
    });

    test('sin `horas`, se muestran las que corresponden a los días', () {
      // El SP no devuelve columna de horas: la calcula el DTO. Si el campo
      // falta, la grilla mostraría 0 horas junto a 1,5 días — dos números que
      // se contradicen en la misma fila.
      final p =
          NominaPermisoModel.fromJson(const {
            'codPermiso': 1,
            'tipoPermiso': 'otro',
            'dias': 1.5,
          }).toEntity();

      expect(p.horas, 12.0);
    });

    test('un JSON vacío no revienta y no inventa nada', () {
      final p = NominaPermisoModel.fromJson(const {}).toEntity();

      expect(p.codPermiso, 0);
      expect(p.dias, 0.0);
      expect(p.horas, 0.0);
      expect(p.tipoPermiso, '');
      expect(p.desde, isNull);
    });
  });

  group('SimulacionPermisoModel.fromJson', () {
    test('el JSON real de EmpleadoColectivoDto llega entero', () {
      // **Es el mismo DTO de la carga colectiva**: el cruce no viaja como
      // cuatro campos propios (`yaTienePermiso`, `codPermisoQueChoca`…) sino
      // como `entra` + `detalle`, y el detalle ya trae el rango del permiso que
      // choca. Leyendo nombres que el servidor no manda, `entra` salía siempre
      // verdadero: el cliente fallaba ABIERTO y la persona se enteraba del
      // choque recién al guardar.
      final s =
          SimulacionPermisoModel.fromJson(const {
            'dias': 1.125,
            'horas': 9,
            'horasAReponer': 9,
            'codSucursal': 1,
            'datoSucursal': 'La Paz',
            'entra': false,
            'detalle':
                'Ya tiene un permiso cargado que se cruza con ese rango (del '
                '17/08/2026 08:00 al 18/08/2026 18:00).',
          }).toEntity();

      expect(s.dias, 1.125);
      expect(s.horasAReponer, 9);
      expect(s.entra, isFalse);
      expect(s.detalle, contains('17/08/2026 08:00'));
    });

    test('falla cerrado: sin `entra` explícito no se puede guardar', () {
      // El campo es un `boolean` primitivo del DTO, así que siempre viene. Si
      // dejara de venir —un rename del otro lado— el peor caso tiene que ser un
      // botón apagado, no una escritura que el servidor ya sabe que rechaza.
      expect(
        SimulacionPermisoModel.fromJson(const {'entra': true}).toEntity().entra,
        isTrue,
      );
      expect(
        SimulacionPermisoModel.fromJson(const {}).toEntity().entra,
        isFalse,
      );
      expect(SimulacionPermisoModel.fromJson(const {}).toEntity().detalle, '');
    });
  });

  group('fechas de ida', () {
    test('prDia manda el día sin hora y prInstante la conserva', () {
      // La vacación colectiva se mide de a media hora entre desde y hasta:
      // perder la hora convierte medio día en cero.
      expect(prDia(DateTime(2026, 8, 31, 18, 30)), '2026-08-31');
      expect(
        prInstante(DateTime(2026, 4, 3, 8, 30)),
        // Sin sufijo de zona: el servidor guarda hora local de Bolivia.
        '2026-04-03T08:30:00',
      );
    });
  });
}
