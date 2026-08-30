import 'dart:typed_data';

import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/talonario_detalle_model.dart';
import 'package:bosque_flutter/data/models/talonario_grupo_model.dart';
import 'package:bosque_flutter/data/models/talonario_lote_model.dart';
import 'package:bosque_flutter/data/models/talonario_model.dart';
import 'package:bosque_flutter/data/models/talonario_por_grupo_model.dart';
import 'package:bosque_flutter/data/models/tipo_recibo_model.dart';
import 'package:bosque_flutter/domain/entities/talonario_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_grupo_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_por_grupo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_recibo_entity.dart';
import 'package:bosque_flutter/domain/repositories/talonarios_repository.dart';

final DateFormat _fmtPayload = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

/// Cuánto se espera un PDF antes de darlo por perdido.
///
/// El default de `BaseOptions` son 30 s, pensados para una llamada normal que
/// devuelve JSON. Un reporte no es eso: Jasper arma el documento entero antes
/// de mandar el primer byte, y mientras tanto el cliente no recibe nada. Con
/// 30 s el cliente cortaba mientras el servidor seguía trabajando —sin dejar
/// rastro en el log del backend, que es lo que hacía difícil de leer la falla.
const Duration _esperaReporteLocal = Duration(minutes: 2);

/// La conciliación lee SAP en vivo por OPENROWSET contra otro servidor, así
/// que juega en otra escala. No es «por las dudas»: la pantalla se lo avisa al
/// usuario antes de pedirlo.
const Duration _esperaReporteSap = Duration(minutes: 5);

class TalonariosImpl extends BaseApiRepository implements TalonariosRepository {
  // ==================== TIPOS DE RECIBO ====================

