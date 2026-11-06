import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';

/// Base de los repositorios de Horas Extras. 204 es éxito sin datos; 403, 400
/// y 409 llegan como [ErrorHex] y el resto como `Exception` técnica.
abstract class HexApiBase extends BaseApiRepository {
  /// Un reporte Jasper puede tardar más que los 30 s del cliente.
  static const Duration _esperaPdf = Duration(minutes: 2);

  Future<List<T>> listar<T>(
    String endpoint,
    Map<String, dynamic> cuerpo,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final dato = _dato(await _enviar(endpoint, cuerpo));
    return [for (final fila in hexFilas(dato)) fromJson(fila)];
  }

  /// El objeto de `data` o, si llegó una lista, su primera fila.
  Future<T?> leerUno<T>(
    String endpoint,
    Map<String, dynamic> cuerpo,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final dato = _dato(await _enviar(endpoint, cuerpo));
    final fila =
        dato is Map
            ? Map<String, dynamic>.from(dato)
            : hexFilas(dato).firstOrNull;
    return fila == null ? null : fromJson(fila);
  }

  /// Escritura: `data` es el id del SP y `message` su `errormsg`.
  Future<HexRespuesta> escribir(
    String endpoint,
    Map<String, dynamic> cuerpo,
  ) async {
    final sobre = await _enviar(endpoint, cuerpo);
    if (sobre is! Map) return (id: BigInt.zero, mensaje: '');
    return (
      id: hexBigInt(sobre['data']) ?? BigInt.zero,
      mensaje: hexTexto(sobre['message']).trim(),
    );
  }

  /// PDF armado en el backend; 204 (no existe) da null.
  Future<Uint8List?> descargarPdf(
    String endpoint,
    Map<String, dynamic> cuerpo,
  ) async {
    final datos = await _enviar(
      endpoint,
      cuerpo,
      opciones: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: _esperaPdf,
      ),
    );
    return switch (datos) {
      final Uint8List bytes => bytes,
      final List<int> bytes => Uint8List.fromList(bytes),
      _ => null,
    };
  }

  /// El [ErrorHex] de un 403, 400 o 409; null si es un error técnico, que el
  /// llamador lanza como `Exception` para que la pantalla lo humanice.
  @visibleForTesting
  static ErrorHex? traducir(DioException e) {
    final respuesta = e.response;
    late final mensaje = _mensajeDe(e);
    return switch ((respuesta?.statusCode, respuesta?.data)) {
      (403, _) => SinPermisoHex(mensaje),
      (400, {'confirmable': true}) => ConfirmacionHex(mensaje),
      (400, _) => NegocioHex(mensaje),
      (409, _) => ConflictoHex(mensaje),
      _ => null,
    };
  }

  /// POST del módulo: el sobre de la respuesta, o null si fue 204.
  Future<Object?> _enviar(
    String endpoint,
    Map<String, dynamic> cuerpo, {
    Options? opciones,
  }) async {
    try {
      final r = await dio.post<Object?>(
        endpoint,
        data: cuerpo,
        options: opciones,
      );
      return r.statusCode == 204 ? null : r.data;
    } on DioException catch (e) {
      throw traducir(e) ?? Exception(_mensajeDe(e));
    }
  }

  static Object? _dato(Object? sobre) => sobre is Map ? sobre['data'] : sobre;

  /// El `message` del backend; un PDF lo trae en bytes y se desenvuelve aparte.
  static String _mensajeDe(DioException e) =>
      e.requestOptions.responseType == ResponseType.bytes
          ? DioClient.mensajeDeReporteFallido(e)
          : DioClient.handleDioError(e, 'No se pudo completar la operación.');
}
