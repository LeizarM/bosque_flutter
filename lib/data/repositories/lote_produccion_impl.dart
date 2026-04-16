import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/empresa_model.dart';
import 'package:bosque_flutter/data/models/lote_produccion_model.dart';
import 'package:bosque_flutter/data/models/maquina_produccion_model.dart';
import 'package:bosque_flutter/data/models/material_ingreso_model.dart';
import 'package:bosque_flutter/data/models/material_salida_model.dart';
import 'package:bosque_flutter/data/models/merma_model.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/material_ingreso_entity.dart';
import 'package:bosque_flutter/domain/entities/material_salida_entity.dart';
import 'package:bosque_flutter/domain/entities/merma_entity.dart';
import 'package:bosque_flutter/domain/repositories/lote_produccion_repository.dart';
import 'package:dio/dio.dart';

class LoteProduccionImpl implements LoteProduccionRepository {
  final Dio _dio = DioClient.getInstance();

  @override
  Future<LoteProduccionEntity?> obtenerNuevoLote(int idMa) async {
    try {
      final response = await _dio.post(
        AppConstants.obtenerLotesProduccion,
        data: {'idMa': idMa},
      );
      final list = (response.data as List<dynamic>);
      if (list.isEmpty) return null;
      return LoteProduccionModel.fromJson(list.first).toEntity();
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<LoteProduccionEntity>> obtenerArticulos() async {
    try {
      final response = await _dio.post(AppConstants.obtenerArticulos, data: {});
      final list = (response.data as List<dynamic>);
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
  Future<List<MaquinaProduccionEntity>> obtenerMaquinas() async {
    try {
      final response = await _dio.post(AppConstants.obtenerMaquinas, data: {});
      final list = (response.data as List<dynamic>);
      return list
          .map((json) => MaquinaProduccionModel.fromJson(json).toEntity())
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
      final list = (response.data as List<dynamic>);
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
      final list = (response.data as List<dynamic>);
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
  Future<bool> registrarLoteProduccion(LoteProduccionEntity lote) async {
    try {
      final model = LoteProduccionModel.fromEntity(lote);
      final response = await _dio.post(
        AppConstants.registrarLoteProduccion,
        data: model.toJson(),
      );
      return response.data?['ok'] == 'ok';
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> registrarMaterialIngreso(
    List<MaterialIngresoEntity> lista,
  ) async {
    try {
      final body =
          lista
              .map((e) => MaterialIngresoModel.fromEntity(e).toJson())
              .toList();
      final response = await _dio.post(
        AppConstants.registrarMaterialIngreso,
        data: body,
      );
      return response.data?['ok'] == 'ok';
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> registrarMaterialSalida(List<MaterialSalidaEntity> lista) async {
    try {
      final body =
          lista.map((e) => MaterialSalidaModel.fromEntity(e).toJson()).toList();
      final response = await _dio.post(
        AppConstants.registrarMaterialSalida,
        data: body,
      );
      return response.data?['ok'] == 'ok';
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> registrarMerma(List<MermaEntity> lista) async {
    try {
      final body = lista.map((e) => MermaModel.fromEntity(e).toJson()).toList();
      final response = await _dio.post(AppConstants.registrarMerma, data: body);
      return response.data?['ok'] == 'ok';
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
