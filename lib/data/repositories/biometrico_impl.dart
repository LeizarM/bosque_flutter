import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/asistencia_dia_model.dart';
import 'package:bosque_flutter/data/models/bitacora_model.dart';
import 'package:bosque_flutter/data/models/bio_check_in_out_adicional_model.dart';
import 'package:bosque_flutter/data/models/bio_check_in_out_model.dart';
import 'package:bosque_flutter/data/models/bio_empl_bosq_empl_model.dart';
import 'package:bosque_flutter/data/models/bio_hr_empleado_model.dart';
import 'package:bosque_flutter/data/models/bio_hr_semanal_detalle_model.dart';
import 'package:bosque_flutter/data/models/bio_hr_semanal_model.dart';
import 'package:bosque_flutter/data/models/bio_hr_x_empl_expandido_model.dart';
import 'package:bosque_flutter/data/models/bio_hrs_model.dart';
import 'package:bosque_flutter/domain/entities/asistencia_dia_entity.dart';
import 'package:bosque_flutter/domain/entities/bitacora_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_check_in_out_adicional_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_check_in_out_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_empl_bosq_empl_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_semanal_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_semanal_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_x_empl_expandido_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hrs_entity.dart';
import 'package:bosque_flutter/data/models/resumen_asistencia_empleado_model.dart';
import 'package:bosque_flutter/domain/entities/resumen_asistencia_empleado_entity.dart';
import 'package:bosque_flutter/domain/repositories/biometrico_repository.dart';

/// `acc` (y `motivo`, para la bitácora) viajan como query param
/// (`?acc=I&motivo=...`) porque el backend los recibe por `@RequestParam`, no
/// en el body — `BaseApiRepository` no tiene un parámetro de query aparte,
/// así que se concatenan en el propio endpoint.
class BiometricoImpl extends BaseApiRepository implements BiometricoRepository {
  String _conAcc(String endpoint, String acc, {String? motivo}) {
    final buffer = StringBuffer('$endpoint?acc=${Uri.encodeQueryComponent(acc)}');
    if (motivo != null && motivo.trim().isNotEmpty) {
      buffer.write('&motivo=${Uri.encodeQueryComponent(motivo.trim())}');
    }
    return buffer.toString();
  }

