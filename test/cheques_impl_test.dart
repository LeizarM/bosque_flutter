import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/repositories/bancos_impl.dart';
import 'package:bosque_flutter/data/repositories/cheques_impl.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/custodia_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/dar_custodia_request_entity.dart';

/// Los repositorios de cheques y de bancos contra el cable: un adaptador de Dio
/// falso devuelve respuestas con la forma del contrato (API_CHEQUES.md) y anota
/// lo que de verdad se mando (ruta y cuerpo JSON ya serializado).
///
/// Cubre lo que los modelos solos no pueden: que cada metodo pegue a su
/// endpoint, que el 204 sea vacio y no error, que el mensaje de un 400 llegue
/// intacto y que ningun cuerpo lleve el usuario de auditoria.
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late _Adaptador cable;
  late ChequesImpl repo;
  late BancosImpl bancos;

  setUp(() {
    cable = _Adaptador();
    repo = ChequesImpl();
    bancos = BancosImpl();
    // El cliente es un singleton: se le quitan los interceptores (leen el token
    // del almacen seguro) y se le pone el adaptador falso. Solo vale para esta
    // prueba, que corre en su propio proceso.
    repo.dio.interceptors.clear();
    repo.dio.httpClientAdapter = cable;
  });

  Map<String, dynamic> envelope(Object? data, {int status = 200}) => {
    'message': 'ok',
    'data': data,
    'status': status,
  };

  Map<String, dynamic> filaJson(int cod) => {
    'codCheque': cod,
    'nrocheque': '$cod',
    'codCliente': 'C$cod',
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
    'nroRecibo': cod,
    'nroTalonario': '0',
    'codEmpresa': 1,
    'audUsuario': 47,
    'audFecha': '2026-08-31 14:54:51.5670000 +00:00',
    'fechaRecepcion': '2026-08-31',
    'datoCliente': 'EDITORA MENDEZ',
    'descMoneda': 'Bs',
    'descTipo': null,
    'descEstado': 'PENDIENTE',
    'nombreBanco': 'BANCO UNION',
    'datoEmpleado': ' - Entregado por el Cliente -',
    'observacion': 'Recibido en caja',
    'datoEmpresa': 'ESPPAPEL',
    'fila': 1,
  };

  group('endpoints: cada constante es la ruta del contrato', () {
    test('cheques', () {
      expect(AppConstants.chqCatalogos, '/cheque/catalogos');
      expect(AppConstants.chqEmpresas, '/cheque/empresas');
      expect(AppConstants.chqSucursalInicial, '/cheque/sucursal-inicial');
      expect(AppConstants.chqSucursales, '/cheque/sucursales');
      expect(AppConstants.chqClientes, '/cheque/clientes');
      expect(AppConstants.chqPersonalEntregan, '/cheque/personal/entregan');
      expect(AppConstants.chqPersonalCustodia, '/cheque/personal/custodia');
      expect(AppConstants.chqListar, '/cheque/listar');
      expect(AppConstants.chqDetalle, '/cheque/detalle');
      expect(AppConstants.chqRegistrar, '/cheque/registrar');
      expect(AppConstants.chqTalonarioValidar, '/cheque/talonario/validar');
      expect(AppConstants.chqAccionFechaCobro, '/cheque/accion/fecha-cobro');
      expect(AppConstants.chqAccionDevolver, '/cheque/accion/devolver');
      expect(AppConstants.chqAccionCerrar, '/cheque/accion/cerrar');
      expect(AppConstants.chqAccionEliminar, '/cheque/accion/eliminar');
      expect(AppConstants.chqTraspasoPendientes, '/cheque/traspaso/pendientes');
      expect(AppConstants.chqTraspaso, '/cheque/traspaso');
      expect(AppConstants.chqCustodiaCheques, '/cheque/custodia/cheques');
      expect(AppConstants.chqCustodia, '/cheque/custodia');
      expect(
        AppConstants.chqDarCustodiaCheques,
        '/cheque/dar-custodia/cheques',
      );
      expect(
        AppConstants.chqDarCustodiaEntregas,
        '/cheque/dar-custodia/entregas',
      );
      expect(AppConstants.chqDarCustodia, '/cheque/dar-custodia');
    });

    test('reportes: seis PDF y la lista de horas del traspaso', () {
      expect(AppConstants.chqReporteRecibidos, '/cheque/reporte/recibidos');
      expect(AppConstants.chqReporteCobranzas, '/cheque/reporte/cobranzas');
      expect(AppConstants.chqReporteCustodio, '/cheque/reporte/custodio');
      expect(
        AppConstants.chqReporteUltimoRecibo,
        '/cheque/reporte/ultimo-recibo',
      );
      expect(AppConstants.chqReporteTraspaso, '/cheque/reporte/traspaso');
      expect(
        AppConstants.chqReporteReimpresionTraspaso,
        '/cheque/reporte/reimpresion-traspaso',
      );
      expect(AppConstants.chqTraspasoHoras, '/cheque/traspaso/horas');
    });

    test('bancos: las lecturas no cambian y las escrituras son nuevas', () {
      expect(AppConstants.bncGetBancos, '/banco/bancosX');
      expect(AppConstants.bncGetBancosPlanilla, '/banco/bancosPlanilla');
      expect(AppConstants.bncRegistrar, '/banco/registrar');
      expect(AppConstants.bncEliminar, '/banco/eliminar');
    });
  });

  group('lecturas', () {
    test('listar: ruta, cuerpo sin usuario y pagina leida', () async {
      cable.responde(
        200,
        envelope({
          'total': 45,
          'pagina': 2,
          'tamanio': 20,
          'filas': [filaJson(21), filaJson(22)],
        }),
      );
      final filtro = const ChequeFiltroEntity(codSucursal: 3, pagina: 2)
          .conCriterios(
            estado: 'PEN',
            fechaCobro: DateTime(2026, 9, 5),
            fechaRecepcionDesde: DateTime(2026, 7, 3),
            fechaRecepcionHasta: DateTime(2026, 10, 3),
          )
          .copyWith(pagina: 2);

      final p = await repo.listar(filtro);

      expect(cable.ultima.ruta, '/cheque/listar');
      expect(cable.ultima.cuerpo, {
        'codSucursal': 3,
        'estado': 'PEN',
        'fechaCobro': '2026-09-05',
        'fechaRecepcionDesde': '2026-07-03',
        'fechaRecepcionHasta': '2026-10-03',
        'orden': 'RECEPCION',
        'pagina': 2,
        'tamanio': 20,
      });
      expect(p.total, 45);
      expect(p.pagina, 2);
      expect(p.filas.map((f) => f.cheque.nrocheque), ['21', '22']);
      expect(p.filas.first.descTipo, isNull);
    });

    test(
      'listar: un 204 es una pagina vacia con la misma pagina, no un error',
      () async {
        cable.responde(204, null);
        final p = await repo.listar(
          const ChequeFiltroEntity(codSucursal: 3, pagina: 3, tamanio: 50),
        );
        expect(p.filas, isEmpty);
        expect(p.total, 0);
        expect(p.pagina, 3);
        expect(p.tamanio, 50);
      },
    );

    test(
      'listar: una pagina con data pero sin filas tampoco es error',
      () async {
        cable.responde(
          200,
          envelope({'total': 0, 'pagina': 1, 'tamanio': 20, 'filas': []}),
        );
        final p = await repo.listar(const ChequeFiltroEntity(codSucursal: 3));
        expect(p.filas, isEmpty);
      },
    );

    test('detalle: manda {id} y lee cheque, acciones y botones', () async {
      cable.responde(
        200,
        envelope({
          'cheque': filaJson(9718),
          'acciones': [
            {
              'codAccion': 1,
              'codCheque': 9718,
              'fecha': '2026-08-31T09:30:15',
              'estado': 'REC',
              'codEmpleado': null,
              'nroSAP': null,
              'observacion': 'Recibido en caja',
              'audUsuario': 47,
              'audFecha': '2026-08-31T09:30:15',
              'descripcion': 'RECIBIDO',
              'nro': 1,
            },
          ],
          'botones': {
            'fechaCobro': false,
            'devolver': false,
            'cerrarConVerificacion': false,
            'cerrarSinVerificacion': false,
            'codigo': '0000',
          },
        }),
      );

      final d = await repo.obtenerDetalle(BigInt.from(9718));

      expect(cable.ultima.ruta, '/cheque/detalle');
      expect(cable.ultima.cuerpo, {'id': 9718});
      expect(d!.cheque.codCheque, BigInt.from(9718));
      expect(d.acciones.single.estado, 'REC');
      expect(d.acciones.single.fecha, DateTime(2026, 8, 31, 9, 30, 15));
      expect(d.botones.codigo, '0000');
    });

    test('catalogos: las siete listas', () async {
      List<Map<String, String>> l(String c, String n) => [
        {'codigo': c, 'nombre': n},
      ];
      cable.responde(
        200,
        envelope({
          'tiposCheque': l('PAG', 'PAGO'),
          'monedas': l('BS', 'Bs'),
          'estadosCheque': l('PEN', 'PENDIENTE'),
          'estadosAccion': l('REC', 'RECIBIDO'),
          'accionesFechaCobro': l('VEN', 'VENCIDO-POSTERGADO'),
          'accionesCierreConVerificacion': l('COB', 'COBRADO'),
          'accionesCierreSinVerificacion': l('CEF', 'CANJEADO EFECTIVO'),
        }),
      );
      final c = await repo.obtenerCatalogos();
      expect(cable.ultima.ruta, '/cheque/catalogos');
      expect(c.tiposCheque.single.codigo, 'PAG');
      expect(c.accionesCierreSinVerificacion.single.codigo, 'CEF');
    });

    test('empresas: ruta, sin datos de entrada y lista leida', () async {
      cable.responde(
        200,
        envelope([
          {'codEmpresa': 1, 'nombre': 'IMPEXPAP'},
          {'codEmpresa': 5, 'nombre': 'ESPPAPEL'},
        ]),
      );
      final l = await repo.listarEmpresas();
      expect(cable.ultima.ruta, '/cheque/empresas');
      expect(cable.ultima.cuerpo, {});
      expect(l.map((e) => e.codEmpresa), [1, 5]);
      expect(l.map((e) => e.nombre), ['IMPEXPAP', 'ESPPAPEL']);
    });

    test('empresas: un 204 es lista vacia, no un error', () async {
      cable.responde(204, null);
      expect(await repo.listarEmpresas(), isEmpty);
    });

    test('empresas: una columna nula no tumba la lista', () async {
      cable.responde(
        200,
        envelope([
          {'codEmpresa': 1, 'nombre': null},
        ]),
      );
      final l = await repo.listarEmpresas();
      expect(l.single.codEmpresa, 1);
      expect(l.single.nombre, '');
    });

    test('sucursal inicial: data es un numero suelto', () async {
      cable.responde(200, envelope(3));
      expect(await repo.obtenerSucursalInicial(), 3);
      expect(cable.ultima.ruta, '/cheque/sucursal-inicial');
    });

    test('sucursal inicial con empresa: manda {id: empresa}', () async {
      cable.responde(200, envelope(7));
      expect(await repo.obtenerSucursalInicial(codEmpresa: 5), 7);
      expect(cable.ultima.cuerpo, {'id': 5});
    });

    test('sucursal inicial sin empresa: no manda ninguna', () async {
      cable.responde(200, envelope(3));
      await repo.obtenerSucursalInicial();
      expect(cable.ultima.cuerpo, {});
      await repo.obtenerSucursalInicial(codEmpresa: 0);
      expect(cable.ultima.cuerpo, {});
    });

    test('sucursal inicial 0: el usuario no tiene sucursal', () async {
      cable.responde(200, envelope(0));
      expect(await repo.obtenerSucursalInicial(), 0);
    });

    test('sucursales: cuerpo {id: empresa} y 204 es lista vacia', () async {
      cable.responde(
        200,
        envelope([
          {'codSucursal': 3, 'nombre': 'LA PAZ'},
        ]),
      );
      final l = await repo.listarSucursales(codEmpresa: 2);
      expect(cable.ultima.ruta, '/cheque/sucursales');
      expect(cable.ultima.cuerpo, {'id': 2});
      expect(l.single.nombre, 'LA PAZ');

      cable.responde(204, null);
      expect(await repo.listarSucursales(), isEmpty);
      expect(cable.ultima.cuerpo, {'id': 0});
    });

    test('clientes: un cliente con columnas NULL no tumba la lista', () async {
      cable.responde(
        200,
        envelope([
          {
            'codCliente': 'ADI0229',
            'datoCliente': 'ADDY SALAZAR',
            'razonSocial': 'EDITORA MENDEZ',
            'nit': '123',
            'codCiudad': 1,
            'datoCiudad': 'CBBA',
            'esVigente': 'Y',
            'codEmpresa': 1,
            'audUsuario': 0,
            'nombreCompleto': 'ADDY SALAZAR - EDITORA MENDEZ',
          },
          {
            'codCliente': 'X1',
            'datoCliente': null,
            'razonSocial': null,
            'nit': null,
            'codCiudad': 0,
            'datoCiudad': null,
            'esVigente': null,
            'codEmpresa': 1,
            'audUsuario': 0,
            'nombreCompleto': null,
          },
        ]),
      );
      final l = await repo.listarClientes();
      expect(cable.ultima.ruta, '/cheque/clientes');
      expect(l, hasLength(2));
      expect(l.first.nombreCompleto, 'ADDY SALAZAR - EDITORA MENDEZ');
      expect(l.last.razonSocial, '');
      expect(l.last.nombreCompleto, '');
    });

    test(
      'personal: entregan y custodia, cada una a su ruta con {id: sucursal}',
      () async {
        cable.responde(
          200,
          envelope([
            {'codEmpleado': 12, 'nombreCompleto': 'PEREZ JUAN'},
          ]),
        );
        final e = await repo.listarQuienesEntregan(3);
        expect(cable.ultima.ruta, '/cheque/personal/entregan');
        expect(cable.ultima.cuerpo, {'id': 3});
        expect(e.single.codEmpleado, 12);

        cable.responde(204, null);
        expect(await repo.listarResponsablesDeCustodia(3), isEmpty);
        expect(cable.ultima.ruta, '/cheque/personal/custodia');
      },
    );

    test('traspasos pendientes: conteo en data', () async {
      cable.responde(200, envelope(5));
      expect(await repo.contarTraspasosPendientes(3), 5);
      expect(cable.ultima.ruta, '/cheque/traspaso/pendientes');
      expect(cable.ultima.cuerpo, {'id': 3});
    });

    test('cheques para custodia: lista de filas', () async {
      cable.responde(200, envelope([filaJson(1), filaJson(2)]));
      final l = await repo.listarChequesParaCustodia(3);
      expect(cable.ultima.ruta, '/cheque/custodia/cheques');
      expect(l, hasLength(2));
    });

    test('dar custodia: cheques y entregas del dia', () async {
      cable.responde(
        200,
        envelope([
          {'codCheque': 1, 'datoCheque': 'Nro Cheque : 1'},
        ]),
      );
      final l = await repo.listarChequesParaDarCustodia(3);
      expect(cable.ultima.ruta, '/cheque/dar-custodia/cheques');
      expect(l.single.codCheque, BigInt.one);

      cable.responde(
        200,
        envelope([
          {'codAccion': 88, 'hora': '09:15'},
        ]),
      );
      final h = await repo.listarEntregasDelDia(
        codSucursal: 3,
        fecha: DateTime(2026, 9, 1, 17, 30),
      );
      expect(cable.ultima.ruta, '/cheque/dar-custodia/entregas');
      expect(cable.ultima.cuerpo, {'codSucursal': 3, 'fecha': '2026-09-01'});
      expect(h.single.codAccion, BigInt.from(88));
    });
  });

  group('validarTalonario', () {
    const mensajeLargo =
        'El talonario «ER1076» no pertenece a la empresa ESPPAPEL: está '
        'registrado en la empresa IMPEXPAP (y el recibo 3752 sí está dentro de '
        'su numeración, 3751 a 3800), y este cheque se está registrando en '
        'ESPPAPEL.\nCambia la empresa en los filtros o usa un talonario de '
        'ESPPAPEL.';

    test('manda el cuerpo exacto, con los dos textos recortados', () async {
      cable.responde(200, envelope({'valido': true}));
      await repo.validarTalonario(
        codEmpresa: 5,
        nroTalonario: '  ER1076 ',
        reciboManual: ' 3752  ',
      );

      expect(cable.ultima.ruta, '/cheque/talonario/validar');
      expect(cable.ultima.cuerpo, {
        'codEmpresa': 5,
        'nroTalonario': 'ER1076',
        'reciboManual': '3752',
      });
      // Es una consulta: ni usuario de auditoria ni sucursal.
      final cuerpo = cable.ultima.cuerpo as Map<String, dynamic>;
      for (final k in const ['audUsuario', 'codSucursal', 'codUsuario']) {
        expect(cuerpo.containsKey(k), isFalse, reason: k);
      }
    });

    test('valido con detalle: lee los tres campos', () async {
      cable.responde(
        200,
        envelope({
          'valido': true,
          'mensaje': null,
          'detalle': 'Talonario ER1076 (IMPEXPAP): recibos del 3751 al 3800.',
        }),
      );
      final r = await repo.validarTalonario(
        codEmpresa: 1,
        nroTalonario: 'ER1076',
        reciboManual: '3752',
      );
      expect(r.valido, isTrue);
      expect(r.mensaje, isNull);
      expect(
        r.detalle,
        'Talonario ER1076 (IMPEXPAP): recibos del 3751 al 3800.',
      );
    });

    test('invalido: el mensaje llega completo, con sus saltos de linea', () async {
      cable.responde(
        200,
        envelope({'valido': false, 'mensaje': mensajeLargo, 'detalle': null}),
      );
      final r = await repo.validarTalonario(
        codEmpresa: 5,
        nroTalonario: 'ER1076',
        reciboManual: '3752',
      );
      expect(r.valido, isFalse);
      expect(r.mensaje, mensajeLargo);
      expect(r.detalle, isNull);
    });

    test('valido sin detalle: nada que mostrar', () async {
      cable.responde(
        200,
        envelope({'valido': true, 'mensaje': null, 'detalle': null}),
      );
      final r = await repo.validarTalonario(
        codEmpresa: 1,
        nroTalonario: '0',
        reciboManual: '0',
      );
      expect(r.valido, isTrue);
      expect(r.detalle, isNull);
    });

    test('un texto vacio o de espacios cuenta como ausente', () async {
      cable.responde(
        200,
        envelope({'valido': true, 'mensaje': '   ', 'detalle': ''}),
      );
      final r = await repo.validarTalonario(
        codEmpresa: 1,
        nroTalonario: 'A',
        reciboManual: '1',
      );
      expect(r.mensaje, isNull);
      expect(r.detalle, isNull);
    });

    test('un 204 se toma como valido, no como error', () async {
      cable.responde(204, null);
      final r = await repo.validarTalonario(
        codEmpresa: 1,
        nroTalonario: 'ER1076',
        reciboManual: '3752',
      );
      expect(r.valido, isTrue);
      expect(r.mensaje, isNull);
      expect(r.detalle, isNull);
    });

    test('un data nulo se toma como valido', () async {
      cable.responde(200, envelope(null));
      final r = await repo.validarTalonario(
        codEmpresa: 1,
        nroTalonario: 'ER1076',
        reciboManual: '3752',
      );
      expect(r.valido, isTrue);
    });

    test('un data sin la clave valido no rechaza a nadie', () async {
      cable.responde(200, envelope({'detalle': 'Talonario X'}));
      final r = await repo.validarTalonario(
        codEmpresa: 1,
        nroTalonario: 'X',
        reciboManual: '1',
      );
      expect(r.valido, isTrue);
      expect(r.detalle, 'Talonario X');
    });

    test('un 400 (empresa ausente o ajena) llega con el texto del backend', () async {
      cable.responde(400, {
        'message': 'La empresa no es una de las empresas de cheques.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.validarTalonario(
          codEmpresa: 99,
          nroTalonario: 'ER1076',
          reciboManual: '3752',
        ),
        throwsA(
          predicate(
            (e) =>
                e.toString() ==
                'Exception: La empresa no es una de las empresas de cheques.',
          ),
        ),
      );
    });

    test('un 403 sin permiso llega con el motivo del backend', () async {
      cable.responde(403, {
        'message': 'No tiene permiso para registrar ni editar cheques.',
        'data': null,
        'status': 403,
      });
      await expectLater(
        repo.validarTalonario(
          codEmpresa: 1,
          nroTalonario: 'ER1076',
          reciboManual: '3752',
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains(
              'No tiene permiso para registrar ni editar cheques.',
            ),
          ),
        ),
      );
    });
  });

  group('escrituras', () {
    test(
      'registrar: devuelve el codCheque y no manda el usuario de auditoria',
      () async {
        cable.responde(201, envelope(9001, status: 201));
        final id = await repo.registrar(
          ChequeRegistroEntity(
            codCheque: BigInt.zero,
            nrocheque: '000123',
            codCliente: 'ADI0229',
            fechaCheque: DateTime(2026, 8, 31, 10, 20),
            fechaCobrar: DateTime(2026, 8, 31),
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
          ),
        );

        expect(id, BigInt.from(9001));
        expect(cable.ultima.ruta, '/cheque/registrar');
        final cuerpo = cable.ultima.cuerpo as Map<String, dynamic>;
        expect(cuerpo['fechaCheque'], '2026-08-31');
        expect(cuerpo['codEmpleado'], 0);
        expect(cuerpo['modo'], 'ESTANDAR');
        for (final prohibida in const [
          'audUsuario',
          'audFecha',
          'estado',
          'nroRecibo',
        ]) {
          expect(cuerpo.containsKey(prohibida), isFalse, reason: prohibida);
        }
        expect(jsonEncode(cuerpo).contains('T00:00'), isFalse);
      },
    );

    test(
      'un 400 llega con el texto del backend, con todos sus saltos de linea',
      () async {
        cable.responde(400, {
          'message':
              'El Nro del Cheque es obligatorio\nLa fecha de cobro esta fuera de rango',
          'data': null,
          'status': 400,
        });
        await expectLater(
          repo.registrar(ChequeRegistroEntity(codCheque: BigInt.zero)),
          throwsA(
            predicate(
              (e) =>
                  e.toString() ==
                  'Exception: El Nro del Cheque es obligatorio\n'
                      'La fecha de cobro esta fuera de rango',
            ),
          ),
        );
      },
    );

    test('un 403 sin permiso se avisa con el mensaje del backend', () async {
      cable.responde(403, {
        'message': 'No tiene permiso para esta accion.',
        'data': null,
        'status': 403,
      });
      await expectLater(
        repo.traspasar(3),
        throwsA(
          predicate(
            (e) => e.toString().contains('No tiene permiso para esta accion.'),
          ),
        ),
      );
    });

    test(
      'acciones: cada una a su ruta, con nroSap y fechas de solo dia',
      () async {
        cable.responde(201, envelope(501, status: 201));
        final accion = AccionChequeRequestEntity(
          codCheque: BigInt.from(9718),
          fecha: DateTime(2026, 9, 1, 8, 15),
          estado: 'VEN',
          nroSap: 'SAP-9',
          observacion: 'Pide plazo',
          nuevaFechaCobro: DateTime(2026, 9, 30),
        );

        expect(await repo.cambiarFechaCobro(accion), BigInt.from(501));
        expect(cable.ultima.ruta, '/cheque/accion/fecha-cobro');
        expect(cable.ultima.cuerpo, {
          'codCheque': 9718,
          'fecha': '2026-09-01',
          'estado': 'VEN',
          'nroSap': 'SAP-9',
          'observacion': 'Pide plazo',
          'nuevaFechaCobro': '2026-09-30',
        });

        await repo.devolver(AccionChequeRequestEntity(codCheque: BigInt.one));
        expect(cable.ultima.ruta, '/cheque/accion/devolver');
        expect(cable.ultima.cuerpo, {'codCheque': 1});

        await repo.cerrar(
          AccionChequeRequestEntity(
            codCheque: BigInt.one,
            estado: 'COB',
            nroSap: 'SAP-1',
            conVerificacion: true,
          ),
        );
        expect(cable.ultima.ruta, '/cheque/accion/cerrar');
        expect(cable.ultima.cuerpo, {
          'codCheque': 1,
          'estado': 'COB',
          'nroSap': 'SAP-1',
          'conVerificacion': true,
        });

        await repo.eliminarAccion(BigInt.from(88));
        expect(cable.ultima.ruta, '/cheque/accion/eliminar');
        expect(cable.ultima.cuerpo, {'id': 88});
      },
    );

    test('traspaso y custodia', () async {
      cable.responde(201, envelope(4, status: 201));
      expect(await repo.traspasar(3), 4);
      expect(cable.ultima.ruta, '/cheque/traspaso');
      expect(cable.ultima.cuerpo, {'id': 3});

      expect(
        await repo.entregarEnCustodia(
          CustodiaChequeRequestEntity(
            codSucursal: 3,
            codEmpleado: 12,
            codCheques: [BigInt.from(1), BigInt.from(2)],
          ),
        ),
        4,
      );
      expect(cable.ultima.ruta, '/cheque/custodia');
      expect(cable.ultima.cuerpo, {
        'codSucursal': 3,
        'codEmpleado': 12,
        'codCheques': [1, 2],
      });

      cable.responde(201, envelope(601, status: 201));
      expect(
        await repo.darCustodia(
          DarCustodiaRequestEntity(
            codSucursal: 3,
            codAccionOrigen: BigInt.from(88),
            codCheque: BigInt.from(9718),
          ),
        ),
        BigInt.from(601),
      );
      expect(cable.ultima.ruta, '/cheque/dar-custodia');
      expect(cable.ultima.cuerpo, {
        'codSucursal': 3,
        'codAccionOrigen': 88,
        'codCheque': 9718,
      });
    });
  });

  group('reportes', () {
    final pdf = Uint8List.fromList(utf8.encode('%PDF-1.4 prueba'));

    /// Ningun cuerpo lleva el usuario de auditoria ni fechas con hora.
    void sinAuditoria() {
      final cuerpo = cable.ultima.cuerpo as Map<String, dynamic>;
      expect(cuerpo.containsKey('audUsuario'), isFalse);
      expect(jsonEncode(cuerpo).contains('T00:00'), isFalse);
    }

    test('recibidos: devuelve los bytes, a su ruta y con 2 minutos', () async {
      cable.responde(200, pdf);
      final bytes = await repo.reporteRecibidos(
        codEmpresa: 5,
        codSucursal: 7,
        fechaDesde: DateTime(2026, 9, 1, 15, 30),
        fechaHasta: DateTime(2026, 9, 30),
      );

      expect(bytes, pdf);
      expect(cable.ultima.ruta, '/cheque/reporte/recibidos');
      expect(cable.ultima.cuerpo, {
        'codEmpresa': 5,
        'codSucursal': 7,
        'fechaDesde': '2026-09-01',
        'fechaHasta': '2026-09-30',
      });
      expect(cable.ultima.espera, const Duration(minutes: 2));
      sinAuditoria();
    });

    test('recibidos: una fecha ausente no viaja', () async {
      cable.responde(200, pdf);
      await repo.reporteRecibidos(codEmpresa: 1, codSucursal: 3);
      expect(cable.ultima.cuerpo, {'codEmpresa': 1, 'codSucursal': 3});

      await repo.reporteRecibidos(
        codEmpresa: 1,
        codSucursal: 3,
        fechaDesde: DateTime(2026, 2, 3),
      );
      expect(cable.ultima.cuerpo, {
        'codEmpresa': 1,
        'codSucursal': 3,
        'fechaDesde': '2026-02-03',
      });
    });

    test('cobranzas: estado y cliente viajan; vacios no', () async {
      cable.responde(200, pdf);
      await repo.reporteCobranzas(
        codEmpresa: 1,
        codSucursal: 3,
        fechaDesde: DateTime(2026, 9, 1),
        fechaHasta: DateTime(2026, 9, 2),
        estado: 'PEN',
        codCliente: ' ADI0229 ',
      );
      expect(cable.ultima.ruta, '/cheque/reporte/cobranzas');
      expect(cable.ultima.cuerpo, {
        'codEmpresa': 1,
        'codSucursal': 3,
        'fechaDesde': '2026-09-01',
        'fechaHasta': '2026-09-02',
        'estado': 'PEN',
        'codCliente': 'ADI0229',
      });
      sinAuditoria();

      await repo.reporteCobranzas(
        codEmpresa: 1,
        codSucursal: 3,
        estado: '',
        codCliente: '   ',
      );
      expect(cable.ultima.cuerpo, {'codEmpresa': 1, 'codSucursal': 3});
    });

    test('custodio: la fecha y el responsable; 0 o ausente es todos', () async {
      cable.responde(200, pdf);
      await repo.reporteCustodio(
        codEmpresa: 1,
        codSucursal: 3,
        fecha: DateTime(2026, 9, 5, 23, 59),
        codEmpleado: 12,
      );
      expect(cable.ultima.ruta, '/cheque/reporte/custodio');
      expect(cable.ultima.cuerpo, {
        'codEmpresa': 1,
        'codSucursal': 3,
        'fecha': '2026-09-05',
        'codEmpleado': 12,
      });
      sinAuditoria();

      await repo.reporteCustodio(
        codEmpresa: 1,
        codSucursal: 3,
        codEmpleado: 0,
      );
      expect(cable.ultima.cuerpo, {'codEmpresa': 1, 'codSucursal': 3});
      await repo.reporteCustodio(codEmpresa: 1, codSucursal: 3);
      expect(cable.ultima.cuerpo, {'codEmpresa': 1, 'codSucursal': 3});
    });

    test('ultimo recibo y nomina del traspaso: solo empresa y sucursal', () async {
      cable.responde(200, pdf);
      expect(await repo.reporteUltimoRecibo(codEmpresa: 5, codSucursal: 7), pdf);
      expect(cable.ultima.ruta, '/cheque/reporte/ultimo-recibo');
      expect(cable.ultima.cuerpo, {'codEmpresa': 5, 'codSucursal': 7});

      expect(await repo.reporteTraspaso(codEmpresa: 5, codSucursal: 7), pdf);
      expect(cable.ultima.ruta, '/cheque/reporte/traspaso');
      expect(cable.ultima.cuerpo, {'codEmpresa': 5, 'codSucursal': 7});
      sinAuditoria();
    });

    test('reimpresion del traspaso: lleva el codAccion elegido', () async {
      cable.responde(200, pdf);
      await repo.reporteReimpresionTraspaso(
        codEmpresa: 1,
        codSucursal: 3,
        codAccion: 88,
      );
      expect(cable.ultima.ruta, '/cheque/reporte/reimpresion-traspaso');
      expect(cable.ultima.cuerpo, {
        'codEmpresa': 1,
        'codSucursal': 3,
        'codAccion': 88,
      });
    });

    test('un error de negocio llega con su mensaje completo', () async {
      // El PDF se pide como bytes: el JSON de error llega sin interpretar y el
      // mensaje se rescata igual.
      cable.responde(400, {
        'message':
            'No hay ningun cheque registrado por usted en esta sucursal.\n'
            'Registre uno primero.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.reporteUltimoRecibo(codEmpresa: 1, codSucursal: 3),
        throwsA(
          predicate(
            (e) =>
                e.toString() ==
                'Exception: No hay ningun cheque registrado por usted en esta '
                    'sucursal.\nRegistre uno primero.',
          ),
        ),
      );
    });

    test('un 403 sin permiso se avisa con el mensaje del backend', () async {
      cable.responde(403, {
        'message': 'No tiene permiso para esta accion.',
        'data': null,
        'status': 403,
      });
      await expectLater(
        repo.reporteCustodio(codEmpresa: 1, codSucursal: 3),
        throwsA(
          predicate(
            (e) => e.toString().contains('No tiene permiso para esta accion.'),
          ),
        ),
      );
    });

    test('horas del traspaso: {codSucursal, fecha} y la lista leida', () async {
      cable.responde(
        200,
        envelope([
          {'codAccion': 88, 'hora': '09:15'},
          {'codAccion': 91, 'hora': '16:40'},
        ]),
      );
      final l = await repo.listarHorasDeTraspaso(
        codSucursal: 3,
        fecha: DateTime(2026, 9, 1, 17, 30),
      );
      expect(cable.ultima.ruta, '/cheque/traspaso/horas');
      expect(cable.ultima.cuerpo, {'codSucursal': 3, 'fecha': '2026-09-01'});
      expect(l.map((h) => h.codAccion), [88, 91]);
      expect(l.map((h) => h.hora), ['09:15', '16:40']);
    });

    test('horas del traspaso: un 204 es lista vacia, no un error', () async {
      cable.responde(204, null);
      expect(
        await repo.listarHorasDeTraspaso(
          codSucursal: 3,
          fecha: DateTime(2026, 9, 1),
        ),
        isEmpty,
      );
    });

    test('horas del traspaso: una columna nula no tumba la lista', () async {
      cable.responde(
        200,
        envelope([
          {'codAccion': null, 'hora': null},
        ]),
      );
      final l = await repo.listarHorasDeTraspaso(
        codSucursal: 3,
        fecha: DateTime(2026, 9, 1),
      );
      expect(l.single.codAccion, 0);
      expect(l.single.hora, '');
    });
  });

  group('bancos: lectura', () {
    Map<String, dynamic> bancoJson(int cod, String nombre) => {
      'codBanco': cod,
      'nombre': nombre,
      'audUsuario': 1,
      'fila': cod,
    };

    test('listar: lista pelada, a /banco/bancosX, en el orden del servidor', () async {
      // La lectura de bancos no usa ApiResponse: el cuerpo ES la lista.
      cable.responde(200, [
        bancoJson(8, 'BANCO MERCANTIL'),
        bancoJson(7, 'BANCO UNION'),
      ]);

      final l = await bancos.listar();

      expect(cable.ultima.ruta, '/banco/bancosX');
      expect(l.map((b) => b.codBanco), [8, 7]);
      expect(l.map((b) => b.nombre), ['BANCO MERCANTIL', 'BANCO UNION']);
      expect(l.first.audUsuario, 1);
    });

    test('listar: tambien acepta el envelope con data', () async {
      cable.responde(200, envelope([bancoJson(7, 'BANCO UNION')]));
      final l = await bancos.listar();
      expect(l.single.nombre, 'BANCO UNION');
    });

    test('listar: una columna en NULL no tumba la lista', () async {
      cable.responde(200, [
        {'codBanco': 9, 'nombre': null, 'audUsuario': null, 'fila': null},
      ]);
      final l = await bancos.listar();
      expect(l.single.codBanco, 9);
      expect(l.single.nombre, '');
    });

    test('listar: un 204 es lista vacia, no un error', () async {
      cable.responde(204, null);
      expect(await bancos.listar(), isEmpty);
    });

    test('listar: una lista vacia tampoco es error', () async {
      cable.responde(200, <Object>[]);
      expect(await bancos.listar(), isEmpty);
    });

    test('listar: un 500 se propaga (no se vuelve lista vacia)', () async {
      cable.responde(500, {
        'message': 'Error interno',
        'data': null,
        'status': 500,
      });
      await expectLater(bancos.listar(), throwsA(isA<DioException>()));
    });

    test('listar: un 400 llega con el texto del backend', () async {
      cable.responde(400, {
        'message': 'No tiene permiso para esta accion.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        bancos.listar(),
        throwsA(
          predicate(
            (e) => e.toString() == 'Exception: No tiene permiso para esta accion.',
          ),
        ),
      );
    });

    test('listar: un 403 se propaga con su respuesta', () async {
      cable.responde(403, {
        'message': 'No tiene permiso para esta accion.',
        'data': null,
        'status': 403,
      });
      await expectLater(
        bancos.listar(),
        throwsA(
          predicate((e) => e is DioException && e.response?.statusCode == 403),
        ),
      );
    });
  });

  group('bancos: escritura', () {
    test('registrar: alta con codBanco 0', () async {
      cable.responde(201, envelope(15, status: 201));
      final id = await bancos.registrar(
        const BancoRegistroEntity(codBanco: 0, nombre: ' BANCO NUEVO '),
      );
      expect(id, BigInt.from(15));
      expect(cable.ultima.ruta, '/banco/registrar');
      expect(cable.ultima.cuerpo, {'codBanco': 0, 'nombre': 'BANCO NUEVO'});
    });

    test(
      'eliminar: manda {id} y un banco en uso llega como error de negocio',
      () async {
        cable.responde(201, envelope(5, status: 201));
        expect(await bancos.eliminar(5), BigInt.from(5));
        expect(cable.ultima.ruta, '/banco/eliminar');
        expect(cable.ultima.cuerpo, {'id': 5});

        cable.responde(400, {
          'message':
              'El banco tiene Depositos o Pagos al Exterior y no se puede eliminar.',
          'data': null,
          'status': 400,
        });
        await expectLater(
          bancos.eliminar(5),
          throwsA(
            predicate((e) => e.toString().contains('no se puede eliminar')),
          ),
        );
      },
    );
  });
}

/// Una peticion tal como salio por el cable.
typedef _Peticion = ({String ruta, Object? cuerpo, Duration? espera});

/// Responde siempre con lo ultimo que se le indico con [responde] y anota las
/// peticiones que recibe.
class _Adaptador implements HttpClientAdapter {
  final List<_Peticion> peticiones = [];
  ({int estado, Object? cuerpo}) _respuesta = (estado: 200, cuerpo: null);

  _Peticion get ultima => peticiones.last;

  void responde(int estado, Object? cuerpo) =>
      _respuesta = (estado: estado, cuerpo: cuerpo);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? cuerpo;
    if (requestStream != null) {
      final bytes = [await for (final b in requestStream) ...b];
      final texto = utf8.decode(bytes);
      cuerpo = texto.isEmpty ? null : jsonDecode(texto);
    }
    peticiones.add((
      ruta: options.path,
      cuerpo: cuerpo,
      espera: options.receiveTimeout,
    ));

    final r = _respuesta;
    // Bytes = un PDF: se entregan tal cual, con su tipo.
    if (r.cuerpo is Uint8List) {
      return ResponseBody.fromBytes(
        r.cuerpo! as Uint8List,
        r.estado,
        headers: {
          Headers.contentTypeHeader: ['application/pdf'],
        },
      );
    }
    return ResponseBody.fromString(
      r.cuerpo == null ? '' : jsonEncode(r.cuerpo),
      r.estado,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
