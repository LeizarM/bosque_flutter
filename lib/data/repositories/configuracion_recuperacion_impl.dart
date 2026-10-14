import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/configuracion_recuperacion_model.dart';
import 'package:bosque_flutter/domain/entities/configuracion_recuperacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/configuracion_recuperacion_repository.dart';

class ConfiguracionRecuperacionImpl extends BaseApiRepository
    implements ConfiguracionRecuperacionRepository {
  @override
  Future<List<ConfiguracionRecuperacionEntity>> listar() {
    return postAndReturnList(
      endpoint: AppConstants.configuracionRecuperacionListar,
      fromJson: (json) => ConfiguracionRecuperacionModel.fromJson(json).toEntity(),
    );
  }

  @override
  Future<String> guardar({required String clave, required String valor}) {
    return postAndReturnFullResponse(
      endpoint: AppConstants.configuracionRecuperacionGuardar,
      data: {'clave': clave, 'valor': valor},
      fromJson: (raiz) => raiz['message'] as String? ?? '',
      errorMessage: 'No se pudo guardar el parámetro. Inténtalo de nuevo.',
    );
  }

  @override
  Future<String> probar(String correo) {
    return postAndReturnFullResponse(
      endpoint: AppConstants.configuracionRecuperacionProbar,
      data: {'correo': correo},
      fromJson: (raiz) => raiz['message'] as String? ?? '',
      errorMessage: 'No se pudo enviar el correo de prueba.',
    );
  }
}
