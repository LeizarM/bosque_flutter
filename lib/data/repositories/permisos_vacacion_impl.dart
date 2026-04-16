import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/permiso_model.dart';
import 'package:bosque_flutter/domain/entities/permiso_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_vacacion_repository.dart';

class PermisosVacacionImpl extends BaseApiRepository
    implements PermisosVacacionRepository {
  @override
  Future<PermisoEntity?> getResumenVacaciones(int codEmpleado) async {
    final modelos = await postAndReturnList<PermisoModel>(
      endpoint: AppConstants.vacDiasDisponibles,
      data: {'codEmpleado': codEmpleado},
      fromJson: (json) => PermisoModel.fromJson(json),
    );
    if (modelos.isNotEmpty) {
      return modelos.first.toEntity();
    }
    return null;
  }
}