  @override
  Future<List<TipoReciboEntity>> listarTipos() async {
    final modelos = await postAndReturnList<TipoReciboModel>(
      endpoint: AppConstants.talListarTipos,
      data: const {},
      fromJson: (json) => TipoReciboModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<TipoReciboEntity?> obtenerTipo(BigInt codTipoRecibo) async {
    final modelos = await postAndReturnList<TipoReciboModel>(
      endpoint: AppConstants.talObtenerTipo,
      data: {'codTipoRecibo': codTipoRecibo.toInt()},
      fromJson: (json) => TipoReciboModel.fromJson(json),
    );
    return modelos.isEmpty ? null : modelos.first.toEntity();
  }

  @override
  Future<BigInt> registrarTipo(TipoReciboEntity tipo) async {
    return postAndReturnId(
      endpoint: AppConstants.talRegistrarTipo,
      data: TipoReciboModel.fromEntity(tipo).toJson(),
      errorMessage: 'Error al registrar el tipo de recibo',
    );
  }

  @override
  Future<BigInt> eliminarTipo(BigInt codTipoRecibo, BigInt audUsuario) async {
    return postAndReturnId(
      endpoint: AppConstants.talEliminarTipo,
      data: {
        'codTipoRecibo': codTipoRecibo.toInt(),
        'audUsuario': audUsuario.toInt(),
      },
      errorMessage: 'Error al eliminar el tipo de recibo',
    );
  }

  // ==================== GRUPOS ====================

  @override
  Future<List<TalonarioGrupoEntity>> listarGrupos() async {
    final modelos = await postAndReturnList<TalonarioGrupoModel>(
      endpoint: AppConstants.talListarGrupos,
      data: const {},
      fromJson: (json) => TalonarioGrupoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<TalonarioGrupoEntity?> obtenerGrupo(BigInt codGrupo) async {
    final modelos = await postAndReturnList<TalonarioGrupoModel>(
      endpoint: AppConstants.talObtenerGrupo,
      data: {'codGrupo': codGrupo.toInt()},
      fromJson: (json) => TalonarioGrupoModel.fromJson(json),
    );
    return modelos.isEmpty ? null : modelos.first.toEntity();
  }

  @override
  Future<BigInt> registrarGrupo(TalonarioGrupoEntity grupo) async {
    return postAndReturnId(
      endpoint: AppConstants.talRegistrarGrupo,
      data: TalonarioGrupoModel.fromEntity(grupo).toJson(),
      errorMessage: 'Error al registrar el grupo',
    );
  }

  @override
  Future<BigInt> eliminarGrupo(BigInt codGrupo, BigInt audUsuario) async {
    return postAndReturnId(
      endpoint: AppConstants.talEliminarGrupo,
      data: {'codGrupo': codGrupo.toInt(), 'audUsuario': audUsuario.toInt()},
      errorMessage: 'Error al eliminar el grupo',
    );
  }

  // ==================== TIPOS POR GRUPO ====================

  @override
  Future<List<TalonarioPorGrupoEntity>> listarTiposPorGrupo(
    BigInt? codGrupo,
  ) async {
    final modelos = await postAndReturnList<TalonarioPorGrupoModel>(
      endpoint: AppConstants.talListarTiposPorGrupo,
      // 0 = todas las asignaciones; el backend lo traduce a "sin filtro"
      data: {'codGrupo': codGrupo?.toInt() ?? 0},
      fromJson: (json) => TalonarioPorGrupoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<TalonarioPorGrupoEntity>> listarTiposDisponibles(
    BigInt codGrupo,
  ) async {
    final modelos = await postAndReturnList<TalonarioPorGrupoModel>(
      endpoint: AppConstants.talListarTiposDisponibles,
      data: {'codGrupo': codGrupo.toInt()},
      fromJson: (json) => TalonarioPorGrupoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> asignarTipoAGrupo(TalonarioPorGrupoEntity asignacion) async {
    return postAndReturnId(
      endpoint: AppConstants.talAsignarTipoGrupo,
      data: TalonarioPorGrupoModel.fromEntity(asignacion).toJson(),
      errorMessage: 'Error al asignar el tipo al grupo',
    );
  }

  @override
  Future<BigInt> quitarTipoDeGrupo(TalonarioPorGrupoEntity asignacion) async {
    return postAndReturnId(
      endpoint: AppConstants.talQuitarTipoGrupo,
      data: TalonarioPorGrupoModel.fromEntity(asignacion).toJson(),
      errorMessage: 'Error al quitar el tipo del grupo',
    );
  }

  // ==================== TALONARIOS ====================

  @override
  Future<List<TalonarioEntity>> listarTalonarios({
    BigInt? codTipoRecibo,
    BigInt? codEmpresa,
    BigInt? codGrupo,
    int? codEstadoActual,
    DateTime? desde,
    DateTime? hasta,
    bool? incluirCerrados,
  }) async {
    // null se manda tal cual: el backend usa Long/Integer/Boolean y omite el
    // parámetro para que el SP aplique su DEFAULT NULL (sin filtro).
    final modelos = await postAndReturnList<TalonarioModel>(
      endpoint: AppConstants.talListarTalonarios,
      data: {
        'codTipoRecibo': codTipoRecibo?.toInt(),
        'codEmpresa': codEmpresa?.toInt(),
        'codGrupo': codGrupo?.toInt(),
        'codEstadoActual': codEstadoActual,
        'fechaDesde': desde == null ? null : _fmtPayload.format(desde),
        'fechaHasta': hasta == null ? null : _fmtPayload.format(hasta),
        'incluirCerrados': incluirCerrados,
      },
      fromJson: (json) => TalonarioModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<TalonarioEntity>> listarDisponibles({BigInt? codGrupo}) async {
    final modelos = await postAndReturnList<TalonarioModel>(
      endpoint: AppConstants.talListarDisponibles,
      data: {'codGrupo': codGrupo?.toInt()},
      fromJson: (json) => TalonarioModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<TalonarioEntity?> obtenerTalonario(BigInt codTalonario) async {
    final modelos = await postAndReturnList<TalonarioModel>(
      endpoint: AppConstants.talObtenerTalonario,
      data: {'codTalonario': codTalonario.toInt()},
      fromJson: (json) => TalonarioModel.fromJson(json),
    );
    return modelos.isEmpty ? null : modelos.first.toEntity();
  }

  @override
  Future<BigInt> registrarTalonario(TalonarioEntity talonario) async {
    return postAndReturnId(
      endpoint: AppConstants.talRegistrarTalonario,
      data: TalonarioModel.fromEntity(talonario).toJson(),
      errorMessage: 'Error al registrar el talonario',
    );
  }

  @override
  Future<BigInt> eliminarTalonario(
    BigInt codTalonario,
    BigInt audUsuario,
  ) async {
    return postAndReturnId(
      endpoint: AppConstants.talEliminarTalonario,
      data: {
        'codTalonario': codTalonario.toInt(),
        'audUsuario': audUsuario.toInt(),
      },
      errorMessage: 'Error al eliminar el talonario',
    );
  }

  // ==================== ALTA MASIVA ====================

  @override
  Future<TalonarioLoteModel> simularLote(TalonarioLoteModel lote) async {
    // Devuelve el DTO completo, no una lista: va con postAndReturnObject.
    final resultado = await postAndReturnObject<TalonarioLoteModel>(
      endpoint: AppConstants.talSimularLote,
      data: lote.toJson(),
      fromJson: (json) => TalonarioLoteModel.fromJson(json),
      errorMessage: 'Error al simular el lote',
    );
    return resultado ?? lote;
  }

  @override
  Future<List<BigInt>> aplicarLote(TalonarioLoteModel lote) async {
    // El backend devuelve data como una lista de NUMEROS (los ids generados),
    // no de objetos, así que postAndReturnList no sirve: su fromJson espera
    // un Map por elemento. Va con postAndReturnFullResponse, que además tira
    // el mensaje del backend como String plano — justo lo que se quiere para
    // el "No se guardó ningún registro" del lote, sin prefijo "Exception: ".
    return postAndReturnFullResponse<List<BigInt>>(
      endpoint: AppConstants.talAplicarLote,
      data: lote.toJson(),
      fromJson: _idsDeLaRespuesta,
      errorMessage: 'Error al registrar el lote de talonarios',
    );
  }

  // ==================== EVENTOS ====================

  @override
  Future<List<TalonarioDetalleEntity>> listarEventos(
    BigInt codTalonario,
  ) async {
    final modelos = await postAndReturnList<TalonarioDetalleModel>(
      endpoint: AppConstants.talListarEventos,
      data: {'codTalonario': codTalonario.toInt()},
      fromJson: (json) => TalonarioDetalleModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarEvento(TalonarioDetalleEntity evento) async {
    return postAndReturnId(
      endpoint: AppConstants.talRegistrarEvento,
      data: TalonarioDetalleModel.fromEntity(evento).toJson(),
      errorMessage: 'Error al registrar el evento',
    );
  }

  @override
  Future<BigInt> eliminarEvento(BigInt codDetalle, BigInt audUsuario) async {
    return postAndReturnId(
      endpoint: AppConstants.talEliminarEvento,
      data: {
        'codDetalle': codDetalle.toInt(),
        'audUsuario': audUsuario.toInt(),
      },
      errorMessage: 'Error al eliminar el evento',
    );
  }

  // ==================== ENTREGA MASIVA ====================

  @override
  Future<List<BigInt>> entregarLote({
    required List<BigInt> codTalonarios,
    required DateTime fechaEvento,
    BigInt? codSucursal,
    BigInt? codEmpleado,
    String observacion = '',
    required BigInt audUsuario,
  }) async {
    return postAndReturnFullResponse<List<BigInt>>(
      endpoint: AppConstants.talEntregarLote,
      data: {
        'codTalonarios': codTalonarios.map((e) => e.toInt()).toList(),
        'fechaEvento': _fmtPayload.format(fechaEvento),
        'codSucursal': codSucursal?.toInt() ?? 0,
        'codEmpleado': codEmpleado?.toInt() ?? 0,
        'observacion': observacion,
        'audUsuario': audUsuario.toInt(),
      },
      fromJson: _idsDeLaRespuesta,
      errorMessage: 'Error al entregar el lote de talonarios',
    );
  }

  /// El envelope trae data como lista de números; los pasa a BigInt.
  static List<BigInt> _idsDeLaRespuesta(Map<String, dynamic> json) {
    final lista = json['data'] as List<dynamic>?;
    if (lista == null) return <BigInt>[];
    return lista.map((e) => BigInt.from((e as num).toInt())).toList();
  }

  // ==================== REPORTES ====================

  @override
  Future<Uint8List> reporteInventario({
    BigInt? codTipoRecibo,
    BigInt? codEmpresa,
    BigInt? codGrupo,
    int? codEstadoActual,
    DateTime? desde,
    DateTime? hasta,
    bool? incluirCerrados,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.talRptInventario,
    receiveTimeout: _esperaReporteLocal,
    data: {
      'codTipoRecibo': codTipoRecibo?.toInt(),
      'codEmpresa': codEmpresa?.toInt(),
      'codGrupo': codGrupo?.toInt(),
      'codEstadoActual': codEstadoActual,
      'fechaDesde': desde == null ? null : _fmtPayload.format(desde),
      'fechaHasta': hasta == null ? null : _fmtPayload.format(hasta),
      'incluirCerrados': incluirCerrados,
    },
  );

  @override
  Future<Uint8List> reporteTrazabilidad({
    BigInt? codTalonario,
    BigInt? codTipoRecibo,
    BigInt? codEmpresa,
    BigInt? codSucursal,
    BigInt? codEmpleado,
    DateTime? desde,
    DateTime? hasta,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.talRptTrazabilidad,
    receiveTimeout: _esperaReporteLocal,
    data: {
      'codTalonario': codTalonario?.toInt(),
      'codTipoRecibo': codTipoRecibo?.toInt(),
      'codEmpresa': codEmpresa?.toInt(),
      'codSucursal': codSucursal?.toInt(),
      'codEmpleado': codEmpleado?.toInt(),
      'fechaDesde': desde == null ? null : _fmtPayload.format(desde),
      'fechaHasta': hasta == null ? null : _fmtPayload.format(hasta),
    },
  );

  @override
  Future<Uint8List> reporteCustodia({
    BigInt? codTipoRecibo,
    BigInt? codEmpresa,
    BigInt? codSucursal,
    BigInt? codEmpleado,
    String? tipoDestinatario,
    int? diasMinimos,
    DateTime? desde,
    DateTime? hasta,
    bool incluirCerrados = false,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.talRptCustodia,
    receiveTimeout: _esperaReporteLocal,
    data: {
      'codTipoRecibo': codTipoRecibo?.toInt(),
      'codEmpresa': codEmpresa?.toInt(),
      'codSucursal': codSucursal?.toInt(),
      'codEmpleado': codEmpleado?.toInt(),
      'tipoDestinatario': tipoDestinatario,
      'diasMinimos': diasMinimos,
      'fechaDesde': desde == null ? null : _fmtPayload.format(desde),
      'fechaHasta': hasta == null ? null : _fmtPayload.format(hasta),
      'incluirCerrados': incluirCerrados,
    },
  );

  @override
  Future<Uint8List> reporteFicha(BigInt codTalonario) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.talRptFicha,
        receiveTimeout: _esperaReporteLocal,
        data: {'codTalonario': codTalonario.toInt()},
      );

  @override
  Future<Uint8List> reporteConciliacionSap({
    required String origen,
    required String accionSap,
    BigInt? codEmpresa,
    BigInt? codTipoRecibo,
    DateTime? desde,
    DateTime? hasta,
    List<BigInt>? seleccion,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.talRptConciliacionSap,
    receiveTimeout: _esperaReporteSap,
    data: {
      'origen': origen,
      'accionSap': accionSap,
      'codEmpresa': codEmpresa?.toInt(),
      'codTipoRecibo': codTipoRecibo?.toInt(),
      'fechaDesde': desde == null ? null : _fmtPayload.format(desde),
      'fechaHasta': hasta == null ? null : _fmtPayload.format(hasta),
      // El SP parsea la lista partiendo por comas, así que va como cadena y no
      // como arreglo. Vacía significa "sin selección" y el backend cambia a
      // modo grupo.
      'seleccion':
          (seleccion == null || seleccion.isEmpty)
              ? null
              : seleccion.map((e) => e.toString()).join(','),
    },
  );
}
