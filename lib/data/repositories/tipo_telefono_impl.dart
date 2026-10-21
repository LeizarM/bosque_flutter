import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/resultado_escritura_model.dart';
import 'package:bosque_flutter/data/models/tipo_telefono_model.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';
import 'package:bosque_flutter/domain/repositories/tipo_telefono_repository.dart';

/// Tipos de teléfono contra el backend. Los textos de éxito y de error los
/// redacta `p_abm_TipoTelefono` y llegan tal cual.
class TipoTelefonoImpl extends BaseApiRepository
    implements TipoTelefonoRepository {
  @override
  Future<List<TipoTelefonoEntity>> listar() async {
    final modelos = await postAndReturnList<TipoTelefonoModel>(
      endpoint: AppConstants.tipoTelefonoListar,
      fromJson: TipoTelefonoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ResultadoEscrituraEntity> registrar(TipoTelefonoEntity tipo) =>
      _escribir(
        AppConstants.tipoTelefonoRegistrar,
        TipoTelefonoModel.fromEntity(tipo).toJson(),
      );

  @override
  Future<ResultadoEscrituraEntity> eliminar(int codTipoTel) =>
      _escribir(AppConstants.tipoTelefonoEliminar, {'id': codTipoTel});

  Future<ResultadoEscrituraEntity> _escribir(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final modelo = await postAndReturnFullResponse<ResultadoEscrituraModel>(
      endpoint: endpoint,
      data: data,
      fromJson: ResultadoEscrituraModel.fromJson,
    );
    return modelo.toEntity();
  }
}
