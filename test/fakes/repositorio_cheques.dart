// Repositorio falso del modulo de cheques, con datos de ejemplo coherentes y
// ganchos para que cada prueba controle lo que devuelve y cuando.
//
// Las escrituras arman el cuerpo con los MISMOS modelos que usa ChequesImpl y
// lo guardan en [cuerpos]: asi una prueba del notifier puede comprobar lo que
// viajaria al backend (por ejemplo, que no lleve audUsuario) sin red.
import 'dart:convert';
import 'dart:typed_data';

import 'package:bosque_flutter/data/models/accion_cheque_request_model.dart';
import 'package:bosque_flutter/data/models/accion_cheque_model.dart';
import 'package:bosque_flutter/data/models/cheque_fila_model.dart';
import 'package:bosque_flutter/data/models/cheque_filtro_model.dart';
import 'package:bosque_flutter/data/models/cheque_registro_model.dart';
import 'package:bosque_flutter/data/models/custodia_cheque_request_model.dart';
import 'package:bosque_flutter/data/models/dar_custodia_request_model.dart';
import 'package:bosque_flutter/data/models/nota_remision_cheque_model.dart';
import 'package:bosque_flutter/data/models/postergacion_model.dart';
import 'package:bosque_flutter/data/models/transaccion_bancaria_model.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/catalogos_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_pagina_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_resumen_entity.dart';
import 'package:bosque_flutter/domain/entities/custodia_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/dar_custodia_request_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/hora_traspaso_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_subida_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_validacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';
import 'package:bosque_flutter/domain/repositories/cheques_repository.dart';

/// Las empresas del combo «Empresa», como las devuelve `/cheque/empresas`.
const empresasChequeFalsas = [
  EmpresaChequeEntity(codEmpresa: 1, nombre: 'IMPEXPAP'),
  EmpresaChequeEntity(codEmpresa: 5, nombre: 'ESPPAPEL'),
];

/// El nombre que lleva un cheque de la empresa [cod] en `datoEmpresa`.
String nombreEmpresaFalsa(int cod) =>
    empresasChequeFalsas
        .where((e) => e.codEmpresa == cod)
        .map((e) => e.nombre)
        .firstOrNull ??
    'EMPRESA $cod';

/// Un cheque de la grilla, armado desde JSON como llega del backend. El dia de
/// recepcion baja con el codigo, asi el orden por recepcion es previsible.
///
/// Por defecto `descTipo` es null, como en 8570 de los 9719 cheques de la base de
/// prueba; las pruebas de pantalla pasan un texto o un `tipo` corrupto segun el
/// caso.
ChequeFilaEntity chequeFalso(
  int cod, {
  String estado = 'PEN',
  String? nroCheque,
  String cliente = 'EDITORA MENDEZ',
  int codSucursal = 3,
  int codEmpresa = 1,
  String? fechaCobrar,
  String? fechaCheque,
  String tipo = 'PAG',
  String? descTipo,
  int codEmpleado = 0,
  String datoEmpleado = ' - Entregado por el Cliente -',
  String nroTalonario = '0',
  String reciboManual = '0',
  String banco = 'BANCO UNION',
  String aOrdenDe = 'BOSQUE S.A.',
  String? observacion = 'Recibido en caja',
  double monto = 1500.5,
}) {
  final dia = (28 - (cod % 28)).toString().padLeft(2, '0');
  return ChequeFilaModel.fromJson({
    'codCheque': cod,
    'nrocheque': nroCheque ?? '${100000 + cod}',
    'codCliente': 'C$cod',
    'aOrdenDe': aOrdenDe,
    'fechaCheque': fechaCheque ?? '2026-08-$dia',
    'fechaCobrar': fechaCobrar ?? '2026-09-$dia',
    'monto': monto,
    'moneda': 'BS',
    'tipo': tipo,
    'estado': estado,
    'codBanco': 7,
    'codEmpleado': codEmpleado,
    'reciboManual': reciboManual,
    'codSucursal': codSucursal,
    'nroRecibo': cod,
    'nroTalonario': nroTalonario,
    'codEmpresa': codEmpresa,
    'audUsuario': 47,
    'audFecha': '2026-08-31 14:54:51.5670000 +00:00',
    'fechaRecepcion': '2026-08-$dia',
    'datoCliente': cliente,
    'descMoneda': 'Bs',
    'descTipo': descTipo,
    'descEstado': estado == 'CER' ? 'CERRADO' : 'PENDIENTE',
    'nombreBanco': banco,
    'datoEmpleado': datoEmpleado,
    'observacion': observacion,
    'datoEmpresa': nombreEmpresaFalsa(codEmpresa),
    'fila': 0,
  }).toEntity();
}

