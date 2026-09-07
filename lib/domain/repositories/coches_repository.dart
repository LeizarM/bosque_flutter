// Destino final: lib/domain/repositories/coches_repository.dart
import 'package:bosque_flutter/domain/entities/coche_del_dia_entity.dart';

abstract class CochesRepository {
  Future<List<CocheDelDiaEntity>> listarDelDia({
    required int idTarRuti,
    required int idBitTarea,
  });

  /// true si esta marca dejó a todos los coches de la ocurrencia con
  /// respuesta (y por lo tanto cerró la tarea rutinaria completa).
  Future<bool> marcarLlegada({
    required int idCo,
    required int llego,
    String? obs,
  });
}
