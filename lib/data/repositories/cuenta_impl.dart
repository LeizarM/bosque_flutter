import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/resultado_escritura_model.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/repositories/cuenta_repository.dart';

class CuentaImpl extends BaseApiRepository implements CuentaRepository {
  @override
  Future<ResultadoEscrituraEntity> cambiarClave({
    required String actual,
    required String nueva,
    required String confirmacion,
  }) async {
    final m = await postAndReturnFullResponse<ResultadoEscrituraModel>(
      endpoint: AppConstants.cuentaCambiarClave,
      data: {'actual': actual, 'nueva': nueva, 'confirmacion': confirmacion},
      fromJson: ResultadoEscrituraModel.fromJson,
      errorMessage: 'No se pudo cambiar la contraseña.',
    );
    return m.toEntity();
  }
}
