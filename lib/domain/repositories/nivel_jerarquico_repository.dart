import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';

abstract class NivelJerarquicoRepository {
  /// Obtiene la lista completa de niveles jerárquicos
  Future<List<NivelJerarquicoEntity>> getNivelesJerarquicos();
}
