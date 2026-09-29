// Destino final: lib/data/repositories/traspaso_efectivo_tesbase_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/traspaso_efectivo_tesbase_model.dart';
import 'package:bosque_flutter/domain/entities/traspaso_efectivo_tesbase_entity.dart';
import 'package:bosque_flutter/domain/repositories/traspaso_efectivo_tesbase_repository.dart';

class TraspasoEfectivoTesBaseImpl extends BaseApiRepository
    implements TraspasoEfectivoTesBaseRepository {
  @override
  Future<DiaRevisadoTesBase> diaRevisado({required int idBitTarRuti}) async {
    const noSeSabe = 'No se pudo saber qué día revisa la tarea.';
    final modelo = await postAndReturnObject<DiaRevisadoTesBaseModel>(
      endpoint: AppConstants.tarTesBaseDiaRevisado,
      data: {'idBitTarRuti': idBitTarRuti},
      fromJson: DiaRevisadoTesBaseModel.fromJson,
      errorMessage: noSeSabe,
    );
    // Sin el día no hay qué mostrar: un 204 aquí es un error, no un vacío.
    final dia = modelo?.toEntity();
    if (dia == null) throw Exception(noSeSabe);
    return dia;
  }

  @override
  Future<List<TraspasoEfectivoTesBaseEntity>> delDia(DateTime fecha) async {
    final modelos = await postAndReturnList<TraspasoEfectivoTesBaseModel>(
      endpoint: AppConstants.tarTesBaseDelDia,
      data: {'fecha': fechaParaSql(fecha)},
      fromJson: TraspasoEfectivoTesBaseModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<TraspasoEfectivoTesBaseEntity>> pendientes() async {
    final modelos = await postAndReturnList<TraspasoEfectivoTesBaseModel>(
      endpoint: AppConstants.tarTesBasePendientes,
      fromJson: TraspasoEfectivoTesBaseModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> cerrar({required int codTes, required int idBitTarRuti}) async {
    await postAndReturnId(
      endpoint: AppConstants.tarTesBaseCerrar,
      data: {'codTes': codTes, 'idBitTarRuti': idBitTarRuti},
      errorMessage: 'No se pudo cerrar la transferencia.',
    );
  }

  @override
  Future<void> sinPendientes({required int idBitTarRuti}) async {
    await postAndReturnId(
      endpoint: AppConstants.tarTesBaseSinPendientes,
      data: {'idBitTarRuti': idBitTarRuti},
      errorMessage: 'No se pudo dar el día por revisado.',
    );
  }
}
