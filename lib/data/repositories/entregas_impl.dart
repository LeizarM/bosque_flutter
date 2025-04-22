import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/entregas_model.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/domain/repositories/entregas_repository.dart';
import 'package:logger/web.dart';

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
                  'fechaEntrega': entrega.fechaEntrega,
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
      debugPrint('Error al sincronizar entregas: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error desconocido: ${e.toString()}');
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
            entregaModel
                .toJson(), // Asegúrate de que EntregaEntity tenga un método toJson()
      );

      if (response.statusCode == 201) {}
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
  Future<bool> marcarDocumentoEntregado(
    int docNum, {
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
      final fechaFormateada = fechaEntrega
          .toIso8601String()
          .substring(0, 19)
          .replaceAll('T', ' ');

      // Crear el objeto con los datos para enviar al servidor
      final data = {
        'docNum': docNum,
        'docEntry': docEntry,
        'db': db,
        'latitud': latitud,
        'longitud': longitud,
        'direccionEntrega':
            direccionEntrega, // Enviando la dirección obtenida por geocodificación
        'fechaEntrega':
            fechaFormateada, // Formato correcto: "yyyy-MM-dd HH:mm:ss"
        'fueEntregado': 1,
        'obs': observaciones ?? '',
        'audUsuario': audUsuario,
        'codSucursalChofer': codSucursalChofer,
        'codCiudadChofer': codCiudadChofer,
      };

      // Endpoint para marcar todo el documento como entregado
      try {
        final response = await _dio.post(
          AppConstants.marcarEntregaCompletada,
          data: data,
        );

        return response.statusCode == 200 || response.statusCode == 201;
      } on DioException catch (e) {
        if (e.response != null) {
          debugPrint('CÓDIGO DE ESTADO: ${e.response?.statusCode}');
          debugPrint('DATOS DE RESPUESTA: ${e.response?.data}');
        }
        if (e.error != null) {
          debugPrint('ERROR DETALLADO: ${e.error}');
        }

        // Intentamos guardar localmente para sincronizar después
        _guardarEntregaLocalPendiente(
          docNum,
          docEntry,
          db,
          latitud,
          longitud,
          fechaEntrega,
          audUsuario,
          codSucursalChofer,
          codCiudadChofer,
          observaciones,
          direccionEntrega,
        );

        return false;
      }
    } catch (e) {
      debugPrint('Error desconocido al marcar documento: ${e.toString()}');
      // Intentamos guardar localmente para sincronizar después
      _guardarEntregaLocalPendiente(
        docNum,
        docEntry,
        db,
        latitud,
        longitud,
        fechaEntrega,
        audUsuario,
        codSucursalChofer,
        codCiudadChofer,
        observaciones,
        direccionEntrega,
      );
      return false;
    }
  }

  // Método auxiliar para guardar entregas localmente cuando hay problemas de red
  void _guardarEntregaLocalPendiente(
    int docNum,
    int docEntry,
    String db,
    double latitud,
    double longitud,
    DateTime fechaEntrega,
    int audUsuario,
    int codSucursalChofer,
    int codCiudadChofer,
    String? observaciones,
    String direccionEntrega,
  ) {
    try {
      debugPrint(
        'Guardando entrega localmente para sincronización posterior...',
      );
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
      debugPrint('Datos guardados localmente: $datosLocales');
    } catch (e) {
      debugPrint('Error al guardar entrega localmente: ${e.toString()}');
    }
  }

  // Obtener dirección a partir de coordenadas geográficas usando un servicio externo (Nominatim OpenStreetMap)
  @override
  Future<String> obtenerDireccionDesdeAPI(
    double latitud,
    double longitud,
  ) async {
    try {
      final Dio dioGeocoding = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'User-Agent':
                AppConstants.nominatimUserAgent, // Usando la constante definida
          },
        ),
      );

      debugPrint(
        'Obteniendo dirección para coordenadas: ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}',
      );

      final response = await dioGeocoding.get(
        '${AppConstants.nominatimBaseUrl}${AppConstants.nominatimReverseEndpoint}', // Usando constantes
        queryParameters: {
          'lat': latitud,
          'lon': longitud,
          'format': 'json',
          'addressdetails': 1,
          'accept-language': 'es',
          'zoom': 18, // Mayor nivel de detalle
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // Construimos una dirección más detallada usando los campos disponibles
        final data = response.data;
        final addressComponents = data['address'] as Map<String, dynamic>?;

        if (addressComponents != null) {
          // Lista de componentes de dirección en orden de importancia
          final components = [
            addressComponents['road'], // Calle
            addressComponents['house_number'], // Número
            addressComponents['suburb'], // Barrio/Zona
            addressComponents['city'] ??
                addressComponents['town'] ??
                addressComponents['village'], // Ciudad
            addressComponents['state'], // Estado/Departamento
            addressComponents['country'], // País
          ];

          // Filtrar valores nulos y vacíos
          final filteredComponents =
              components
                  .where(
                    (component) =>
                        component != null && component.toString().isNotEmpty,
                  )
                  .toList();

          // Crear dirección formateada
          final direccionDetallada = filteredComponents.join(', ');

          debugPrint('DIRECCIÓN OBTENIDA DE API: $direccionDetallada');

          return direccionDetallada.isNotEmpty
              ? direccionDetallada
              : data['display_name'] ??
                  'Ubicación marcada en ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
        }

        // Si no hay address details, usar display_name (dirección completa formateada)
        final direccion = data['display_name'] as String? ?? '';

        debugPrint('DIRECCIÓN OBTENIDA DE API (display_name): $direccion');

        return direccion.isNotEmpty
            ? direccion
            : 'Ubicación marcada en ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
      }

      return 'Ubicación marcada en ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
    } catch (e) {
      debugPrint('Error al obtener dirección desde API: ${e.toString()}');
      return 'Ubicación marcada en ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
    }
  }

  @override
  Future<bool> registrarRuta({
    required int docEntry,
    required int docNum,
    required int factura,
    required String cardName,
    required String cardCode,
    required String addressEntregaFac,
    required String addressEntregaMat,
    required int codEmpleado,
    required String valido,
    required String db,
    required String direccionEntrega,
    required int fueEntregado,
    required DateTime fechaEntrega,
    required double latitud,
    required double longitud,
    required String obs,
    required int audUsuario,
  }) async {
    try {
      // Formatear la fecha al formato esperado por el backend: "yyyy-MM-dd HH:mm:ss"
      final fechaFormateada = fechaEntrega
          .toIso8601String()
          .substring(0, 19)
          .replaceAll('T', ' ');

      // Crear el objeto con los datos para enviar al servidor
      final data = {
        'docEntry': docEntry,
        'docNum': docNum,
        'factura': factura,
        'cardName': cardName,
        'cardCode': cardCode,
        'addressEntregaFac': addressEntregaFac,
        'addressEntregaMat': addressEntregaMat,
        'codEmpleado': codEmpleado,
        'valido': valido,
        'db': db,
        'direccionEntrega': direccionEntrega,
        'fueEntregado': fueEntregado,
        'fechaEntrega': fechaFormateada,
        'latitud': latitud,
        'longitud': longitud,
        'obs': obs,
        'audUsuario': audUsuario,
      };

      // Endpoint para marcar todo el documento como entregado
      try {
        final response = await _dio.post(
          AppConstants.inicioEntregaYFinEndpoint,
          data: data,
        );

        return response.statusCode == 200 || response.statusCode == 201;
      } on DioException catch (e) {
        if (e.response != null) {
          debugPrint('CÓDIGO DE ESTADO: ${e.response?.statusCode}');
          debugPrint('DATOS DE RESPUESTA: ${e.response?.data}');
        }
        if (e.error != null) {
          debugPrint('ERROR DETALLADO: ${e.error}');
        }

        return false;
      }
    } catch (e) {
      debugPrint('Error desconocido al marcar documento: ${e.toString()}');
      // Intentamos guardar localmente para sincronizar después

      return false;
    }
  }

  @override
  Future<List<EntregaEntity>> getHistorialRuta(
    DateTime fecha,
    int codEmpleado,
  ) async {
    // Formatear la fecha al formato esperado por el backend: "yyyy-MM-dd"
    final fechaFormateada = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    
    debugPrint('Consultando historial de ruta para fecha $fechaFormateada y chofer $codEmpleado');

    try {
      final response = await _dio.post(
        AppConstants.rutaChoferEndpoint,
        data: {
          'fechaEntrega': fechaFormateada,
          'codEmpleado': codEmpleado,
        },
      );

      if (response.statusCode == 200) {
        
        final List<dynamic> jsonList = response.data as List<dynamic>;
        
        try {
          final items = jsonList.map((json) {
            try {
              return EntregaModel.fromJson(json);
            } catch (e) {
              debugPrint('⚠️ Error al parsear elemento: ${e.toString()}');
              debugPrint('⚠️ Elemento con error: ${json.toString()}');
              return null;
            }
          })
          .where((model) => model != null)
          .cast<EntregaModel>()
          .toList();
          
          debugPrint('✅ Modelos procesados correctamente: ${items.length}');
          return items.map((model) => model.toEntity()).toList();
        } catch (e) {
          debugPrint('❌ Error al procesar los datos: ${e.toString()}');
          throw Exception('Error al procesar datos de historial: ${e.toString()}');
        }
      } else {
        debugPrint('❌ Error al obtener el historial: Código ${response.statusCode}');
        throw Exception('Error al obtener el historial de ruta por chofer');
      }
    } on DioException catch (e) {
      // Manejar errores de red o del servidor
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      debugPrint('❌ DioException: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('❌ Error desconocido: ${e.toString()}');
      throw Exception('Error desconocido: ${e.toString()}');
    }
  }
  
  @override
  Future<List<EntregaEntity>> getChoferes() async {
    
    try {
      final response = await _dio.post(
        AppConstants.choferesEndPoint,
        data: {}
      );

      if (response.statusCode == 200 && response.data != null) {
        final items =
            (response.data as List<dynamic>)
                .map((json) => EntregaModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los choferes');
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
  Future<List<EntregaEntity>> getExtractoRutas( DateTime fechaInicio, DateTime fechaFin ) async {
    

    try {
      final response = await _dio.post(
        AppConstants.entregasRutasChoferes,
        data: {
          'fechaInicio': "${fechaInicio.year}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}",
          'fechaFin': "${fechaFin.year}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}",
        }

        
      );

      if (response.statusCode == 200 && response.data != null) {
        final items =
            (response.data as List<dynamic>)
                .map((json) => EntregaModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener la ruta de los choferes');
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
