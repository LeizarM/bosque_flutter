import 'package:bosque_flutter/domain/entities/planilla_incapacidad_entity.dart';

abstract class PlanillaIncapacidadRepository {
  /// Bajas cuyo inicio cae en el rango. Antes de listar, el servidor carga las
  /// bajas nuevas que ya tienen planilla ejecutada.
  Future<List<PlanillaIncapacidadEntity>> listar({
    required DateTime desde,
    required DateTime hasta,
  });

  Future<void> marcarRevisado({required int idPIT, required bool revisado});
}
