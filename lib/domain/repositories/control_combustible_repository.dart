

import 'package:bosque_flutter/domain/entities/control_combustible_entity.dart';

abstract class ControlCombustibleRepository {
  
  Future<bool> createControlCombustible( CombustibleControlEntity data );

  Future<List<CombustibleControlEntity>> getCoches();
  
}