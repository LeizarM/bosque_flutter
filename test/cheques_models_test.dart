import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/data/models/accion_cheque_model.dart';
import 'package:bosque_flutter/data/models/accion_cheque_request_model.dart';
import 'package:bosque_flutter/data/models/banco_registro_model.dart';
import 'package:bosque_flutter/data/models/botones_cheque_model.dart';
import 'package:bosque_flutter/data/models/catalogos_cheque_model.dart';
import 'package:bosque_flutter/data/models/cheque_detalle_model.dart';
import 'package:bosque_flutter/data/models/cheque_fila_model.dart';
import 'package:bosque_flutter/data/models/cheque_filtro_model.dart';
import 'package:bosque_flutter/data/models/cheque_model.dart';
import 'package:bosque_flutter/data/models/cheque_pagina_model.dart';
import 'package:bosque_flutter/data/models/cheque_registro_model.dart';
import 'package:bosque_flutter/data/models/cheque_resumen_model.dart';
import 'package:bosque_flutter/data/models/custodia_cheque_request_model.dart';
import 'package:bosque_flutter/data/models/dar_custodia_request_model.dart';
import 'package:bosque_flutter/data/models/entrega_cheque_model.dart';
import 'package:bosque_flutter/data/models/hora_traspaso_cheque_model.dart';
import 'package:bosque_flutter/data/models/personal_cheque_model.dart';
import 'package:bosque_flutter/data/models/sucursal_cheque_model.dart';
import 'package:bosque_flutter/data/models/talonario_validacion_model.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_pagina_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/custodia_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/dar_custodia_request_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_validacion_entity.dart';

