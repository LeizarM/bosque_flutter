import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:dio/dio.dart';

abstract class BaseApiRepository {
  // Todas las clases que hereden de esta usarán la misma instancia Singleton
  final Dio dio = DioClient.getInstance();

  /// Genérico para peticiones POST que retornan un ID (BigInt).
  /// Maneja 200 y 201 (retorna data), 204 (retorna BigInt.zero).
  /// Para 400, extrae response.data.message como excepción.
  Future<BigInt> postAndReturnId({
    required String endpoint,
    required Map<String, dynamic> data,
    String errorMessage = 'Error en la operación',
  }) async {
    try {
      final response = await dio.post(endpoint, data: data);
      final status = response.statusCode ?? 0;

      // 204: sin contenido → operación exitosa sin ID retornado
      if (status == 204 || response.data == null) return BigInt.zero;

      // 200 / 201: extraer ID del body
      if (status == 200 || status == 201) {
        final id = response.data is Map ? response.data['data'] : null;
        return id != null ? BigInt.from(id) : BigInt.zero;
      }

      throw Exception(errorMessage);
    } on DioException catch (e) {
      // 400: extraer mensaje legible del backend
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        throw Exception(e.response!.data['message'] ?? errorMessage);
      }
      throw Exception(DioClient.handleDioError(e, errorMessage));
    } catch (e) {
      rethrow;
    }
  }

  /// Genérico para peticiones POST que devuelven una Lista de Entidades.
  /// 204 o data == null → devuelve lista vacía (estado vacío, NO error).
  Future<List<T>> postAndReturnList<T>({
    required String endpoint,
    Map<String, dynamic> data = const {},
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await dio.post(endpoint, data: data);
      final status = response.statusCode ?? 0;

      // 204: sin contenido → lista vacía
      if (status == 204 || response.data == null) return [];

      if (status == 200 || status == 201) {
        final raw = response.data;
        final List<dynamic> rawData =
            raw is List ? raw : ((raw as Map)['data'] as List<dynamic>? ?? []);
        return rawData
            .map((json) => fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        throw Exception(
          e.response!.data['message'] ?? 'Error al obtener datos',
        );
      }
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  /// Genérico para peticiones POST que devuelven un solo Objeto.
  /// 204 o data == null → devuelve null (sin error).
  Future<T?> postAndReturnObject<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String errorMessage = 'Error al obtener el registro',
  }) async {
    try {
      final response = await dio.post(endpoint, data: data);
      final status = response.statusCode ?? 0;

      // 204: sin contenido
      if (status == 204 || response.data == null) return null;

      if (status == 200 || status == 201) {
        final responseData = response.data['data'];
        if (responseData != null) {
          return fromJson(responseData);
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        throw Exception(e.response!.data['message'] ?? errorMessage);
      }
      throw Exception(DioClient.handleDioError(e, errorMessage));
    } catch (e) {
      rethrow;
    }
  }
}
