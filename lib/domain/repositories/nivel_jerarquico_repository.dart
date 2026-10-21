import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';

abstract class NivelJerarquicoRepository {
  /// Obtiene la lista completa de niveles jerárquicos
  Future<List<NivelJerarquicoEntity>> getNivelesJerarquicos();

  /// Todas las escalas (vigentes y anteriores), con cuántos cargos usan cada una.
  Future<List<NivelJerarquicoEntity>> listarEscalas();

  /// Alta si `codNivel` es 0 (también una nueva vigencia), edición si es mayor.
  Future<ResultadoEscrituraEntity> registrar(NivelJerarquicoEntity escala);

  Future<ResultadoEscrituraEntity> eliminar(int codNivel);
}
