// Destino final: lib/domain/repositories/arqueo_caja_repository.dart
import 'package:bosque_flutter/domain/entities/vale_arqueo_entity.dart';

abstract class ArqueoCajaRepository {
  Future<void> registrar({
    required int idTarRuti,
    required int idBitTarea,
    required double saldoMovSap,
    required double tc,
    String? obs,
    required Map<int, int> cantidadPorCorte,
    required Map<int, double> montoPorDoc,
    required List<ValeArqueoEntity> vales,
  });
}
