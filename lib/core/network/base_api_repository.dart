import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:dio/dio.dart';

abstract class BaseApiRepository {
  // Todas las clases que hereden de esta usarán la misma instancia Singleton
  final Dio dio = DioClient.getInstance();

  /// Genérico para peticiones POST que retornan un ID (BigInt)
  Future<BigInt> postAndReturnId({
    required String endpoint,
    required Map<String, dynamic> data,
    String errorMessage = 'Error en la operación',
  }) async {
    try {
      final response = await dio.post(endpoint, data: data);
      if (response.data != null) {
        final id = response.data['data'];
        return id != null ? BigInt.from(id) : BigInt.zero;
      }
      throw Exception(errorMessage);
    } on DioException catch (e) {
      throw Exception(DioClient.handleDioError(e, errorMessage));
    } catch (e) {
      rethrow;
    }
  }

  /// Genérico para peticiones POST que devuelven una Lista de Entidades
  Future<List<T>> postAndReturnList<T>({
    required String endpoint,
    Map<String, dynamic> data = const {},
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await dio.post(endpoint, data: data);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'] ?? [];
        return (rawData as List<dynamic>)
            .map((json) => fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      // Puedes decidir si lanzar el error o retornar lista vacía según tu negocio
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Genérico para peticiones POST que devuelven un solo Objeto
  Future<T?> postAndReturnObject<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String errorMessage = 'Error al obtener el registro',
  }) async {
    try {
      final response = await dio.post(endpoint, data: data);
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'];
        if (responseData != null) {
          return fromJson(responseData);
        }
      }
      return null;
    } on DioException catch (e) {
      throw Exception(DioClient.handleDioError(e, errorMessage));
    } catch (e) {
      rethrow;
    }
  }
}
