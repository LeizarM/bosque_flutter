import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/sap_conexion_model.dart';
import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';
import 'package:bosque_flutter/domain/repositories/sap_conexion_repository.dart';
import 'package:dio/dio.dart';

class SapConexionImpl extends BaseApiRepository implements SapConexionRepository {
  /// El cuerpo de la respuesta, o una excepción con el mensaje del backend (400 y 409, que
  /// BaseApiRepository no lee).
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
      if ((status == 400 || status == 409) && body is Map && body['message'] != null) {
        throw Exception(body['message']);
      }
      throw Exception(DioClient.handleDioError(e, porDefecto));
    }
  }

  static String _mensaje(Map<String, dynamic> body, String porDefecto) =>
      body['message']?.toString() ?? porDefecto;

  @override
  Future<List<SapConexionEntity>> listar() async {
    final body = await _post(
      AppConstants.sapConexionesListar,
      {},
      'No se pudieron cargar las conexiones',
    );
    return (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(SapConexionModel.fromJson)
        .toList();
  }

  @override
  Future<String> guardar(SapConexionEntity c) async {
    final body = await _post(
      AppConstants.sapConexionesGuardar,
      SapConexionModel.toJson(c),
      'No se pudo guardar la conexión',
    );
    return _mensaje(body, 'Conexión guardada.');
  }

  @override
  Future<String> guardarClave({required int idConexion, required String clave}) async {
    final body = await _post(AppConstants.sapConexionesClave, {
      'idConexion': idConexion,
      'clave': clave,
    }, 'No se pudo guardar la contraseña');
    return _mensaje(body, 'Contraseña guardada.');
  }

  @override
  Future<String> eliminar(int idConexion) async {
    final body = await _post(AppConstants.sapConexionesEliminar, {
      'idConexion': idConexion,
    }, 'No se pudo quitar la conexión');
    return _mensaje(body, 'Conexión eliminada.');
  }

  @override
  Future<String> probar(int idConexion) async {
    final body = await _post(AppConstants.sapConexionesProbar, {
      'idConexion': idConexion,
    }, 'No se pudo probar la conexión');
    return _mensaje(body, 'Conexión correcta.');
  }
}