/// Los combos como los devuelve `/cheque/catalogos`.
const catalogosChequeFalsos = CatalogosChequeEntity(
  tiposCheque: [
    OpcionChequeEntity(codigo: 'PAG', nombre: 'PAGO'),
    OpcionChequeEntity(codigo: 'RES', nombre: 'RESPALDO'),
  ],
  monedas: [
    OpcionChequeEntity(codigo: 'BS', nombre: 'Bs'),
    OpcionChequeEntity(codigo: 'SUS', nombre: r'$us'),
  ],
  estadosCheque: [
    OpcionChequeEntity(codigo: 'PEN', nombre: 'PENDIENTE'),
    OpcionChequeEntity(codigo: 'CER', nombre: 'CERRADO'),
  ],
  estadosAccion: [
    OpcionChequeEntity(codigo: 'REC', nombre: 'RECIBIDO'),
    OpcionChequeEntity(codigo: 'TRASP', nombre: 'TRASPASO'),
    OpcionChequeEntity(codigo: 'CUS', nombre: 'A COBRANZA'),
    OpcionChequeEntity(codigo: 'DEV', nombre: 'DEVUELTO'),
    OpcionChequeEntity(codigo: 'VEN', nombre: 'VENCIDO-POSTERGADO'),
    OpcionChequeEntity(codigo: 'ADE', nombre: 'ADELANTADO'),
    OpcionChequeEntity(codigo: 'COB', nombre: 'COBRADO'),
    OpcionChequeEntity(codigo: 'CEF', nombre: 'CANJEADO EFECTIVO'),
    OpcionChequeEntity(codigo: 'CCH', nombre: 'CANJEADO CHEQUE'),
    OpcionChequeEntity(codigo: 'PAP', nombre: 'PAGO PARCIAL'),
    OpcionChequeEntity(codigo: 'DPR', nombre: 'DEPOSITADO-RECHAZADO'),
  ],
  accionesFechaCobro: [
    OpcionChequeEntity(codigo: 'VEN', nombre: 'VENCIDO-POSTERGADO'),
    OpcionChequeEntity(codigo: 'ADE', nombre: 'ADELANTADO'),
  ],
  accionesCierreConVerificacion: [
    OpcionChequeEntity(codigo: 'COB', nombre: 'COBRADO'),
  ],
  accionesCierreSinVerificacion: [
    OpcionChequeEntity(codigo: 'CEF', nombre: 'CANJEADO EFECTIVO'),
    OpcionChequeEntity(codigo: 'CCH', nombre: 'CANJEADO CHEQUE'),
    OpcionChequeEntity(codigo: 'PAP', nombre: 'PAGO PARCIAL'),
    OpcionChequeEntity(codigo: 'DPR', nombre: 'DEPOSITADO-RECHAZADO'),
  ],
);

class RepositorioChequesFalso implements ChequesRepository {
  RepositorioChequesFalso({int total = 45})
    : cheques = [for (var i = 1; i <= total; i++) chequeFalso(i)];

  /// Todo lo que hay en la sucursal 3; `listar` filtra y pagina sobre esto.
  List<ChequeFilaEntity> cheques;

  /// Orden de las llamadas, por nombre de metodo.
  final List<String> llamadas = [];

  /// Los filtros que llegaron a `listar`, en orden.
  final List<ChequeFiltroEntity> filtros = [];

  /// Los cuerpos JSON que ChequesImpl mandaria, por metodo.
  final List<({String metodo, Map<String, dynamic> cuerpo})> cuerpos = [];

  /// El cuerpo JSON de cada `listar`, en orden. Va aparte de [cuerpos], que es
  /// de las escrituras.
  final List<Map<String, dynamic>> cuerposListar = [];

  /// Si `listar` tambien filtra por el rango de recepcion (por defecto no: las
  /// fechas de los cheques de ejemplo son de agosto de 2026 y una prueba no debe
  /// depender del dia en que corre).
  bool filtrarPorRecepcion = false;

  int sucursalInicial = 3;

  /// La sucursal inicial de las empresas que no son la primera; la que no figura
  /// aqui usa [sucursalInicial].
  Map<int, int> sucursalInicialPorEmpresa = {5: 7};
  Object? errorSucursalInicial;

  /// Lo que devuelve `listarEmpresas`; con [errorEmpresas] la lectura falla.
  List<EmpresaChequeEntity> empresas = empresasChequeFalsas;
  Object? errorEmpresas;

  /// Cada empresa que llego a `obtenerSucursalInicial`, `listarSucursales` y
  /// `listarClientes`, en orden. Un 0 aqui es el error de diseno que se corrigio
  /// (pedir «la empresa del login»): las pruebas comprueban que no aparezca.
  final List<int> empresasDeSucursalInicial = [];
  final List<int> empresasDeSucursales = [];
  final List<int> empresasDeClientes = [];

  /// Las sucursales de cada empresa; la que no figura devuelve una lista vacia.
  Map<int, List<SucursalChequeEntity>> sucursalesPorEmpresa = {
    1: const [
      SucursalChequeEntity(codSucursal: 3, nombre: 'LA PAZ'),
      SucursalChequeEntity(codSucursal: 4, nombre: 'EL ALTO'),
    ],
    5: const [
      SucursalChequeEntity(codSucursal: 7, nombre: 'SANTA CRUZ'),
      SucursalChequeEntity(codSucursal: 8, nombre: 'COCHABAMBA'),
    ],
  };

  /// Clientes por empresa; la que no figura usa [clientes].
  Map<int, List<SocioNegocioEntity>> clientesPorEmpresa = {};

  /// Sustituye a `obtenerSucursalInicial`; sirve para controlar cuando responde
  /// cada empresa.
  Future<int> Function(int codEmpresa)? alObtenerSucursalInicial;
  Object? errorListar;
  Object? errorEscritura;

