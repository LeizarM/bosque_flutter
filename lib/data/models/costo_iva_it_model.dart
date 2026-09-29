import 'dart:convert';
import 'package:bosque_flutter/domain/entities/costo_iva_it_entity.dart';

CostoIvaItModel costoIvaItModelFromJson(String str) =>
    CostoIvaItModel.fromJson(json.decode(str));

String costoIvaItModelToJson(CostoIvaItModel data) =>
    json.encode(data.toJson());

/// Mapea 1:1 la tabla dbo.tpr_costoIvaIt. Los seis campos son exactamente los
/// seis parametros de p_abm_costoIvaIt, asi que no se agrega ninguno mas: un
/// campo de mas es un EXEC que falla.
///
/// totalIvaIt NO esta aca a proposito: no es una columna, es
/// ISNULL(iva,0) + ISNULL(it,0) que el SP devuelve solo en la accion 'V'. Se
/// resuelve como getter derivado en la entity para que tambien exista en la
/// accion 'L'.
class CostoIvaItModel {
  int idCii;
  BigInt idPropuesta;
  double iva;
  double it;
  BigInt audUsuario;
  DateTime? audFecha;

  CostoIvaItModel({
    required this.idCii,
    required this.idPropuesta,
    required this.iva,
    required this.it,
    required this.audUsuario,
    this.audFecha,
  });

  factory CostoIvaItModel.fromJson(Map<String, dynamic> json) =>
      CostoIvaItModel(
        // La clave viaja como "idCII": es el nombre del campo del model Java.
        idCii: json["idCII"] ?? 0,
        // Hoy siempre llega null: la columna existe pero ningun SP la filtra.
        idPropuesta:
            json["idPropuesta"] != null
                ? BigInt.from(json["idPropuesta"])
                : BigInt.zero,
        // En el backend son BigDecimal (float(53) en la BD). Dart no tiene
        // BigDecimal, van en double y se pierde precision exacta.
        iva: (json["iva"] as num?)?.toDouble() ?? 0.0,
        it: (json["it"] as num?)?.toDouble() ?? 0.0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // Se mandan los seis campos del model Java, ni uno mas.
  // totalIvaIt no se envia: no existe como columna, lo calcula el SP para
  // mostrar y vive como getter derivado en la entity.
  // audFecha se envia igual: si va null, el SP graba GETDATE().
  Map<String, dynamic> toJson() => {
    "idCII": idCii,
    "idPropuesta": idPropuesta.toInt(),
    "iva": iva,
    "it": it,
    "audUsuario": audUsuario.toInt(),
    "audFecha": audFecha?.toIso8601String(),
  };

  CostoIvaItEntity toEntity() => CostoIvaItEntity(
    idCii: idCii,
    idPropuesta: idPropuesta,
    iva: iva,
    it: it,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory CostoIvaItModel.fromEntity(CostoIvaItEntity e) => CostoIvaItModel(
    idCii: e.idCii,
    idPropuesta: e.idPropuesta,
    iva: e.iva,
    it: e.it,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );
}
