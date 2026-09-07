// Destino final: lib/domain/repositories/tar_ru_x_cargo_repository.dart
import 'package:bosque_flutter/domain/entities/tar_ru_x_cargo_entity.dart';

abstract class TarRuXCargoRepository {
  Future<List<TarRuXCargoEntity>> obtener();
  Future<BigInt> registrar(TarRuXCargoEntity item);
  Future<void> eliminar(int idTarXCargo, int audUsuario);
}
