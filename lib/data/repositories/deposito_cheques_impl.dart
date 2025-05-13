import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bosque_flutter/data/models/deposito_cheque_model.dart';
import 'package:bosque_flutter/data/models/nota_remision_model.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/banco_cuenta_model.dart';
import 'package:bosque_flutter/data/models/empresa_model.dart';
import 'package:bosque_flutter/data/models/socio_negocio_model.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/repositories/deposito_cheques_repository.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class DepositoChequesImpl implements DepositoChequesRepository {
  final Dio _dio = DioClient.getInstance();

  @override
  Future<List<BancoXCuentaEntity>> getBancos(int codEmpresa) async {
    try {
      final response = await _dio.post(
        AppConstants.deplstBancos,
        data: {'codEmpresa': codEmpresa},
      );

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => BancoXCuentaModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        // Si el backend responde con error, retorna lista vacía en vez de lanzar excepción
        return [];
      }
    } on DioException catch (e) {
      // Si hay error de red o servidor, retorna lista vacía
      return [];
    } catch (e) {
      // Si hay cualquier otro error, retorna lista vacía
      return [];
    }
  }

  @override
  Future<List<EmpresaEntity>> getEmpresas() async {
    try {
      final response = await _dio.post(AppConstants.deplstEmpresas, data: {});

      // El backend retorna: { message, data: [ ... ], status }
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
  Future<List<NotaRemisionEntity>> getNotasRemision(
    int codEmpresa,
    String codCliente,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.deplstNotaRemision,
        data: {'codEmpresaBosque': codEmpresa, 'codCliente': codCliente},
      );

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => NotaRemisionModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        // Si el backend responde con error, retorna lista vacía en vez de lanzar excepción
        return [];
      }
    } on DioException catch (e) {
      // Si hay error de red o servidor, retorna lista vacía
      return [];
    } catch (e) {
      // Si hay cualquier otro error, retorna lista vacía
      return [];
    }
  }

  @override
  Future<List<SocioNegocioEntity>> getSociosNegocio(int codEmpresa) async {
    try {
      final response = await _dio.post(
        AppConstants.deplstSocioNegocio,
        data: {'codEmpresa': codEmpresa},
      );

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => SocioNegocioModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        // Si el backend responde con error, retorna lista vacía en vez de lanzar excepción
        return [];
      }
    } on DioException catch (e) {
      // Si hay error de red o servidor, retorna lista vacía
      return [];
    } catch (e) {
      // Si hay cualquier otro error, retorna lista vacía
      return [];
    }
  }

  @override
  Future<bool> registrarDeposito(
    DepositoChequeEntity deposito,
    dynamic imagen,
  ) async {
    final model = DepositoChequeModel.fromEntity(deposito);

    try {
      MultipartFile multipartFile;

      if (imagen is Uint8List) {
        multipartFile = MultipartFile.fromBytes(
          imagen,
          filename: "imagen.jpg",
          contentType: MediaType('image', 'jpeg'),
        );
      } else if (imagen is File) {
        multipartFile = await MultipartFile.fromFile(
          imagen.path,
          filename: "imagen.jpg",
          contentType: MediaType('image', 'jpeg'),
        );
      } else {
        throw Exception('Formato de imagen no soportado');
      }

      FormData formData = FormData.fromMap({
        'depositoCheque': jsonEncode(model.toJson()),
        'file': multipartFile,
      });

      final response = await _dio.post(
        AppConstants.depRegister,
        data:
            formData, // Asegúrate de que EntregaEntity tenga un método toJson()
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
      throw Exception('Error desconocido registrarDeposito: ${e.toString()}');
    }
  }

  @override
  Future<bool> guardarNotaRemision(NotaRemisionEntity notaRemision) async {
    final model = NotaRemisionModel.fromEntity(notaRemision);
    try {
      final response = await _dio.post(
        AppConstants.depRegisterNotaRemision,
        data:
            model
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
      throw Exception('Error desconocido guardarNotaRemision: ${e.toString()}');
    }
  }

  @override
  Future<List<DepositoChequeEntity>> obtenerDepositos(
    int codEmpresa,
    int idBxC,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String codCliente,
    String estadoFiltro,
  ) async {
    final Map<String, dynamic> data = {
      'codEmpresa': codEmpresa,
      'idBxC': idBxC,
      'codCliente': codCliente,
      'estadoFiltro': estadoFiltro,
    };
    if (fechaInicio != null) {
      data['fechaInicio'] = DateFormat('yyyy-MM-dd').format(fechaInicio);
    } else {
      data.remove('fechaInicio');
    }
    if (fechaFin != null) {
      data['fechaFin'] = DateFormat('yyyy-MM-dd').format(fechaFin);
    } else {
      data.remove('fechaFin');
    }

    try {
      final response = await _dio.post(
        AppConstants.depListarDepositos,
        data: data,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => DepositoChequeModel.fromJson(json))
                .toList();
        Logger().i(items.length);
        return items.map((model) => model.toEntity()).toList();
      } else {
        return [];
      }
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<DepositoChequeEntity>> lstDepositxIdentificar(
    int idBxC,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String codCliente,
  ) {
    // TODO: implement lstDepositxIdentificar
    throw UnimplementedError();
  }
}
