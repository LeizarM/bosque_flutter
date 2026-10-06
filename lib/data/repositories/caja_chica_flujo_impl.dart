// Destino final: lib/data/repositories/caja_chica_flujo_impl.dart
import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/caja_chica_model.dart';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:bosque_flutter/domain/repositories/caja_chica_flujo_repository.dart';

/// Tope de espera solo para el PDF (RptCajaChica, sin subreportes — el más
/// liviano de los reportes de Tareas Rutinarias). El default de 30 s de
/// `BaseOptions` alcanza casi siempre, pero Jasper arma el documento entero
/// antes de mandar el primer byte — con un lote grande puede tardar más.
/// Mismo criterio que `_esperaReporteLocal` de `talonarios_impl.dart`.
const Duration _esperaReporteCajaChica = Duration(minutes: 1);

class CajaChicaFlujoImpl extends BaseApiRepository
    implements CajaChicaFlujoRepository {
  @override
  Future<List<CajaChicaEntity>> listarDelLote({required int idBitTarea}) async {
    final modelos = await postAndReturnList<CajaChicaModel>(
      endpoint: AppConstants.tarCajaChicaListarDelLote,
      data: {'idBitTarea': idBitTarea},
      fromJson: (json) => CajaChicaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> registrarEgreso({
    required int idBitTarea,
    required double montoEg,
    required String descripcion,
    required int codEmpDestino,
    int? numFactura,
    int? numVale,
    String moneda = 'BS',
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.tarCajaChicaRegistrarEgreso,
      data: {
        'idBitTarea': idBitTarea,
        'montoEg': montoEg,
        'descripcion': descripcion,
        'codEmpDestino': codEmpDestino,
        'numFactura': numFactura,
        'numVale': numVale,
        'moneda': moneda,
      },
      errorMessage: 'No se pudo registrar el egreso.',
    );
  }

  @override
  Future<void> cerrarLote(int idBitTarea) async {
    await postAndReturnId(
      endpoint: AppConstants.tarCajaChicaCerrarLote,
      data: {'idBitTarea': idBitTarea},
      errorMessage: 'No se pudo cerrar el lote de caja chica.',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerHistorialLotes(int idBitTarea) {
    return postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarCajaChicaHistorialLotes,
      data: {'idBitTarea': idBitTarea},
      fromJson: (json) => json,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> buscarEmpleados(String texto) {
    return postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarCajaChicaBuscarEmpleados,
      data: {'search': texto},
      fromJson: (json) => json,
    );
  }

  @override
  Future<Uint8List> generarReportePdf({
    required int lote,
    required int codSucursal,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.tarCajaChicaReportePdf,
    receiveTimeout: _esperaReporteCajaChica,
    data: {'lote': lote, 'codSucursal': codSucursal},
  );
}
