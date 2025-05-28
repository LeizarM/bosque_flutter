

import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';

abstract class ControlCombustibleMaquinaMontacargaRepository {
  
  Future<bool> registerControlCombustibleMaquinaMontacarga( ControlCombustibleMaquinaMontacargaEntity mb );

  Future<List<ControlCombustibleMaquinaMontacargaEntity>> obtenerAlmacenes();

}