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

  Future<bool> registrarDeposito(
  DepositoChequeEntity deposito,
  dynamic imagen,
) async {
  final model = DepositoChequeModel.fromEntity(deposito);

  try {
    // Convertir el modelo a JSON y luego a String
    final depositoChequeJson = jsonEncode(model.toJson());
    
    // Crear FormData con el campo 'depositoCheque' como String
    FormData formData = FormData();
    
    // Añadir el campo depositoCheque como un campo normal, no como parte de un objeto
    formData.fields.add(MapEntry('depositoCheque', depositoChequeJson));
    
    // Añadir la imagen si existe
    if (imagen != null) {
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
      
      // Añadir la imagen como un archivo
      formData.files.add(MapEntry('file', multipartFile));
    }

    // Realizar la solicitud POST
    final response = await _dio.post(
      AppConstants.depRegister,
      data: formData,
    );

    return response.statusCode == 200 || response.statusCode == 201;
  } on DioException catch (e) {
    // Manejo de errores
    String errorMessage = 'Error de conexión: ${e.message}';
    if (e.response != null && e.response!.data != null) {
      errorMessage = 'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
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

  @override
  Future<Uint8List> obtenerPdfDeposito(
    int idDeposito,
    DepositoChequeEntity deposito,
  ) async {
    try {
      final model = DepositoChequeModel.fromEntity(deposito);

      final response = await _dio.post(
        AppConstants.depGenPdfDeposito + idDeposito.toString(),
        data: model.toJson(),
        options: Options(
        responseType: ResponseType.bytes,  // Crucial para recibir datos binarios
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/pdf',
        },
      ),
      );

      if (response.statusCode == 200) {
        // Verificar que tenemos datos y son del tipo correcto
        if (response.data is List<int>) {
          final pdfBytes = Uint8List.fromList(response.data);

          // Verificar que los datos parecen ser un PDF
          if (pdfBytes.isNotEmpty) {
            return pdfBytes;
          } else {
            throw Exception('El PDF recibido está vacío');
          }
        } else {
          throw Exception('Formato inesperado: ${response.data.runtimeType}');
        }
      } else {
        throw Exception('Error obteniendo PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }
  
  @override
  Future<Uint8List> obtenerImagenDeposito( int idDeposito ) async {
    
    try {
    final response = await _dio.get(
      AppConstants.depObtImagen + idDeposito.toString(),
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Accept': '*/*',  // Aceptar cualquier tipo de contenido
        },
      ),
    );

    if (response.statusCode == 200) {
      if (response.data is List<int>) {
        final bytes = Uint8List.fromList(response.data);
        
        // Verificar que tenemos datos
        if (bytes.isNotEmpty) {
         
          return bytes;
        } else {
          throw Exception('La imagen recibida está vacía');
        }
      } else {
        throw Exception('Formato inesperado: ${response.data.runtimeType}');
      }
    } else {
      throw Exception('Error obteniendo imagen: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error en la solicitud: $e');
  }


  }
  
  @override
  Future<bool> actualizarNroTransaccion( DepositoChequeEntity deposito ) async {
    
    final model = DepositoChequeModel.fromEntity(deposito);

    try {
      final response = await _dio.post(
        AppConstants.depActualizarNotaRemision,
        data:
            model.toJson(), // Asegúrate de que EntregaEntity tenga un método toJson()
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
  
  @override
  Future<bool> rechazarNotaRemision( DepositoChequeEntity deposito ) async {
    
    final model = DepositoChequeModel.fromEntity(deposito);

    try {
      final response = await _dio.post(
        AppConstants.depRechazarNotaRemision,
        data:
            model.toJson(), // Asegúrate de que EntregaEntity tenga un método toJson()
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
}
