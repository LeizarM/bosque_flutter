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

  String fechaMovimientoString;
  String origen;
  String destino;
  String nombreCompleto;

  DateTime fechaInicio;
  DateTime fechaFin;
  int idTipo;
  String nombreSucursal;
  String tipo;
  String nombreCoche;

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

    required this.fechaMovimientoString,
    required this.origen,
    required this.destino,
    required this.nombreCompleto,

    required this.fechaInicio,
    required this.fechaFin,
    required this.idTipo,
    required this.nombreSucursal,
    required this.tipo,
    required this.nombreCoche,
  });

  factory MovimientoModel.fromJson(Map<String, dynamic> json) =>
      MovimientoModel(
        idMovimiento: json["idMovimiento"] ?? 0,
        tipoMovimiento: json["tipoMovimiento"] ?? '',
        idOrigen: json["idOrigen"] ?? 0,
        codigoOrigen: json["codigoOrigen"] ?? '',
        sucursalOrigen: json["sucursalOrigen"] ?? 0,
        idDestino: json["idDestino"] ?? 0,
        codigoDestino: json["codigoDestino"] ?? '',
        sucursalDestino: json["sucursalDestino"] ?? 0,
        codSucursal: json["codSucursal"] ?? 0,
        fechaMovimiento:
            json["fechaMovimiento"] != null
                ? DateTime.parse(json["fechaMovimiento"])
                : DateTime.now(),
        valor: json["valor"]?.toDouble() ?? 0.0,
        valorEntrada: json["valorEntrada"]?.toDouble() ?? 0.0,
        valorSalida: json["valorSalida"]?.toDouble() ?? 0.0,
        valorSaldo: json["valorSaldo"]?.toDouble() ?? 0.0,
        unidadMedida: json["unidadMedida"] ?? '',
        estado: json["estado"] ?? 0,
        obs: json["obs"] ?? '',
        codEmpleado: json["codEmpleado"] ?? 0,
        idCompraGarrafa: json["idCompraGarrafa"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,

        fechaMovimientoString: json["fechaMovimientoString"] ?? '',
        origen: json["origen"] ?? '',
        destino: json["destino"] ?? '',
        nombreCompleto: json["nombreCompleto"] ?? '',

        fechaInicio:
            json["fechaInicio"] != null
                ? DateTime.parse(json["fechaInicio"])
                : DateTime.now(),
        fechaFin:
            json["fechaFin"] != null
                ? DateTime.parse(json["fechaFin"])
                : DateTime.now(),
        idTipo: json["idTipo"] ?? 0,
        nombreSucursal: json["nombreSucursal"] ?? '',
        tipo: json["tipo"] ?? '',
        nombreCoche: json["nombreCoche"] ?? '',
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
    "fechaMovimientoString": fechaMovimientoString,
    "origen": origen,
    "destino": destino,
    "nombreCompleto": nombreCompleto,
    "fechaInicio": fechaInicio.toIso8601String(),
    "fechaFin": fechaFin.toIso8601String(),
    "idTipo": idTipo,
    "nombreSucursal": nombreSucursal,
    "tipo": tipo,
    "nombreCoche": nombreCoche,
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

    fechaMovimientoString: fechaMovimientoString,
    origen: origen,
    destino: destino,
    nombreCompleto: nombreCompleto,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    idTipo: idTipo,
    nombreSucursal: nombreSucursal,
    tipo: tipo,
    nombreCoche: nombreCoche,
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

        fechaMovimientoString: entity.fechaMovimientoString,
        origen: entity.origen,
        destino: entity.destino,
        nombreCompleto: entity.nombreCompleto,

        fechaInicio: entity.fechaInicio,
        fechaFin: entity.fechaFin,
        idTipo: entity.idTipo,
        nombreSucursal: entity.nombreSucursal,
        tipo: entity.tipo,
        nombreCoche: entity.nombreCoche,
      );
}
