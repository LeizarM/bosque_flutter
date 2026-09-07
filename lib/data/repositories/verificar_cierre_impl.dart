// Destino final: lib/data/repositories/verificar_cierre_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/traspaso_mov_caja_model.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/verificar_cierre_repository.dart';

class VerificarCierreImpl extends BaseApiRepository implements VerificarCierreRepository {
  @override
  Future<List<Map<String, dynamic>>> obtenerArqueosDeHoy(
    int idBitTarea, {
    bool todasSucursales = false,
  }) {
    return postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarVerificarCierreArqueosDeHoy,
      data: {'idBitTarea': idBitTarea, 'todasSucursales': todasSucursales},
      fromJson: (json) => json,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerLlegadasDeHoy(
    int idBitTarea, {
    bool todasSucursales = false,
  }) {
    return postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarVerificarCierreLlegadasDeHoy,
      data: {'idBitTarea': idBitTarea, 'todasSucursales': todasSucursales},
      fromJson: (json) => json,
    );
  }

  @override
  Future<List<TraspasoMovCajaEntity>> obtenerTraspasosDeHoy() async {
    final hoy = DateTime.now();
    final modelos = await postAndReturnList<TraspasoMovCajaModel>(
      endpoint: AppConstants.tarObtenerTraspasoMovCaja,
      data: {'fecha': DateTime(hoy.year, hoy.month, hoy.day).toIso8601String()},
      fromJson: (json) => TraspasoMovCajaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> marcarArqueoRevisado(int idAC) async {
    await postAndReturnId(
      endpoint: AppConstants.tarVerificarCierreMarcarArqueoRevisado,
      data: {'idAC': idAC},
      errorMessage: 'No se pudo marcar el arqueo como revisado.',
    );
  }

  @override
  Future<void> marcarLlegadaVerificada(int idRp, int fueVerificado) async {
    await postAndReturnId(
      endpoint: AppConstants.tarVerificarCierreMarcarLlegadaVerificada,
      data: {'idRp': idRp, 'fueVerificado': fueVerificado},
      errorMessage: 'No se pudo marcar la llegada como verificada.',
    );
  }

  @override
  Future<int> confirmar(int idBitTarea) async {
    final resultado = await postAndReturnId(
      endpoint: AppConstants.tarVerificarCierreConfirmar,
      data: {'idBitTarea': idBitTarea},
      errorMessage: 'No se pudo confirmar la verificación.',
    );
    return resultado.toInt();
  }
}
