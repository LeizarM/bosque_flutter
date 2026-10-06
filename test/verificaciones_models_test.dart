import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/data/models/cheque_pendiente_verificacion_model.dart';
import 'package:bosque_flutter/data/models/pagina_verificacion_model.dart';
import 'package:bosque_flutter/data/models/pendientes_verificacion_filtro_model.dart';
import 'package:bosque_flutter/data/models/verificacion_deposito_model.dart';
import 'package:bosque_flutter/data/models/verificacion_fila_model.dart';
import 'package:bosque_flutter/data/models/verificacion_filtro_model.dart';
import 'package:bosque_flutter/data/models/verificacion_preparada_model.dart';
import 'package:bosque_flutter/data/models/verificacion_registro_model.dart';
import 'package:bosque_flutter/domain/entities/pendientes_verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_deposito_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_registro_entity.dart';

/// Los modelos de «Verificar Cheques» contra el JSON del contrato
/// (`API_CHEQUES.md`, seccion «Verificar Cheques»): lo que llega, lo que se manda
/// y lo que se tolera.
void main() {
  Map<String, dynamic> filaJson({
    int codvd = 12,
    String estado = 'Y',
    Object? nroCheque = '480123',
    String? moneda = 'BS',
  }) => {
    'fila': 3,
    'codvd': codvd,
    'codCheque': 9001,
    'codBanco': 8,
    'fechaBanco': '2026-10-03',
    'observacion': 'Cobrado en ventanilla',
    'estado': estado,
    'audUsuario': null,
    'audFecha': null,
    'datoBanco': 'BANCO MERCANTIL SANTA CRUZ',
    'nroCheque': nroCheque,
    'montoCheque': 1500.5,
    'datoBancoCheque': 'BANCO UNION',
    'datoEstadoCheque': 'PENDIENTE',
    'fechaCobrarCheque': '2026-10-03',
    'chequeCerrado': false,
    'datoEstado': estado == 'Y' ? 'Valido' : 'Anulado',
    'moneda': moneda,
    'descMoneda': moneda == 'SUS' ? r'$us' : (moneda == null ? null : 'Bs'),
  };

  group('VerificacionDepositoModel (la tabla tch_verificacionDeposito)', () {
    test('lee las columnas con sus nombres exactos, codvd en minuscula', () {
      final m = VerificacionDepositoModel.fromJson(filaJson());
      expect(m.codvd, BigInt.from(12));
      expect(m.codCheque, BigInt.from(9001));
      expect(m.codBanco, 8);
      expect(m.fechaBanco, DateTime(2026, 10, 3));
      expect(m.observacion, 'Cobrado en ventanilla');
      expect(m.estado, 'Y');
      expect(m.audUsuario, isNull, reason: 'la rama A no lo devuelve');
      expect(m.audFecha, isNull);
    });

    test('ida y vuelta por la entidad y por el JSON no pierde nada', () {
      final m = VerificacionDepositoModel.fromJson({
        ...filaJson(),
        'audUsuario': 47,
        'audFecha': '2026-10-03T14:22:10',
      });
      final otra = VerificacionDepositoModel.fromJson(m.toJson());
      expect(otra.toJson(), m.toJson());
      final e = m.toEntity();
      expect(VerificacionDepositoModel.fromEntity(e).toJson(), m.toJson());
      expect(m.toJson()['fechaBanco'], '2026-10-03', reason: 'solo el dia');
      expect(m.audFecha, DateTime(2026, 10, 3, 14, 22, 10));
    });

    test('Y es valida y N anulada; el resto no es ninguna de las dos', () {
      expect(
        VerificacionDepositoModel.fromJson(filaJson()).toEntity().esValida,
        isTrue,
      );
      final anulada =
          VerificacionDepositoModel.fromJson(filaJson(estado: 'N')).toEntity();
      expect(anulada.estaAnulada, isTrue);
      expect(anulada.esValida, isFalse);
      expect(VerificacionDepositoEntity.valida, 'Y');
      expect(VerificacionDepositoEntity.anulada, 'N');
    });

    test('tolera columnas en null y un estado con espacios', () {
      final m = VerificacionDepositoModel.fromJson({'codvd': 1, 'estado': ' Y '});
      expect(m.codCheque, BigInt.zero);
      expect(m.codBanco, isNull);
      expect(m.fechaBanco, isNull);
      expect(m.observacion, isNull);
      expect(m.estado, 'Y');
    });
  });

  group('VerificacionFilaModel (lo que sale de los JOIN)', () {
    test('lee los datos del cheque junto a los de la verificacion', () {
      final f = VerificacionFilaModel.fromJson(filaJson()).toEntity();
      expect(f.fila, 3);
      expect(f.codvd, BigInt.from(12));
      expect(
        f.datoBanco,
        'BANCO MERCANTIL SANTA CRUZ',
        reason: 'el banco donde se verifico',
      );
      expect(f.cheque.datoBancoCheque, 'BANCO UNION', reason: 'el del cheque');
      expect(f.cheque.nroCheque, '480123');
      expect(f.cheque.montoCheque, 1500.5);
      expect(f.cheque.fechaCobrarCheque, DateTime(2026, 10, 3));
      expect(f.cheque.chequeCerrado, isFalse);
      expect(f.cheque.unidadMoneda, 'Bs');
      expect(f.datoEstado, 'Valido');
    });

    test('un numero de cheque con guion o signo de pregunta llega como texto', () {
      final f =
          VerificacionFilaModel.fromJson(filaJson(nroCheque: '12-34?56'))
              .toEntity();
      expect(f.cheque.nroCheque, '12-34?56');
    });

    test('sin moneda no hay unidad: el importe se muestra sin pastilla', () {
      final f =
          VerificacionFilaModel.fromJson(filaJson(moneda: null)).toEntity();
      expect(f.cheque.moneda, isNull);
      expect(f.cheque.descMoneda, isNull);
      expect(f.cheque.unidadMoneda, '');
    });

    test(r'en dolares la unidad es $us', () {
      final f =
          VerificacionFilaModel.fromJson(filaJson(moneda: 'SUS')).toEntity();
      expect(f.cheque.unidadMoneda, r'$us');
    });

    test('ida y vuelta por JSON y por entidad', () {
      final m = VerificacionFilaModel.fromJson(filaJson());
      expect(VerificacionFilaModel.fromJson(m.toJson()).toJson(), m.toJson());
      expect(
        VerificacionFilaModel.fromEntity(m.toEntity()).toJson(),
        m.toJson(),
      );
    });
  });

  group('ChequePendienteVerificacionModel', () {
    final pendiente = {
      'fila': 1,
      'codCheque': 321,
      'codBanco': 7,
      'nroCheque': '5551',
      'montoCheque': 2350,
      'datoBancoCheque': 'BANCO UNION',
      'datoEstadoCheque': 'CERRADO',
      'fechaCobrarCheque': '2026-09-20',
      'chequeCerrado': true,
      'moneda': 'SUS',
      'descMoneda': r'$us',
    };

    test('codBanco es el banco DEL CHEQUE y un cheque cerrado no se puede elegir', () {
      final p = ChequePendienteVerificacionModel.fromJson(pendiente).toEntity();
      expect(p.codCheque, BigInt.from(321));
      expect(p.codBancoCheque, 7);
      expect(
        p.cheque.montoCheque,
        2350.0,
        reason: 'un entero del JSON es un double',
      );
      expect(p.cheque.chequeCerrado, isTrue);
      expect(p.seleccionable, isFalse);
      final abierto =
          ChequePendienteVerificacionModel.fromJson({
            ...pendiente,
            'chequeCerrado': false,
          }).toEntity();
      expect(abierto.seleccionable, isTrue);
    });

    test('ida y vuelta', () {
      final m = ChequePendienteVerificacionModel.fromJson(pendiente);
      expect(
        ChequePendienteVerificacionModel.fromJson(m.toJson()).toJson(),
        m.toJson(),
      );
      expect(
        ChequePendienteVerificacionModel.fromEntity(m.toEntity()).toJson(),
        m.toJson(),
      );
    });
  });

  group('PaginaVerificacionModel', () {
    test('lee {total, pagina, tamanio, filas} y calcula las paginas', () {
      final m = PaginaVerificacionModel<VerificacionFilaModel, dynamic>.fromJson({
        'total': 45,
        'pagina': 2,
        'tamanio': 20,
        'filas': [filaJson(), filaJson(codvd: 13)],
      }, fila: VerificacionFilaModel.fromJson);
      final p = m.toEntity((f) => f.toEntity());
      expect(p.total, 45);
      expect(p.pagina, 2);
      expect(p.totalPaginas, 3);
      expect(p.filas, hasLength(2));
      expect(p.hayAnterior, isTrue);
      expect(p.haySiguiente, isTrue);
      expect(p.desde, 21);
      expect(p.hasta, 22);
    });

    test('sin filas ni totales usa valores seguros', () {
      final m = PaginaVerificacionModel<VerificacionFilaModel, dynamic>.fromJson(
        const {},
        fila: VerificacionFilaModel.fromJson,
      );
      expect(m.total, 0);
      expect(m.pagina, 1);
      expect(m.tamanio, 20);
      expect(m.filas, isEmpty);
      expect(m.toEntity((f) => f.toEntity()).totalPaginas, 0);
    });
  });

  group('lo que se manda', () {
    test('el filtro de la lista: con fecha viaja yyyy-MM-dd; sin fecha no viaja nada', () {
      final con =
          VerificacionFiltroModel.fromEntity(
            VerificacionFiltroEntity(
              fechaBanco: DateTime(2026, 10, 3),
              pagina: 2,
              tamanio: 20,
            ),
          ).toJson();
      expect(con, {'fechaBanco': '2026-10-03', 'pagina': 2, 'tamanio': 20});

      final sin =
          VerificacionFiltroModel.fromEntity(
            const VerificacionFiltroEntity(),
          ).toJson();
      expect(sin.containsKey('fechaBanco'), isFalse, reason: 'ausente = todas');
      expect(sin, {'pagina': 1, 'tamanio': 20});
    });

    test('el filtro de pendientes: por defecto PEN y solo hoy; «Todos» no manda estado', () {
      final porDefecto =
          PendientesVerificacionFiltroModel.fromEntity(
            const PendientesVerificacionFiltroEntity(),
          ).toJson();
      expect(porDefecto, {
        'estado': 'PEN',
        'soloCobranzaHoy': true,
        'pagina': 1,
        'tamanio': 20,
      });

      final todos =
          PendientesVerificacionFiltroModel.fromEntity(
            const PendientesVerificacionFiltroEntity().copyWith(
              todosLosEstados: true,
              soloCobranzaHoy: false,
            ),
          ).toJson();
      expect(todos.containsKey('estado'), isFalse);
      expect(
        todos['soloCobranzaHoy'],
        false,
        reason: 'false viaja: es el «1» del legacy',
      );
    });

    test('el registro: sin estado ni usuario, con el dia y la observacion recortada', () {
      final j =
          VerificacionRegistroModel.fromEntity(
            VerificacionRegistroEntity(
              codvd: BigInt.zero,
              codCheque: BigInt.from(321),
              codBanco: 8,
              fechaBanco: DateTime(2026, 10, 3, 18, 45),
              observacion: '  Cobrado  ',
            ),
          ).toJson();
      expect(j, {
        'codvd': 0,
        'codCheque': 321,
        'codBanco': 8,
        'fechaBanco': '2026-10-03',
        'observacion': 'Cobrado',
      });
      expect(j.containsKey('estado'), isFalse, reason: 'lo fija el servidor');
      expect(j.containsKey('audUsuario'), isFalse, reason: 'sale del token');
    });

    test('un registro con codvd 0 es un alta y con otro codvd es una edicion', () {
      VerificacionRegistroEntity r(int codvd) => VerificacionRegistroEntity(
        codvd: BigInt.from(codvd),
        codCheque: BigInt.one,
        codBanco: 1,
        fechaBanco: DateTime(2026, 1, 1),
        observacion: '',
      );
      expect(r(0).esAlta, isTrue);
      expect(r(5).esAlta, isFalse);
    });
  });

  group('VerificacionPreparadaModel', () {
    test('lee {cheque, fechaBanco}', () {
      final p =
          VerificacionPreparadaModel.fromJson({
            'cheque': {
              'fila': 1,
              'codCheque': 321,
              'codBanco': 7,
              'nroCheque': '5551',
              'montoCheque': 100.0,
              'datoBancoCheque': 'BANCO UNION',
              'datoEstadoCheque': 'PENDIENTE',
              'fechaCobrarCheque': '2026-10-03',
              'chequeCerrado': false,
              'moneda': 'BS',
              'descMoneda': 'Bs',
            },
            'fechaBanco': '2026-10-03',
          }).toEntity();
      expect(p.cheque.codCheque, BigInt.from(321));
      expect(p.cheque.codBancoCheque, 7);
      expect(p.fechaBanco, DateTime(2026, 10, 3));
    });

    test('si no llega la fecha se propone el dia del dispositivo (el servidor la valida igual)', () {
      final p = VerificacionPreparadaModel.fromJson({
        'cheque': const <String, dynamic>{},
      });
      final hoy = DateTime.now();
      expect(p.fechaBanco, DateTime(hoy.year, hoy.month, hoy.day));
    });
  });
}