  /// Sustituye a `listar`; sirve para controlar cuando responde cada consulta.
  Future<ChequePaginaEntity> Function(ChequeFiltroEntity filtro)? alListar;

  /// Lo que devuelve `obtenerDetalle`.
  BotonesChequeEntity botones = BotonesChequeEntity.ninguno;

  /// Lo que devuelve `traspasar`.
  int traspasados = 4;

  /// Lo que devuelve `contarTraspasosPendientes`.
  int pendientes = 4;

  /// Lo que devuelven las lecturas de custodia. Por defecto, listas vacias.
  List<ChequeFilaEntity> chequesCustodia = const [];
  List<PersonalChequeEntity> responsables = const [];
  List<ChequeResumenEntity> chequesDarCustodia = const [];
  List<EntregaChequeEntity> entregas = const [];

  /// Los dias que se pidieron a `listarEntregasDelDia`, en orden.
  final List<DateTime> fechasDeEntregas = [];

  /// Hace fallar una lectura de traspaso o custodia: la clave es el nombre del
  /// metodo (`contarTraspasosPendientes`, `listarChequesParaCustodia`,
  /// `listarResponsablesDeCustodia`, `listarChequesParaDarCustodia`,
  /// `listarEntregasDelDia`). Se quita para que el reintento salga bien.
  final Map<String, Object> erroresDeLectura = {};

  void _lectura(String metodo) {
    llamadas.add(metodo);
    final e = erroresDeLectura[metodo];
    if (e != null) throw e;
  }

  /// Si se asigna, `registrar` espera a que termine antes de responder: sirve
  /// para tener una escritura en vuelo.
  Future<void>? esperaEscritura;

  /// Lo que devuelve `obtenerCatalogos`.
  CatalogosChequeEntity catalogos = catalogosChequeFalsos;

  /// Lo que devuelven `listarClientes` y `listarQuienesEntregan`.
  List<SocioNegocioEntity> clientes = const [];
  List<PersonalChequeEntity> personal = const [];

  /// Sustituye a `obtenerDetalle`; sirve para armar un cheque cerrado, un
  /// historial con Nro SAP o un fallo.
  Future<ChequeDetalleEntity?> Function(BigInt codCheque)? alObtenerDetalle;

  int contar(String metodo) => llamadas.where((m) => m == metodo).length;

  Map<String, dynamic> ultimoCuerpo(String metodo) =>
      cuerpos.lastWhere((c) => c.metodo == metodo).cuerpo;

  void _escritura(String metodo, [Map<String, dynamic>? cuerpo]) {
    llamadas.add(metodo);
    if (cuerpo != null) cuerpos.add((metodo: metodo, cuerpo: cuerpo));
    if (errorEscritura != null) throw errorEscritura!;
  }

  // ── Apoyo ──────────────────────────────────────────────────────────────

  @override
  Future<CatalogosChequeEntity> obtenerCatalogos() async {
    llamadas.add('obtenerCatalogos');
    return catalogos;
  }

  @override
  Future<List<EmpresaChequeEntity>> listarEmpresas() async {
    llamadas.add('listarEmpresas');
    if (errorEmpresas != null) throw errorEmpresas!;
    return empresas;
  }

  @override
  Future<int> obtenerSucursalInicial({int codEmpresa = 0}) async {
    llamadas.add('obtenerSucursalInicial');
    empresasDeSucursalInicial.add(codEmpresa);
    if (alObtenerSucursalInicial != null) {
      return alObtenerSucursalInicial!(codEmpresa);
    }
    if (errorSucursalInicial != null) throw errorSucursalInicial!;
    return sucursalInicialPorEmpresa[codEmpresa] ?? sucursalInicial;
  }

  @override
  Future<List<SucursalChequeEntity>> listarSucursales({
    int codEmpresa = 0,
  }) async {
    llamadas.add('listarSucursales');
    empresasDeSucursales.add(codEmpresa);
    return sucursalesPorEmpresa[codEmpresa] ?? const [];
  }

  @override
  Future<List<SocioNegocioEntity>> listarClientes({int codEmpresa = 0}) async {
    llamadas.add('listarClientes');
    empresasDeClientes.add(codEmpresa);
    return clientesPorEmpresa[codEmpresa] ?? clientes;
  }

  @override
  Future<List<PersonalChequeEntity>> listarQuienesEntregan(
    int codSucursal,
  ) async {
    llamadas.add('listarQuienesEntregan');
    return personal;
  }

  @override
  Future<List<PersonalChequeEntity>> listarResponsablesDeCustodia(
    int codSucursal,
  ) async {
    _lectura('listarResponsablesDeCustodia');
    return responsables;
  }

  // ── Cheques ────────────────────────────────────────────────────────────

