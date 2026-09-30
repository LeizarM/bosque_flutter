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

class DepositoChequesImpl implements DepositoChequesRepository {
  final Dio _dio = DioClient.getInstance();

  /// POST de un listado. `204` es «sin registros» y devuelve `[]`; cualquier
  /// otro fallo se lanza como [DepositoChequesException] con el mensaje del
  /// backend o uno por tipo de error (no se disfraza de lista vacía).
  Future<List<T>> _postLista<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(dynamic json) desdeJson,
    required String errorPorDefecto,
  }) async {
    final Response response;
    try {
      response = await _dio.post(endpoint, data: data);
    } on DioException catch (e) {
      throw DepositoChequesException(
        DioClient.handleDioError(e, errorPorDefecto),
      );
    }

    if (response.statusCode != 200 || response.data == null) return [];
    try {
      // El backend retorna: { message, data: [ ... ], status }
      final crudos = (response.data['data'] ?? []) as List<dynamic>;
      return crudos.map(desdeJson).toList();
    } catch (_) {
      throw DepositoChequesException(errorPorDefecto);
    }
  }

  /// Mensaje de una descarga de bytes (PDF, imagen). Con `responseType.bytes`
  /// el JSON de error del backend llega como bytes y `handleDioError` no lo ve.
  String _mensajeDeBytes(DioException e, String porDefecto) {
    final datos = e.response?.data;
    if (datos is List<int>) {
      try {
        final cuerpo = jsonDecode(utf8.decode(datos));
        if (cuerpo is Map && cuerpo['message'] != null) {
          final msg = cuerpo['message'].toString();
          if (msg.isNotEmpty) return msg;
        }
      } catch (_) {
        // No era JSON: se sigue con el mensaje por tipo de error.
      }
    }
    return DioClient.handleDioError(e, porDefecto);
  }

  /// Mensaje de un fallo de escritura, sin exponer el cuerpo crudo de la
  /// respuesta.
  String _mensaje(Object e, String porDefecto) {
    if (e is DepositoChequesException) return e.mensaje;
    if (e is DioException) return DioClient.handleDioError(e, porDefecto);
    return porDefecto;
  }

  @override
  Future<List<BancoXCuentaEntity>> getBancos(int codEmpresa) async {
    final modelos = await _postLista<BancoXCuentaModel>(
      endpoint: AppConstants.deplstBancos,
      data: {'codEmpresa': codEmpresa},
      desdeJson: (json) => BancoXCuentaModel.fromJson(json),
      errorPorDefecto: 'No se pudieron cargar los bancos.',
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<EmpresaEntity>> getEmpresas() async {
    final modelos = await _postLista<EmpresaModel>(
      endpoint: AppConstants.deplstEmpresas,
      data: {},
      desdeJson: (json) => EmpresaModel.fromJson(json),
      errorPorDefecto: 'No se pudieron cargar las empresas.',
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<NotaRemisionEntity>> getNotasRemision(
    int codEmpresa,
    String codCliente,
  ) async {
    final modelos = await _postLista<NotaRemisionModel>(
      endpoint: AppConstants.deplstNotaRemision,
      data: {'codEmpresaBosque': codEmpresa, 'codCliente': codCliente},
      desdeJson: (json) => NotaRemisionModel.fromJson(json),
      errorPorDefecto: 'No se pudieron cargar las notas de remisión.',
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SocioNegocioEntity>> getSociosNegocio(int codEmpresa) async {
    final modelos = await _postLista<SocioNegocioModel>(
      endpoint: AppConstants.deplstSocioNegocio,
      data: {'codEmpresa': codEmpresa},
      desdeJson: (json) => SocioNegocioModel.fromJson(json),
      errorPorDefecto: 'No se pudieron cargar los clientes.',
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
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
          throw const DepositoChequesException(
            'El formato de la imagen no es compatible.',
          );
        }
        // Añadir la imagen como un archivo
        formData.files.add(MapEntry('file', multipartFile));
      }

      // Con la foto, el servidor la decodifica y la vuelve a guardar antes de
      // responder: los 30 s globales de recepción no alcanzan en red lenta. En
      // web el tope total de la petición es connect + receive.
      final response = await _dio.post(
        AppConstants.depRegister,
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw DepositoChequesException(
        DioClient.handleDioError(e, 'No se pudo registrar el depósito.'),
      );
    } on DepositoChequesException {
      rethrow;
    } catch (_) {
      throw const DepositoChequesException(
        'No se pudo registrar el depósito.',
      );
    }
  }

  @override
  Future<bool> guardarNotaRemision(NotaRemisionEntity notaRemision) async {
    final model = NotaRemisionModel.fromEntity(notaRemision);
    try {
      final response = await _dio.post(
        AppConstants.depRegisterNotaRemision,
        data: model.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw DepositoChequesException(
        DioClient.handleDioError(e, 'No se pudo guardar la nota de remisión.'),
      );
    } catch (_) {
      throw const DepositoChequesException(
        'No se pudo guardar la nota de remisión.',
      );
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
    }
    if (fechaFin != null) {
      data['fechaFin'] = DateFormat('yyyy-MM-dd').format(fechaFin);
    }

    final modelos = await _postLista<DepositoChequeModel>(
      endpoint: AppConstants.depListarDepositos,
      data: data,
      desdeJson: (json) => DepositoChequeModel.fromJson(json),
      errorPorDefecto: 'No se pudieron cargar los depósitos.',
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<DepositoChequeEntity>> lstDepositxIdentificar(
    int idBxC,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String codCliente,
  ) async {
    final Map<String, dynamic> data = {
      'idBxC': idBxC,
      'codCliente': codCliente,
    };
    if (fechaInicio != null) {
      data['fechaInicio'] = DateFormat('yyyy-MM-dd').format(fechaInicio);
    }
    if (fechaFin != null) {
      data['fechaFin'] = DateFormat('yyyy-MM-dd').format(fechaFin);
    }

    final modelos = await _postLista<DepositoChequeModel>(
      endpoint: AppConstants.depListDepositosIde,
      data: data,
      desdeJson: (json) => DepositoChequeModel.fromJson(json),
      errorPorDefecto: 'No se pudieron cargar los depósitos por identificar.',
    );
    return modelos.map((m) => m.toEntity()).toList();
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
          responseType:
              ResponseType.bytes, // Crucial para recibir datos binarios
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/pdf',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List<int>) {
        final pdfBytes = Uint8List.fromList(response.data);
        if (pdfBytes.isNotEmpty) return pdfBytes;
        throw const DepositoChequesException('El PDF recibido está vacío.');
      }
      throw const DepositoChequesException(
        'No se pudo generar el PDF del depósito.',
      );
    } on DioException catch (e) {
      throw DepositoChequesException(
        _mensajeDeBytes(e, 'No se pudo generar el PDF del depósito.'),
      );
    } on DepositoChequesException {
      rethrow;
    } catch (_) {
      throw const DepositoChequesException(
        'No se pudo generar el PDF del depósito.',
      );
    }
  }

  @override
  Future<Uint8List> obtenerImagenDeposito(int idDeposito) async {
    try {
      final response = await _dio.get(
        AppConstants.depObtImagen + idDeposito.toString(),
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': '*/*', // Aceptar cualquier tipo de contenido
          },
        ),
      );

      if (response.statusCode == 200) {
        final Uint8List? bytes;
        if (response.data is Uint8List) {
          bytes = response.data as Uint8List;
        } else if (response.data is List<int>) {
          bytes = Uint8List.fromList(response.data as List<int>);
        } else {
          bytes = null;
        }
        if (bytes != null && bytes.isNotEmpty) return bytes;
        throw const DepositoChequesException(
          'La imagen recibida está vacía.',
        );
      }
      throw const DepositoChequesException(
        'No se pudo descargar la imagen del depósito.',
      );
    } on DioException catch (e) {
      throw DepositoChequesException(
        _mensajeDeBytes(e, 'No se pudo descargar la imagen del depósito.'),
      );
    } on DepositoChequesException {
      rethrow;
    } catch (_) {
      throw const DepositoChequesException(
        'No se pudo descargar la imagen del depósito.',
      );
    }
  }

  @override
  Future<bool> actualizarNroTransaccion(DepositoChequeEntity deposito) async {
    final model = DepositoChequeModel.fromEntity(deposito);

    try {
      final response = await _dio.post(
        AppConstants.depActualizarNotaRemision,
        data: model.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw DepositoChequesException(
        _mensaje(e, 'No se pudo actualizar el depósito.'),
      );
    }
  }

  @override
  Future<bool> rechazarNotaRemision(DepositoChequeEntity deposito) async {
    final model = DepositoChequeModel.fromEntity(deposito);

    try {
      final response = await _dio.post(
        AppConstants.depRechazarNotaRemision,
        data: model.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw DepositoChequesException(
        _mensaje(e, 'No se pudo rechazar el depósito.'),
      );
    }
  }
}
