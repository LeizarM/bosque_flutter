// To parse this JSON data, do
//
//     final movimientoModel = movimientoModelFromJson(jsonString);
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/movimiento_entity.dart';

MovimientoModel movimientoModelFromJson(String str) =>
    MovimientoModel.fromJson(json.decode(str));

String movimientoModelToJson(MovimientoModel data) =>
    json.encode(data.toJson());

class MovimientoModel {
  int idMovimiento;
  String tipoMovimiento;
  int idOrigen;
  String codigoOrigen;
  int sucursalOrigen;
  int idDestino;
  String codigoDestino;
  int sucursalDestino;
  int codSucursal;
  DateTime fechaMovimiento;
  double valor;
  double valorEntrada;
  double valorSalida;
  double valorSaldo;
  String unidadMedida;
  int estado;
  String obs;
  int codEmpleado;
  int idCompraGarrafa;
  int audUsuario;

  MovimientoModel({
    required this.idMovimiento,
    required this.tipoMovimiento,
    required this.idOrigen,
    required this.codigoOrigen,
    required this.sucursalOrigen,
    required this.idDestino,
    required this.codigoDestino,
    required this.sucursalDestino,
    required this.codSucursal,
    required this.fechaMovimiento,
    required this.valor,
    required this.valorEntrada,
    required this.valorSalida,
    required this.valorSaldo,
    required this.unidadMedida,
    required this.estado,
    required this.obs,
    required this.codEmpleado,
    required this.idCompraGarrafa,
    required this.audUsuario,
  });

  factory MovimientoModel.fromJson(Map<String, dynamic> json) =>
      MovimientoModel(
        idMovimiento: json["idMovimiento"],
        tipoMovimiento: json["tipoMovimiento"],
        idOrigen: json["idOrigen"],
        codigoOrigen: json["codigoOrigen"],
        sucursalOrigen: json["sucursalOrigen"],
        idDestino: json["idDestino"],
        codigoDestino: json["codigoDestino"],
        sucursalDestino: json["sucursalDestino"],
        codSucursal: json["codSucursal"],
        fechaMovimiento: DateTime.parse(json["fechaMovimiento"]),
        valor: json["valor"]?.toDouble(),
        valorEntrada: json["valorEntrada"]?.toDouble(),
        valorSalida: json["valorSalida"]?.toDouble(),
        valorSaldo: json["valorSaldo"]?.toDouble(),
        unidadMedida: json["unidadMedida"],
        estado: json["estado"],
        obs: json["obs"],
        codEmpleado: json["codEmpleado"],
        idCompraGarrafa: json["idCompraGarrafa"],
        audUsuario: json["audUsuario"],
      );

  Map<String, dynamic> toJson() => {
    "idMovimiento": idMovimiento,
    "tipoMovimiento": tipoMovimiento,
    "idOrigen": idOrigen,
    "codigoOrigen": codigoOrigen,
    "sucursalOrigen": sucursalOrigen,
    "idDestino": idDestino,
    "codigoDestino": codigoDestino,
    "sucursalDestino": sucursalDestino,
    "codSucursal": codSucursal,
    "fechaMovimiento": fechaMovimiento.toIso8601String(),
    "valor": valor,
    "valorEntrada": valorEntrada,
    "valorSalida": valorSalida,
    "valorSaldo": valorSaldo,
    "unidadMedida": unidadMedida,
    "estado": estado,
    "obs": obs,
    "codEmpleado": codEmpleado,
    "idCompraGarrafa": idCompraGarrafa,
    "audUsuario": audUsuario,
  };

  // Método para convertir de Model a Entity
  MovimientoEntity toEntity() => MovimientoEntity(
    idMovimiento: idMovimiento,
    tipoMovimiento: tipoMovimiento,
    idOrigen: idOrigen,
    codigoOrigen: codigoOrigen,
    sucursalOrigen: sucursalOrigen,
    idDestino: idDestino,
    codigoDestino: codigoDestino,
    sucursalDestino: sucursalDestino,
    codSucursal: codSucursal,
    fechaMovimiento: fechaMovimiento,
    valor: valor,
    valorEntrada: valorEntrada,
    valorSalida: valorSalida,
    valorSaldo: valorSaldo,
    unidadMedida: unidadMedida,
    estado: estado,
    obs: obs,
    codEmpleado: codEmpleado,
    idCompraGarrafa: idCompraGarrafa,
    audUsuario: audUsuario,
  );

  // Método factory para convertir de Entity a Model
  factory MovimientoModel.fromEntity(MovimientoEntity entity) =>
      MovimientoModel(
        idMovimiento: entity.idMovimiento,
        tipoMovimiento: entity.tipoMovimiento,
        idOrigen: entity.idOrigen,
        codigoOrigen: entity.codigoOrigen,
        sucursalOrigen: entity.sucursalOrigen,
        idDestino: entity.idDestino,
        codigoDestino: entity.codigoDestino,
        sucursalDestino: entity.sucursalDestino,
        codSucursal: entity.codSucursal,
        fechaMovimiento: entity.fechaMovimiento,
        valor: entity.valor,
        valorEntrada: entity.valorEntrada,
        valorSalida: entity.valorSalida,
        valorSaldo: entity.valorSaldo,
        unidadMedida: entity.unidadMedida,
        estado: entity.estado,
        obs: entity.obs,
        codEmpleado: entity.codEmpleado,
        idCompraGarrafa: entity.idCompraGarrafa,
        audUsuario: entity.audUsuario,
      );
}