  @override
  Future<ChequePaginaEntity> listar(ChequeFiltroEntity filtro) async {
    llamadas.add('listar');
    filtros.add(filtro);
    cuerposListar.add(ChequeFiltroModel.fromEntity(filtro).toJson());
    if (alListar != null) return alListar!(filtro);
    if (errorListar != null) throw errorListar!;

    final coinciden =
        cheques.where((c) {
          final ch = c.cheque;
          final recibido = c.fechaRecepcion;
          return ch.codSucursal == filtro.codSucursal &&
              (!filtrarPorRecepcion ||
                  recibido == null ||
                  ((filtro.fechaRecepcionDesde == null ||
                          !recibido.isBefore(filtro.fechaRecepcionDesde!)) &&
                      (filtro.fechaRecepcionHasta == null ||
                          !recibido.isAfter(filtro.fechaRecepcionHasta!)))) &&
              (filtro.nroCheque == null ||
                  ch.nrocheque.contains(filtro.nroCheque!)) &&
              (filtro.estado == null || ch.estado == filtro.estado) &&
              (filtro.cliente == null ||
                  c.datoCliente.toLowerCase().contains(
                    filtro.cliente!.toLowerCase(),
                  ));
        }).toList();
    if (filtro.orden == OrdenCheques.cobro) {
      coinciden.sort(
        (a, b) => a.cheque.fechaCobrar!.compareTo(b.cheque.fechaCobrar!),
      );
    } else {
      coinciden.sort((a, b) {
        final c = b.fechaRecepcion!.compareTo(a.fechaRecepcion!);
        return c != 0 ? c : b.codCheque.compareTo(a.codCheque);
      });
    }
    final desde = (filtro.pagina - 1) * filtro.tamanio;
    return ChequePaginaEntity(
      total: coinciden.length,
      pagina: filtro.pagina,
      tamanio: filtro.tamanio,
      filas: coinciden.skip(desde).take(filtro.tamanio).toList(),
    );
  }

  @override
  Future<ChequeDetalleEntity?> obtenerDetalle(BigInt codCheque) async {
    llamadas.add('obtenerDetalle');
    if (alObtenerDetalle != null) return alObtenerDetalle!(codCheque);
    return ChequeDetalleEntity(
      cheque: chequeFalso(codCheque.toInt()),
      acciones: [
        for (final (i, e) in const ['REC', 'TRASP', 'CUS'].indexed)
          AccionChequeModel.fromJson({
            'codAccion': codCheque.toInt() * 10 + i,
            'codCheque': codCheque.toInt(),
            'fecha': '2026-08-31T0${8 + i}:00:00',
            'estado': e,
            'codEmpleado': i == 0 ? null : 12,
            'nroSAP': null,
            'observacion': null,
            'audUsuario': 47,
            'audFecha': '2026-08-31T0${8 + i}:00:00',
            'descripcion': e,
            'nro': i + 1,
          }).toEntity(),
      ],
      botones: botones,
    );
  }

  @override
  Future<BigInt> registrar(ChequeRegistroEntity registro) async {
    _escritura('registrar', ChequeRegistroModel.fromEntity(registro).toJson());
    if (esperaEscritura != null) await esperaEscritura;
    return registro.esAlta ? BigInt.from(9001) : registro.codCheque;
  }

  // ── Comprobacion del talonario ─────────────────────────────────────────

  /// Cada consulta que llego a `validarTalonario`, en orden y tal como llego
  /// (el recorte de espacios lo hace `ChequesImpl`, no el falso).
  final List<({int codEmpresa, String nroTalonario, String reciboManual})>
  consultasTalonario = [];

  /// Lo que responde `validarTalonario`. Por defecto, valido sin detalle (no
  /// se dibuja nada).
  TalonarioValidacionEntity respuestaTalonario =
      TalonarioValidacionEntity.sinObjeciones;

  /// Cuanto tarda en responder. Cero = al instante.
  Duration demoraTalonario = Duration.zero;

  /// Hace fallar a `validarTalonario` (red, 400 o 403).
  Object? errorTalonario;

  /// Sustituye a `validarTalonario`; sirve para controlar cuando responde cada
  /// consulta y con que (por ejemplo, una vieja que llega despues de la nueva).
  Future<TalonarioValidacionEntity> Function(
    int codEmpresa,
    String nroTalonario,
    String reciboManual,
  )?
  alValidarTalonario;

  @override
  Future<TalonarioValidacionEntity> validarTalonario({
    required int codEmpresa,
    required String nroTalonario,
    required String reciboManual,
  }) async {
    llamadas.add('validarTalonario');
    consultasTalonario.add((
      codEmpresa: codEmpresa,
      nroTalonario: nroTalonario,
      reciboManual: reciboManual,
    ));
    if (alValidarTalonario != null) {
      return alValidarTalonario!(codEmpresa, nroTalonario, reciboManual);
    }
    if (demoraTalonario > Duration.zero) {
      await Future<void>.delayed(demoraTalonario);
    }
    if (errorTalonario != null) throw errorTalonario!;
    return respuestaTalonario;
  }

  // ── Acciones del detalle ───────────────────────────────────────────────

  @override
  Future<BigInt> cambiarFechaCobro(AccionChequeRequestEntity accion) async {
    _escritura(
      'cambiarFechaCobro',
      AccionChequeRequestModel.fromEntity(accion).toJson(),
    );
    return BigInt.from(501);
  }

  @override
  Future<BigInt> devolver(AccionChequeRequestEntity accion) async {
    _escritura(
      'devolver',
      AccionChequeRequestModel.fromEntity(accion).toJson(),
    );
    return BigInt.from(502);
  }

  @override
  Future<BigInt> cerrar(AccionChequeRequestEntity accion) async {
    _escritura('cerrar', AccionChequeRequestModel.fromEntity(accion).toJson());
    return BigInt.from(503);
  }

