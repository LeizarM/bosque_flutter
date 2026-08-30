import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tipo_recibo_entity.dart';

TipoReciboModel tipoReciboModelFromJson(String str) =>
    TipoReciboModel.fromJson(json.decode(str));

String tipoReciboModelToJson(TipoReciboModel data) => json.encode(data.toJson());

BigInt _big(dynamic v) =>
    v == null ? BigInt.zero : BigInt.from((v as num).toInt());
DateTime? _fecha(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

class TipoReciboModel {
  BigInt codTipoRecibo;
  String nombre;
  String detalle;
  String estado;
  String sigla;
  BigInt audUsuario;
  DateTime? audFecha;
  String datoEstado;
  String datoTipo;
  int cantTalonarios;
  int cantGrupos;
  int ultimoFolio;

  TipoReciboModel({
    required this.codTipoRecibo,
    required this.nombre,
    required this.detalle,
    required this.estado,
    required this.sigla,
    required this.audUsuario,
    this.audFecha,
    this.datoEstado = '',
    this.datoTipo = '',
    this.cantTalonarios = 0,
    this.cantGrupos = 0,
    this.ultimoFolio = 0,
  });

  factory TipoReciboModel.fromJson(Map<String, dynamic> json) => TipoReciboModel(
    codTipoRecibo: _big(json["codTipoRecibo"]),
    nombre: json["nombre"] ?? '',
    detalle: json["detalle"] ?? '',
    estado: json["estado"] ?? '1',
    sigla: json["sigla"] ?? '',
    audUsuario: _big(json["audUsuario"]),
    audFecha: _fecha(json["audFecha"]),
    datoEstado: json["datoEstado"] ?? '',
    datoTipo: json["datoTipo"] ?? '',
    cantTalonarios: json["cantTalonarios"] ?? 0,
    cantGrupos: json["cantGrupos"] ?? 0,
    ultimoFolio: json["ultimoFolio"] ?? 0,
  );

  /// Solo los campos que el SP de ABM acepta.
  Map<String, dynamic> toJson() => {
    "codTipoRecibo": codTipoRecibo.toInt(),
    "nombre": nombre,
    "detalle": detalle,
    "estado": estado,
    "sigla": sigla,
    "audUsuario": audUsuario.toInt(),
  };

  TipoReciboEntity toEntity() => TipoReciboEntity(
    codTipoRecibo: codTipoRecibo,
    nombre: nombre,
    detalle: detalle,
    estado: estado,
    sigla: sigla,
    audUsuario: audUsuario,
    audFecha: audFecha,
    datoEstado: datoEstado,
    datoTipo: datoTipo,
    cantTalonarios: cantTalonarios,
    cantGrupos: cantGrupos,
    ultimoFolio: ultimoFolio,
  );

  factory TipoReciboModel.fromEntity(TipoReciboEntity e) => TipoReciboModel(
    codTipoRecibo: e.codTipoRecibo,
    nombre: e.nombre,
    detalle: e.detalle,
    estado: e.estado,
    sigla: e.sigla,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    datoEstado: e.datoEstado,
    datoTipo: e.datoTipo,
    cantTalonarios: e.cantTalonarios,
    cantGrupos: e.cantGrupos,
    ultimoFolio: e.ultimoFolio,
  );
}
