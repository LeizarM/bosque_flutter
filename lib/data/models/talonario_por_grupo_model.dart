import 'dart:convert';
import 'package:bosque_flutter/domain/entities/talonario_por_grupo_entity.dart';

TalonarioPorGrupoModel talonarioPorGrupoModelFromJson(String str) =>
    TalonarioPorGrupoModel.fromJson(json.decode(str));

String talonarioPorGrupoModelToJson(TalonarioPorGrupoModel data) =>
    json.encode(data.toJson());

BigInt _big(dynamic v) =>
    v == null ? BigInt.zero : BigInt.from((v as num).toInt());
DateTime? _fecha(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

class TalonarioPorGrupoModel {
  BigInt codGrupo;
  BigInt codTipoRecibo;
  BigInt audUsuario;
  DateTime? audFecha;
  String datoGrupo;
  String datoTipoNombre;
  String sigla;
  String datoTipo;

  TalonarioPorGrupoModel({
    required this.codGrupo,
    required this.codTipoRecibo,
    required this.audUsuario,
    this.audFecha,
    this.datoGrupo = '',
    this.datoTipoNombre = '',
    this.sigla = '',
    this.datoTipo = '',
  });

  factory TalonarioPorGrupoModel.fromJson(Map<String, dynamic> json) =>
      TalonarioPorGrupoModel(
        codGrupo: _big(json["codGrupo"]),
        codTipoRecibo: _big(json["codTipoRecibo"]),
        audUsuario: _big(json["audUsuario"]),
        audFecha: _fecha(json["audFecha"]),
        datoGrupo: json["datoGrupo"] ?? '',
        datoTipoNombre: json["datoTipoNombre"] ?? '',
        sigla: json["sigla"] ?? '',
        datoTipo: json["datoTipo"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "codGrupo": codGrupo.toInt(),
    "codTipoRecibo": codTipoRecibo.toInt(),
    "audUsuario": audUsuario.toInt(),
  };

  TalonarioPorGrupoEntity toEntity() => TalonarioPorGrupoEntity(
    codGrupo: codGrupo,
    codTipoRecibo: codTipoRecibo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    datoGrupo: datoGrupo,
    datoTipoNombre: datoTipoNombre,
    sigla: sigla,
    datoTipo: datoTipo,
  );

  factory TalonarioPorGrupoModel.fromEntity(TalonarioPorGrupoEntity e) =>
      TalonarioPorGrupoModel(
        codGrupo: e.codGrupo,
        codTipoRecibo: e.codTipoRecibo,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        datoGrupo: e.datoGrupo,
        datoTipoNombre: e.datoTipoNombre,
        sigla: e.sigla,
        datoTipo: e.datoTipo,
      );
}
