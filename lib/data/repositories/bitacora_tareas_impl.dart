// Destino final: lib/data/repositories/bitacora_tareas_impl.dart
import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/bitacora_tareas_model.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/repositories/bitacora_tareas_repository.dart';

class BitacoraTareasImpl extends BaseApiRepository
    implements BitacoraTareasRepository {
  @override
  Future<List<BitacoraCumplimientoEntity>> cumplimiento({
    required DateTime desde,
    required DateTime hasta,
  }) => postAndReturnList(
    endpoint: AppConstants.tarBitacoraCumplimiento,
    data: {'fechaIni': fechaParaSql(desde), 'fechaFin': fechaParaSql(hasta)},
    fromJson: BitacoraTareasModel.cumplimiento,
  );

  @override
  Future<Uint8List> cumplimientoPdf(FiltroBitacora filtro) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.tarBitacoraCumplimientoPdf,
        data: filtro.toJson(),
        // Un rango largo de toda la empresa pasa de los 30 s por defecto.
        receiveTimeout: const Duration(minutes: 3),
      );

  @override
  Future<List<ResumenGeneracionEntity>> generacion({
    required DateTime desde,
    required DateTime hasta,
  }) => postAndReturnList(
    endpoint: AppConstants.tarBitacoraGeneracion,
    data: {'fechaIni': fechaParaSql(desde), 'fechaFin': fechaParaSql(hasta)},
    fromJson: BitacoraTareasModel.resumen,
  );

  @override
  Future<List<DiagnosticoGeneracionEntity>> porQue({
    int? codEmpleado,
    required DateTime fecha,
    int? idTarRuti,
  }) => postAndReturnList(
    endpoint: AppConstants.tarBitacoraPorQue,
    data: {
      if (codEmpleado != null) 'codEmpleado': codEmpleado,
      'fecha': fechaParaSql(fecha),
      if (idTarRuti != null) 'idTarRuti': idTarRuti,
    },
    fromJson: BitacoraTareasModel.diagnostico,
  );

  @override
  Future<List<PersonaBuscada>> buscarPersonas(String texto) async {
    // El buscador de Caja Chica: cualquier usuario autenticado del módulo
    // puede usarlo. Encontrar a alguien no da permiso para verlo; eso lo
    // decide /bitacora/por-que.
    final empleados = await postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarCajaChicaBuscarEmpleados,
      data: {'search': texto},
      fromJson: (json) => json,
    );
    return empleados
        .map(BitacoraTareasModel.persona)
        .whereType<PersonaBuscada>()
        .toList();
  }
}
