import 'dart:convert';

import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';

ControlCombustibleMaquinaMontacargaModel
controlCombustibleMaquinaMontacargaModelFromJson(String str) =>
    ControlCombustibleMaquinaMontacargaModel.fromJson(json.decode(str));

String controlCombustibleMaquinaMontacargaModelToJson(
  ControlCombustibleMaquinaMontacargaModel data,
) => json.encode(data.toJson());

class ControlCombustibleMaquinaMontacargaModel {
  final int idCM;
  final int idMaquinaVehiculoOrigen;
  final int idMaquinaVehiculoDestino;
  final int codSucursalMaqVehiOrigen;
  final int codSucursalMaqVehiDestino;
  final String codigoOrigen;
  final String codigoDestino;
  final DateTime fecha;
  final double litrosIngreso;
  final double litrosSalida;
  final double saldoLitros;
  final int codEmpleado;
  final String codAlmacen;
  final String obs;
  final String tipoTransaccion;
  final int audUsuario;
  final String whsCode;
  final String whsName;
  final String maquina;
  final String nombreCompleto;
  final String nombreMaquinaOrigen;
  final String nombreMaquinaDestino;
  final String nombreSucursal;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  

  ControlCombustibleMaquinaMontacargaModel({
    required this.idCM,
    required this.idMaquinaVehiculoOrigen,
    required this.idMaquinaVehiculoDestino,
    required this.codSucursalMaqVehiOrigen,
    required this.codSucursalMaqVehiDestino,
    required this.codigoOrigen,
    required this.codigoDestino,
    required this.fecha,
    required this.litrosIngreso,
    required this.litrosSalida,
    required this.saldoLitros,
    required this.codEmpleado,
    required this.codAlmacen,
    required this.obs,
    required this.tipoTransaccion,
    required this.audUsuario,
    required this.whsCode,
    required this.whsName,
    required this.maquina,
    required this.nombreCompleto,
    required this.nombreMaquinaOrigen,
    required this.nombreMaquinaDestino,
    required this.nombreSucursal,
    required this.fechaInicio,
    required this.fechaFin,
    
  });

  factory ControlCombustibleMaquinaMontacargaModel.fromJson(
    Map<String, dynamic> json,
  ) => ControlCombustibleMaquinaMontacargaModel(
    idCM: json["idCM"] ?? 0,
    idMaquinaVehiculoOrigen: json["idMaquinaVehiculoOrigen"] ?? 0,
    idMaquinaVehiculoDestino: json["idMaquinaVehiculoDestino"] ?? 0,
    codSucursalMaqVehiOrigen: json["codSucursalMaqVehiOrigen"] ?? 0,
    codSucursalMaqVehiDestino: json["codSucursalMaqVehiDestino"] ?? 0,
    codigoOrigen: json["codigoOrigen"] ?? '',
    codigoDestino: json["codigoDestino"] ?? '',
    fecha: json["fecha"] != null && json["fecha"] != '' ? DateTime.parse(json["fecha"]) : DateTime.now(),
    litrosIngreso: json["litrosIngreso"]?.toDouble() ?? 0.0,
    litrosSalida: json["litrosSalida"]?.toDouble() ?? 0.0  ,
    saldoLitros: json["saldoLitros"]?.toDouble() ?? 0.0,
    codEmpleado: json["codEmpleado"] ?? 0,
    codAlmacen: json["codAlmacen"] ?? '',
    obs: json["obs"] ?? '',
    tipoTransaccion: json["tipoTransaccion"] ?? '',
    audUsuario: json["audUsuario"] ?? 0,
    whsCode: json["whsCode"] ?? '',
    whsName: json["whsName"] ?? '',
    maquina: json["maquina"] ?? '',
    nombreCompleto: json["nombreCompleto"] ?? '',
    nombreMaquinaOrigen: json["nombreMaquinaOrigen"] ?? '',
    nombreMaquinaDestino: json["nombreMaquinaDestino"] ?? '',
    nombreSucursal: json["nombreSucursal"] ?? '',
    fechaInicio: json["fechaInicio"] != null && json["fechaInicio"] != '' ? DateTime.parse(json["fechaInicio"]) : DateTime.now(),
    fechaFin: json["fechaFin"] != null && json["fechaFin"] != '' ? DateTime.parse(json["fechaFin"]) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    "idMaquinaVehiculoOrigen": idMaquinaVehiculoOrigen,
    "idMaquinaVehiculoDestino": idMaquinaVehiculoDestino == 0 ? null : idMaquinaVehiculoDestino,
    "codSucursalMaqVehiOrigen": codSucursalMaqVehiOrigen == 0 ? null : codSucursalMaqVehiOrigen,
    "codSucursalMaqVehiDestino": codSucursalMaqVehiDestino == 0 ? null : codSucursalMaqVehiDestino,
    "codigoOrigen": codigoOrigen.isEmpty ? null : codigoOrigen,
    "codigoDestino": codigoDestino.isEmpty ? null : codigoDestino,
    "fecha": fecha.toIso8601String(),
    "litrosIngreso": litrosIngreso,
    "litrosSalida": litrosSalida,
    "codEmpleado": codEmpleado,
    "codAlmacen": codAlmacen,
    "obs": obs,
    "audUsuario": audUsuario,
    "tipoTransaccion": tipoTransaccion.isEmpty ? null : tipoTransaccion,
    "whsCode": whsCode.isEmpty ? null : whsCode,
    "whsName": whsName.isEmpty ? null : whsName,
    "maquina": maquina.isEmpty ? null : maquina,
    "nombreCompleto": nombreCompleto.isEmpty ? null : nombreCompleto,
    "nombreMaquinaOrigen": nombreMaquinaOrigen.isEmpty ? null : nombreMaquinaOrigen,
    "nombreMaquinaDestino": nombreMaquinaDestino.isEmpty ? null : nombreMaquinaDestino,
    "nombreSucursal": nombreSucursal.isEmpty ? null : nombreSucursal,
    "fechaInicio": fechaInicio.toIso8601String(),
    "fechaFin": fechaFin.toIso8601String(),
  };

