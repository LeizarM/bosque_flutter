import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/tipo_solicitud_model.dart';
import 'package:dio/dio.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/solicitud_chofer_model.dart';
import 'package:bosque_flutter/domain/entities/estado_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_solicitud_entity.dart';
import 'package:bosque_flutter/domain/repositories/prestamo_vehiculos_repository.dart';
import 'package:logger/web.dart';

class PrestamoVehiculosImpl implements PrestamoVehiculosRepository {
  
  
   final Dio _dio = DioClient.getInstance();
  
  @override
  Future<bool> actualizarSolicitud( SolicitudChoferEntity mb ) {
    // TODO: implement actualizarSolicitud
    throw UnimplementedError();
  }

  @override
  Future<List<EstadoChoferEntity>> lstEstados() {
    // TODO: implement lstEstados
    throw UnimplementedError();
  }

  @override
  Future<List<PrestamoChoferEntity>> lstSolicitudesPretamos(int codSucursal, int codEmpEntregadoPor) {
    // TODO: implement lstSolicitudesPretamos
    throw UnimplementedError();
  }

  @override
  Future<List<TipoSolicitudEntity>> lstTipoSolicitudes() async {
    
    try {
      final response = await _dio.post(AppConstants.preTipoSolicitudes, data: {});

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => TipoSolicitudModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los tipos de solicitudes');
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
      throw Exception('Error desconocido lstTipoSolicitudes: ${e.toString()}');
    }



  }

  @override
  Future<List<SolicitudChoferEntity>> obtainCoches() async {
   

    try {
      final response = await _dio.post(AppConstants.preCoches, data: {});

      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => SolicitudChoferModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los coches para la solicitud');
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
      throw Exception('Error desconocido obtainCoches: ${e.toString()}');
    }



  }

  @override
  Future<List<SolicitudChoferEntity>> obtainSolicitudes( int codEmpleado ) async {
    
     try {
      final response = await _dio.post(AppConstants.preSolicitudesXEmp
      ,data: {
        
      });

      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => SolicitudChoferModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los coches para la solicitud');
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
      throw Exception('Error desconocido obtainCoches: ${e.toString()}');
    }


  }

  @override
  Future<bool> registerPrestamo(PrestamoChoferEntity mb) {
    // TODO: implement registerPrestamo
    throw UnimplementedError();
  }

  @override
  Future<bool> registerSolicitudChofer(SolicitudChoferEntity mb) async {
  final model = SolicitudChoferModel.fromEntity(mb);
  
  // Create a modified JSON without the fechaSolicitud field
  final Map<String, dynamic> requestData = model.toJson();
  requestData.remove('fechaSolicitud'); // Remove the field so backend calculates it
  requestData.remove('fechaSolicitudCad'); // Remove formatted date string too
  
  try {
    final response = await _dio.post(
      AppConstants.preRegister,
      data: requestData,
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
      throw Exception('Error desconocido guardarNotaRemision: ${e.toString()}');
    }
  }
  
}