import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/detalle_resmado_model.dart';
import 'package:bosque_flutter/data/models/empresa_model.dart';
import 'package:bosque_flutter/data/models/grupo_produccion_model.dart';
import 'package:bosque_flutter/data/models/lote_produccion_model.dart';
import 'package:bosque_flutter/data/models/resmado_model.dart';
import 'package:bosque_flutter/domain/entities/detalle_resmando_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/resmado_entity.dart';
import 'package:bosque_flutter/domain/repositories/resmado_repository.dart';
import 'package:dio/dio.dart';

class ResmadoImpl implements ResmadoRepository {
  final Dio _dio = DioClient.getInstance();

  @override
  Future<List<LoteProduccionEntity>> obtenerArticulos() async {
    try {
      final response = await _dio.post(
        AppConstants.obtenerArticulosRes,
        data: {},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((json) => LoteProduccionModel.fromJson(json).toEntity())
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<GrupoProduccionEntity>> obtenerGrupoProduccion() async {
    try {
      final response = await _dio.post(
        AppConstants.obtenerGrupoProduccion,
        data: {},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((json) => GrupoProduccionModel.fromJson(json).toEntity())
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<EmpresaEntity>> obtenerEmpresas() async {
    try {
      final response = await _dio.post(AppConstants.obtenerEmpresas, data: {});
      final list = response.data as List<dynamic>;
      return list
          .map((json) => EmpresaModel.fromJson(json).toEntity())
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<LoteProduccionEntity>> obtenerDocNumXEmpresa(
    int codEmpresa,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.obtenerDocNumOrdFabXEmpresa,
        data: {'codEmpresa': codEmpresa},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((json) => LoteProduccionModel.fromJson(json).toEntity())
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> registrarResmado(ResmadoEntity resmado) async {
    try {
      final model = ResmadoModel.fromEntity(resmado);
      final response = await _dio.post(
        AppConstants.registrarResmado,
        data: model.toJson(),
      );
      final ok = response.data['ok'] == 'ok';
      return ok;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> registrarDetalleResmado(
    List<DetalleResmadoEntity> detalles,
  ) async {
    try {
      final payload =
          detalles
              .map((e) => DetalleResmadoModel.fromEntity(e).toJson())
              .toList();
      final response = await _dio.post(
        AppConstants.registrarDetalleResmado,
        data: payload,
      );
      final ok = response.data['ok'] == 'ok';
      return ok;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
