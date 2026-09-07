// Destino final: lib/data/models/arqueo_caja_sucursales_model.dart
import 'dart:convert';
import 'package:bosque_flutter/domain/entities/arqueo_caja_sucursales_entity.dart';

ArqueoCajaSucursalesResponse arqueoCajaSucursalesResponseFromJson(
  String str,
) => ArqueoCajaSucursalesResponse.fromJson(json.decode(str));
String arqueoCajaSucursalesResponseToJson(
  ArqueoCajaSucursalesResponse data,
) => json.encode(data.toJson());

class ArqueoCajaSucursalesResponse {
  String message;
  List<ArqueoCajaSucursalesModel> data;
  int status;
  int? idGenerado;

  ArqueoCajaSucursalesResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory ArqueoCajaSucursalesResponse.fromJson(Map<String, dynamic> json) {
    List<ArqueoCajaSucursalesModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<ArqueoCajaSucursalesModel>.from(
          (json["data"] as List).map(
            (x) => ArqueoCajaSucursalesModel.fromJson(x),
          ),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return ArqueoCajaSucursalesResponse(
      message: json["message"] ?? '',
      data: listaData,
      status: json["status"] ?? 0,
      idGenerado: json["idGenerado"] ?? idGen,
    );
  }

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "status": status,
    "idGenerado": idGenerado,
  };
}

class ArqueoCajaSucursalesModel {
  int idAC;
  int? idTarRuti;
  int? codEmpleadoEncargado;
  DateTime? fecha;
  String? hora;
  double? saldoMovSap;
  String? obs;
  int? codEmpleadoSupCierre;
  double? total;
  double? diferencia;
  double? tc;
  int? idBitTarea;
  DateTime? fechaRevisado;
  int audUsuario;
  DateTime? audFecha;

  ArqueoCajaSucursalesModel({
    required this.idAC,
    this.idTarRuti,
    this.codEmpleadoEncargado,
    this.fecha,
    this.hora,
    this.saldoMovSap,
    this.obs,
    this.codEmpleadoSupCierre,
    this.total,
    this.diferencia,
    this.tc,
    this.idBitTarea,
    this.fechaRevisado,
    required this.audUsuario,
    this.audFecha,
  });

  factory ArqueoCajaSucursalesModel.fromJson(Map<String, dynamic> json) {
    return ArqueoCajaSucursalesModel(
      idAC: json["idAC"] ?? 0,
      idTarRuti: json["idTarRuti"],
      codEmpleadoEncargado: json["codEmpleadoEncargado"],
      fecha: json["fecha"] != null ? DateTime.tryParse(json["fecha"]) : null,
      hora: json["hora"],
      saldoMovSap: json["saldoMovSap"],
      obs: json["obs"],
      codEmpleadoSupCierre: json["codEmpleadoSupCierre"],
      total: json["total"],
      diferencia: json["diferencia"],
      tc: json["tc"],
      idBitTarea: json["idBitTarea"],
      fechaRevisado: json["fechaRevisado"] != null
          ? DateTime.tryParse(json["fechaRevisado"])
          : null,
      audUsuario: json["audUsuario"] ?? 0,
      audFecha: json["audFecha"] != null
          ? DateTime.tryParse(json["audFecha"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "idAC": idAC,
    "idTarRuti": idTarRuti,
    "codEmpleadoEncargado": codEmpleadoEncargado,
    "fecha": fecha?.toIso8601String(),
    "hora": hora,
    "saldoMovSap": saldoMovSap,
    "obs": obs,
    "codEmpleadoSupCierre": codEmpleadoSupCierre,
    "total": total,
    "diferencia": diferencia,
    "tc": tc,
    "idBitTarea": idBitTarea,
    "fechaRevisado": fechaRevisado?.toIso8601String(),
    "audUsuario": audUsuario,
    "audFecha": audFecha?.toIso8601String(),
  };

  ArqueoCajaSucursalesEntity toEntity() {
    return ArqueoCajaSucursalesEntity(
      idAC: idAC,
      idTarRuti: idTarRuti,
      codEmpleadoEncargado: codEmpleadoEncargado,
      fecha: fecha,
      hora: hora,
      saldoMovSap: saldoMovSap,
      obs: obs,
      codEmpleadoSupCierre: codEmpleadoSupCierre,
      total: total,
      diferencia: diferencia,
      tc: tc,
      idBitTarea: idBitTarea,
      fechaRevisado: fechaRevisado,
      audUsuario: audUsuario,
      audFecha: audFecha,
    );
  }

  factory ArqueoCajaSucursalesModel.fromEntity(
    ArqueoCajaSucursalesEntity entity,
  ) {
    return ArqueoCajaSucursalesModel(
      idAC: entity.idAC,
      idTarRuti: entity.idTarRuti,
      codEmpleadoEncargado: entity.codEmpleadoEncargado,
      fecha: entity.fecha,
      hora: entity.hora,
      saldoMovSap: entity.saldoMovSap,
      obs: entity.obs,
      codEmpleadoSupCierre: entity.codEmpleadoSupCierre,
      total: entity.total,
      diferencia: entity.diferencia,
      tc: entity.tc,
      idBitTarea: entity.idBitTarea,
      fechaRevisado: entity.fechaRevisado,
      audUsuario: entity.audUsuario,
      audFecha: entity.audFecha,
    );
  }
}
