import 'package:dio/dio.dart';

import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/repositories/ttk_tickets_repository.dart';

/// Base de los repositorios Tickets / Bingo. Suma [escribir], que devuelve el
/// id y el `message` del sobre: el texto del SP que la pantalla muestra.
abstract class TtkApiBase extends BaseApiRepository {
  /// Igual que el de la base, pero un 403 o un 500 llega con el `message`
  /// del backend y no con el texto crudo de un `DioException`.
  @override
  Future<List<T>> postAndReturnList<T>({
    required String endpoint,
    Map<String, dynamic> data = const {},
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      return await super.postAndReturnList<T>(
        endpoint: endpoint,
        data: data,
        fromJson: fromJson,
      );
    } on DioException catch (e) {
      throw Exception(_mensajeDe(e, 'No se pudieron obtener los datos.'));
    }
  }

  /// POST de escritura: `data` = id generado, `message` = `errormsg` del SP.
  /// 204 es éxito sin datos; un 400 lanza el `message` del backend.
  Future<TtkRespuesta> escribir(
    String endpoint,
    Map<String, dynamic> cuerpo, {
    String errorMessage = 'No se pudo completar la operación.',
  }) async {
    try {
      final r = await dio.post<Object?>(endpoint, data: cuerpo);
      final sobre = r.data;
      if (r.statusCode == 204 || sobre is! Map) {
        return (id: BigInt.zero, mensaje: '');
      }
      return (
        id: ttkBigInt(sobre['data']) ?? BigInt.zero,
        mensaje: ttkTexto(sobre['message']).trim(),
      );
    } on DioException catch (e) {
      throw Exception(_mensajeDe(e, errorMessage));
    }
  }

  /// POST que devuelve un objeto en `data` (estado en vivo, validar cartón).
  /// Acepta también una lista y toma su primera fila; 204 → null.
  Future<Map<String, dynamic>?> leerObjeto(
    String endpoint,
    Map<String, dynamic> cuerpo, {
    String errorMessage = 'No se pudo obtener el dato.',
  }) async {
    try {
      final r = await dio.post<Object?>(endpoint, data: cuerpo);
      final sobre = r.data;
      if (r.statusCode == 204 || sobre == null || sobre == '') return null;
      final dato = sobre is Map ? sobre['data'] : sobre;
      if (dato is Map) return Map<String, dynamic>.from(dato);
      if (dato is List && dato.isNotEmpty && dato.first is Map) {
        return Map<String, dynamic>.from(dato.first as Map);
      }
      return null;
    } on DioException catch (e) {
      throw Exception(_mensajeDe(e, errorMessage));
    }
  }

  String _mensajeDe(DioException e, String porDefecto) {
    final cuerpo = e.response?.data;
    if (cuerpo is Map && ttkTextoN(cuerpo['message']) != null) {
      return cuerpo['message'].toString();
    }
    return DioClient.handleDioError(e, porDefecto);
  }
}
