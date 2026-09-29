// Destino final: lib/data/repositories/cierre_operaciones_impl.dart
import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/bitacora_tareas_model.dart';
import 'package:bosque_flutter/data/models/cierre_operaciones_model.dart';
import 'package:bosque_flutter/data/models/traspaso_mov_caja_model.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/cierre_operaciones_repository.dart';

class CierreOperacionesImpl extends BaseApiRepository
    implements CierreOperacionesRepository {
  Map<String, dynamic> _delDia(int idBitTarea, DateTime fecha, bool todas) => {
    'idBitTarea': idBitTarea,
    'fecha': fechaParaSql(fecha),
    'todasSucursales': todas,
  };

  @override
  Future<List<ArqueoDelCierre>> arqueos(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) => postAndReturnList(
    endpoint: AppConstants.tarVerificarCierreArqueosDeHoy,
    data: _delDia(idBitTarea, fecha, todasSucursales),
    fromJson: CierreOperacionesModel.arqueo,
  );

  @override
  Future<List<TraspasoMovCajaEntity>> traspasos({
    required DateTime fecha,
  }) async {
    final modelos = await postAndReturnList<TraspasoMovCajaModel>(
      endpoint: AppConstants.tarTraspasoEntreSistemasDelDia,
      data: {'fecha': fechaParaSql(fecha)},
      fromJson: TraspasoMovCajaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<LlegadaDelCierre>> cajaFuerte(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) => postAndReturnList(
    endpoint: AppConstants.tarVerificarCierreLlegadasDeHoy,
    data: _delDia(idBitTarea, fecha, todasSucursales),
    fromJson: CierreOperacionesModel.llegada,
  );

  @override
  Future<List<ChequeDelCierre>> cheques(
    int idBitTarea, {
    required DateTime fecha,
  }) => postAndReturnList(
    endpoint: AppConstants.tarCierreOperacionesCheques,
    data: {'idBitTarea': idBitTarea, 'fecha': fechaParaSql(fecha)},
    fromJson: CierreOperacionesModel.cheque,
  );

  @override
  Future<List<BitacoraCumplimientoEntity>> tareas(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) => postAndReturnList(
    endpoint: AppConstants.tarCierreOperacionesTareasDelDia,
    data: _delDia(idBitTarea, fecha, todasSucursales),
    fromJson: BitacoraTareasModel.cumplimiento,
  );

  @override
  Future<void> marcarArqueoRevisado(int idAC, {required int idBitTarea}) async {
    await postAndReturnId(
      endpoint: AppConstants.tarVerificarCierreMarcarArqueoRevisado,
      // La ocurrencia viaja porque es el permiso: el servidor comprueba que
      // quien marca tenga la tarea de revisión de ese día.
      data: {'idAC': idAC, 'idBitTarea': idBitTarea},
      errorMessage: 'No se pudo marcar el arqueo como revisado.',
    );
  }

  @override
  Future<void> marcarLlegadaVerificada(
    int idRp, {
    required int idBitTarea,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.tarVerificarCierreMarcarLlegadaVerificada,
      data: {'idRp': idRp, 'fueVerificado': 1, 'idBitTarea': idBitTarea},
      errorMessage: 'No se pudo marcar la llegada como verificada.',
    );
  }

  @override
  Future<int> cerrar(
    int idBitTarea, {
    required ModoCierre modo,
    required DateTime fecha,
  }) async {
    final resultado = switch (modo) {
      ModoCierre.cierre => await postAndReturnId(
        endpoint: AppConstants.tarCierreOperacionesConfirmar,
        data: {'idBitTarea': idBitTarea, 'fecha': fechaParaSql(fecha)},
        errorMessage: 'No se pudo cerrar el Cierre de Operaciones.',
      ),
      // El servidor cierra las ocurrencias del día de la ocurrencia: la fecha
      // no viaja.
      ModoCierre.verificacion => await postAndReturnId(
        endpoint: AppConstants.tarVerificarCierreConfirmar,
        data: {'idBitTarea': idBitTarea},
        errorMessage: 'No se pudo cerrar la verificación del cierre.',
      ),
    };
    return resultado.toInt();
  }

  @override
  Future<Uint8List> pdfCierre(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.tarVerificarCierreReporteCierreOperacionesPdf,
    data: _delDia(idBitTarea, fecha, todasSucursales),
  );

  @override
  Future<Uint8List> pdfCajaFuerte(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.tarVerificarCierreReporteCajaFuertePdf,
    data: _delDia(idBitTarea, fecha, todasSucursales),
  );

  @override
  Future<Uint8List> pdfArqueo(int idAC) => DioClient.descargarReportePdf(
    endpoint: AppConstants.tarArqueoCajaReportePdf,
    data: {'idAC': idAC},
  );
}
