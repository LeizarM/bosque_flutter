import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/accion_cheque_request_model.dart';
import 'package:bosque_flutter/data/models/catalogos_cheque_model.dart';
import 'package:bosque_flutter/data/models/cheque_detalle_model.dart';
import 'package:bosque_flutter/data/models/cheque_fila_model.dart';
import 'package:bosque_flutter/data/models/cheque_filtro_model.dart';
import 'package:bosque_flutter/data/models/cheque_pagina_model.dart';
import 'package:bosque_flutter/data/models/cheque_registro_model.dart';
import 'package:bosque_flutter/data/models/cheque_resumen_model.dart';
import 'package:bosque_flutter/data/models/custodia_cheque_request_model.dart';
import 'package:bosque_flutter/data/models/dar_custodia_request_model.dart';
import 'package:bosque_flutter/data/models/empresa_cheque_model.dart';
import 'package:bosque_flutter/data/models/entrega_cheque_model.dart';
import 'package:bosque_flutter/data/models/hora_traspaso_cheque_model.dart';
import 'package:bosque_flutter/data/models/nota_remision_cheque_model.dart';
import 'package:bosque_flutter/data/models/pdf_cheque_estado_model.dart';
import 'package:bosque_flutter/data/models/pdf_cheque_subida_model.dart';
import 'package:bosque_flutter/data/models/personal_cheque_model.dart';
import 'package:bosque_flutter/data/models/postergacion_model.dart';
import 'package:bosque_flutter/data/models/socio_negocio_model.dart';
import 'package:bosque_flutter/data/models/sucursal_cheque_model.dart';
import 'package:bosque_flutter/data/models/talonario_validacion_model.dart';
import 'package:bosque_flutter/data/models/transaccion_bancaria_model.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_request_entity.dart';
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
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_validacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';
import 'package:bosque_flutter/domain/repositories/cheques_repository.dart';

/// Implementacion del modulo de cheques contra el backend Spring.
///
/// Los helpers de BaseApiRepository resuelven el envelope, el 204 y el 400: el
/// `message` de un 400 es texto de negocio y llega tal cual a quien llame.
/// Los conteos (`data` es un numero suelto) tambien van por `postAndReturnId`.
class ChequesImpl extends BaseApiRepository implements ChequesRepository {
  // ========================= APOYO Y CATALOGOS =============================

  @override
  Future<CatalogosChequeEntity> obtenerCatalogos() async {
    final modelo = await postAndReturnObject<CatalogosChequeModel>(
      endpoint: AppConstants.chqCatalogos,
      data: const {},
      fromJson: CatalogosChequeModel.fromJson,
      errorMessage: 'No se pudieron cargar los catálogos de cheques.',
    );
    return modelo?.toEntity() ?? CatalogosChequeEntity.vacio;
  }

