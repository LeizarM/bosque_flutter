// Destino final: lib/data/repositories/cierre_operaciones_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/traspaso_mov_caja_model.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/cierre_operaciones_repository.dart';

class CierreOperacionesImpl extends BaseApiRepository implements CierreOperacionesRepository {
  @override
  Future<List<TraspasoMovCajaEntity>> obtenerTraspasos({DateTime? fecha}) async {
    // Reutiliza el endpoint genérico de tac_traspasoMovCaja — este flujo no
    // los crea, ya existen (sincronizados desde afuera); acá solo se
    // muestran, filtrados a la fecha elegida (default hoy).
    final f = fecha ?? DateTime.now();
    final modelos = await postAndReturnList<TraspasoMovCajaModel>(
      endpoint: AppConstants.tarObtenerTraspasoMovCaja,
      data: {'fecha': DateTime(f.year, f.month, f.day).toIso8601String()},
      fromJson: (json) => TraspasoMovCajaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<int> confirmar(
    int idBitTarea, {
    DateTime? fecha,
    required List<Map<String, dynamic>> traspasos,
  }) async {
    final resultado = await postAndReturnId(
      endpoint: AppConstants.tarCierreOperacionesConfirmar,
      data: {
        'idBitTarea': idBitTarea,
        if (fecha != null)
          'fecha': DateTime(fecha.year, fecha.month, fecha.day).toIso8601String(),
        'traspasos': traspasos,
      },
      errorMessage: 'No se pudo confirmar el cierre de operaciones.',
    );
    return resultado.toInt();
  }
}
