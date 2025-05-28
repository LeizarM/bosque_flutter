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
  });

  factory ControlCombustibleMaquinaMontacargaModel.fromJson(
    Map<String, dynamic> json,
  ) => ControlCombustibleMaquinaMontacargaModel(
    idCM: json["idCM"],
    idMaquinaVehiculoOrigen: json["idMaquinaVehiculoOrigen"],
    idMaquinaVehiculoDestino: json["idMaquinaVehiculoDestino"],
    codSucursalMaqVehiOrigen: json["codSucursalMaqVehiOrigen"],
    codSucursalMaqVehiDestino: json["codSucursalMaqVehiDestino"],
    codigoOrigen: json["codigoOrigen"] ?? '',
    codigoDestino: json["codigoDestino"] ?? '',
    fecha: DateTime.parse(json["fecha"]),
    litrosIngreso: json["litrosIngreso"]?.toDouble(),
    litrosSalida: json["litrosSalida"]?.toDouble(),
    saldoLitros: json["saldoLitros"]?.toDouble(),
    codEmpleado: json["codEmpleado"],
    codAlmacen: json["codAlmacen"],
    obs: json["obs"],
    tipoTransaccion: json["tipoTransaccion"],
    audUsuario: json["audUsuario"],
    whsCode: json["whsCode"],
    whsName: json["whsName"],
    maquina: json["maquina"],
    nombreCompleto: json["nombreCompleto"],
  );

  Map<String, dynamic> toJson() => {
    "idCM": idCM,
    "idMaquinaVehiculoOrigen": idMaquinaVehiculoOrigen,
    "idMaquinaVehiculoDestino": idMaquinaVehiculoDestino,
    "codSucursalMaqVehiOrigen": codSucursalMaqVehiOrigen,
    "codSucursalMaqVehiDestino": codSucursalMaqVehiDestino,
    "codigoOrigen": codigoOrigen,
    "codigoDestino": codigoDestino,
    "fecha": fecha.toIso8601String(),
    "litrosIngreso": litrosIngreso,
    "litrosSalida": litrosSalida,
    "saldoLitros": saldoLitros,
    "codEmpleado": codEmpleado,
    "codAlmacen": codAlmacen,
    "obs": obs,
    "tipoTransaccion": tipoTransaccion,
    "audUsuario": audUsuario,
    "whsCode": whsCode,
    "whsName": whsName,
    "maquina": maquina,
    "nombreCompleto": nombreCompleto,
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
  );
}
