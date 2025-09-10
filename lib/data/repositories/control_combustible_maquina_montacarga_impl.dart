import 'package:bosque_flutter/data/models/compra_garrafa_model.dart';
import 'package:bosque_flutter/data/models/contenedor_model.dart';
import 'package:bosque_flutter/data/models/movimiento_model.dart';
import 'package:bosque_flutter/data/models/sucursal_model.dart';
import 'package:bosque_flutter/data/models/tipo_contenedor_model.dart';
import 'package:bosque_flutter/domain/entities/compra_garrafa_entity.dart';
import 'package:bosque_flutter/domain/entities/contenedor_entity.dart';
import 'package:bosque_flutter/domain/entities/movimiento_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_contenedor_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/control_combustible_maquina_montacarga_model.dart';
import 'package:bosque_flutter/data/models/maquina_montacarga_model.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_montacarga_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/repositories/control_combustible_maquina_montacarga_repository.dart';

class ControlCombustibleMaquinaMontacargaImpl
    implements ControlCombustibleMaquinaMontacargaRepository {
  final Dio _dio = DioClient.getInstance();

  // Implementación de los métodos de la interfaz

  @override
  Future<bool> registerControlCombustibleMaquinaMontacarga(
    ControlCombustibleMaquinaMontacargaEntity mb,
  ) async {
    try {
      // Create the data map to send to the backend
      final data = ControlCombustibleMaquinaMontacargaModel.fromEntity(mb);
      final jsonData = data.toJson();

      final response = await _dio.post(
        AppConstants.registrarControlCombustibleMaqMont,
        data: jsonData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response indicates success - accept both 200 and 201
        if (response.data != null &&
            (response.data['status'] == 200 ||
                response.data['status'] == 201)) {
          return true;
        }
      }

      return false;
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        // Try to extract error message from response
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          errorMessage = 'Error del servidor: ${e.response!.data['message']}';
        } else {
          errorMessage =
              'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
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

        final items =
            (data as List<dynamic>)
                .map(
                  (json) =>
                      ControlCombustibleMaquinaMontacargaModel.fromJson(json),
                )
                .toList();

        return items.map((model) => model.toEntity()).toList();
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
      throw Exception('Error desconocido obtenerAlmacenes: ${e.toString()}');
    }
  }

  @override
  Future<List<MaquinaMontacargaEntity>> obtenerMaquinasMontacargas() async {
    try {
      final response = await _dio.post(
        AppConstants.listarMaquinaMontacarga,
        data: {},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>)
                .map((json) => MaquinaMontacargaModel.fromJson(json))
                .toList();

        final entities = items.map((model) => model.toEntity()).toList();

        return entities;
      } else {
        throw Exception(
          'Error al obtener los los montacargas, bidones o maquinas',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Error desconocido en obtenerMaquinasMontacargas: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ControlCombustibleMaquinaMontacargaEntity>>
  lstRptMovBidonesXTipoTransaccion(
    DateTime fechaInicio,
    DateTime fechaFin,
    int codSucursal,
  ) async {
    final data = {
      'fechaInicio': DateFormat('yyyy-MM-dd').format(fechaInicio),
      'fechaFin': DateFormat('yyyy-MM-dd').format(fechaFin),
      'codSucursalMaqVehiDestino': codSucursal,
    };

    debugPrint('Data para lstRptMovBidonesXTipoTransaccion: $data');
    try {
      final response = await _dio.post(AppConstants.listarBidones, data: data);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        debugPrint('Raw data from API: $data'); // Debug

        final items =
            (data as List<dynamic>).map((json) {
              debugPrint('Processing item: $json'); // Debug
              return ControlCombustibleMaquinaMontacargaModel.fromJson(json);
            }).toList();

        final entities =
            items.map((model) {
              final entity = model.toEntity();
              debugPrint(
                'Entity created - tipoTransaccion: "${entity.tipoTransaccion}" (length: ${entity.tipoTransaccion.length}), nombreCompleto: "${entity.nombreCompleto}"',
              ); // Debug

              // Debug adicional para TRASPASO específicamente
              if (entity.tipoTransaccion.toUpperCase().contains('TRASPASO')) {
                debugPrint('TRASPASO encontrado: "${entity.tipoTransaccion}"');
              }

              return entity;
            }).toList();

        // Contar tipos de transacción
        final tiposCounts = <String, int>{};
        for (final entity in entities) {
          final tipo = entity.tipoTransaccion.trim().toUpperCase();
          tiposCounts[tipo] = (tiposCounts[tipo] ?? 0) + 1;
        }
        debugPrint('Tipos de transacción encontrados: $tiposCounts');

        debugPrint('Movimientos obtenidos: ${entities.length} registros');
        return entities;
      } else {
        throw Exception(
          'Error al obtener los movimientos de los bidones por tipo de transacción',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Error desconocido en lstRptMovBidonesXTipoTransaccion: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ControlCombustibleMaquinaMontacargaEntity>>
  lstBidonesXSucursal() async {
    try {
      final response = await _dio.post(
        AppConstants.listarBidonesXSucursales,
        data: {},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>)
                .map(
                  (json) =>
                      ControlCombustibleMaquinaMontacargaModel.fromJson(json),
                )
                .toList();

        final entities = items.map((model) => model.toEntity()).toList();

        return entities;
      } else {
        throw Exception(
          'Error al obtener los movimientos de los bidones por sucursal',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Error desconocido en lstBidonesXSucursal: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ControlCombustibleMaquinaMontacargaEntity>>
  lstBidonesUltimosMov() async {
    try {
      final response = await _dio.post(
        AppConstants.listarUltimosMovBidones,
        data: {},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>)
                .map(
                  (json) =>
                      ControlCombustibleMaquinaMontacargaModel.fromJson(json),
                )
                .toList();

        final entities = items.map((model) => model.toEntity()).toList();

        return entities;
      } else {
        throw Exception(
          'Error al obtener los ultimos movimientos de los bidones',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Error desconocido en lstBidonesUltimosMov: ${e.toString()}',
      );
    }
  }

  //===================================================
  //  NUEVOS METODOS PARA REGISTRAR LOS BIDONES
  //===================================================

  ///Listara los contenedores
  @override
  Future<List<ContenedorEntity>> lstContenedores() async {
    try {
      final response = await _dio.post(AppConstants.lstContenedores, data: {});

      // Aceptar tanto 200 como 204. 204 significa que no hay contenido (no hay bidones)
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Si es 204 o no hay datos, retornar lista vacía
        if (response.statusCode == 204 || response.data == null) {
          return [];
        }

        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>)
                .map((json) => ContenedorModel.fromJson(json))
                .toList();

        final entities = items.map((model) => model.toEntity()).toList();

        return entities;
      } else {
        throw Exception('Error al obtener las sucursales');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido en lstSucursal: ${e.toString()}');
    }
  }

  /// Para registrar el movimiento
  @override
  Future<bool> registerMovimiento(MovimientoEntity mb) async {
    try {
      // Create the data map to send to the backend
      final data = MovimientoModel.fromEntity(mb);
      final jsonData = data.toJson();

      final response = await _dio.post(
        AppConstants.registerMovimiento,
        data: jsonData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response indicates success - accept both 200 and 201
        if (response.data != null &&
            (response.data['status'] == 200 ||
                response.data['status'] == 201)) {
          return true;
        }
      }

      return false;
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        // Try to extract error message from response
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          errorMessage = 'Error del servidor: ${e.response!.data['message']}';
        } else {
          errorMessage =
              'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido: ${e.toString()}');
    }
  }

  @override
  Future<bool> registerCompraGarrafa(CompraGarrafaEntity garrafa) async {
    try {
      // Create the data map to send to the backend
      final data = CompraGarrafaModel.fromEntity(garrafa);
      final jsonData = data.toJson();

      final response = await _dio.post(
        AppConstants.registerCompraGarrafa,
        data: jsonData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response indicates success - accept both 200 and 201
        if (response.data != null &&
            (response.data['status'] == 200 ||
                response.data['status'] == 201)) {
          return true;
        }
      }

      return false;
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        // Try to extract error message from response
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          errorMessage = 'Error del servidor: ${e.response!.data['message']}';
        } else {
          errorMessage =
              'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido: ${e.toString()}');
    }
  }

  @override
  Future<List<SucursalEntity>> lstSucursal() async {
    try {
      final response = await _dio.post(AppConstants.listarSucural, data: {});

      // Aceptar tanto 200 como 204. 204 significa que no hay contenido (no hay bidones)
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Si es 204 o no hay datos, retornar lista vacía
        if (response.statusCode == 204 || response.data == null) {
          return [];
        }

        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>)
                .map((json) => SucursalModel.fromJson(json))
                .toList();

        final entities = items.map((model) => model.toEntity()).toList();

        return entities;
      } else {
        throw Exception('Error al obtener las sucursales');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido en lstSucursal: ${e.toString()}');
    }
  }

  @override
  Future<List<TipoContenedorEntity>> lstTipoContenedor() async {
    try {
      final response = await _dio.post(
        AppConstants.lstTipoContenedor,
        data: {},
      );

      // Aceptar tanto 200 como 204. 204 significa que no hay contenido (no hay bidones)
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Si es 204 o no hay datos, retornar lista vacía
        if (response.statusCode == 204 || response.data == null) {
          return [];
        }

        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>)
                .map((json) => TipoContenedorModel.fromJson(json))
                .toList();

        final entities = items.map((model) => model.toEntity()).toList();

        return entities;
      } else {
        throw Exception('Error al obtener los tipos de contenedor');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Error desconocido en lstTipoContenedor: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<MovimientoEntity>> lstMovimientos(
    DateTime fechaInicio,
    DateTime fechaFin,
    int codSucursal,
    int idTipo,
  ) async {
    final data = {
      'fechaInicio': DateFormat('yyyy-MM-dd').format(fechaInicio),
      'fechaFin': DateFormat('yyyy-MM-dd').format(fechaFin),
      'codSucursal': codSucursal,
      'idTipo': idTipo,
    };

    try {
      final response = await _dio.post(AppConstants.lstMovimientos, data: data);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>).map((json) {
              return MovimientoModel.fromJson(json);
            }).toList();

        final entities =
            items.map((model) {
              final entity = model.toEntity();

              return entity;
            }).toList();

        return entities;
      } else {
        throw Exception(
          'Error al obtener los movimientos de los bidones por tipo de transacción',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido en lstMovimientos: ${e.toString()}');
    }
  }

  @override
  Future<List<MovimientoEntity>> lstSaldosActuales() async {
    try {
      final response = await _dio.post(
        AppConstants.lstSaldosActuales,
        data: {},
      );

      // Aceptar tanto 200 como 204. 204 significa que no hay contenido (no hay bidones)
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Si es 204 o no hay datos, retornar lista vacía
        if (response.statusCode == 204 || response.data == null) {
          return [];
        }

        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>)
                .map((json) => MovimientoModel.fromJson(json))
                .toList();

        final entities = items.map((model) => model.toEntity()).toList();

        return entities;
      } else {
        throw Exception('Error al obtener los saldos actuales');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Error desconocido en lstSaldosActuales: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<MovimientoEntity>> listBidonesPendientes(
    int sucursalDestino,
  ) async {
    final requestData = {'sucursalDestino': sucursalDestino};

    try {
      final response = await _dio.post(
        AppConstants.listarBidonesPendientes,
        data: requestData,
      );

      // Aceptar tanto 200 como 204. 204 significa que no hay contenido (no hay bidones)
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Si es 204 o no hay datos, retornar lista vacía
        if (response.statusCode == 204 || response.data == null) {
          return [];
        }

        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>)
                .map((json) => MovimientoModel.fromJson(json))
                .toList();

        final entities = items.map((model) => model.toEntity()).toList();

        return entities;
      } else {
        throw Exception(
          'Error al obtener los bidones pendientes para la sucursal',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Error desconocido en listBidonesPendientes: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<MovimientoEntity>> listDetalleBidon(idMovimiento) async {
    final requestData = {'idMovimiento': idMovimiento};

    try {
      final response = await _dio.post(
        AppConstants.listarDetalleBidon,
        data: requestData,
      );

      // Aceptar tanto 200 como 204. 204 significa que no hay contenido (no hay bidones)
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Si es 204 o no hay datos, retornar lista vacía
        if (response.statusCode == 204 || response.data == null) {
          return [];
        }

        final data = response.data['data'] ?? [];

        final items =
            (data as List<dynamic>)
                .map((json) => MovimientoModel.fromJson(json))
                .toList();

        final entities = items.map((model) => model.toEntity()).toList();

        return entities;
      } else {
        throw Exception('Error al obtener el detalle del bidón');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido en listDetalleBidon: ${e.toString()}');
    }
  }
}
