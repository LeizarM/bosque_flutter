import 'dart:convert';
import 'package:bosque_flutter/domain/entities/costo_sugerido_entity.dart';

CostoSugeridoModel costoSugeridoModelFromJson(String str) =>
    CostoSugeridoModel.fromJson(json.decode(str));

String costoSugeridoModelToJson(CostoSugeridoModel data) =>
    json.encode(data.toJson());

class CostoSugeridoModel {
  BigInt idCosSug;
  BigInt idPropuesta;
  int codigoFamilia;
  double costoSug;
  DateTime? fechaI;
  BigInt audUsuario;
  DateTime? audFecha;

  CostoSugeridoModel({
    required this.idCosSug,
    required this.idPropuesta,
    required this.codigoFamilia,
    required this.costoSug,
    this.fechaI,
    required this.audUsuario,
    this.audFecha,
  });

  factory CostoSugeridoModel.fromJson(Map<String, dynamic> json) =>
      CostoSugeridoModel(
        idCosSug:
            json["idCosSug"] != null
                ? BigInt.from(json["idCosSug"])
                : BigInt.zero,
        idPropuesta:
            json["idPropuesta"] != null
                ? BigInt.from(json["idPropuesta"])
                : BigInt.zero,
        codigoFamilia: json["codigoFamilia"] ?? 0,
        // float(53) en la base, BigDecimal en el backend: en Dart es double.
        costoSug: (json["costoSug"] as num?)?.toDouble() ?? 0.0,
        // Nulo real: la columna es datetime NULL y el listado la devuelve vacia
        // en las filas viejas.
        fechaI: json["fechaI"] != null ? DateTime.parse(json["fechaI"]) : null,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        audFecha:
            json["audFecha"] != null ? DateTime.parse(json["audFecha"]) : null,
      );

  // Van las 7 columnas de tpr_costoSug y ninguna mas: SpHelper.ejecutarAbm
  // serializa el POJO completo y manda cada campo como parametro de
  // p_abm_costoSug, asi que un campo de adorno (el nombre de la familia que
  // llega por JOIN, por ejemplo) haria fallar el EXEC.
  //
  // fechaI y audFecha son de escritura del servidor: en la accion I el
  // procedimiento las pisa con GETDATE() y audFecha tambien en la U. Se mandan
  // igual porque el procedimiento declara @fechaI y @audFecha, y porque la
  // accion U si respeta el fechaI que se envia.
  Map<String, dynamic> toJson() => {
    "idCosSug": idCosSug.toInt(),
    "idPropuesta": idPropuesta.toInt(),
    "codigoFamilia": codigoFamilia,
    "costoSug": costoSug,
    "fechaI": fechaI != null ? _fecha(fechaI!) : null,
    "audUsuario": audUsuario.toInt(),
    "audFecha": audFecha != null ? _fecha(audFecha!) : null,
  };

  static String _fecha(DateTime f) =>
      f.toIso8601String().substring(0, 19).replaceAll('T', ' ');

  CostoSugeridoEntity toEntity() => CostoSugeridoEntity(
    idCosSug: idCosSug,
    idPropuesta: idPropuesta,
    codigoFamilia: codigoFamilia,
    costoSug: costoSug,
    fechaI: fechaI,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory CostoSugeridoModel.fromEntity(CostoSugeridoEntity entity) =>
      CostoSugeridoModel(
        idCosSug: entity.idCosSug,
        idPropuesta: entity.idPropuesta,
        codigoFamilia: entity.codigoFamilia,
        costoSug: entity.costoSug,
        fechaI: entity.fechaI,
        audUsuario: entity.audUsuario,
        audFecha: entity.audFecha,
      );
}