  // Método para convertir de Model a Entity
  ControlCombustibleMaquinaMontacargaEntity toEntity() =>
      ControlCombustibleMaquinaMontacargaEntity(
        idCM: idCM,
        idMaquinaVehiculoOrigen: idMaquinaVehiculoOrigen,
        idMaquinaVehiculoDestino: idMaquinaVehiculoDestino,
        codSucursalMaqVehiOrigen: codSucursalMaqVehiOrigen,
        codSucursalMaqVehiDestino: codSucursalMaqVehiDestino,
        codigoOrigen: codigoOrigen,
        codigoDestino: codigoDestino,
        fecha: fecha,
        litrosIngreso: litrosIngreso,
        litrosSalida: litrosSalida,
        saldoLitros: saldoLitros,
        codEmpleado: codEmpleado,
        codAlmacen: codAlmacen,
        obs: obs,
        tipoTransaccion: tipoTransaccion,
        audUsuario: audUsuario,
        whsCode: whsCode,
        whsName: whsName,
        maquina: maquina,
        nombreCompleto: nombreCompleto,
        nombreMaquinaOrigen: nombreMaquinaOrigen,
        nombreMaquinaDestino: nombreMaquinaDestino,
        nombreSucursal: nombreSucursal,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

  // Método factory para convertir de Entity a Model
  factory ControlCombustibleMaquinaMontacargaModel.fromEntity(
    ControlCombustibleMaquinaMontacargaEntity entity,
  ) => ControlCombustibleMaquinaMontacargaModel(
    idCM: entity.idCM,
    idMaquinaVehiculoOrigen: entity.idMaquinaVehiculoOrigen,
    idMaquinaVehiculoDestino: entity.idMaquinaVehiculoDestino,
    codSucursalMaqVehiOrigen: entity.codSucursalMaqVehiOrigen,
    codSucursalMaqVehiDestino: entity.codSucursalMaqVehiDestino,
    codigoOrigen: entity.codigoOrigen,
    codigoDestino: entity.codigoDestino,

    fecha: entity.fecha,
    litrosIngreso: entity.litrosIngreso,
    litrosSalida: entity.litrosSalida,
    saldoLitros: entity.saldoLitros,
    codEmpleado: entity.codEmpleado,
    codAlmacen: entity.codAlmacen,
    obs: entity.obs,
    tipoTransaccion: entity.tipoTransaccion,
    audUsuario: entity.audUsuario,
    whsCode: entity.whsCode,
    whsName: entity.whsName,
    maquina: entity.maquina,
    nombreCompleto: entity.nombreCompleto,
    nombreMaquinaOrigen: entity.nombreMaquinaOrigen,
    nombreMaquinaDestino: entity.nombreMaquinaDestino,
    nombreSucursal: entity.nombreSucursal,
    fechaInicio: entity.fechaInicio,
    fechaFin: entity.fechaFin,

  );
}
