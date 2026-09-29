import 'dart:convert';
import 'package:bosque_flutter/domain/entities/grupo_fam_tipo_rango_gram_entity.dart';

GrupoFamTipoRangoGramModel grupoFamTipoRangoGramModelFromJson(String str) =>
    GrupoFamTipoRangoGramModel.fromJson(json.decode(str));

String grupoFamTipoRangoGramModelToJson(GrupoFamTipoRangoGramModel data) =>
    json.encode(data.toJson());

/// Espejo de la clase Java GrupoFamTipoRangoGram: exactamente las 5 columnas
/// de la tabla tpr_grupoFamTipoRangoGram, sin campos de despliegue.
///
/// No hay id: la tabla es un HEAP y la fila se identifica por la clave natural
/// (idGrpFamiliaSap, idTipo). Todas las columnas admiten NULL, por eso cada
/// lectura de fromJson lleva default defensivo.
class GrupoFamTipoRangoGramModel {
  int idGrpFamiliaSap;
  int idTipo;
  int idRangoGram;
  BigInt audUsuario;
  DateTime? audFecha;

  GrupoFamTipoRangoGramModel({
    required this.idGrpFamiliaSap,
    required this.idTipo,
    required this.idRangoGram,
    required this.audUsuario,
    this.audFecha,
  });

  factory GrupoFamTipoRangoGramModel.fromJson(Map<String, dynamic> json) =>
      GrupoFamTipoRangoGramModel(
        idGrpFamiliaSap: json["idGrpFamiliaSap"] ?? 0,
        idTipo: json["idTipo"] ?? 0,
        idRangoGram: json["idRangoGram"] ?? 0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        // tryParse sobre el texto: la columna es datetime NULL y segun la
        // configuracion de Jackson puede llegar como cadena ISO o como otro
        // formato. Si no se puede parsear queda null en vez de reventar.
        audFecha:
            json["audFecha"] != null
                ? DateTime.tryParse(json["audFecha"].toString())
                : null,
      );

  // audFecha no se envia: el SP de ABM ignora el valor recibido y siempre
  // estampa GETDATE(). Es un campo de solo lectura para la aplicacion.
  Map<String, dynamic> toJson() => {
    "idGrpFamiliaSap": idGrpFamiliaSap,
    "idTipo": idTipo,
    "idRangoGram": idRangoGram,
    "audUsuario": audUsuario.toInt(),
  };

  GrupoFamTipoRangoGramEntity toEntity() => GrupoFamTipoRangoGramEntity(
    idGrpFamiliaSap: idGrpFamiliaSap,
    idTipo: idTipo,
    idRangoGram: idRangoGram,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory GrupoFamTipoRangoGramModel.fromEntity(
    GrupoFamTipoRangoGramEntity e,
  ) => GrupoFamTipoRangoGramModel(
    idGrpFamiliaSap: e.idGrpFamiliaSap,
    idTipo: e.idTipo,
    idRangoGram: e.idRangoGram,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );
}
