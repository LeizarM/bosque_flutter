import 'package:dio/dio.dart';

import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';

/// Base de los repositorios de exámenes (empleado y postulante). Suma
/// [postDato] para los `data` sin forma fija (`estado` como objeto o lista,
/// `responder` como id o estado), con los que fallan los helpers de la base.
abstract class TcpeApiBase extends BaseApiRepository {
  /// Igual que el de la base, pero un error que no es 400 (el 403 de
  /// `TcpePermisos` con su motivo, un 401, un 500) llega a la pantalla con el
  /// `message` del backend y no como el texto crudo de un `DioException`.
  @override
  Future<List<T>> postAndReturnList<T>({
    required String endpoint,
    Map<String, dynamic> data = const {},
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      return await super.postAndReturnList<T>(
        endpoint: endpoint,
        data: data,
        fromJson: fromJson,
      );
    } on DioException catch (e) {
      throw Exception(DioClient.handleDioError(e, 'No se pudieron obtener los datos.'));
    }
  }

  /// POST que devuelve el `data` del sobre tal cual (número, objeto, lista o
  /// null). 204 es éxito sin datos; 400 lanza el `message` del backend.
  Future<Object?> postDato(
    String endpoint,
    Map<String, dynamic> data, {
    String errorMessage = 'No se pudo completar la operación.',
  }) async {
    try {
      final r = await dio.post<Object?>(endpoint, data: data);
      final cuerpo = r.data;
      if (r.statusCode == 204 || cuerpo == null || cuerpo == '') return null;
      return cuerpo is Map ? cuerpo['data'] : cuerpo;
    } on DioException catch (e) {
      final cuerpo = e.response?.data;
      if (e.response?.statusCode == 400 && cuerpo is Map) {
        throw Exception(cuerpo['message'] ?? errorMessage);
      }
      throw Exception(DioClient.handleDioError(e, errorMessage));
    }
  }

  /// POST de escritura que devuelve el `message` del sobre: en el módulo es el
  /// `errormsg` del SP ("Nota guardada.", "Calificacion cerrada: 3 de 5...").
  /// 204 o sin cuerpo: null. Los errores, como en [postDato].
  Future<String?> postMensaje(
    String endpoint,
    Map<String, dynamic> data, {
    String errorMessage = 'No se pudo completar la operación.',
  }) async {
    try {
      final r = await dio.post<Object?>(endpoint, data: data);
      final cuerpo = r.data;
      final m = cuerpo is Map ? '${cuerpo['message'] ?? ''}'.trim() : '';
      return r.statusCode == 204 || m.isEmpty ? null : m;
    } on DioException catch (e) {
      final cuerpo = e.response?.data;
      if (e.response?.statusCode == 400 && cuerpo is Map) {
        throw Exception(cuerpo['message'] ?? errorMessage);
      }
      throw Exception(DioClient.handleDioError(e, errorMessage));
    }
  }

  /// La primera fila de un `data` que puede ser objeto o lista.
  static Map<String, dynamic>? primeraFila(Object? dato) {
    if (dato is Map) return Map<String, dynamic>.from(dato);
    if (dato is List && dato.isNotEmpty && dato.first is Map) {
      return Map<String, dynamic>.from(dato.first as Map);
    }
    return null;
  }

  /// Quita los null y pasa los BigInt a int: el body que espera el backend.
  static Map<String, dynamic> cuerpo(Map<String, Object?> datos) => {
    for (final e in datos.entries)
      if (e.value != null) e.key: e.value is BigInt ? (e.value as BigInt).toInt() : e.value,
  };
}
