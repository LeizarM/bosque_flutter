// Destino final: lib/domain/repositories/arqueo_caja_repository.dart
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/vale_arqueo_entity.dart';

abstract class ArqueoCajaRepository {
  /// Devuelve el idAC del arqueo recién creado — lo necesita
  /// [reportePdf] para poder generar el comprobante apenas se cierra.
  Future<int> registrar({
    required int idTarRuti,
    required int idBitTarea,
    required double saldoMovSap,
    required double tc,
    String? obs,
    required Map<int, int> cantidadPorCorte,
    required Map<int, double> montoPorDoc,
    required List<ValeArqueoEntity> vales,
  });

  /// PDF de un arqueo ya registrado (RptArqueoDeCaja del legacy).
  Future<Uint8List> reportePdf(int idAC);
}
