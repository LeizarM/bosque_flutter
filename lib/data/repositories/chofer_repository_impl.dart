import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/chofer_model.dart';
import 'package:bosque_flutter/domain/entities/chofer_entity.dart';
import 'package:bosque_flutter/domain/repositories/chofer_repository.dart';

class ChoferRepositoryImpl implements ChoferRepository {
  final Dio _dio = DioClient.getInstance();

  @override
  Future<List<ChoferEntity>> getChoferes() async {
    try {
      final response = await _dio.post(
        AppConstants.choferesEndPoint,
        data: {}
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = (response.data as List<dynamic>)
            .map((json) => ChoferModel.fromJson(json))
            .toList();
            
        // Convertir de EntregaModel a ChoferEntity y filtrar duplicados por codEmpleado
        final choferes = items
            .map((model) => ChoferEntity.fromEntregaEntity(model))
            .toSet().toList();
            
        // Ordenar alfabéticamente por nombre
        choferes.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
        
        return choferes;
      } else {
        throw Exception('Error al obtener la lista de choferes');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage = 'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      debugPrint(errorMessage);
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Error desconocido: ${e.toString()}');
      throw Exception('Error desconocido: ${e.toString()}');
    }
  }
  
  @override
  Future<ChoferEntity?> getChoferById(int codEmpleado) async {
    try {
      // Obtenemos todos los choferes y filtramos por ID
      final choferes = await getChoferes();
      return choferes.firstWhere(
        (chofer) => chofer.codEmpleado == codEmpleado,
        orElse: () => throw Exception('No se encontró el chofer con código $codEmpleado'),
      );
    } catch (e) {
      debugPrint('❌ Error al buscar chofer por ID: ${e.toString()}');
      return null;
    }
  }
}