import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/recuperacion_enviada_model.dart';
import 'package:bosque_flutter/domain/entities/recuperacion_enviada_entity.dart';
import 'package:bosque_flutter/domain/repositories/recuperacion_acceso_repository.dart';

class RecuperacionAccesoImpl extends BaseApiRepository
    implements RecuperacionAccesoRepository {
  @override
  Future<RecuperacionEnviadaEntity> solicitarCodigo(String login) {
    return postAndReturnFullResponse(
      endpoint: AppConstants.recuperacionSolicitarEndpoint,
      data: {'login': login},
      fromJson:
          (raiz) =>
              RecuperacionEnviadaModel.fromJson(
                raiz['data'] as Map<String, dynamic>,
              ).toEntity(),
      errorMessage:
          'No se pudo enviar el código. Espera un momento e inténtalo de nuevo.',
    );
  }

  @override
  Future<String> restablecer({
    required String login,
    required String codigo,
    required String nuevaContrasena,
  }) {
    return postAndReturnFullResponse(
      endpoint: AppConstants.recuperacionRestablecerEndpoint,
      data: {
        'login': login,
        'codigo': codigo,
        'nuevaContrasena': nuevaContrasena,
      },
      fromJson: (raiz) => raiz['message'] as String? ?? '',
      errorMessage:
          'No se pudo cambiar la contraseña. Espera un momento e inténtalo de nuevo.',
    );
  }
}
