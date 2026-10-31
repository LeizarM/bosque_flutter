import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/asiento_sap_model.dart';
import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
import 'package:bosque_flutter/domain/repositories/asiento_sap_repository.dart';
import 'package:dio/dio.dart';

class AsientoSapImpl extends BaseApiRepository implements AsientoSapRepository {
  /// El cuerpo de la respuesta, o una excepción con el mensaje del backend.
  ///
  /// 409 = SAP ya tiene un asiento con esa referencia; BaseApiRepository solo lee el 400.
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> data,
    String porDefecto,
  ) async {
    try {
      final r = await dio.post(endpoint, data: data);
      return r.data is Map<String, dynamic> ? r.data : <String, dynamic>{};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      if ((status == 400 || status == 409) &&
          body is Map &&
          body['message'] != null) {
        throw Exception(body['message']);
      }
      throw Exception(DioClient.handleDioError(e, porDefecto));
    }
  }

  static String _mensaje(Map<String, dynamic> body, String porDefecto) =>
      body['message']?.toString() ?? porDefecto;

  static List<Map<String, dynamic>> _lista(Map<String, dynamic> body) =>
      (body['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

  @override
  Future<List<AsientoSapEmpresaEntity>> empresas() async {
    final body = await _post(
      AppConstants.planillaAsientoSapEmpresas,
      {},
      'No se pudieron cargar las empresas',
    );
    return _lista(body)
        .map(
          (e) => AsientoSapEmpresaEntity(
            codEmpresa: e['codEmpresa'] ?? 0,
            empresa: e['empresa'] ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<AsientoSapEntity?> vistaPrevia({
    required int anio,
    required int mes,
    required int codEmpresa,
  }) async {
    final body = await _post(AppConstants.planillaAsientoSapVistaPrevia, {
      'anio': anio,
      'mes': mes,
      'codEmpresa': codEmpresa,
    }, 'No se pudo armar el asiento');
    final data = body['data'];
    return data is Map<String, dynamic>
        ? AsientoSapModel.fromJson(data).toEntity()
        : null;
  }

  @override
  Future<String> enviar({
    required int anio,
    required int mes,
    required int codEmpresa,
  }) async {
    final body = await _post(AppConstants.planillaAsientoSapEnviar, {
      'anio': anio,
      'mes': mes,
      'codEmpresa': codEmpresa,
    }, 'No se pudo enviar el asiento a SAP');
    return _mensaje(body, 'Asiento creado en SAP.');
  }

  @override
  Future<List<AsientoSapConfigEntity>> listarConfig() async {
    final body = await _post(
      AppConstants.asientoSapConfigListar,
      {},
      'No se pudo cargar la configuración',
    );
    return _lista(body).map(AsientoSapConfigModel.fromJson).toList();
  }

  @override
  Future<String> guardarConfig(AsientoSapConfigEntity c) async {
    final body = await _post(
      AppConstants.asientoSapConfigGuardar,
      AsientoSapConfigModel.toJson(c),
      'No se pudo guardar la configuración',
    );
    return _mensaje(body, 'Guardado.');
  }

  @override
  Future<String> guardarClave({
    required int codEmpresa,
    required String clave,
  }) async {
    final body = await _post(AppConstants.asientoSapConfigClave, {
      'codEmpresa': codEmpresa,
      'clave': clave,
    }, 'No se pudo guardar la contraseña');
    return _mensaje(body, 'Contraseña guardada.');
  }

  @override
  Future<String> eliminarConfig(int codEmpresa) async {
    final body = await _post(AppConstants.asientoSapConfigEliminar, {
      'codEmpresa': codEmpresa,
    }, 'No se pudo eliminar la configuración');
    return _mensaje(body, 'Configuración eliminada.');
  }

  @override
  Future<String> probar(int codEmpresa) async {
    final body = await _post(AppConstants.asientoSapConfigProbar, {
      'codEmpresa': codEmpresa,
    }, 'No se pudo probar la conexión');
    return _mensaje(body, 'Conexión correcta.');
  }
}
