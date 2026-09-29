import 'dart:convert';
import 'package:bosque_flutter/domain/entities/costo_incremento_entity.dart';

CostoIncrementoModel costoIncrementoModelFromJson(String str) =>
    CostoIncrementoModel.fromJson(json.decode(str));

String costoIncrementoModelToJson(CostoIncrementoModel data) =>
    json.encode(data.toJson());

class CostoIncrementoModel {
  BigInt idIncre;
  BigInt codSucursal;
  BigInt idPropuesta;

  /// Dinero. En el backend es BigDecimal; Dart no lo tiene, va como double.
  double valor;

  BigInt audUsuario;
  DateTime? audFecha;

  CostoIncrementoModel({
    required this.idIncre,
    required this.codSucursal,
    required this.idPropuesta,
    required this.valor,
    required this.audUsuario,
    this.audFecha,
  });

  factory CostoIncrementoModel.fromJson(
    Map<String, dynamic> json,
  ) => CostoIncrementoModel(
    idIncre:
        json["idIncre"] != null ? BigInt.from(json["idIncre"]) : BigInt.zero,
    codSucursal:
        json["codSucursal"] != null
            ? BigInt.from(json["codSucursal"])
            : BigInt.zero,
    // La rama 'L' del listado legacy manda esta columna al final del SELECT
    // y puede no venir: por eso el default en cero.
    idPropuesta:
        json["idPropuesta"] != null
            ? BigInt.from(json["idPropuesta"])
            : BigInt.zero,
    valor: (json["valor"] as num?)?.toDouble() ?? 0.0,
    audUsuario:
        json["audUsuario"] != null
            ? BigInt.from(json["audUsuario"])
            : BigInt.zero,
    audFecha:
        json["audFecha"] != null ? DateTime.tryParse(json["audFecha"]) : null,
  );

  // audFecha no se envia: la escribe el propio SP con GETDATE() en 'I' y 'U'.
  // Es de solo lectura, solo se recibe en el listado.
  Map<String, dynamic> toJson() => {
    "idIncre": idIncre.toInt(),
    "codSucursal": codSucursal.toInt(),
    "idPropuesta": idPropuesta.toInt(),
    "valor": valor,
    "audUsuario": audUsuario.toInt(),
  };

  CostoIncrementoEntity toEntity() => CostoIncrementoEntity(
    idIncre: idIncre,
    codSucursal: codSucursal,
    idPropuesta: idPropuesta,
    valor: valor,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory CostoIncrementoModel.fromEntity(CostoIncrementoEntity e) =>
      CostoIncrementoModel(
        idIncre: e.idIncre,
        codSucursal: e.codSucursal,
        idPropuesta: e.idPropuesta,
        valor: e.valor,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}
