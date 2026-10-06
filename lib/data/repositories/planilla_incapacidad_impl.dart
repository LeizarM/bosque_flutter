import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/planilla_incapacidad_model.dart';
import 'package:bosque_flutter/domain/entities/planilla_incapacidad_entity.dart';
import 'package:bosque_flutter/domain/repositories/planilla_incapacidad_repository.dart';

/// El usuario de auditoría lo toma el servidor del token: no se manda.
class PlanillaIncapacidadImpl extends BaseApiRepository
    implements PlanillaIncapacidadRepository {
  @override
  Future<List<PlanillaIncapacidadEntity>> listar({
    required DateTime desde,
    required DateTime hasta,
  }) => postAndReturnList(
    endpoint: AppConstants.planillaIncapacidadListar,
    data: {'desde': fechaParaSql(desde), 'hasta': fechaParaSql(hasta)},
    fromJson: (json) => PlanillaIncapacidadModel.fromJson(json).toEntity(),
  );

  @override
  Future<void> marcarRevisado({
    required int idPIT,
    required bool revisado,
  }) => postAndReturnId(
    endpoint: AppConstants.planillaIncapacidadRevisar,
    data: {'idPIT': idPIT, 'fueRevisado': revisado ? 1 : 0},
    errorMessage: 'No se pudo guardar la revisión',
  );
}
