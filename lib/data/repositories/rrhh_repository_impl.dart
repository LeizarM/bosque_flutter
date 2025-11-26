import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/cargo_model.dart';
import 'package:bosque_flutter/data/models/cargo_sucursal_model.dart';
import 'package:bosque_flutter/data/models/empresa_model.dart';
import 'package:bosque_flutter/data/models/sucursal_model.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/repositories/rrhh_repository.dart';
import 'package:dio/dio.dart';

class RRHHRepositoryImpl implements RRHHRepository {
  final Dio _dio = DioClient.getInstance();

  /// Listar empresas
  @override
  Future<List<EmpresaEntity>> lstEmpresas() async {
    try {
      final response = await _dio.post(AppConstants.lstEmpresa, data: {});

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => EmpresaModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener las empresas');
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
      throw Exception('Error desconocido getEmpresas: ${e.toString()}');
    }
  }

  @override
  Future<bool> registerEmpresa(EmpresaEntity mb) {
    // TODO: implement registerEmpresa
    throw UnimplementedError();
  }

  /// Listar cargos por empresa
  @override
  Future<List<CargoEntity>> lstCargos(int codEmpresa) async {
    try {
      final response = await _dio.post(
        AppConstants.lstCargos,
        data: {'codEmpresa': codEmpresa},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => CargoModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los cargos');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido lstCargos: ${e.toString()}');
    }
  }

  /// Listar sucursales por empresa
  @override
  Future<List<SucursalEntity>> lstSucursales(int codEmpresa) async {
    try {
      final response = await _dio.post(
        AppConstants.lstSucursales,
        data: {'codEmpresa': codEmpresa},
      );

      if (response.statusCode == 200 && response.data != null) {
        // El backend devuelve directamente el array, NO dentro de 'data'
        final data =
            response.data is List
                ? response.data
                : (response.data['data'] ?? []);

        final items =
            (data as List<dynamic>)
                .map((json) => SucursalModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
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
      throw Exception('Error desconocido lstSucursales: ${e.toString()}');
    }
  }

  //para listar los cargos por empresa pero con detalles adicionales
  @override
  Future<List<CargoEntity>> lstCargosXEmpresa(int codEmpresa) async {
    try {
      final response = await _dio.post(
        AppConstants.lstCargosXEmpresaNew,
        data: {'codEmpresa': codEmpresa},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => CargoModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los cargos detallados');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido lstCargosXEmpresa: ${e.toString()}');
    }
  }

  //Para Actualizar o registrar un cargo
  @override
  Future<bool> registrarCargo(CargoEntity cargo) async {
    final model = CargoModel.fromEntity(cargo);

    try {
      final response = await _dio.post(
        AppConstants.registrarCargo,
        data: model.toJson(),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        // El backend puede responder con 'success', 'ok', o 'msg'
        final success =
            response.data['success'] ??
            (response.data['ok'] == 'ok') ??
            (response.data['msg'] != null);
        return success;
      } else {
        throw Exception('Error al registrar el cargo');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido registrarCargo: ${e.toString()}');
    }
  }

  //Listar las sucursales que pertenece un cargo
  @override
  Future<List<CargoSucursalEntity>> lstSucursalesXCargo(int codCargo) async {
    try {
      final response = await _dio.post(
        AppConstants.lstSucursalesXCargo,
        data: {'codCargo': codCargo},
      );

      if (response.statusCode == 200 && response.data != null) {
        // El backend devuelve directamente el array, NO dentro de 'data'
        final data =
            response.data is List
                ? response.data
                : (response.data['data'] ?? []);
        final items =
            (data as List<dynamic>)
                .map((json) => CargoSucursalModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener las sucursales por cargo');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido lstSucursalesXCargo: ${e.toString()}');
    }
  }

  //Registrar asignación de cargo a sucursal o actualizar
  @override
  Future<bool> registrarCargoSucursal(CargoSucursalEntity cargoSucursal) async {
    final model = CargoSucursalModel.fromEntity(cargoSucursal);

    try {
      final response = await _dio.post(
        AppConstants.registrarCargoSucursal,
        data: model.toJson(),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final success =
            response.data['success'] ??
            (response.data['ok'] == 'ok') ??
            (response.data['msg'] != null);
        return success;
      } else {
        throw Exception('Error al registrar la asignación cargo-sucursal');
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
        'Error desconocido registrarCargoSucursal: ${e.toString()}',
      );
    }
  }

  //Eliminar asignación de cargo a sucursal
  @override
  Future<bool> eliminarCargoSucursal(int codCargoSucursal) async {
    try {
      final response = await _dio.post(
        AppConstants.eliminarCargoSucursal,
        data: {'codCargoSucursal': codCargoSucursal},
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final success =
            response.data['success'] ??
            (response.data['ok'] == 'ok') ??
            (response.data['msg'] != null);
        return success;
      } else {
        throw Exception('Error al eliminar la asignación cargo-sucursal');
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
        'Error desconocido eliminarCargoSucursal: ${e.toString()}',
      );
    }
  }

  //Obtener los empleados asignados a un cargo
  @override
  Future<List<CargoEntity>> obtenerEmpleadosXCargo(int codCargo) async {
    try {
      final response = await _dio.post(
        AppConstants.obtenerEmpleadosXCargo,
        data: {'codCargo': codCargo},
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // El backend devuelve directamente el array, NO dentro de 'data'
        final data =
            response.data is List
                ? response.data
                : (response.data['data'] ?? []);

        if (data == null) {
          return [];
        }

        final items =
            (data as List<dynamic>)
                .map((json) => CargoModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else if (response.statusCode == 200 && response.data == null) {
        // Respuesta vacía válida
        return [];
      } else {
        throw Exception('Error al obtener los empleados por cargo');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Tiempo de espera agotado. Intente nuevamente.';
      } else if (e.response != null && e.response!.data != null) {
        errorMessage = 'Error del servidor: ${e.response!.statusCode}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error al cargar empleados: ${e.toString()}');
    }
  }
}
