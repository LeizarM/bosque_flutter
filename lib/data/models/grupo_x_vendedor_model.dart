import 'dart:convert';
import 'package:bosque_flutter/domain/entities/grupo_x_vendedor_entity.dart';

GrupoXVendedorModel grupoXVendedorModelFromJson(String str) =>
    GrupoXVendedorModel.fromJson(json.decode(str));

String grupoXVendedorModelToJson(GrupoXVendedorModel data) =>
    json.encode(data.toJson());

class GrupoXVendedorModel {
  BigInt idGrpVen;
  BigInt idVendedor;
  BigInt idGrupo;
  int estado;
  int ignoraComision;
  DateTime fechaInicio;
  DateTime? fechaFinalizacion;
  BigInt audUsuario;

  String nomVenSap;
  String grupo;
  double porcentaje;
  double porcenComision;
  int esParaVenta;
  int esInterno;
  int vigente;

  GrupoXVendedorModel({
    required this.idGrpVen,
    required this.idVendedor,
    required this.idGrupo,
    required this.estado,
    required this.ignoraComision,
    required this.fechaInicio,
    this.fechaFinalizacion,
    required this.audUsuario,
    required this.nomVenSap,
    required this.grupo,
    required this.porcentaje,
    required this.porcenComision,
    required this.esParaVenta,
    required this.esInterno,
    required this.vigente,
  });

  factory GrupoXVendedorModel.fromJson(
    Map<String, dynamic> json,
  ) => GrupoXVendedorModel(
    idGrpVen:
        json["idGrpVen"] != null ? BigInt.from(json["idGrpVen"]) : BigInt.zero,
    idVendedor:
        json["idVendedor"] != null
            ? BigInt.from(json["idVendedor"])
            : BigInt.zero,
    idGrupo:
        json["idGrupo"] != null ? BigInt.from(json["idGrupo"]) : BigInt.zero,
    estado: json["estado"] ?? 0,
    ignoraComision: json["ignoraComision"] ?? 0,
    fechaInicio:
        json["fechaInicio"] != null
            ? DateTime.parse(json["fechaInicio"])
            : DateTime.now(),
    // Nulo real: una asignacion sin fecha de fin sigue vigente. Sustituirlo
    // por DateTime.now() la haria aparecer como cerrada hoy.
    fechaFinalizacion:
        json["fechaFinalizacion"] != null
            ? DateTime.parse(json["fechaFinalizacion"])
            : null,
    audUsuario:
        json["audUsuario"] != null
            ? BigInt.from(json["audUsuario"])
            : BigInt.zero,
    nomVenSap: json["nomVenSap"] ?? '',
    grupo: json["grupo"] ?? '',
    porcentaje: (json["porcentaje"] as num?)?.toDouble() ?? 0.0,
    porcenComision: (json["porcenComision"] as num?)?.toDouble() ?? 0.0,
    esParaVenta: json["esParaVenta"] ?? 0,
    esInterno: json["esInterno"] ?? 0,
    vigente: json["vigente"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "idGrpVen": idGrpVen.toInt(),
    "idVendedor": idVendedor.toInt(),
    "idGrupo": idGrupo.toInt(),
    "estado": estado,
    "ignoraComision": ignoraComision,
    "fechaInicio": _fecha(fechaInicio),
    "fechaFinalizacion":
        fechaFinalizacion != null ? _fecha(fechaFinalizacion!) : null,
    "audUsuario": audUsuario.toInt(),
  };

  static String _fecha(DateTime f) =>
      f.toIso8601String().substring(0, 19).replaceAll('T', ' ');

  GrupoXVendedorEntity toEntity() => GrupoXVendedorEntity(
    idGrpVen: idGrpVen,
    idVendedor: idVendedor,
    idGrupo: idGrupo,
    estado: estado,
    ignoraComision: ignoraComision,
    fechaInicio: fechaInicio,
    fechaFinalizacion: fechaFinalizacion,
    audUsuario: audUsuario,
    nomVenSap: nomVenSap,
    grupo: grupo,
    porcentaje: porcentaje,
    porcenComision: porcenComision,
    esParaVenta: esParaVenta,
    esInterno: esInterno,
    vigente: vigente,
  );

  factory GrupoXVendedorModel.fromEntity(GrupoXVendedorEntity entity) =>
      GrupoXVendedorModel(
        idGrpVen: entity.idGrpVen,
        idVendedor: entity.idVendedor,
        idGrupo: entity.idGrupo,
        estado: entity.estado,
        ignoraComision: entity.ignoraComision,
        fechaInicio: entity.fechaInicio,
        fechaFinalizacion: entity.fechaFinalizacion,
        audUsuario: entity.audUsuario,
        nomVenSap: entity.nomVenSap,
        grupo: entity.grupo,
        porcentaje: entity.porcentaje,
        porcenComision: entity.porcenComision,
        esParaVenta: entity.esParaVenta,
        esInterno: entity.esInterno,
        vigente: entity.vigente,
      );
}