/// Los modelos del modulo de cheques frente al JSON que describe
/// API_CHEQUES.md: lo que llega del backend y lo que se le manda.
///
/// Los ejemplos reproducen los casos incomodos de la base de prueba: `descTipo`
/// nulo, un `tipo` con caracteres raros, `codEmpleado` 0, `audFecha` como texto
/// de datetimeoffset y acciones con fecha ISO con hora.
void main() {
  // Una fila de la grilla tal como la devuelve /cheque/listar.
  Map<String, dynamic> filaJson() => {
    'codCheque': 9718,
    'nrocheque': '000123-4',
    'codCliente': 'ADI0229',
    'aOrdenDe': 'BOSQUE S.A.',
    'fechaCheque': '2026-08-31',
    'fechaCobrar': '2026-09-15',
    'monto': 1500.5,
    'moneda': 'BS',
    'tipo': 'PAG',
    'estado': 'PEN',
    'codBanco': 7,
    'codEmpleado': 0,
    'reciboManual': '0',
    'codSucursal': 3,
    'nroRecibo': 55,
    'nroTalonario': '0',
    'codEmpresa': 1,
    'audUsuario': 47,
    'audFecha': '2026-08-31 14:54:51.5670000 +00:00',
    'fechaRecepcion': '2026-08-31',
    'datoCliente': 'ADDY SALAZAR ORTIZ - EDITORA MENDEZ - CBBA',
    'descMoneda': 'Bs',
    'descTipo': null,
    'descEstado': 'PENDIENTE',
    'nombreBanco': 'BANCO UNION',
    'datoEmpleado': ' - Entregado por el Cliente -',
    'observacion': 'Recibido en caja',
    'datoEmpresa': 'ESPPAPEL',
    'fila': 1,
  };

  Map<String, dynamic> accionJson({
    int cod = 1,
    String estado = 'REC',
    Object? codEmpleado,
  }) => {
    'codAccion': cod,
    'codCheque': 9718,
    'fecha': '2026-08-31T09:30:15',
    'estado': estado,
    'codEmpleado': codEmpleado,
    'nroSAP': null,
    'observacion': 'Recibido en caja',
    'audUsuario': 47,
    'audFecha': '2026-08-31T09:30:15',
    'descripcion': 'RECIBIDO',
    'nro': cod,
  };

  /// Lo que viajaria por la red: se pasa por jsonEncode/jsonDecode para que la
  /// comparacion sea la del cable y no la de objetos de Dart.
  Map<String, dynamic> cable(Map<String, dynamic> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  group('ChequeModel (espejo de tch_cheque)', () {
    test('lee las 19 columnas con los nombres exactos', () {
      final c = ChequeModel.fromJson(filaJson());
      expect(c.codCheque, BigInt.from(9718));
      expect(c.nrocheque, '000123-4');
      expect(c.codCliente, 'ADI0229');
      expect(c.aOrdenDe, 'BOSQUE S.A.');
      expect(c.fechaCheque, DateTime(2026, 8, 31));
      expect(c.fechaCobrar, DateTime(2026, 9, 15));
      expect(c.monto, 1500.5);
      expect(c.moneda, 'BS');
      expect(c.tipo, 'PAG');
      expect(c.estado, 'PEN');
      expect(c.codBanco, 7);
      expect(c.codEmpleado, 0);
      expect(c.reciboManual, '0');
      expect(c.codSucursal, 3);
      expect(c.nroRecibo, 55);
      expect(c.nroTalonario, '0');
      expect(c.codEmpresa, 1);
      expect(c.audUsuario, 47);
    });

    test('ida y vuelta: toJson devuelve las mismas claves y valores', () {
      final original =
          filaJson()..removeWhere(
            (k, _) => const {
              'fechaRecepcion',
              'datoCliente',
              'descMoneda',
              'descTipo',
              'descEstado',
              'nombreBanco',
              'datoEmpleado',
              'observacion',
              'datoEmpresa',
              'fila',
            }.contains(k),
          );
      expect(cable(ChequeModel.fromJson(original).toJson()), original);
    });

    test('audFecha es texto de datetimeoffset y se guarda sin tocar', () {
      final c = ChequeModel.fromJson(filaJson());
      expect(c.audFecha, '2026-08-31 14:54:51.5670000 +00:00');
      expect(c.toJson()['audFecha'], '2026-08-31 14:54:51.5670000 +00:00');
    });

    test(
      'casi todo es NULL en la base: solo codCheque y nrocheque cuentan',
      () {
        final c = ChequeModel.fromJson({'codCheque': 5, 'nrocheque': '77'});
        expect(c.codCliente, isNull);
        expect(c.aOrdenDe, isNull);
        expect(c.fechaCheque, isNull);
        expect(c.fechaCobrar, isNull);
        expect(c.monto, isNull);
        expect(c.moneda, isNull);
        expect(c.tipo, isNull);
        expect(c.estado, isNull);
        expect(c.codBanco, isNull);
        expect(c.codEmpleado, isNull);
        expect(c.reciboManual, isNull);
        expect(c.codSucursal, isNull);
        expect(c.nroRecibo, isNull);
        expect(c.nroTalonario, isNull);
        expect(c.codEmpresa, isNull);
        expect(c.audUsuario, isNull);
        expect(c.audFecha, isNull);
        // Y vuelve a salir con nulls, sin reventar al serializar.
        expect(c.toJson()['fechaCheque'], isNull);
      },
    );

    test('un JSON vacio no revienta', () {
      final c = ChequeModel.fromJson(const {});
      expect(c.codCheque, BigInt.zero);
      expect(c.nrocheque, '');
    });

    test('nroRecibo y codSucursal grandes (bigint) no se truncan', () {
      final c = ChequeModel.fromJson({
        'codCheque': 1,
        'nrocheque': '1',
        'codSucursal': 4294967296,
        'nroRecibo': 9007199254740991,
      });
      expect(c.codSucursal, 4294967296);
      expect(c.nroRecibo, 9007199254740991);
    });

    test('toEntity y fromEntity conservan todo', () {
      final c = ChequeModel.fromJson(filaJson());
      final vuelta = ChequeModel.fromEntity(c.toEntity());
      expect(cable(vuelta.toJson()), cable(c.toJson()));
    });

    test('la entidad lee el estado y la entrega sin espacios', () {
      final c = ChequeModel.fromJson(filaJson()).toEntity();
      expect(c.estaPendiente, isTrue);
      expect(c.estaCerrado, isFalse);
      expect(c.loEntregoElCliente, isTrue);
      expect(c.sinReciboManual, isTrue);
      expect(c.sinTalonario, isTrue);
      expect(c.esNuevo, isFalse);

      final cerrado =
          ChequeModel.fromJson({...filaJson(), 'estado': 'CER '}).toEntity();
      expect(cerrado.estaCerrado, isTrue);

      final sinEstado =
          ChequeModel.fromJson({...filaJson(), 'estado': null}).toEntity();
      expect(sinEstado.estaCerrado, isFalse);
    });
  });

  group('ChequeFilaModel (la fila de la grilla)', () {
    test('compone el cheque y agrega lo que sale de los JOIN', () {
      final f = ChequeFilaModel.fromJson(filaJson()).toEntity();
      expect(f.cheque.nrocheque, '000123-4');
      expect(f.codCheque, BigInt.from(9718));
      expect(f.fechaRecepcion, DateTime(2026, 8, 31));
      expect(f.datoCliente, 'ADDY SALAZAR ORTIZ - EDITORA MENDEZ - CBBA');
      expect(f.descMoneda, 'Bs');
      expect(f.descEstado, 'PENDIENTE');
      expect(f.nombreBanco, 'BANCO UNION');
      expect(f.datoEmpleado, ' - Entregado por el Cliente -');
      expect(f.observacion, 'Recibido en caja');
      expect(f.datoEmpresa, 'ESPPAPEL');
      expect(f.fila, 1);
    });

    test('tolera descTipo null (el tipo esta corrupto en la base)', () {
      final f = ChequeFilaModel.fromJson(filaJson()).toEntity();
      expect(f.descTipo, isNull);
    });

    test('tolera un tipo con caracteres raros y lo devuelve igual', () {
      // En la base de prueba el tipo son los bytes crudos de «PAG» dentro de un
      // nvarchar: llegan como un texto sin sentido.
      const raro = 'ä\u0000䅐Gé';
      final json = {...filaJson(), 'tipo': raro};
      final f = ChequeFilaModel.fromJson(json);
      expect(f.cheque.tipo, raro);
      expect(f.toEntity().cheque.tipo, raro);
      expect(cable(f.toJson())['tipo'], raro);
    });

    test('audFecha en texto no se parsea como fecha', () {
      final f = ChequeFilaModel.fromJson(filaJson()).toEntity();
      expect(f.cheque.audFecha, '2026-08-31 14:54:51.5670000 +00:00');
    });

    test('ida y vuelta completa del JSON plano', () {
      final original = filaJson();
      expect(cable(ChequeFilaModel.fromJson(original).toJson()), original);
    });

    test('fromEntity(toEntity) es identidad', () {
      final m = ChequeFilaModel.fromJson(filaJson());
      expect(
        cable(ChequeFilaModel.fromEntity(m.toEntity()).toJson()),
        filaJson(),
      );
    });

    test('sin fechaRecepcion ni observacion tampoco revienta', () {
      final f =
          ChequeFilaModel.fromJson({
            ...filaJson(),
            'fechaRecepcion': null,
            'observacion': null,
          }).toEntity();
      expect(f.fechaRecepcion, isNull);
      expect(f.observacion, isNull);
    });
  });

  group('AccionChequeModel (espejo de tch_accion)', () {
    test('lee la fecha ISO con hora y el nroSAP', () {
      final a =
          AccionChequeModel.fromJson({
            ...accionJson(estado: 'COB', codEmpleado: 0),
            'nroSAP': 'SAP-123',
          }).toEntity();
      expect(a.codAccion, BigInt.one);
      expect(a.codCheque, BigInt.from(9718));
      expect(a.fecha, DateTime(2026, 8, 31, 9, 30, 15));
      expect(a.estado, 'COB');
      expect(a.nroSAP, 'SAP-123');
      expect(a.codEmpleado, 0);
      expect(a.descripcion, 'RECIBIDO');
      expect(a.nro, 1);
    });

    test('codEmpleado null en REC y 0 en las manuales son cosas distintas', () {
      final rec = AccionChequeModel.fromJson(accionJson()).toEntity();
      final dev =
          AccionChequeModel.fromJson(
            accionJson(estado: 'DEV', codEmpleado: 0),
          ).toEntity();
      expect(rec.codEmpleado, isNull);
      expect(dev.codEmpleado, 0);
    });

    test('ida y vuelta: la fecha vuelve con T y hora', () {
      final original = accionJson(cod: 7, estado: 'CUS', codEmpleado: 12);
      final vuelta = cable(AccionChequeModel.fromJson(original).toJson());
      expect(vuelta, original);
      expect(vuelta['fecha'], '2026-08-31T09:30:15');
    });

    test('el campo se llama nroSAP, no nroSap', () {
      final json = AccionChequeModel.fromJson(accionJson()).toJson();
      expect(json.containsKey('nroSAP'), isTrue);
      expect(json.containsKey('nroSap'), isFalse);
    });

    test('una accion con un estado fuera del catalogo se lee igual', () {
      final a =
          AccionChequeModel.fromJson({
            ...accionJson(),
            'estado': 'PEN',
            'descripcion': '',
          }).toEntity();
      expect(a.estado, 'PEN');
      expect(a.descripcion, '');
    });

    test('esBase marca REC, TRASP y CUS', () {
      bool base(String e) =>
          AccionChequeModel.fromJson(accionJson(estado: e)).toEntity().esBase;
      expect(base('REC'), isTrue);
      expect(base('TRASP'), isTrue);
      expect(base('CUS'), isTrue);
      expect(base('DEV'), isFalse);
      expect(base('COB'), isFalse);
    });

    test('fromEntity(toEntity) es identidad', () {
      final m = AccionChequeModel.fromJson(accionJson(codEmpleado: 3));
      expect(
        cable(AccionChequeModel.fromEntity(m.toEntity()).toJson()),
        accionJson(codEmpleado: 3),
      );
    });
  });

  group('botones (rama K)', () {
    test('lee los cuatro booleanos y el codigo', () {
      final b =
          BotonesChequeModel.fromJson({
            'fechaCobro': false,
            'devolver': true,
            'cerrarConVerificacion': false,
            'cerrarSinVerificacion': true,
            'codigo': '0101',
          }).toEntity();
      expect(b.fechaCobro, isFalse);
      expect(b.devolver, isTrue);
      expect(b.cerrarConVerificacion, isFalse);
      expect(b.cerrarSinVerificacion, isTrue);
      expect(b.codigo, '0101');
      expect(b.hayAlguno, isTrue);
    });

    test('si falta un booleano se lee del caracter que le corresponde', () {
      final b = BotonesChequeModel.fromJson({'codigo': '1000'}).toEntity();
      expect(b.fechaCobro, isTrue);
      expect(b.devolver, isFalse);
      expect(b.cerrarConVerificacion, isFalse);
      expect(b.cerrarSinVerificacion, isFalse);
    });

    test('cualquier cosa que no sea un 1 deshabilita', () {
      final b = BotonesChequeModel.fromJson({'codigo': '0x2?'}).toEntity();
      expect(b.hayAlguno, isFalse);
      final vacio = BotonesChequeModel.fromJson(const {}).toEntity();
      expect(vacio.hayAlguno, isFalse);
    });

    test('ida y vuelta', () {
      final original = {
        'fechaCobro': false,
        'devolver': false,
        'cerrarConVerificacion': true,
        'cerrarSinVerificacion': false,
        'codigo': '0010',
      };
      expect(cable(BotonesChequeModel.fromJson(original).toJson()), original);
    });
  });

  group('detalle y pagina', () {
    test('el detalle trae cheque, acciones y botones', () {
      final d =
          ChequeDetalleModel.fromJson({
            'cheque': filaJson(),
            'acciones': [accionJson(), accionJson(cod: 2, estado: 'TRASP')],
            'botones': {
              'fechaCobro': true,
              'devolver': false,
              'cerrarConVerificacion': false,
              'cerrarSinVerificacion': false,
              'codigo': '1000',
            },
          }).toEntity();
      expect(d.cheque.codCheque, BigInt.from(9718));
      expect(d.acciones.map((a) => a.estado), ['REC', 'TRASP']);
      expect(d.botones.fechaCobro, isTrue);
    });

    test('sin botones el detalle los deja todos deshabilitados', () {
      final d =
          ChequeDetalleModel.fromJson({
            'cheque': filaJson(),
            'acciones': [],
          }).toEntity();
      expect(d.botones.hayAlguno, isFalse);
      expect(d.botones.codigo, BotonesChequeEntity.ninguno.codigo);
    });

    test('ida y vuelta del detalle', () {
      final original = {
        'cheque': filaJson(),
        'acciones': [accionJson()],
        'botones': {
          'fechaCobro': false,
          'devolver': false,
          'cerrarConVerificacion': false,
          'cerrarSinVerificacion': false,
          'codigo': '0000',
        },
      };
      expect(cable(ChequeDetalleModel.fromJson(original).toJson()), original);
    });

    test('la pagina calcula paginas y el rango de filas', () {
      final p =
          ChequePaginaModel.fromJson({
            'total': 45,
            'pagina': 2,
            'tamanio': 20,
            'filas': [for (var i = 0; i < 20; i++) filaJson()],
          }).toEntity();
      expect(p.totalPaginas, 3);
      expect(p.hayAnterior, isTrue);
      expect(p.haySiguiente, isTrue);
      expect(p.desde, 21);
      expect(p.hasta, 40);
    });

    test('la ultima pagina no tiene siguiente y la vacia no tiene rango', () {
      final ultima =
          ChequePaginaModel.fromJson({
            'total': 45,
            'pagina': 3,
            'tamanio': 20,
            'filas': [for (var i = 0; i < 5; i++) filaJson()],
          }).toEntity();
      expect(ultima.haySiguiente, isFalse);
      expect(ultima.hasta, 45);

      const vacia = ChequePaginaEntity.vacia();
      expect(vacia.totalPaginas, 0);
      expect(vacia.desde, 0);
      expect(vacia.hasta, 0);
      expect(vacia.hayAnterior, isFalse);
      expect(vacia.haySiguiente, isFalse);
    });

    test('ida y vuelta de la pagina', () {
      final original = {
        'total': 1,
        'pagina': 1,
        'tamanio': 20,
        'filas': [filaJson()],
      };
      expect(cable(ChequePaginaModel.fromJson(original).toJson()), original);
    });
  });

  group('catalogos y listas de apoyo', () {
    final catalogosJson = {
      'tiposCheque': [
        {'codigo': 'PAG', 'nombre': 'PAGO'},
        {'codigo': 'RES', 'nombre': 'RESPALDO'},
      ],
      'monedas': [
        {'codigo': 'BS', 'nombre': 'Bs'},
        {'codigo': 'SUS', 'nombre': r'$us'},
      ],
      'estadosCheque': [
        {'codigo': 'PEN', 'nombre': 'PENDIENTE'},
        {'codigo': 'CER', 'nombre': 'CERRADO'},
      ],
      'estadosAccion': [
        {'codigo': 'REC', 'nombre': 'RECIBIDO'},
        {'codigo': 'CUS', 'nombre': 'A COBRANZA'},
      ],
      'accionesFechaCobro': [
        {'codigo': 'VEN', 'nombre': 'VENCIDO-POSTERGADO'},
        {'codigo': 'ADE', 'nombre': 'ADELANTADO'},
      ],
      'accionesCierreConVerificacion': [
        {'codigo': 'COB', 'nombre': 'COBRADO'},
      ],
      'accionesCierreSinVerificacion': [
        {'codigo': 'CEF', 'nombre': 'CANJEADO EFECTIVO'},
        {'codigo': 'CCH', 'nombre': 'CANJEADO CHEQUE'},
        {'codigo': 'PAP', 'nombre': 'PAGO PARCIAL'},
        {'codigo': 'DPR', 'nombre': 'DEPOSITADO-RECHAZADO'},
      ],
    };

    test('catalogos: las siete listas y ida y vuelta', () {
      final m = CatalogosChequeModel.fromJson(catalogosJson);
      final c = m.toEntity();
      expect(c.tiposCheque.map((o) => o.codigo), ['PAG', 'RES']);
      expect(c.monedas.last.nombre, r'$us');
      expect(c.accionesFechaCobro.map((o) => o.codigo), ['VEN', 'ADE']);
      expect(c.accionesCierreConVerificacion.single.codigo, 'COB');
      expect(c.accionesCierreSinVerificacion, hasLength(4));
      expect(cable(m.toJson()), catalogosJson);
      expect(cable(CatalogosChequeModel.fromEntity(c).toJson()), catalogosJson);
    });

    test('catalogos: el nombre de un estado, o el codigo si no esta', () {
      final c = CatalogosChequeModel.fromJson(catalogosJson).toEntity();
      expect(c.nombreEstadoAccion('CUS'), 'A COBRANZA');
      expect(c.nombreEstadoAccion('PEN'), 'PEN');
    });

    test('catalogos: listas ausentes son listas vacias', () {
      final c = CatalogosChequeModel.fromJson(const {}).toEntity();
      expect(c.tiposCheque, isEmpty);
      expect(c.accionesCierreSinVerificacion, isEmpty);
    });

    test('personal: codEmpleado y nombreCompleto', () {
      final j = {'codEmpleado': 12, 'nombreCompleto': 'PEREZ JUAN'};
      final e = PersonalChequeModel.fromJson(j).toEntity();
      expect(e.codEmpleado, 12);
      expect(e.nombreCompleto, 'PEREZ JUAN');
      expect(cable(PersonalChequeModel.fromEntity(e).toJson()), j);
    });

    test('sucursal: codSucursal y nombre', () {
      final j = {'codSucursal': 3, 'nombre': 'LA PAZ'};
      final e = SucursalChequeModel.fromJson(j).toEntity();
      expect(e.codSucursal, 3);
      expect(cable(SucursalChequeModel.fromEntity(e).toJson()), j);
    });

    test('resumen de cheque (Dar Custodia, paso 1)', () {
      final j = {
        'codCheque': 9718,
        'datoCheque': 'Nro Cheque : 123, Cliente : X, Monto (BS) : 10',
      };
      final e = ChequeResumenModel.fromJson(j).toEntity();
      expect(e.codCheque, BigInt.from(9718));
      expect(cable(ChequeResumenModel.fromEntity(e).toJson()), j);
    });

    test('entrega del dia (Dar Custodia, paso 2)', () {
      final j = {'codAccion': 88, 'hora': '09:15 Entregado a PEREZ JUAN'};
      final e = EntregaChequeModel.fromJson(j).toEntity();
      expect(e.codAccion, BigInt.from(88));
      expect(cable(EntregaChequeModel.fromEntity(e).toJson()), j);
    });

    test('hora de un traspaso (Imp Traspso): codAccion es un int simple', () {
      final j = {'codAccion': 91, 'hora': '16:40'};
      final e = HoraTraspasoChequeModel.fromJson(j).toEntity();
      expect(e.codAccion, 91);
      expect(e.hora, '16:40');
      expect(cable(HoraTraspasoChequeModel.fromEntity(e).toJson()), j);
    });

    test('hora de un traspaso: columnas nulas o numeros con decimales', () {
      final vacio = HoraTraspasoChequeModel.fromJson({
        'codAccion': null,
        'hora': null,
      });
      expect(vacio.codAccion, 0);
      expect(vacio.hora, '');
      expect(
        HoraTraspasoChequeModel.fromJson({'codAccion': 7.0, 'hora': '08:00'})
            .codAccion,
        7,
      );
    });
  });

  group('peticiones: lo que se le manda al backend', () {
    /// Ninguna peticion de este modulo lleva el usuario de auditoria: el
    /// backend lo toma del token.
    void sinAuditoria(Map<String, dynamic> cuerpo) {
      expect(cuerpo.containsKey('audUsuario'), isFalse);
      expect(cuerpo.containsKey('audFecha'), isFalse);
    }

    test(
      'listar: solo viajan los criterios con valor, con fechas yyyy-MM-dd',
      () {
        final f = const ChequeFiltroEntity(codSucursal: 3).conCriterios(
          nroCheque: ' 123 ',
          cliente: '   ',
          estado: 'PEN',
          codBanco: 0,
          fechaCobro: DateTime(2026, 9, 5, 14, 30),
          fechaRecepcionDesde: DateTime(2026, 7, 3),
          fechaRecepcionHasta: DateTime(2026, 10, 3, 18, 45),
        );
        final cuerpo = ChequeFiltroModel.fromEntity(f).toJson();
        expect(cuerpo, {
          'codSucursal': 3,
          'nroCheque': '123',
          'estado': 'PEN',
          'fechaCobro': '2026-09-05',
          'fechaRecepcionDesde': '2026-07-03',
          'fechaRecepcionHasta': '2026-10-03',
          'orden': 'RECEPCION',
          'pagina': 1,
          'tamanio': 20,
        });
        sinAuditoria(cuerpo);
      },
    );

    test(
      'listar: las dos fechas de recepcion viajan por separado y la clave '
      'antigua `fechaRecepcion` ya no se manda',
      () {
        final soloDesde =
            ChequeFiltroModel.fromEntity(
              ChequeFiltroEntity(
                codSucursal: 3,
                fechaRecepcionDesde: DateTime(2026, 7, 3),
              ),
            ).toJson();
        expect(soloDesde['fechaRecepcionDesde'], '2026-07-03');
        expect(soloDesde.containsKey('fechaRecepcionHasta'), isFalse);

        final soloHasta =
            ChequeFiltroModel.fromEntity(
              ChequeFiltroEntity(
                codSucursal: 3,
                fechaRecepcionHasta: DateTime(2026, 10, 3),
              ),
            ).toJson();
        expect(soloHasta['fechaRecepcionHasta'], '2026-10-03');
        expect(soloHasta.containsKey('fechaRecepcionDesde'), isFalse);

        final ninguna =
            ChequeFiltroModel.fromEntity(
              const ChequeFiltroEntity(codSucursal: 3),
            ).toJson();
        expect(ninguna.containsKey('fechaRecepcionDesde'), isFalse);
        expect(ninguna.containsKey('fechaRecepcionHasta'), isFalse);

        for (final c in [soloDesde, soloHasta, ninguna]) {
          expect(c.containsKey('fechaRecepcion'), isFalse);
          sinAuditoria(c);
        }
      },
    );

    test('listar: orden por cobro, pagina y tamanio', () {
      const f = ChequeFiltroEntity(
        codSucursal: 3,
        orden: OrdenCheques.cobro,
        pagina: 4,
        tamanio: 50,
      );
      final cuerpo = ChequeFiltroModel.fromEntity(f).toJson();
      expect(cuerpo['orden'], 'COBRO');
      expect(cuerpo['pagina'], 4);
      expect(cuerpo['tamanio'], 50);
    });

    test('listar: pagina menor a 1 y tamanio fuera de rango se corrigen', () {
      const f = ChequeFiltroEntity(codSucursal: 3, pagina: 0, tamanio: 5000);
      final cuerpo = ChequeFiltroModel.fromEntity(f).toJson();
      expect(cuerpo['pagina'], 1);
      expect(cuerpo['tamanio'], 200);
    });

    test('registrar: no lleva estado, nroRecibo, audUsuario ni audFecha', () {
      final r = ChequeRegistroEntity(
        codCheque: BigInt.zero,
        nrocheque: ' 000123 ',
        codCliente: 'ADI0229',
        aOrdenDe: 'BOSQUE S.A.',
        fechaCheque: DateTime(2026, 8, 31),
        fechaCobrar: DateTime(2026, 8, 31, 23, 59),
        monto: 1500.5,
        moneda: 'BS',
        tipo: 'PAG',
        codBanco: 7,
        codEmpleado: 0,
        reciboManual: '0',
        codSucursal: 3,
        nroTalonario: '0',
        codEmpresa: 1,
        observacion: 'Recibido en caja',
      );
      final cuerpo = ChequeRegistroModel.fromEntity(r).toJson();
      expect(cuerpo, {
        'codCheque': 0,
        'modo': 'ESTANDAR',
        'nrocheque': '000123',
        'codCliente': 'ADI0229',
        'aOrdenDe': 'BOSQUE S.A.',
        'fechaCheque': '2026-08-31',
        'fechaCobrar': '2026-08-31',
        'monto': 1500.5,
        'moneda': 'BS',
        'tipo': 'PAG',
        'codBanco': 7,
        'codEmpleado': 0,
        'reciboManual': '0',
        'codSucursal': 3,
        'nroTalonario': '0',
        'codEmpresa': 1,
        'observacion': 'Recibido en caja',
      });
      expect(cuerpo.containsKey('estado'), isFalse);
      expect(cuerpo.containsKey('nroRecibo'), isFalse);
      sinAuditoria(cuerpo);
    });

    test('registrar: codEmpleado 0 (lo dejo el cliente) viaja; null no', () {
      final con0 =
          ChequeRegistroModel.fromEntity(
            ChequeRegistroEntity(codCheque: BigInt.zero, codEmpleado: 0),
          ).toJson();
      expect(con0['codEmpleado'], 0);
      final sin =
          ChequeRegistroModel.fromEntity(
            ChequeRegistroEntity(codCheque: BigInt.zero),
          ).toJson();
      expect(sin.containsKey('codEmpleado'), isFalse);
    });

    group('registrar: la observacion', () {
      Map<String, dynamic> cuerpo(BigInt cod, String? obs) =>
          ChequeRegistroModel.fromEntity(
            ChequeRegistroEntity(codCheque: cod, observacion: obs),
          ).toJson();

      test('en una edicion, vaciada viaja como cadena vacia (la borra)', () {
        for (final vacia in ['', '   ']) {
          final c = cuerpo(BigInt.from(9), vacia);
          expect(c.containsKey('observacion'), isTrue, reason: "'$vacia'");
          expect(c['observacion'], '');
        }
      });

      test('en una edicion, sin tocar (null) no viaja la clave', () {
        expect(cuerpo(BigInt.from(9), null).containsKey('observacion'), isFalse);
      });

      test('en una edicion, con texto viaja recortado', () {
        expect(cuerpo(BigInt.from(9), '  Nueva obs  ')['observacion'], 'Nueva obs');
      });

      test('en el alta, vacia no viaja: no hay nada que borrar', () {
        expect(cuerpo(BigInt.zero, '').containsKey('observacion'), isFalse);
        expect(cuerpo(BigInt.zero, '   ').containsKey('observacion'), isFalse);
        expect(cuerpo(BigInt.zero, null).containsKey('observacion'), isFalse);
        expect(cuerpo(BigInt.zero, 'Recibido')['observacion'], 'Recibido');
      });

      test('la cadena vacia sobrevive a sacar las claves nulas', () {
        final c = cuerpo(BigInt.from(9), '');
        // Solo codCheque, modo y la observacion vacia: nada mas viaja.
        expect(c, {'codCheque': 9, 'modo': 'ESTANDAR', 'observacion': ''});
      });
    });

    test('registrar: los tres modos viajan con su codigo', () {
      String modo(ModoRegistroCheque m) =>
          ChequeRegistroModel.fromEntity(
                ChequeRegistroEntity(codCheque: BigInt.one, modo: m),
              ).toJson()['modo']
              as String;
      expect(modo(ModoRegistroCheque.estandar), 'ESTANDAR');
      expect(modo(ModoRegistroCheque.talonario), 'TALONARIO');
      expect(modo(ModoRegistroCheque.admin), 'ADMIN');
    });

    test('registrar: una edicion parte de los datos actuales del cheque', () {
      final c = ChequeModel.fromJson(filaJson()).toEntity();
      final r = ChequeRegistroEntity.desdeCheque(
        c,
        modo: ModoRegistroCheque.talonario,
      );
      expect(r.esAlta, isFalse);
      expect(r.codCheque, BigInt.from(9718));
      final cuerpo = ChequeRegistroModel.fromEntity(r).toJson();
      expect(cuerpo['codCheque'], 9718);
      expect(cuerpo['modo'], 'TALONARIO');
      expect(cuerpo['fechaCheque'], '2026-08-31');
      expect(cuerpo.containsKey('estado'), isFalse);
      expect(cuerpo.containsKey('nroRecibo'), isFalse);
      sinAuditoria(cuerpo);
    });

    test('accion: nroSap en minuscula, fechas yyyy-MM-dd, sin vacios', () {
      final a = AccionChequeRequestEntity(
        codCheque: BigInt.from(9718),
        fecha: DateTime(2026, 9, 1, 10, 45),
        estado: 'COB',
        nroSap: ' SAP-77 ',
        observacion: '   ',
        conVerificacion: true,
        nuevaFechaCobro: DateTime(2026, 9, 30),
      );
      final cuerpo = AccionChequeRequestModel.fromEntity(a).toJson();
      expect(cuerpo, {
        'codCheque': 9718,
        'fecha': '2026-09-01',
        'estado': 'COB',
        'nroSap': 'SAP-77',
        'conVerificacion': true,
        'nuevaFechaCobro': '2026-09-30',
      });
      expect(cuerpo.containsKey('nroSAP'), isFalse);
      sinAuditoria(cuerpo);
    });

    test('accion: conVerificacion false viaja (no es lo mismo que null)', () {
      final cuerpo =
          AccionChequeRequestModel.fromEntity(
            AccionChequeRequestEntity(
              codCheque: BigInt.one,
              conVerificacion: false,
            ),
          ).toJson();
      expect(cuerpo['conVerificacion'], isFalse);
      expect(
        AccionChequeRequestModel.fromEntity(
          AccionChequeRequestEntity(codCheque: BigInt.one),
        ).toJson().containsKey('conVerificacion'),
        isFalse,
      );
    });

    test(
      'custodia: la sucursal, el responsable y los cheques como numeros',
      () {
        final cuerpo =
            CustodiaChequeRequestModel.fromEntity(
              CustodiaChequeRequestEntity(
                codSucursal: 3,
                codEmpleado: 12,
                codCheques: [BigInt.from(9718), BigInt.from(9719)],
              ),
            ).toJson();
        expect(cuerpo, {
          'codSucursal': 3,
          'codEmpleado': 12,
          'codCheques': [9718, 9719],
        });
        sinAuditoria(cuerpo);
      },
    );

    test('dar custodia: sucursal, accion de origen y cheque', () {
      final cuerpo =
          DarCustodiaRequestModel.fromEntity(
            DarCustodiaRequestEntity(
              codSucursal: 3,
              codAccionOrigen: BigInt.from(88),
              codCheque: BigInt.from(9718),
            ),
          ).toJson();
      expect(cuerpo, {
        'codSucursal': 3,
        'codAccionOrigen': 88,
        'codCheque': 9718,
      });
      sinAuditoria(cuerpo);
    });

    test('banco: codBanco 0 es alta y el nombre va sin espacios de mas', () {
      const r = BancoRegistroEntity(codBanco: 0, nombre: '  BANCO UNION ');
      expect(r.esAlta, isTrue);
      final cuerpo = BancoRegistroModel.fromEntity(r).toJson();
      expect(cuerpo, {'codBanco': 0, 'nombre': 'BANCO UNION'});
      sinAuditoria(cuerpo);
    });
  });

  group('filtro de la grilla', () {
    test(
      'conCriterios reemplaza todo, vuelve a la pagina 1 y limpia blancos',
      () {
        final base = const ChequeFiltroEntity(
          codSucursal: 3,
          nroCheque: '123',
          estado: 'PEN',
          orden: OrdenCheques.cobro,
          pagina: 4,
        );
        final f = base.conCriterios(cliente: ' mendez ');
        expect(f.nroCheque, isNull);
        expect(f.estado, isNull);
        expect(f.cliente, 'mendez');
        expect(f.pagina, 1);
        expect(f.codSucursal, 3);
        expect(f.orden, OrdenCheques.cobro);
        expect(base.conCriterios().sinCriterios, isTrue);
      },
    );

    test('el rango de recepcion es un criterio y se distingue de los demas', () {
      const sin = ChequeFiltroEntity(codSucursal: 3);
      expect(sin.sinCriterios, isTrue);
      expect(sin.tieneRangoRecepcion, isFalse);

      final soloRango = ChequeFiltroEntity(
        codSucursal: 3,
        fechaRecepcionHasta: DateTime(2026, 10, 3),
      );
      expect(soloRango.sinCriterios, isFalse);
      expect(soloRango.tieneRangoRecepcion, isTrue);
      expect(soloRango.tieneCriteriosSalvoRecepcion, isFalse);

      const otro = ChequeFiltroEntity(codSucursal: 3, estado: 'PEN');
      expect(otro.tieneCriteriosSalvoRecepcion, isTrue);
      expect(otro.tieneRangoRecepcion, isFalse);
    });

    test('rangoRecepcionInvalido: solo con las dos fechas y hasta < desde', () {
      ChequeFiltroEntity con(DateTime? d, DateTime? h) => ChequeFiltroEntity(
        codSucursal: 3,
        fechaRecepcionDesde: d,
        fechaRecepcionHasta: h,
      );
      expect(
        con(DateTime(2026, 10, 3), DateTime(2026, 10, 2)).rangoRecepcionInvalido,
        isTrue,
      );
      expect(
        con(DateTime(2026, 10, 3), DateTime(2026, 10, 3)).rangoRecepcionInvalido,
        isFalse,
      );
      expect(con(DateTime(2026, 10, 3), null).rangoRecepcionInvalido, isFalse);
      expect(con(null, DateTime(2026, 1, 1)).rangoRecepcionInvalido, isFalse);
    });

    test('igualdad y copyWith tienen en cuenta las dos fechas de recepcion', () {
      final a = ChequeFiltroEntity(
        codSucursal: 3,
        fechaRecepcionDesde: DateTime(2026, 7, 3),
        fechaRecepcionHasta: DateTime(2026, 10, 3),
      );
      final b = ChequeFiltroEntity(
        codSucursal: 3,
        fechaRecepcionDesde: DateTime(2026, 7, 3),
        fechaRecepcionHasta: DateTime(2026, 10, 4),
      );
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
      final c = a.copyWith(pagina: 2, codSucursal: 4);
      expect(c.fechaRecepcionDesde, DateTime(2026, 7, 3));
      expect(c.fechaRecepcionHasta, DateTime(2026, 10, 3));
    });

    test('copyWith conserva los criterios', () {
      final f = const ChequeFiltroEntity(
        codSucursal: 3,
        nroCheque: '123',
      ).copyWith(pagina: 2, codSucursal: 4);
      expect(f.nroCheque, '123');
      expect(f.pagina, 2);
      expect(f.codSucursal, 4);
    });

    test('igualdad por valor', () {
      const a = ChequeFiltroEntity(codSucursal: 3, nroCheque: '1');
      const b = ChequeFiltroEntity(codSucursal: 3, nroCheque: '1');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(pagina: 2), isFalse);
    });
  });

  group('TalonarioValidacionModel', () {
    test('lee valido, mensaje y detalle', () {
      final m = TalonarioValidacionModel.fromJson({
        'valido': false,
        'mensaje': 'Linea uno\nLinea dos',
        'detalle': null,
      });
      expect(m.valido, isFalse);
      expect(m.mensaje, 'Linea uno\nLinea dos');
      expect(m.detalle, isNull);
      final e = m.toEntity();
      expect(e.valido, isFalse);
      expect(e.mensaje, 'Linea uno\nLinea dos');
    });

    test('solo un false explicito rechaza: ausente o raro es valido', () {
      bool valido(Object? v) =>
          TalonarioValidacionModel.fromJson({'valido': v}).valido;
      expect(valido(false), isFalse);
      expect(valido('false'), isFalse);
      expect(valido(' FALSE '), isFalse);
      expect(valido(true), isTrue);
      expect(valido('true'), isTrue);
      expect(valido(null), isTrue);
      expect(valido(1), isTrue);
      expect(TalonarioValidacionModel.fromJson(const {}).valido, isTrue);
    });

    test('un texto vacio o de espacios es ausencia', () {
      final m = TalonarioValidacionModel.fromJson({
        'valido': true,
        'mensaje': '',
        'detalle': '  ',
      });
      expect(m.mensaje, isNull);
      expect(m.detalle, isNull);
    });

    test('ida y vuelta por la entidad', () {
      const e = TalonarioValidacionEntity(
        valido: true,
        detalle: 'Talonario ER1076 (IMPEXPAP): recibos del 3751 al 3800.',
      );
      final de = TalonarioValidacionModel.fromEntity(e).toEntity();
      expect(de.valido, isTrue);
      expect(de.detalle, e.detalle);
      expect(de.mensaje, isNull);
      expect(TalonarioValidacionEntity.sinObjeciones.valido, isTrue);
    });
  });
}