  @override
  Future<List<EmpresaChequeEntity>> listarEmpresas() async {
    final modelos = await postAndReturnList<EmpresaChequeModel>(
      endpoint: AppConstants.chqEmpresas,
      fromJson: EmpresaChequeModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> obtenerSucursalInicial({int codEmpresa = 0}) async {
    final cod = await postAndReturnId(
      endpoint: AppConstants.chqSucursalInicial,
      // El cuerpo es opcional: sin empresa no viaja ninguna.
      data: codEmpresa > 0 ? {'id': codEmpresa} : const {},
      errorMessage: 'No se pudo consultar la sucursal inicial.',
    );
    return cod.toInt();
  }

  @override
  Future<List<SucursalChequeEntity>> listarSucursales({
    int codEmpresa = 0,
  }) async {
    final modelos = await postAndReturnList<SucursalChequeModel>(
      endpoint: AppConstants.chqSucursales,
      data: {'id': codEmpresa},
      fromJson: SucursalChequeModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SocioNegocioEntity>> listarClientes({int codEmpresa = 0}) async {
    final modelos = await postAndReturnList<SocioNegocioModel>(
      endpoint: AppConstants.chqClientes,
      data: {'id': codEmpresa},
      fromJson: (json) => SocioNegocioModel.fromJson(_completarSocio(json)),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  /// `SocioNegocioModel` (el de Depositos) lee varias claves como no nulas: un
  /// cliente con una columna en NULL tumbaria toda la lista y con ella el alta
  /// del cheque. Se completan con vacio o 0 antes de entregarselo.
  static Map<String, dynamic> _completarSocio(Map<String, dynamic> json) => {
    ...json,
    'codCliente': json['codCliente'] ?? '',
    'razonSocial': json['razonSocial'] ?? '',
    'codCiudad': json['codCiudad'] ?? 0,
    'codEmpresa': json['codEmpresa'] ?? 0,
    'audUsuario': json['audUsuario'] ?? 0,
    'nombreCompleto': json['nombreCompleto'] ?? '',
  };

  @override
  Future<List<PersonalChequeEntity>> listarQuienesEntregan(int codSucursal) =>
      _personal(AppConstants.chqPersonalEntregan, codSucursal);

  @override
  Future<List<PersonalChequeEntity>> listarResponsablesDeCustodia(
    int codSucursal,
  ) => _personal(AppConstants.chqPersonalCustodia, codSucursal);

  Future<List<PersonalChequeEntity>> _personal(
    String endpoint,
    int codSucursal,
  ) async {
    final modelos = await postAndReturnList<PersonalChequeModel>(
      endpoint: endpoint,
      data: {'id': codSucursal},
      fromJson: PersonalChequeModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ============================== CHEQUES ==================================

  @override
  Future<ChequePaginaEntity> listar(ChequeFiltroEntity filtro) async {
    final modelo = await postAndReturnObject<ChequePaginaModel>(
      endpoint: AppConstants.chqListar,
      data: ChequeFiltroModel.fromEntity(filtro).toJson(),
      fromJson: ChequePaginaModel.fromJson,
      errorMessage: 'No se pudieron cargar los cheques.',
    );
    return modelo?.toEntity() ??
        ChequePaginaEntity.vacia(
          pagina: filtro.pagina,
          tamanio: filtro.tamanio,
        );
  }

  @override
  Future<ChequeDetalleEntity?> obtenerDetalle(BigInt codCheque) async {
    final modelo = await postAndReturnObject<ChequeDetalleModel>(
      endpoint: AppConstants.chqDetalle,
      data: {'id': codCheque.toInt()},
      fromJson: ChequeDetalleModel.fromJson,
      errorMessage: 'No se pudo cargar el cheque.',
    );
    return modelo?.toEntity();
  }

  @override
  Future<BigInt> registrar(ChequeRegistroEntity registro) => postAndReturnId(
    endpoint: AppConstants.chqRegistrar,
    data: ChequeRegistroModel.fromEntity(registro).toJson(),
    errorMessage: 'No se pudo guardar el cheque.',
  );

  @override
  Future<TalonarioValidacionEntity> validarTalonario({
    required int codEmpresa,
    required String nroTalonario,
    required String reciboManual,
  }) async {
    final modelo = await postAndReturnObject<TalonarioValidacionModel>(
      endpoint: AppConstants.chqTalonarioValidar,
      data: {
        'codEmpresa': codEmpresa,
        'nroTalonario': nroTalonario.trim(),
        'reciboManual': reciboManual.trim(),
      },
      fromJson: TalonarioValidacionModel.fromJson,
      errorMessage: 'No se pudo comprobar el talonario.',
    );
    // Sin cuerpo no hay nada que objetar: el servidor valida igual al guardar.
    return modelo?.toEntity() ?? TalonarioValidacionEntity.sinObjeciones;
  }

  // ====================== ACCIONES DEL DETALLE =============================

  @override
  Future<BigInt> cambiarFechaCobro(AccionChequeRequestEntity accion) =>
      postAndReturnId(
        endpoint: AppConstants.chqAccionFechaCobro,
        data: AccionChequeRequestModel.fromEntity(accion).toJson(),
        errorMessage: 'No se pudo cambiar la fecha de cobro.',
      );

  @override
  Future<BigInt> devolver(AccionChequeRequestEntity accion) => postAndReturnId(
    endpoint: AppConstants.chqAccionDevolver,
    data: AccionChequeRequestModel.fromEntity(accion).toJson(),
    errorMessage: 'No se pudo devolver el cheque.',
  );

  @override
  Future<BigInt> cerrar(AccionChequeRequestEntity accion) => postAndReturnId(
    endpoint: AppConstants.chqAccionCerrar,
    data: AccionChequeRequestModel.fromEntity(accion).toJson(),
    errorMessage: 'No se pudo cerrar el cheque.',
  );

  @override
  Future<BigInt> eliminarAccion(BigInt codAccion) => postAndReturnId(
    endpoint: AppConstants.chqAccionEliminar,
    data: {'id': codAccion.toInt()},
    errorMessage: 'No se pudo eliminar la acción.',
  );

  // ======================== TRASPASO Y CUSTODIA ============================

  @override
  Future<int> contarTraspasosPendientes(int codSucursal) async {
    final n = await postAndReturnId(
      endpoint: AppConstants.chqTraspasoPendientes,
      data: {'id': codSucursal},
      errorMessage: 'No se pudo consultar los traspasos pendientes.',
    );
    return n.toInt();
  }

  @override
  Future<int> traspasar(int codSucursal) async {
    final n = await postAndReturnId(
      endpoint: AppConstants.chqTraspaso,
      data: {'id': codSucursal},
      errorMessage: 'No se pudo generar el traspaso.',
    );
    return n.toInt();
  }

  @override
  Future<List<ChequeFilaEntity>> listarChequesParaCustodia(
    int codSucursal,
  ) async {
    final modelos = await postAndReturnList<ChequeFilaModel>(
      endpoint: AppConstants.chqCustodiaCheques,
      data: {'id': codSucursal},
      fromJson: ChequeFilaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> entregarEnCustodia(CustodiaChequeRequestEntity pedido) async {
    final n = await postAndReturnId(
      endpoint: AppConstants.chqCustodia,
      data: CustodiaChequeRequestModel.fromEntity(pedido).toJson(),
      errorMessage: 'No se pudo entregar los cheques en custodia.',
    );
    return n.toInt();
  }

  @override
  Future<List<ChequeResumenEntity>> listarChequesParaDarCustodia(
    int codSucursal,
  ) async {
    final modelos = await postAndReturnList<ChequeResumenModel>(
      endpoint: AppConstants.chqDarCustodiaCheques,
      data: {'id': codSucursal},
      fromJson: ChequeResumenModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<EntregaChequeEntity>> listarEntregasDelDia({
    required int codSucursal,
    required DateTime fecha,
  }) async {
    final modelos = await postAndReturnList<EntregaChequeModel>(
      endpoint: AppConstants.chqDarCustodiaEntregas,
      data: {'codSucursal': codSucursal, 'fecha': fechaParaSql(fecha)},
      fromJson: EntregaChequeModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> darCustodia(DarCustodiaRequestEntity pedido) =>
      postAndReturnId(
        endpoint: AppConstants.chqDarCustodia,
        data: DarCustodiaRequestModel.fromEntity(pedido).toJson(),
        errorMessage: 'No se pudo asignar la custodia.',
      );

  // ============================== REPORTES =================================

  /// Los reportes recorren las tablas de cheques y acciones y los arma Jasper en
  /// el servidor: los 30 s por defecto de Dio no siempre alcanzan.
  static const Duration _esperaReporte = Duration(minutes: 2);

  @override
  Future<Uint8List> reporteRecibidos({
    required int codEmpresa,
    required int codSucursal,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) => _pdf(
    AppConstants.chqReporteRecibidos,
    _cuerpoReporte(
      codEmpresa,
      codSucursal,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    ),
  );

  @override
  Future<Uint8List> reporteCobranzas({
    required int codEmpresa,
    required int codSucursal,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? estado,
    String? codCliente,
  }) => _pdf(
    AppConstants.chqReporteCobranzas,
    _cuerpoReporte(
      codEmpresa,
      codSucursal,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      estado: estado,
      codCliente: codCliente,
    ),
  );

  @override
  Future<Uint8List> reporteCustodio({
    required int codEmpresa,
    required int codSucursal,
    DateTime? fecha,
    int? codEmpleado,
  }) => _pdf(
    AppConstants.chqReporteCustodio,
    _cuerpoReporte(
      codEmpresa,
      codSucursal,
      fecha: fecha,
      // 0 es «todos los cobradores», igual que no mandarlo.
      codEmpleado: (codEmpleado ?? 0) > 0 ? codEmpleado : null,
    ),
  );

  @override
  Future<Uint8List> reporteUltimoRecibo({
    required int codEmpresa,
    required int codSucursal,
  }) => _pdf(
    AppConstants.chqReporteUltimoRecibo,
    _cuerpoReporte(codEmpresa, codSucursal),
  );

  @override
  Future<Uint8List> reporteTraspaso({
    required int codEmpresa,
    required int codSucursal,
  }) => _pdf(
    AppConstants.chqReporteTraspaso,
    _cuerpoReporte(codEmpresa, codSucursal),
  );

  @override
  Future<Uint8List> reporteReimpresionTraspaso({
    required int codEmpresa,
    required int codSucursal,
    required int codAccion,
  }) => _pdf(
    AppConstants.chqReporteReimpresionTraspaso,
    _cuerpoReporte(codEmpresa, codSucursal, codAccion: codAccion),
  );

  @override
  Future<List<HoraTraspasoChequeEntity>> listarHorasDeTraspaso({
    required int codSucursal,
    required DateTime fecha,
  }) async {
    final modelos = await postAndReturnList<HoraTraspasoChequeModel>(
      endpoint: AppConstants.chqTraspasoHoras,
      data: {'codSucursal': codSucursal, 'fecha': fechaParaSql(fecha)},
      fromJson: HoraTraspasoChequeModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ======================== DOCUMENTO PDF DEL CHEQUE =======================

  @override
  Future<PdfChequeEstadoEntity> estadoPdf(BigInt codCheque) async {
    final modelo = await postAndReturnObject<PdfChequeEstadoModel>(
      endpoint: AppConstants.chqPdfEstado,
      data: {'codCheque': codCheque.toInt()},
      fromJson: PdfChequeEstadoModel.fromJson,
      errorMessage: 'No se pudo consultar el PDF del cheque.',
    );
    // Sin cuerpo no hay archivo: no es un error.
    return modelo?.toEntity() ?? PdfChequeEstadoEntity.sinArchivo;
  }

  /// Un PDF de 2 MB por una red lenta tarda mas que los 30 s de espera global
  /// (en la web el tope de la peticion es conexion + espera).
  static const Duration _esperaSubidaPdf = Duration(minutes: 2);

  @override
  Future<PdfChequeSubidaEntity> subirPdf(
    BigInt codCheque,
    Uint8List bytes,
    String nombreArchivo, {
    void Function(int enviados, int total)? alProgreso,
  }) => _subirMultipart(
    endpoint: AppConstants.chqPdfSubir,
    parteId: 'codCheque',
    id: codCheque,
    bytes: bytes,
    nombreArchivo: nombreArchivo,
    respaldo: 'No se pudo cargar el PDF del cheque.',
    alProgreso: alProgreso,
  );

  /// La subida de un PDF, igual para el del cheque y el de una postergacion:
  /// multipart con el id como parte de texto (`codCheque` o `codPostergacion`) y
  /// el archivo en la parte `archivo`.
  Future<PdfChequeSubidaEntity> _subirMultipart({
    required String endpoint,
    required String parteId,
    required BigInt id,
    required Uint8List bytes,
    required String nombreArchivo,
    required String respaldo,
    void Function(int enviados, int total)? alProgreso,
  }) async {
    // El servidor solo toma la parte como archivo si trae un nombre: sin el,
    // Tomcat la trata como texto y responde «No se recibio ningun archivo».
    final nombre =
        nombreArchivo.trim().isEmpty ? '$id.pdf' : nombreArchivo.trim();
    try {
      final formulario = FormData.fromMap({
        // Parte de texto: el id va como texto, no como archivo.
        parteId: id.toInt().toString(),
        'archivo': MultipartFile.fromBytes(
          bytes,
          filename: nombre,
          contentType: DioMediaType('application', 'pdf'),
        ),
      });
      final response = await dio.post(
        endpoint,
        data: formulario,
        onSendProgress: alProgreso,
        options: Options(
          sendTimeout: _esperaSubidaPdf,
          receiveTimeout: _esperaSubidaPdf,
        ),
      );
      final cuerpo = response.data;
      final datos = cuerpo is Map ? cuerpo['data'] : null;
      if (datos is! Map<String, dynamic>) throw Exception(respaldo);
      return PdfChequeSubidaModel.fromJson(datos).toEntity();
    } on DioException catch (e) {
      // Un archivo que pasa el tope del servidor se corta antes de llegar al
      // controlador: la respuesta no trae el mensaje de negocio.
      if (e.response?.statusCode == 413 && e.response?.data is! Map) {
        throw Exception(
          'El servidor rechazó el archivo porque pesa demasiado. '
          'Elige un PDF más liviano.',
        );
      }
      throw Exception(DioClient.handleDioError(e, respaldo));
    }
  }

  @override
  Future<Uint8List> descargarPdf(BigInt codCheque) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.chqPdfDescargar,
        data: {'codCheque': codCheque.toInt()},
        receiveTimeout: _esperaReporte,
      );

  // ============ PANELES DEL DETALLE: NOTAS, TRANSACCIONES, POSTERGACIONES ====

  @override
  Future<List<NotaRemisionChequeEntity>> listarNotasRemision(
    BigInt codCheque,
  ) async {
    final modelos = await postAndReturnList<NotaRemisionChequeModel>(
      endpoint: AppConstants.chqNotaRemisionListar,
      data: {'codCheque': codCheque.toInt()},
      fromJson: NotaRemisionChequeModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registrarNotaRemision(NotaRemisionChequeEntity nota) async {
    await postAndReturnId(
      endpoint: AppConstants.chqNotaRemisionRegistrar,
      data: NotaRemisionChequeModel.fromEntity(nota).toCuerpoRegistro(),
      errorMessage: 'No se pudo guardar la nota de remisión.',
    );
  }

  @override
  Future<int> eliminarNotaRemision({
    required BigInt codCheque,
    required String notaRemision,
  }) async {
    final n = await postAndReturnId(
      endpoint: AppConstants.chqNotaRemisionEliminar,
      data: {'codCheque': codCheque.toInt(), 'notaRemision': notaRemision},
      errorMessage: 'No se pudo eliminar la nota de remisión.',
    );
    return n.toInt();
  }

  @override
  Future<List<TransaccionBancariaEntity>> listarTransacciones(
    BigInt codCheque,
  ) async {
    final modelos = await postAndReturnList<TransaccionBancariaModel>(
      endpoint: AppConstants.chqTransaccionListar,
      data: {'codCheque': codCheque.toInt()},
      fromJson: TransaccionBancariaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registrarTransaccion(
    TransaccionBancariaEntity transaccion,
  ) async {
    await postAndReturnId(
      endpoint: AppConstants.chqTransaccionRegistrar,
      data: TransaccionBancariaModel.fromEntity(transaccion).toCuerpoRegistro(),
      errorMessage: 'No se pudo guardar la transacción bancaria.',
    );
  }

  @override
  Future<int> eliminarTransaccion({
    required BigInt codCheque,
    required String nroTransaccion,
  }) async {
    final n = await postAndReturnId(
      endpoint: AppConstants.chqTransaccionEliminar,
      data: {'codCheque': codCheque.toInt(), 'nroTransaccion': nroTransaccion},
      errorMessage: 'No se pudo eliminar la transacción bancaria.',
    );
    return n.toInt();
  }

  @override
  Future<List<PostergacionEntity>> listarPostergaciones(
    BigInt codCheque,
  ) async {
    final modelos = await postAndReturnList<PostergacionModel>(
      endpoint: AppConstants.chqPostergacionListar,
      data: {'codCheque': codCheque.toInt()},
      fromJson: PostergacionModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarPostergacion(PostergacionEntity postergacion) =>
      postAndReturnId(
        endpoint: AppConstants.chqPostergacionRegistrar,
        data: PostergacionModel.fromEntity(postergacion).toCuerpoRegistro(),
        errorMessage: 'No se pudo guardar la postergación.',
      );

  @override
  Future<BigInt> eliminarPostergacion({
    required BigInt codCheque,
    required BigInt codPostergacion,
  }) => postAndReturnId(
    endpoint: AppConstants.chqPostergacionEliminar,
    data: {
      'codCheque': codCheque.toInt(),
      'codPostergacion': codPostergacion.toInt(),
    },
    errorMessage: 'No se pudo eliminar la postergación.',
  );

  @override
  Future<PdfChequeEstadoEntity> estadoPdfPostergacion(
    BigInt codPostergacion,
  ) async {
    final modelo = await postAndReturnObject<PdfChequeEstadoModel>(
      endpoint: AppConstants.chqPostergacionPdfEstado,
      data: {'codPostergacion': codPostergacion.toInt()},
      fromJson: PdfChequeEstadoModel.fromJson,
      errorMessage: 'No se pudo consultar el PDF de la postergación.',
    );
    // Sin cuerpo no hay archivo: no es un error.
    return modelo?.toEntity() ?? PdfChequeEstadoEntity.sinArchivo;
  }

  @override
  Future<PdfChequeSubidaEntity> subirPdfPostergacion(
    BigInt codPostergacion,
    Uint8List bytes,
    String nombreArchivo, {
    void Function(int enviados, int total)? alProgreso,
  }) => _subirMultipart(
    endpoint: AppConstants.chqPostergacionPdfSubir,
    parteId: 'codPostergacion',
    id: codPostergacion,
    bytes: bytes,
    nombreArchivo: nombreArchivo,
    respaldo: 'No se pudo cargar el PDF de la postergación.',
    alProgreso: alProgreso,
  );

  @override
  Future<Uint8List> descargarPdfPostergacion(BigInt codPostergacion) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.chqPostergacionPdfDescargar,
        data: {'codPostergacion': codPostergacion.toInt()},
        receiveTimeout: _esperaReporte,
      );

  Future<Uint8List> _pdf(String endpoint, Map<String, dynamic> cuerpo) =>
      DioClient.descargarReportePdf(
        endpoint: endpoint,
        data: cuerpo,
        receiveTimeout: _esperaReporte,
      );

  /// El cuerpo de un reporte. Solo viaja lo que se indico: una fecha ausente, un
  /// texto vacio o un id en null se omiten y el servidor los toma como «todos».
  /// Nunca lleva el usuario de auditoria.
  static Map<String, dynamic> _cuerpoReporte(
    int codEmpresa,
    int codSucursal, {
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    DateTime? fecha,
    String? estado,
    String? codCliente,
    int? codEmpleado,
    int? codAccion,
  }) {
    String? texto(String? t) => (t == null || t.trim().isEmpty) ? null : t.trim();
    return {
      'codEmpresa': codEmpresa,
      'codSucursal': codSucursal,
      if (fechaDesde != null) 'fechaDesde': fechaParaSql(fechaDesde),
      if (fechaHasta != null) 'fechaHasta': fechaParaSql(fechaHasta),
      if (fecha != null) 'fecha': fechaParaSql(fecha),
      if (texto(estado) != null) 'estado': texto(estado),
      if (texto(codCliente) != null) 'codCliente': texto(codCliente),
      if (codEmpleado != null) 'codEmpleado': codEmpleado,
      if (codAccion != null) 'codAccion': codAccion,
    };
  }
}