  @override
  Future<List<BioCheckInOutEntity>> listarMarcaciones(
    Map<String, dynamic> filtro,
  ) async {
    final modelos = await postAndReturnList<BioCheckInOutModel>(
      endpoint: AppConstants.biometricoListarMarcaciones,
      data: filtro,
      fromJson: BioCheckInOutModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<String> importarMarcacionesMensual(DateTime checkTime) async {
    final resp = await postAndReturnFullResponse<Map<String, dynamic>>(
      endpoint: AppConstants.biometricoImportarMarcacionesMensual,
      data: {'checkTime': checkTime.toIso8601String()},
      fromJson: (json) => json,
      errorMessage: 'Error al importar las marcaciones del mes',
    );
    return (resp['data'] ?? '').toString();
  }

  @override
  Future<List<BioCheckInOutAdicionalEntity>> listarMarcacionesAdicionales(
    Map<String, dynamic> filtro,
  ) async {
    final modelos = await postAndReturnList<BioCheckInOutAdicionalModel>(
      endpoint: AppConstants.biometricoListarMarcacionesAdicionales,
      data: filtro,
      fromJson: BioCheckInOutAdicionalModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registrarMarcacionAdicional(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  }) => postAndReturnId(
    endpoint: _conAcc(
      AppConstants.biometricoRegistrarMarcacionAdicional,
      acc,
      motivo: motivo,
    ),
    data: payload,
    errorMessage: 'Error al registrar la marcación adicional',
  );

  @override
  Future<List<BioEmplBosqEmplEntity>> listarEmpleados(
    Map<String, dynamic> filtro,
  ) async {
    final modelos = await postAndReturnList<BioEmplBosqEmplModel>(
      endpoint: AppConstants.biometricoListarEmpleados,
      data: filtro,
      fromJson: BioEmplBosqEmplModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarEmpleado(Map<String, dynamic> payload, String acc) =>
      postAndReturnId(
        endpoint: _conAcc(AppConstants.biometricoRegistrarEmpleado, acc),
        data: payload,
        errorMessage: 'Error al registrar el cruce de empleado',
      );

  @override
  Future<List<BioHrsEntity>> listarHorarios(
    Map<String, dynamic> filtro,
  ) async {
    final modelos = await postAndReturnList<BioHrsModel>(
      endpoint: AppConstants.biometricoListarHorarios,
      data: filtro,
      fromJson: BioHrsModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registrarHorario(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  }) => postAndReturnId(
    endpoint: _conAcc(
      AppConstants.biometricoRegistrarHorario,
      acc,
      motivo: motivo,
    ),
    data: payload,
    errorMessage: 'Error al registrar el horario',
  );

  @override
  Future<List<BioHrSemanalEntity>> listarHorariosSemanales(
    Map<String, dynamic> filtro,
  ) async {
    final modelos = await postAndReturnList<BioHrSemanalModel>(
      endpoint: AppConstants.biometricoListarHorariosSemanales,
      data: filtro,
      fromJson: BioHrSemanalModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registrarHorarioSemanal(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  }) => postAndReturnId(
    endpoint: _conAcc(
      AppConstants.biometricoRegistrarHorarioSemanal,
      acc,
      motivo: motivo,
    ),
    data: payload,
    errorMessage: 'Error al registrar el horario semanal',
  );

  @override
  Future<List<BioHrSemanalDetalleEntity>> listarHorariosSemanalesDetalle(
    Map<String, dynamic> filtro,
  ) async {
    final modelos = await postAndReturnList<BioHrSemanalDetalleModel>(
      endpoint: AppConstants.biometricoListarHorariosSemanalesDetalle,
      data: filtro,
      fromJson: BioHrSemanalDetalleModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registrarHorarioSemanalDetalle(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  }) => postAndReturnId(
    endpoint: _conAcc(
      AppConstants.biometricoRegistrarHorarioSemanalDetalle,
      acc,
      motivo: motivo,
    ),
    data: payload,
    errorMessage: 'Error al registrar el detalle del horario semanal',
  );

  @override
  Future<List<BioHrEmpleadoEntity>> listarHorarioEmpleado(
    Map<String, dynamic> filtro,
  ) async {
    final modelos = await postAndReturnList<BioHrEmpleadoModel>(
      endpoint: AppConstants.biometricoListarHorarioEmpleado,
      data: filtro,
      fromJson: BioHrEmpleadoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registrarHorarioEmpleado(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  }) => postAndReturnId(
    endpoint: _conAcc(
      AppConstants.biometricoRegistrarHorarioEmpleado,
      acc,
      motivo: motivo,
    ),
    data: payload,
    errorMessage: 'Error al registrar el horario del empleado',
  );

  @override
  Future<List<BioHrXEmplExpandidoEntity>> listarCalendarioExpandido(
    Map<String, dynamic> filtro,
  ) async {
    final modelos = await postAndReturnList<BioHrXEmplExpandidoModel>(
      endpoint: AppConstants.biometricoListarCalendarioExpandido,
      data: filtro,
      fromJson: BioHrXEmplExpandidoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registrarCalendarioExpandido(
    Map<String, dynamic> payload,
    String acc,
  ) => postAndReturnId(
    endpoint: _conAcc(
      AppConstants.biometricoRegistrarCalendarioExpandido,
      acc,
    ),
    data: payload,
    errorMessage: 'Error al registrar el calendario expandido',
  );

  @override
  Future<void> regenerarCalendarioExpandido({
    required BigInt codEmpleado,
    required int anio,
    required int mes,
  }) => postAndReturnId(
    endpoint: AppConstants.biometricoRegenerarCalendarioExpandido,
    data: {'codEmpleado': codEmpleado.toInt(), 'anio': anio, 'mes': mes},
    errorMessage: 'Error al regenerar el calendario expandido',
  );

  @override
  Future<List<BitacoraEntity>> listarBitacora(
    Map<String, dynamic> filtro,
  ) async {
    final modelos = await postAndReturnList<BitacoraModel>(
      endpoint: AppConstants.biometricoListarBitacora,
      data: filtro,
      fromJson: BitacoraModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AsistenciaDiaEntity>> reporteMensual({
    required BigInt codEmpleado,
    required int anio,
    required int mes,
  }) async {
    final modelos = await postAndReturnList<AsistenciaDiaModel>(
      endpoint: AppConstants.biometricoReporteMensual,
      data: {'codEmpleado': codEmpleado.toInt(), 'anio': anio, 'mes': mes},
      fromJson: AsistenciaDiaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Uint8List> reporteMensualPdf({
    required BigInt codEmpleado,
    required int anio,
    required int mes,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.biometricoReporteMensualPdf,
    data: {'codEmpleado': codEmpleado.toInt(), 'anio': anio, 'mes': mes},
  );

  @override
  Future<List<ResumenAsistenciaEmpleadoEntity>> reporteMensualResumen({
    required int anio,
    required int mes,
  }) async {
    final modelos = await postAndReturnList<ResumenAsistenciaEmpleadoModel>(
      endpoint: AppConstants.biometricoReporteMensualResumen,
      data: {'anio': anio, 'mes': mes},
      fromJson: ResumenAsistenciaEmpleadoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Uint8List> reporteMensualResumenPdf({
    required int anio,
    required int mes,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.biometricoReporteMensualResumenPdf,
    data: {'anio': anio, 'mes': mes},
    // 400 empleados × varias consultas cada uno puede tardar más que el
    // timeout normal de 30s de BaseOptions — ver la nota de N+1 en
    // BiometricoController.calcularResumen.
    receiveTimeout: const Duration(seconds: 90),
  );

  @override
  Future<Uint8List> reporteMensualDetalladoTodosPdf({
    required int anio,
    required int mes,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.biometricoReporteMensualDetalladoTodosPdf,
    data: {'anio': anio, 'mes': mes},
    // Más pesado que reporteMensualResumenPdf: allá cada empleado es UNA
    // fila; acá cada empleado es un llenado Jasper completo (hasta 31 filas)
    // que hay que unir con los demás. Mismo cálculo N+1 en el backend, más
    // trabajo de Jasper encima — no probado aún contra el padrón completo,
    // así que el margen es generoso a propósito.
    receiveTimeout: const Duration(seconds: 180),
  );

  @override
  Future<Uint8List> horarioVigentePorEmpleadoPdf() => DioClient.descargarReportePdf(
    endpoint: AppConstants.biometricoHorarioVigentePorEmpleadoPdf,
    // Sin body — "ahora mismo" no toma anio/mes.
    // Más liviano que reporteMensualResumenPdf: por empleado sólo lee sus
    // asignaciones de horario, no marcaciones/permisos de todo un mes — pero
    // mismo paralelismo acotado (3 hilos) en el backend, así que se deja el
    // mismo margen por las dudas.
    receiveTimeout: const Duration(seconds: 90),
  );
}
