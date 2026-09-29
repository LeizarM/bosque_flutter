import 'dart:convert';
import 'package:bosque_flutter/domain/entities/rango_gramaje_entity.dart';

RangoGramajeModel rangoGramajeModelFromJson(String str) =>
    RangoGramajeModel.fromJson(json.decode(str));

String rangoGramajeModelToJson(RangoGramajeModel data) =>
    json.encode(data.toJson());

/// Espeja las 5 columnas de tpr_RangoGramaje, ni una mas: el backend serializa
/// el POJO equivalente y manda cada campo como parametro de
/// p_abm_rangoGramaje, asi que un campo de despliegue extra hace fallar el
/// EXEC. La etiqueta armada "[ min - max ]" que devuelve el listado vive en el
/// DTO del backend, no aqui; en el cliente la arma la entity.
///
/// min y max son decimal(16,2) en la base y aqui van en double porque Dart no
/// tiene BigDecimal: alcanza para mostrar y comparar, pero el valor exacto lo
/// manda y lo guarda el backend.
class RangoGramajeModel {
  BigInt idRangoGram;
  double min;
  double max;
  BigInt audUsuario;
  DateTime? audFecha;

  RangoGramajeModel({
    required this.idRangoGram,
    required this.min,
    required this.max,
    required this.audUsuario,
    this.audFecha,
  });

  factory RangoGramajeModel.fromJson(Map<String, dynamic> json) =>
      RangoGramajeModel(
        idRangoGram:
            json["idRangoGram"] != null
                ? BigInt.from(json["idRangoGram"])
                : BigInt.zero,
        min: (json["min"] as num?)?.toDouble() ?? 0.0,
        max: (json["max"] as num?)?.toDouble() ?? 0.0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        // tryParse y no parse: la rama 'L' del listado puede no traer la
        // columna y algunos SP devuelven la fecha en formatos distintos.
        audFecha:
            json["audFecha"] != null
                ? DateTime.tryParse(json["audFecha"])
                : null,
      );

  // audFecha no se envia: es de solo lectura, el SP de ABM ignora lo que se le
  // mande y siempre estampa GETDATE().
  Map<String, dynamic> toJson() => {
    "idRangoGram": idRangoGram.toInt(),
    "min": min,
    "max": max,
    "audUsuario": audUsuario.toInt(),
  };

  RangoGramajeEntity toEntity() => RangoGramajeEntity(
    idRangoGram: idRangoGram,
    min: min,
    max: max,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory RangoGramajeModel.fromEntity(RangoGramajeEntity e) =>
      RangoGramajeModel(
        idRangoGram: e.idRangoGram,
        min: e.min,
        max: e.max,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}