  @override
  Future<BigInt> eliminarAccion(BigInt codAccion) async {
    _escritura('eliminarAccion', {'id': codAccion.toInt()});
    return codAccion;
  }

  // ── Traspaso y custodia ────────────────────────────────────────────────

  @override
  Future<int> contarTraspasosPendientes(int codSucursal) async {
    _lectura('contarTraspasosPendientes');
    return pendientes;
  }

  @override
  Future<int> traspasar(int codSucursal) async {
    _escritura('traspasar', {'id': codSucursal});
    return traspasados;
  }

  @override
  Future<List<ChequeFilaEntity>> listarChequesParaCustodia(
    int codSucursal,
  ) async {
    _lectura('listarChequesParaCustodia');
    return chequesCustodia;
  }

  @override
  Future<int> entregarEnCustodia(CustodiaChequeRequestEntity pedido) async {
    _escritura(
      'entregarEnCustodia',
      CustodiaChequeRequestModel.fromEntity(pedido).toJson(),
    );
    return pedido.codCheques.length;
  }

  @override
  Future<List<ChequeResumenEntity>> listarChequesParaDarCustodia(
    int codSucursal,
  ) async {
    _lectura('listarChequesParaDarCustodia');
    return chequesDarCustodia;
  }

  @override
  Future<List<EntregaChequeEntity>> listarEntregasDelDia({
    required int codSucursal,
    required DateTime fecha,
  }) async {
    _lectura('listarEntregasDelDia');
    fechasDeEntregas.add(fecha);
    return entregas;
  }

  @override
  Future<BigInt> darCustodia(DarCustodiaRequestEntity pedido) async {
    _escritura(
      'darCustodia',
      DarCustodiaRequestModel.fromEntity(pedido).toJson(),
    );
    return BigInt.from(601);
  }

  // ── Reportes ───────────────────────────────────────────────────────────

  /// Los parametros de cada reporte **tal como llegaron al repositorio**, con
  /// sus nulos y sus fechas como `DateTime`. Lo que de verdad viaja por el cable
  /// (claves omitidas, fechas yyyy-MM-dd) se comprueba en `cheques_impl_test`.
  final List<({String metodo, Map<String, Object?> parametros})> reportes = [];

  /// El PDF que devuelve cualquier reporte.
  Uint8List pdfFalso = Uint8List.fromList(utf8.encode('%PDF-1.4 falso'));

  /// Si se asigna, un reporte espera a que termine antes de responder: sirve
  /// para tener una generacion en vuelo.
  Future<void>? esperaReporte;

  /// Hace fallar a cualquier reporte, con el mensaje que traeria el backend.
  Object? errorReporte;

  /// Lo que devuelve `listarHorasDeTraspaso` cuando el dia no figura en
  /// [horasPorFecha] (clave yyyy-MM-dd).
  List<HoraTraspasoChequeEntity> horasDeTraspaso = const [];
  Map<String, List<HoraTraspasoChequeEntity>> horasPorFecha = {};

  /// Los dias que se pidieron a `listarHorasDeTraspaso`, en orden.
  final List<DateTime> fechasDeHoras = [];

  Map<String, Object?> ultimoReporte(String metodo) =>
      reportes.lastWhere((r) => r.metodo == metodo).parametros;

  Future<Uint8List> _reporte(String metodo, Map<String, Object?> parametros) async {
    llamadas.add(metodo);
    reportes.add((metodo: metodo, parametros: parametros));
    if (esperaReporte != null) await esperaReporte;
    if (errorReporte != null) throw errorReporte!;
    return pdfFalso;
  }

