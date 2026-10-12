// Destino final: lib/domain/repositories/coches_repository.dart
import 'package:bosque_flutter/domain/entities/coche_del_dia_entity.dart';

/// Revisar Autos sin ocurrencia (archivo SQL 96): la lista es de la sucursal
/// de quien inició sesión, y el backend la saca de su cargo vigente.
abstract class CochesRepository {
  Future<List<CocheDelDiaEntity>> listarDelDia();

  Future<void> marcarLlegada({
    required int idCo,
    required int llego,
    String? obs,
  });
}
