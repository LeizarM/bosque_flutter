import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/ccr_solicitud_detalle_model.dart';
import 'package:bosque_flutter/data/models/ccr_solicitud_model.dart';
import 'package:bosque_flutter/data/models/item_sap_model.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/item_sap_entity.dart';
import 'package:bosque_flutter/domain/repositories/solicitud_corte_repository.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class SolicitudCorteImpl implements SolicitudCorteRepository {
  final Dio _dio = DioClient.getInstance();

  /// Rango a medianoche: el SP compara contra una columna `date`.
  Map<String, dynamic> _rango(DateTime desde, DateTime hasta) {
    final fmt = DateFormat("yyyy-MM-dd'T'00:00:00.000");
    return {'fechaIni': fmt.format(desde), 'fechaFin': fmt.format(hasta)};
  }

  /// El mensaje del backend, para mostrarlo tal cual al usuario.
  String _mensaje(DioException e, String porDefecto) {
    final data = e.response?.data;
    if (data is Map && data['msg'] != null) return data['msg'].toString();
    return porDefecto;
  }

  @override
  Future<List<CcrSolicitudEntity>> obtenerSolicitudes(
    DateTime desde,
    DateTime hasta,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.listadoSolicitudesCorte,
        data: _rango(desde, hasta),
      );
      final list = (response.data as List<dynamic>?) ?? const [];
      return list
          .map((json) => CcrSolicitudModel.fromJson(json).toEntity())
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<CcrSolicitudDetalleEntity>> obtenerDetalle(
    int idSolicitud,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.detalleSolicitudCorte,
        data: {'idSolicitud': idSolicitud},
      );
      final list = (response.data as List<dynamic>?) ?? const [];
      return list
          .map((json) => CcrSolicitudDetalleModel.fromJson(json).toEntity())
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ItemSapEntity>> buscarItemsSap({
    required String texto,
    int limite = 50,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.itemsSapCorte,
        data: {'texto': texto, 'limite': limite},
      );
      final list = (response.data as List<dynamic>?) ?? const [];
      return list.map((json) => ItemSapModel.fromJson(json).toEntity()).toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<int> totalItemsSap() async {
    try {
      final response = await _dio.post(
        AppConstants.itemsSapCorteTotal,
        data: {},
      );
      return (response.data?['total'] ?? 0).toInt();
    } on DioException {
      return 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<int> registrarSolicitud({
    required CcrSolicitudEntity solicitud,
    required List<CcrSolicitudDetalleEntity> detalle,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.registrarSolicitudCorte,
        data: {
          'solicitud': CcrSolicitudModel.fromEntity(solicitud).toJson(),
          'detalle': detalle
              .map((d) => CcrSolicitudDetalleModel.fromEntity(d).toJson())
              .toList(),
        },
      );
      return (response.data?['idSolicitud'] ?? 0).toInt();
    } on DioException catch (e) {
      throw _mensaje(e, 'No se pudo registrar la solicitud de corte.');
    }
  }

  @override
  Future<void> cancelarSolicitud({
    required int idSolicitud,
    required String motivo,
    required int audUsuario,
  }) async {
    try {
      await _dio.post(
        AppConstants.cancelarSolicitudCorte,
        data: {
          'idSolicitud': idSolicitud,
          'observacion': motivo,
          'audUsuario': audUsuario,
        },
      );
    } on DioException catch (e) {
      throw _mensaje(e, 'No se pudo cancelar la solicitud.');
    }
  }

  @override
  Future<Uint8List> reporteSolicitudPdf(int idSolicitud) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.reporteSolicitudCortePdf,
        data: {'idSolicitud': idSolicitud},
      );

  @override
  Future<Uint8List> reporteResumenPdf(DateTime desde, DateTime hasta) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.reporteResumenCortePdf,
        data: _rango(desde, hasta),
      );
}
