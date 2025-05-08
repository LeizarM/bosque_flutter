

import 'dart:io';
import 'package:bosque_flutter/data/models/nota_remision_model.dart';
import 'package:dio/dio.dart';
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

class DepositoChequesImpl implements DepositoChequesRepository {
  
  final Dio _dio = DioClient.getInstance();
  
  @override
  Future<List<BancoXCuentaEntity>> getBancos(int codEmpresa) async {
    try {
      final response = await _dio.post(AppConstants.deplstBancos, data: {
        'codEmpresa': codEmpresa
      });

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items = (data as List<dynamic>)
            .map((json) => BancoXCuentaModel.fromJson(json))
            .toList();
        
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los bancos y sus cuentas por empresa');
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
      throw Exception('Error desconocido getBancos por cuentas: ${e.toString()}');
    }
  }

  @override
  Future<List<EmpresaEntity>> getEmpresas() async {
    
    try {
      final response = await _dio.post(AppConstants.deplstEmpresas, data: {});

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items = (data as List<dynamic>)
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
  Future<List<NotaRemisionEntity>> getNotasRemision(int codEmpresa, String codCliente) async {
    try {
      final response = await _dio.post(AppConstants.deplstNotaRemision, data: {
        'codEmpresaBosque': codEmpresa,
        'codCliente': codCliente
      });

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items = (data as List<dynamic>)
            .map((json) => NotaRemisionModel.fromJson(json))
            .toList();
        
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener las notas de remisión por cliente');
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
      throw Exception('Error desconocido getNotasRemision: ${e.toString()}');
    }
  }

  @override
  Future<List<SocioNegocioEntity>> getSociosNegocio(int codEmpresa) async {
    
    try {
      final response = await _dio.post(AppConstants.deplstSocioNegocio, data: {
        'codEmpresa': codEmpresa
      });

      // El backend retorna: { message, data: [ ... ], status }
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items = (data as List<dynamic>)
            .map((json) => SocioNegocioModel.fromJson(json))
            .toList();
        
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los socios de negocio por empresa');
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
      throw Exception('Error desconocido getSociosNegocio: ${e.toString()}');
    }

  }

  @override
  Future<bool> guardarNotaRemision(NotaRemisionEntity notaRemision) {
    // TODO: implement guardarNotaRemision
    throw UnimplementedError();
  }

  @override
  Future<List<DepositoChequeEntity>> lstDepositxIdentificar(int idBxC, DateTime fechaInicio, DateTime fechaFin, String codCliente) {
    // TODO: implement lstDepositxIdentificar
    throw UnimplementedError();
  }

  @override
  Future<List<DepositoChequeEntity>> obtenerDepositos(int codEmpresa, int idBxC, DateTime fechaInicio, DateTime fechaFin, String codCliente, String estadoFiltro) {
    // TODO: implement obtenerDepositos
    throw UnimplementedError();
  }

  @override
  Future<bool> registrarDeposito(DepositoChequeEntity deposito, File imagen) {
    // TODO: implement registrarDeposito
    throw UnimplementedError();
  }
  


}