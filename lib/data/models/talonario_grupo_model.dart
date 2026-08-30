import 'dart:convert';
import 'package:bosque_flutter/domain/entities/talonario_grupo_entity.dart';

TalonarioGrupoModel talonarioGrupoModelFromJson(String str) =>
    TalonarioGrupoModel.fromJson(json.decode(str));

String talonarioGrupoModelToJson(TalonarioGrupoModel data) =>
    json.encode(data.toJson());

BigInt _big(dynamic v) =>
    v == null ? BigInt.zero : BigInt.from((v as num).toInt());
DateTime? _fecha(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

class TalonarioGrupoModel {
  BigInt codGrupo;
  String nombre;
  String detalle;
  BigInt audUsuario;
  DateTime? audFecha;
  int cantTipos;
  int cantTalonarios;

  TalonarioGrupoModel({
    required this.codGrupo,
    required this.nombre,
    required this.detalle,
    required this.audUsuario,
    this.audFecha,
    this.cantTipos = 0,
    this.cantTalonarios = 0,
  });

  factory TalonarioGrupoModel.fromJson(Map<String, dynamic> json) =>
      TalonarioGrupoModel(
        codGrupo: _big(json["codGrupo"]),
        nombre: json["nombre"] ?? '',
        detalle: json["detalle"] ?? '',
        audUsuario: _big(json["audUsuario"]),
        audFecha: _fecha(json["audFecha"]),
        cantTipos: json["cantTipos"] ?? 0,
        cantTalonarios: json["cantTalonarios"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "codGrupo": codGrupo.toInt(),
    "nombre": nombre,
    "detalle": detalle,
    "audUsuario": audUsuario.toInt(),
  };

  TalonarioGrupoEntity toEntity() => TalonarioGrupoEntity(
    codGrupo: codGrupo,
    nombre: nombre,
    detalle: detalle,
    audUsuario: audUsuario,
    audFecha: audFecha,
    cantTipos: cantTipos,
    cantTalonarios: cantTalonarios,
  );

  factory TalonarioGrupoModel.fromEntity(TalonarioGrupoEntity e) =>
      TalonarioGrupoModel(
        codGrupo: e.codGrupo,
        nombre: e.nombre,
        detalle: e.detalle,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        cantTipos: e.cantTipos,
        cantTalonarios: e.cantTalonarios,
      );
}