  @override
  Future<Uint8List> reporteRecibidos({
    required int codEmpresa,
    required int codSucursal,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) => _reporte('reporteRecibidos', {
    'codEmpresa': codEmpresa,
    'codSucursal': codSucursal,
    'fechaDesde': fechaDesde,
    'fechaHasta': fechaHasta,
  });

  @override
  Future<Uint8List> reporteCobranzas({
    required int codEmpresa,
    required int codSucursal,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? estado,
    String? codCliente,
  }) => _reporte('reporteCobranzas', {
    'codEmpresa': codEmpresa,
    'codSucursal': codSucursal,
    'fechaDesde': fechaDesde,
    'fechaHasta': fechaHasta,
    'estado': estado,
    'codCliente': codCliente,
  });

  @override
  Future<Uint8List> reporteCustodio({
    required int codEmpresa,
    required int codSucursal,
    DateTime? fecha,
    int? codEmpleado,
  }) => _reporte('reporteCustodio', {
    'codEmpresa': codEmpresa,
    'codSucursal': codSucursal,
    'fecha': fecha,
    'codEmpleado': codEmpleado,
  });

  @override
  Future<Uint8List> reporteUltimoRecibo({
    required int codEmpresa,
    required int codSucursal,
  }) => _reporte('reporteUltimoRecibo', {
    'codEmpresa': codEmpresa,
    'codSucursal': codSucursal,
  });

  @override
  Future<Uint8List> reporteTraspaso({
    required int codEmpresa,
    required int codSucursal,
  }) => _reporte('reporteTraspaso', {
    'codEmpresa': codEmpresa,
    'codSucursal': codSucursal,
  });

  @override
  Future<Uint8List> reporteReimpresionTraspaso({
    required int codEmpresa,
    required int codSucursal,
    required int codAccion,
  }) => _reporte('reporteReimpresionTraspaso', {
    'codEmpresa': codEmpresa,
    'codSucursal': codSucursal,
    'codAccion': codAccion,
  });

  @override
  Future<List<HoraTraspasoChequeEntity>> listarHorasDeTraspaso({
    required int codSucursal,
    required DateTime fecha,
  }) async {
    _lectura('listarHorasDeTraspaso');
    fechasDeHoras.add(fecha);
    final dia =
        '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
    return horasPorFecha[dia] ?? horasDeTraspaso;
  }

  // ── Documento PDF del cheque ───────────────────────────────────────────

  /// Lo que devuelve `estadoPdf` para cualquier cheque que no figure en
  /// [estadosPdf]. Por defecto, sin PDF. Una subida lo actualiza: asi la
  /// relectura que hace el dialogo despues de cargar ve el archivo nuevo.
  PdfChequeEstadoEntity estadoPdfDeTodos = PdfChequeEstadoEntity.sinArchivo;

  /// El estado de un cheque en particular (clave: codCheque).
  final Map<BigInt, PdfChequeEstadoEntity> estadosPdf = {};

  /// Hace fallar a `estadoPdf` con el mensaje que traeria el backend. Se quita
  /// para que el reintento salga bien.
  Object? errorEstadoPdf;

  /// Si se asigna, `estadoPdf` espera a que termine antes de responder: sirve
  /// para tener la primera consulta en vuelo.
  Future<void>? esperaEstadoPdf;

  /// Cada codCheque que llego a `estadoPdf`, en orden.
  final List<BigInt> consultasPdf = [];

  /// Lo que llego a `subirPdf`, tal cual.
  final List<({BigInt codCheque, Uint8List bytes, String nombre})> subidasPdf =
      [];

  /// Hace fallar a `subirPdf` con el mensaje que traeria el backend.
  Object? errorSubidaPdf;

  /// Si se asigna, `subirPdf` espera a que termine antes de responder: sirve para
  /// tener una subida en vuelo.
  Future<void>? esperaSubidaPdf;

  /// Los avances `(enviados, total)` que `subirPdf` informa antes de esperar.
  List<(int, int)> avancesDeSubidaPdf = const [];

  /// Lo que devuelve `descargarPdf`.
  Uint8List pdfDelCheque = Uint8List.fromList(utf8.encode('%PDF-1.4 cheque'));

  /// Hace fallar a `descargarPdf` con el mensaje que traeria el backend.
  Object? errorDescargaPdf;

  /// Si se asigna, `descargarPdf` espera a que termine antes de responder.
  Future<void>? esperaDescargaPdf;

  /// Cada codCheque que llego a `descargarPdf`, en orden.
  final List<BigInt> descargasPdf = [];

  @override
  Future<PdfChequeEstadoEntity> estadoPdf(BigInt codCheque) async {
    llamadas.add('estadoPdf');
    consultasPdf.add(codCheque);
    if (esperaEstadoPdf != null) await esperaEstadoPdf;
    if (errorEstadoPdf != null) throw errorEstadoPdf!;
    return estadosPdf[codCheque] ?? estadoPdfDeTodos;
  }

  @override
  Future<PdfChequeSubidaEntity> subirPdf(
    BigInt codCheque,
    Uint8List bytes,
    String nombreArchivo, {
    void Function(int enviados, int total)? alProgreso,
  }) async {
    llamadas.add('subirPdf');
    subidasPdf.add((codCheque: codCheque, bytes: bytes, nombre: nombreArchivo));
    for (final (enviados, total) in avancesDeSubidaPdf) {
      alProgreso?.call(enviados, total);
    }
    if (esperaSubidaPdf != null) await esperaSubidaPdf;
    if (errorSubidaPdf != null) throw errorSubidaPdf!;
    final habia = (estadosPdf[codCheque] ?? estadoPdfDeTodos).existe;
    final nombre = '$codCheque.pdf';
    estadosPdf[codCheque] = PdfChequeEstadoEntity(
      existe: true,
      nombreArchivo: nombre,
      tamanoBytes: bytes.length,
      fechaModificacion: DateTime(2026, 10, 3, 14, 22, 10),
    );
    return PdfChequeSubidaEntity(
      nombreArchivo: nombre,
      tamanoBytes: bytes.length,
      reemplazo: habia,
    );
  }

  @override
  Future<Uint8List> descargarPdf(BigInt codCheque) async {
    llamadas.add('descargarPdf');
    descargasPdf.add(codCheque);
    if (esperaDescargaPdf != null) await esperaDescargaPdf;
    if (errorDescargaPdf != null) throw errorDescargaPdf!;
    return pdfDelCheque;
  }

  // ── Paneles del detalle: notas, transacciones y postergaciones ─────────

  /// Lo que hay guardado por cheque (clave: codCheque). Registrar agrega y
  /// eliminar quita, asi la relectura que hace la pantalla despues de escribir
  /// ve el cambio. Un cheque que no figura tiene listas vacias.
  final Map<BigInt, List<NotaRemisionChequeEntity>> notasPorCheque = {};
  final Map<BigInt, List<TransaccionBancariaEntity>> transaccionesPorCheque =
      {};
  final Map<BigInt, List<PostergacionEntity>> postergacionesPorCheque = {};

  /// Los bancos que conoce el falso para poner `datoBanco` a una transaccion
  /// nueva (clave: codBanco).
  Map<int, String> nombresDeBanco = {7: 'BANCO UNION', 8: 'BANCO MERCANTIL'};

  int _proximaPostergacion = 9100;

  /// Si se asigna, la escritura de un panel espera a que termine antes de
  /// responder: sirve para tener una en vuelo.
  Future<void>? esperaEscrituraPaneles;

  /// El cheque de cada lectura de un panel, en orden.
  final List<BigInt> consultasDePaneles = [];

  @override
  Future<List<NotaRemisionChequeEntity>> listarNotasRemision(
    BigInt codCheque,
  ) async {
    _lectura('listarNotasRemision');
    consultasDePaneles.add(codCheque);
    return List.of(notasPorCheque[codCheque] ?? const []);
  }

  @override
  Future<void> registrarNotaRemision(NotaRemisionChequeEntity nota) async {
    _escritura(
      'registrarNotaRemision',
      NotaRemisionChequeModel.fromEntity(nota).toCuerpoRegistro(),
    );
    if (esperaEscrituraPaneles != null) await esperaEscrituraPaneles;
    final lista = notasPorCheque.putIfAbsent(nota.codCheque, () => []);
    lista.add(
      NotaRemisionChequeEntity(
        codCheque: nota.codCheque,
        notaRemision: nota.notaRemision,
        nroFactura: nota.nroFactura,
        fechaFactura: nota.fechaFactura,
        audUsuario: 47,
        fila: lista.length + 1,
      ),
    );
  }

  @override
  Future<int> eliminarNotaRemision({
    required BigInt codCheque,
    required String notaRemision,
  }) async {
    _escritura('eliminarNotaRemision', {
      'codCheque': codCheque.toInt(),
      'notaRemision': notaRemision,
    });
    if (esperaEscrituraPaneles != null) await esperaEscrituraPaneles;
    final lista = notasPorCheque[codCheque] ?? [];
    final antes = lista.length;
    lista.removeWhere((n) => n.notaRemision == notaRemision);
    return antes - lista.length;
  }

  @override
  Future<List<TransaccionBancariaEntity>> listarTransacciones(
    BigInt codCheque,
  ) async {
    _lectura('listarTransacciones');
    consultasDePaneles.add(codCheque);
    return List.of(transaccionesPorCheque[codCheque] ?? const []);
  }

  @override
  Future<void> registrarTransaccion(
    TransaccionBancariaEntity transaccion,
  ) async {
    _escritura(
      'registrarTransaccion',
      TransaccionBancariaModel.fromEntity(transaccion).toCuerpoRegistro(),
    );
    if (esperaEscrituraPaneles != null) await esperaEscrituraPaneles;
    final lista = transaccionesPorCheque.putIfAbsent(
      transaccion.codCheque,
      () => [],
    );
    lista.add(
      TransaccionBancariaEntity(
        codCheque: transaccion.codCheque,
        nroTransaccion: transaccion.nroTransaccion,
        codBanco: transaccion.codBanco,
        fechaTransaccion: transaccion.fechaTransaccion,
        datoBanco: nombresDeBanco[transaccion.codBanco] ?? '',
        fila: lista.length + 1,
      ),
    );
  }

  @override
  Future<int> eliminarTransaccion({
    required BigInt codCheque,
    required String nroTransaccion,
  }) async {
    _escritura('eliminarTransaccion', {
      'codCheque': codCheque.toInt(),
      'nroTransaccion': nroTransaccion,
    });
    if (esperaEscrituraPaneles != null) await esperaEscrituraPaneles;
    final lista = transaccionesPorCheque[codCheque] ?? [];
    final antes = lista.length;
    lista.removeWhere((t) => t.nroTransaccion == nroTransaccion);
    return antes - lista.length;
  }

  @override
  Future<List<PostergacionEntity>> listarPostergaciones(
    BigInt codCheque,
  ) async {
    _lectura('listarPostergaciones');
    consultasDePaneles.add(codCheque);
    return List.of(postergacionesPorCheque[codCheque] ?? const []);
  }

  @override
  Future<BigInt> registrarPostergacion(PostergacionEntity postergacion) async {
    _escritura(
      'registrarPostergacion',
      PostergacionModel.fromEntity(postergacion).toCuerpoRegistro(),
    );
    if (esperaEscrituraPaneles != null) await esperaEscrituraPaneles;
    final cod = BigInt.from(_proximaPostergacion++);
    final lista = postergacionesPorCheque.putIfAbsent(
      postergacion.codCheque,
      () => [],
    );
    lista.add(
      PostergacionEntity(
        codPostergacion: cod,
        codCheque: postergacion.codCheque,
        fecha: postergacion.fecha,
        observacion: postergacion.observacion,
        audUsuario: 47,
        tienePdf: false,
        fila: lista.length + 1,
      ),
    );
    return cod;
  }

  @override
  Future<BigInt> eliminarPostergacion({
    required BigInt codCheque,
    required BigInt codPostergacion,
  }) async {
    _escritura('eliminarPostergacion', {
      'codCheque': codCheque.toInt(),
      'codPostergacion': codPostergacion.toInt(),
    });
    if (esperaEscrituraPaneles != null) await esperaEscrituraPaneles;
    postergacionesPorCheque[codCheque]?.removeWhere(
      (p) => p.codPostergacion == codPostergacion,
    );
    return codPostergacion;
  }

  // ── PDF de la postergacion ─────────────────────────────────────────────

  /// Lo que devuelve `estadoPdfPostergacion` para una postergacion que no figure
  /// en [estadosPdfPostergacion]. Por defecto, sin PDF. Una subida lo actualiza.
  PdfChequeEstadoEntity estadoPdfDeTodasLasPostergaciones =
      PdfChequeEstadoEntity.sinArchivo;

  /// El estado de una postergacion en particular (clave: codPostergacion).
  final Map<BigInt, PdfChequeEstadoEntity> estadosPdfPostergacion = {};

  /// Hace fallar a `estadoPdfPostergacion` con el mensaje del backend.
  Object? errorEstadoPdfPostergacion;

  /// Cada codPostergacion que llego a `estadoPdfPostergacion`, en orden.
  final List<BigInt> consultasPdfPostergacion = [];

  /// Lo que llego a `subirPdfPostergacion`, tal cual.
  final List<({BigInt codPostergacion, Uint8List bytes, String nombre})>
  subidasPdfPostergacion = [];

  /// Hace fallar a `subirPdfPostergacion` con el mensaje del backend.
  Object? errorSubidaPdfPostergacion;

  /// Si se asigna, `subirPdfPostergacion` espera a que termine antes de
  /// responder: sirve para tener una subida en vuelo.
  Future<void>? esperaSubidaPdfPostergacion;

  /// Los avances `(enviados, total)` que la subida informa antes de esperar.
  List<(int, int)> avancesDeSubidaPdfPostergacion = const [];

  /// Lo que devuelve `descargarPdfPostergacion`.
  Uint8List pdfDeLaPostergacion = Uint8List.fromList(
    utf8.encode('%PDF-1.4 postergacion'),
  );

  /// Hace fallar a `descargarPdfPostergacion` con el mensaje del backend.
  Object? errorDescargaPdfPostergacion;

  /// Cada codPostergacion que llego a `descargarPdfPostergacion`, en orden.
  final List<BigInt> descargasPdfPostergacion = [];

  @override
  Future<PdfChequeEstadoEntity> estadoPdfPostergacion(
    BigInt codPostergacion,
  ) async {
    llamadas.add('estadoPdfPostergacion');
    consultasPdfPostergacion.add(codPostergacion);
    if (errorEstadoPdfPostergacion != null) throw errorEstadoPdfPostergacion!;
    return estadosPdfPostergacion[codPostergacion] ??
        estadoPdfDeTodasLasPostergaciones;
  }

  @override
  Future<PdfChequeSubidaEntity> subirPdfPostergacion(
    BigInt codPostergacion,
    Uint8List bytes,
    String nombreArchivo, {
    void Function(int enviados, int total)? alProgreso,
  }) async {
    llamadas.add('subirPdfPostergacion');
    subidasPdfPostergacion.add((
      codPostergacion: codPostergacion,
      bytes: bytes,
      nombre: nombreArchivo,
    ));
    for (final (enviados, total) in avancesDeSubidaPdfPostergacion) {
      alProgreso?.call(enviados, total);
    }
    if (esperaSubidaPdfPostergacion != null) await esperaSubidaPdfPostergacion;
    if (errorSubidaPdfPostergacion != null) throw errorSubidaPdfPostergacion!;
    final habia =
        (estadosPdfPostergacion[codPostergacion] ??
                estadoPdfDeTodasLasPostergaciones)
            .existe;
    final nombre = '$codPostergacion.pdf';
    estadosPdfPostergacion[codPostergacion] = PdfChequeEstadoEntity(
      existe: true,
      nombreArchivo: nombre,
      tamanoBytes: bytes.length,
      fechaModificacion: DateTime(2026, 10, 3, 14, 22, 10),
    );
    // El listado de postergaciones tambien lo ve: la pastilla «PDF cargado».
    for (final lista in postergacionesPorCheque.values) {
      for (var i = 0; i < lista.length; i++) {
        final p = lista[i];
        if (p.codPostergacion != codPostergacion) continue;
        lista[i] = PostergacionEntity(
          codPostergacion: p.codPostergacion,
          codCheque: p.codCheque,
          fecha: p.fecha,
          observacion: p.observacion,
          nombreArchivo: p.nombreArchivo,
          audUsuario: p.audUsuario,
          audFecha: p.audFecha,
          tienePdf: true,
          fila: p.fila,
        );
      }
    }
    return PdfChequeSubidaEntity(
      nombreArchivo: nombre,
      tamanoBytes: bytes.length,
      reemplazo: habia,
    );
  }

  @override
  Future<Uint8List> descargarPdfPostergacion(BigInt codPostergacion) async {
    llamadas.add('descargarPdfPostergacion');
    descargasPdfPostergacion.add(codPostergacion);
    if (errorDescargaPdfPostergacion != null) {
      throw errorDescargaPdfPostergacion!;
    }
    return pdfDeLaPostergacion;
  }
}
