import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/control_combustible_model.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_entity.dart';
import 'package:bosque_flutter/domain/repositories/control_combustible_repository.dart';

class ControlCombustibleImpl implements ControlCombustibleRepository {
  
  final Dio _dio = DioClient.getInstance();

  // Implementación de los métodos de la interfaz

  //Para el registro del combestible
  @override
  Future<bool> createControlCombustible(CombustibleControlEntity data) async {
    final combustibleModel = CombustibleControlModel.fromEntity(data);

    try {
      final response = await _dio.post(
        AppConstants.registrarCombustibleEndPoint,
        data:
            combustibleModel
                .toJson(), // Asegúrate de que EntregaEntity tenga un método toJson()
      );

      return response.statusCode == 200 || response.statusCode == 201;
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

  // Para obtener los coches registrados
  @override
  Future<List<CombustibleControlEntity>> getCoches() async {
    try {
      final response = await _dio.post(AppConstants.listarCoches, data: {});

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        
        final items = (data as List<dynamic>)
            .map((json) => CombustibleControlModel.fromJson(json))
            .toList();
        
        final entities = items.map((model) => model.toEntity()).toList();
        
        return entities;
      } else {
        throw Exception('Error al obtener los coches');
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
  
  @override
  Future<List<CombustibleControlEntity>> getCombustiblesPorCoche( int idCoche ) async {
    
    try {
      final response = await _dio.post(AppConstants.listarKilometrajeCoches, data: {
        'idCoche': idCoche,
      });

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items = (data as List<dynamic>)
            .map((json) => CombustibleControlModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener el kilometraje del coche');
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
  
  @override
  Future<List<CombustibleControlEntity>> listConsumo( double kilometraje, int idCoche ) async {
    try {
      final response = await _dio.post(AppConstants.listarObtenerConsumo, data: {
        'kilometraje': kilometraje,
        'idCoche': idCoche,
      });

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items = (data as List<dynamic>)
            .map((json) => CombustibleControlModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener el recorrido siguiente del coche');
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
