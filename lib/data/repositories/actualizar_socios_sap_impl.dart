import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/actualizar_socios_sap_model.dart';
import 'package:bosque_flutter/domain/entities/actualizar_socios_sap_entity.dart';
import 'package:bosque_flutter/domain/repositories/actualizar_socios_sap_repository.dart';

/// «Actualizar datos SAP» contra el backend Spring.
///
/// `postAndReturnFullResponse` y no `postAndReturnId`: no hay id ni conteo que
/// leer (`data` viene nulo); lo util es el `message`, la frase ya redactada. Un
/// 400 o un 403 lanzan el `message` del servidor como texto, sin el prefijo
/// `Exception:`.
class ActualizarSociosSapImpl extends BaseApiRepository
    implements ActualizarSociosSapRepository {
  @override
  Future<ActualizarSociosSapEntity> actualizar() async {
    final modelo = await postAndReturnFullResponse<ActualizarSociosSapModel>(
      endpoint: AppConstants.chqActualizarClientesSap,
      // El endpoint no lee cuerpo; se manda un objeto vacio como todo POST de
      // la app.
      data: const <String, dynamic>{},
      fromJson: ActualizarSociosSapModel.fromJson,
      errorMessage: 'No se pudieron traer los clientes de SAP.',
    );
    return modelo.toEntity();
  }
}
