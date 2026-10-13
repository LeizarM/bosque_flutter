// Destino final: lib/domain/repositories/coche_repository.dart
import 'package:bosque_flutter/domain/entities/coche_entity.dart';

abstract class CocheRepository {
  /// Sin criterios devuelve todos. [estado] 0 filtra solo los inactivos: el
  /// backend arma el filtro a mano (`CocheDao.listarGestion`) justamente para
  /// que ese 0 no se descarte.
  Future<List<CocheEntity>> obtener({int? codSucursal, int? estado});

  /// Alta si `idCoche == 0`, edición si no. Devuelve el id.
  Future<BigInt> registrar(CocheEntity item);

  /// Falla con el motivo del backend si el coche ya tiene movimiento
  /// (kilometraje): en ese caso corresponde darlo de baja con `estado = 0`.
  Future<void> eliminar(int idCoche, int audUsuario);
}
