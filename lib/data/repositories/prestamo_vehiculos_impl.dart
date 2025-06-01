import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/estado_chofer_model.dart';
import 'package:bosque_flutter/data/models/prestamo_chofer_model.dart';
import 'package:bosque_flutter/data/models/tipo_solicitud_model.dart';
import 'package:dio/dio.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/solicitud_chofer_model.dart';
import 'package:bosque_flutter/domain/entities/estado_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_solicitud_entity.dart';
import 'package:bosque_flutter/domain/repositories/prestamo_vehiculos_repository.dart';

class PrestamoVehiculosImpl implements PrestamoVehiculosRepository {
  
  
   final Dio _dio = DioClient.getInstance();
  
  @override
  Future<bool> actualizarSolicitud( SolicitudChoferEntity mb ) async {
   
    final model = SolicitudChoferModel.fromEntity(mb);

  
    try {
      final response = await _dio.post(
        AppConstants.preRegister,
        data: model.toJson(),
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
        throw Exception('Error desconocido actualizarSolicitud: ${e.toString()}');
      }
    }

  

  @override
  Future<List<EstadoChoferEntity>> lstEstados() async {
    try {
      final response = await _dio.post(AppConstants.preEstados, data: {});

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => EstadoChoferModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los estados de solicitudes');
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
      throw Exception('Error desconocido lstEstados: ${e.toString()}');
    }
  }

  @override
  Future<List<PrestamoChoferEntity>> lstSolicitudesPretamos(int codSucursal, int codEmpEntregadoPor) async {
    
    final data = {
      'codSucursal': codSucursal,
      'codEmpEntregadoPor': codEmpEntregadoPor,
    };
    
    try {
      final response = await _dio.post(AppConstants.preListarSolicitudesPrestamos, data: data);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => PrestamoChoferModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener la solicitudes para prestamos');
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
      throw Exception('Error desconocido lstSolicitudesPretamos: ${e.toString()}');
    }

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
        'codEmpSoli': codEmpleado,
      });

      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => SolicitudChoferModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener la solicitud de coches');
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
      throw Exception('Error desconocido obtainSolicitudes: ${e.toString()}');
    }

  }

  @override
  Future<bool> registerPrestamo(PrestamoChoferEntity mb) async {
    final model = PrestamoChoferModel.fromEntity(mb);

    try {
      // Crear JSON sin la fecha de entrega para que el backend la calcule
      final Map<String, dynamic> requestData = model.toJson();
      requestData.remove('fechaEntrega'); // Remover para que el backend la calcule

      final response = await _dio.post(
        AppConstants.preRegistrarPrestamo,
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
        throw Exception('Error desconocido registerPrestamo: ${e.toString()}');
      }
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
      throw Exception('Error desconocido registerSolicitudChofer: ${e.toString()}');
    }
  }
}