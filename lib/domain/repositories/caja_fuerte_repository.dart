// Destino final: lib/domain/repositories/caja_fuerte_repository.dart
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/llegada_caja_fuerte_entity.dart';

/// Caja Fuerte sin ocurrencia (archivo SQL 96): el backend saca la sucursal
/// del cargo vigente de quien inició sesión.
abstract class CajaFuerteRepository {
  /// Devuelve la cantidad de llegadas registradas (>0 filtra las de
  /// importe<=0, igual que el SP).
  Future<int> registrar({required List<LlegadaCajaFuerteEntity> llegadas});

  /// Lo que ya quedó registrado HOY en tu sucursal.
  ///
  /// Devuelve [LlegadaDelCierre], la misma entidad del panel del supervisor:
  /// son las mismas filas de `tac_llegada` leídas con la misma rama del SP, y
  /// duplicar el modelo solo serviría para que se desincronicen.
  Future<List<LlegadaDelCierre>> registradasHoy();
}
