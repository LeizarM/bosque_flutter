import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/agenda_empleado_model.dart';
import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';
import 'package:bosque_flutter/domain/repositories/agenda_repository.dart';

class AgendaImpl extends BaseApiRepository implements AgendaRepository {
  @override
  Future<List<AgendaEmpleadoEntity>> empleados() async {
    final m = await postAndReturnList<AgendaEmpleadoModel>(
      endpoint: AppConstants.agendaEmpleados,
      fromJson: AgendaEmpleadoModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }
}
