// Destino final: lib/data/repositories/traspaso_mov_caja_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/traspaso_mov_caja_model.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/traspaso_mov_caja_repository.dart';

class TraspasoMovCajaImpl extends BaseApiRepository
    implements TraspasoMovCajaRepository {
  @override
  Future<List<TraspasoMovCajaEntity>> obtener() async {
    final modelos = await postAndReturnList<TraspasoMovCajaModel>(
      endpoint: AppConstants.tarObtenerTraspasoMovCaja,
      fromJson: (json) => TraspasoMovCajaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(TraspasoMovCajaEntity item) async {
    final model = TraspasoMovCajaModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarTraspasoMovCaja,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el traspaso de movimiento de caja.',
    );
  }

  @override
  Future<void> eliminar(int idTrasp, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarTraspasoMovCaja,
      data: {'idTrasp': idTrasp, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar el traspaso de movimiento de caja.',
    );
  }

  // ===== Tarea 289 "Verificar Traspaso de Efectivo Entre Sistemas" =====

  @override
  Future<List<TraspasoMovCajaEntity>> obtenerDelDia(DateTime fecha) async {
    final modelos = await postAndReturnList<TraspasoMovCajaModel>(
      endpoint: AppConstants.tarTraspasoEntreSistemasDelDia,
      data: {'fecha': fecha.toIso8601String().substring(0, 10)},
      fromJson: (json) => TraspasoMovCajaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> verificar({
    required int idBitTarRuti,
    required TraspasoMovCajaEntity fila,
    required bool cuadra,
    String? obs,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.tarTraspasoEntreSistemasVerificar,
      data: {
        'idBitTarRuti': idBitTarRuti,
        // 0 = la fila todavia no existe en Bosque; el servidor la inserta.
        'idTrasp': fila.idTrasp,
        'bd': fila.bd,
        'fecha': fila.fecha?.toIso8601String().substring(0, 10),
        'account': fila.account,
        'contraAct': fila.contraAct,
        'acctName': fila.acctName,
        'tipoTransaccion': fila.tipoTransaccion,
        'dolares': fila.dolares,
        'bs': fila.bs,
        'fueVerificado': cuadra ? 1 : 0,
        'obs': obs,
      },
      errorMessage: 'No se pudo guardar la verificacion del traspaso.',
    );
  }

  @override
  Future<void> sinNovedad({
    required int idBitTarRuti,
    required DateTime fecha,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.tarTraspasoEntreSistemasSinNovedad,
      data: {
        'idBitTarRuti': idBitTarRuti,
        'fecha': fecha.toIso8601String().substring(0, 10),
      },
      errorMessage: 'No se pudo cerrar el dia como sin novedad.',
    );
  }
}
