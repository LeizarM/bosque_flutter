import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_disponibles_entity.dart';

/// Cuántas preguntas válidas y distintas tiene una categoría (`p_list_tcpe_Lote` D).
class TcpeDisponiblesModel {
  final BigInt codClasificacion;
  final int disponibles;

  const TcpeDisponiblesModel({
    required this.codClasificacion,
    this.disponibles = 0,
  });

  factory TcpeDisponiblesModel.fromJson(Map<String, dynamic> json) => TcpeDisponiblesModel(
    codClasificacion: tcpeBigInt(json['codClasificacion']) ?? BigInt.zero,
    disponibles: tcpeInt(json['disponibles']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'codClasificacion': codClasificacion.toInt(),
    'disponibles': disponibles,
  };

  TcpeDisponiblesEntity toEntity() => TcpeDisponiblesEntity(
    codClasificacion: codClasificacion,
    disponibles: disponibles,
  );

  factory TcpeDisponiblesModel.fromEntity(TcpeDisponiblesEntity e) => TcpeDisponiblesModel(
    codClasificacion: e.codClasificacion,
    disponibles: e.disponibles,
  );
}
