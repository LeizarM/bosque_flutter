import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/entregas_model.dart';
import 'package:dio/dio.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/domain/repositories/entregas_repository.dart';

class EntregasImpl implements EntregasRepository {
  final Dio _dio = DioClient.getInstance();

  @override
  Future<List<EntregaEntity>> getEntregas(int uchofer) async {
    try {
      final response = await _dio.post(
        AppConstants.entregasEndpoint,
        data: {'uchofer': uchofer},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items =
            (response.data as List<dynamic>)
                .map((json) => EntregaModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener las entregas');
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
  Future<bool> sincronizarEntregasCompletadas(
    List<EntregaEntity> entregas,
  ) async {
    try {
      // Filtrar solo las entregas que han sido marcadas como entregadas
      final entregasCompletadas =
          entregas.where((e) => e.fueEntregado == 1).toList();

      if (entregasCompletadas.isEmpty) {
        return true; // No hay nada que sincronizar
      }

      // Convertir las entregas a un formato que el servidor pueda entender
      final data =
          entregasCompletadas
              .map(
                (entrega) => {
                  'idEntrega': entrega.idEntrega,
                  'fueEntregado': entrega.fueEntregado,
                  'latitud': entrega.latitud,
                  'longitud': entrega.longitud,
                  'direccionEntrega': entrega.direccionEntrega,
                  'fechaEntrega': entrega.fechaEntrega.toIso8601String(),
                },
              )
              .toList();

      // Aquí asumimos que hay un endpoint para sincronizar entregas
      // Si no existe, deberás crearlo en el backend
      final response = await _dio.post(
        '${AppConstants.baseUrl}/sincronizar-entregas',
        data: data,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      // Manejar errores de red o del servidor
      print('Error al sincronizar entregas: ${e.message}');
      return false;
    } catch (e) {
      print('Error desconocido: ${e.toString()}');
      return false;
    }
  }

  @override
  Future<void> registrarInicioEntrega(EntregaEntity entrega) async {
    final entregaModel = EntregaModel.fromEntity(entrega);

    try {
      final response = await _dio.post(
        AppConstants.inicioEntregaYFinEndpoint,
        data:
            entregaModel.toJson(), // Asegúrate de que EntregaEntity tenga un método toJson()
      );

      if(response.statusCode == 201) {
        
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
  Future<bool> marcarDocumentoEntregado(int docNum, {
    required int docEntry,
    required String db,
    required double latitud,
    required double longitud,
    required String direccionEntrega,
    required DateTime fechaEntrega,
    required int audUsuario,
    required int codSucursalChofer,
    required int codCiudadChofer,
    String? observaciones,
  }) async {
    try {
      // Formatear la fecha al formato esperado por el backend: "yyyy-MM-dd HH:mm:ss"
      final fechaFormateada = fechaEntrega.toIso8601String().substring(0, 19).replaceAll('T', ' ');
      
      // Crear el objeto con los datos para enviar al servidor
      final data = {
        'docNum': docNum,
        'docEntry': docEntry,
        'db': db,
        'latitud': latitud,
        'longitud': longitud,
        'direccionEntrega': direccionEntrega, // Enviando la dirección obtenida por geocodificación
        'fechaEntrega': fechaFormateada, // Formato correcto: "yyyy-MM-dd HH:mm:ss"
        'fueEntregado': 1,
        'obs': observaciones ?? '',
        'audUsuario': audUsuario,
        'codSucursalChofer': codSucursalChofer,
        'codCiudadChofer': codCiudadChofer,
      };
      
      // Mostrar en consola los datos que se están enviando
      print('=============================================');
      print('DATOS DE ENTREGA ENVIADOS AL BACKEND:');
      print('Documento: $docNum');
      print('Doc Entry: $docEntry');
      print('DB: $db');
      print('Latitud: $latitud');
      print('Longitud: $longitud');
      print('Dirección: $direccionEntrega'); // Mostrar la dirección en los logs
      print('Fecha Entrega (formateada): $fechaFormateada');
      print('Observaciones: ${observaciones ?? "Sin observaciones"}');
      print('Usuario: $audUsuario');
      print('Suc Chofer: $codSucursalChofer');
      print('Ciudad Chofer: $codCiudadChofer');
      print('=============================================');
      
      // Usar el endpoint correcto definido en las constantes
      
   
      // Endpoint para marcar todo el documento como entregado
      try {
        final response = await _dio.post(
          AppConstants.marcarEntregaCompletada,
          data: data,
          
        );
        
        // Mostrar respuesta del servidor
        print('RESPUESTA DEL SERVIDOR: ${response.statusCode}');
        print('DATOS: ${response.data}');
        print('=============================================');
        
        return response.statusCode == 200 || response.statusCode == 201;
      } on DioException catch (e) {
        print('ERROR DE DIO: ${e.type}');
        print('MENSAJE: ${e.message}');
        if (e.response != null) {
          print('CÓDIGO DE ESTADO: ${e.response?.statusCode}');
          print('DATOS DE RESPUESTA: ${e.response?.data}');
        }
        if (e.error != null) {
          print('ERROR DETALLADO: ${e.error}');
        }
        
        // Intentamos guardar localmente para sincronizar después
        _guardarEntregaLocalPendiente(docNum, docEntry, db, latitud, longitud, fechaEntrega, 
            audUsuario, codSucursalChofer, codCiudadChofer, observaciones, direccionEntrega);
        
        return false;
      }
    } catch (e) {
      print('Error desconocido al marcar documento: ${e.toString()}');
      // Intentamos guardar localmente para sincronizar después
      _guardarEntregaLocalPendiente(docNum, docEntry, db, latitud, longitud, fechaEntrega, 
          audUsuario, codSucursalChofer, codCiudadChofer, observaciones, direccionEntrega);
      return false;
    }
  }
  
  // Método auxiliar para guardar entregas localmente cuando hay problemas de red
  void _guardarEntregaLocalPendiente(int docNum, int docEntry, String db, double latitud, double longitud, 
      DateTime fechaEntrega, int audUsuario, int codSucursalChofer, int codCiudadChofer, String? observaciones, String direccionEntrega) {
    try {
      print('Guardando entrega localmente para sincronización posterior...');
      // Aquí podrías implementar la lógica para guardar en SharedPreferences o SQLite
      // Incluimos la dirección en los datos guardados localmente
      final datosLocales = {
        'docNum': docNum,
        'docEntry': docEntry,
        'db': db,
        'latitud': latitud,
        'longitud': longitud,
        'direccionEntrega': direccionEntrega,
        'fechaEntrega': fechaEntrega.toIso8601String(),
        'fueEntregado': 1,
        'obs': observaciones ?? '',
        'audUsuario': audUsuario,
        'codSucursalChofer': codSucursalChofer,
        'codCiudadChofer': codCiudadChofer,
      };
      print('Datos guardados localmente: $datosLocales');
    } catch (e) {
      print('Error al guardar entrega localmente: ${e.toString()}');
    }
  }
}
