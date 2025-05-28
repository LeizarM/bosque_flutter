import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/control_combustible_maquina_montacarga_model.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:bosque_flutter/domain/repositories/control_combustible_maquina_montacarga_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ControlCombustibleMaquinaMontacargaImpl
    implements ControlCombustibleMaquinaMontacargaRepository {
  final Dio _dio = DioClient.getInstance();

  // Implementación de los métodos de la interfaz

  @override
  Future<bool> registerControlCombustibleMaquinaMontacarga( ControlCombustibleMaquinaMontacargaEntity mb ) async {
    try {
      // Crear el mapa de datos como lo estás enviando actualmente
      final data = ControlCombustibleMaquinaMontacargaModel.fromEntity( mb );

      final response = await _dio.post(
        AppConstants.registrarControlCombustibleMaqMont,
        data: data.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('ERROR: ${e.type}');
      debugPrint('URL: ${e.requestOptions.uri}');
      debugPrint('Método: ${e.requestOptions.method}');

      if (e.response != null) {
        debugPrint('Código de estado: ${e.response!.statusCode}');
        debugPrint('Respuesta del servidor: ${e.response!.data}');
      }

      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Error desconocido: $e');
      throw Exception('Error desconocido: ${e.toString()}');
    }
  }

  @override
  Future<List<ControlCombustibleMaquinaMontacargaEntity>>
  obtenerAlmacenes() async {
    try {
      final response = await _dio.post(AppConstants.listarAlmacenes, data: {});

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];

        // Crear manualmente las entidades para manejar la estructura específica de los almacenes
        final List<ControlCombustibleMaquinaMontacargaEntity> almacenes = [];

        return almacenes;
      } else {
        throw Exception('Error al obtener los almacenes');
      }
    } on DioException catch (e) {
      // Manejar errores de red o del servidor
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido: ${e.toString()}');
    }
  }


  
}
