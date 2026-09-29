import 'dart:convert';
import 'package:bosque_flutter/domain/entities/porcentaje_precio_entity.dart';

PorcentajePrecioModel porcentajePrecioModelFromJson(String str) =>
    PorcentajePrecioModel.fromJson(json.decode(str));

String porcentajePrecioModelToJson(PorcentajePrecioModel data) =>
    json.encode(data.toJson());

class PorcentajePrecioModel {
  BigInt idPorcen;
  int codigoFamilia;
  BigInt idClasificacion;
  double porcen;
  BigInt audUsuario;
  DateTime? audFecha;

  PorcentajePrecioModel({
    required this.idPorcen,
    required this.codigoFamilia,
    required this.idClasificacion,
    required this.porcen,
    required this.audUsuario,
    this.audFecha,
  });

  factory PorcentajePrecioModel.fromJson(Map<String, dynamic> json) =>
      PorcentajePrecioModel(
        // 0 cuando la fila todavia no existe: el listado devuelve 0 o null en
        // las familias que aun no tienen porcentaje para esa lista.
        idPorcen:
            json["idPorcen"] != null
                ? BigInt.from(json["idPorcen"])
                : BigInt.zero,
        codigoFamilia: json["codigoFamilia"] ?? 0,
        idClasificacion:
            json["idClasificacion"] != null
                ? BigInt.from(json["idClasificacion"])
                : BigInt.zero,
        // Puntos porcentuales: 12.5 es 12,5%. En el backend es BigDecimal, aca
        // double, asi que hay que redondear antes de comparar.
        porcen: (json["porcen"] as num?)?.toDouble() ?? 0.0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        // Nulo real: las filas pendientes del listado nunca se grabaron.
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // audFecha no se envia: es de solo lectura, el procedimiento la pisa siempre
  // con GETDATE() tanto en el alta como en la modificacion.
  Map<String, dynamic> toJson() => {
    "idPorcen": idPorcen.toInt(),
    "codigoFamilia": codigoFamilia,
    "idClasificacion": idClasificacion.toInt(),
    "porcen": porcen,
    "audUsuario": audUsuario.toInt(),
  };

  PorcentajePrecioEntity toEntity() => PorcentajePrecioEntity(
    idPorcen: idPorcen,
    codigoFamilia: codigoFamilia,
    idClasificacion: idClasificacion,
    porcen: porcen,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory PorcentajePrecioModel.fromEntity(PorcentajePrecioEntity e) =>
      PorcentajePrecioModel(
        idPorcen: e.idPorcen,
        codigoFamilia: e.codigoFamilia,
        idClasificacion: e.idClasificacion,
        porcen: e.porcen,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}
