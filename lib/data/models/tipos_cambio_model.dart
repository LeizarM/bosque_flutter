import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tipos_cambio_entity.dart';

TiposCambioModel tiposCambioModelFromJson(String str) =>
    TiposCambioModel.fromJson(json.decode(str));

String tiposCambioModelToJson(TiposCambioModel data) =>
    json.encode(data.toJson());

class TiposCambioModel {
  BigInt idTipoCambio;
  int codBanco;
  DateTime fechaVigencia;
  int idMonedaOrigen;
  int idMonedaDestino;
  double tasaCompra;
  double tasaVenta;
  double tasaPromedio;
  String fuente;
  int audUsuario;

  TiposCambioModel({
    required this.idTipoCambio,
    required this.codBanco,
    required this.fechaVigencia,
    required this.idMonedaOrigen,
    required this.idMonedaDestino,
    required this.tasaCompra,
    required this.tasaVenta,
    required this.tasaPromedio,
    required this.fuente,
    required this.audUsuario,
  });

  factory TiposCambioModel.fromJson(Map<String, dynamic> json) =>
      TiposCambioModel(
        idTipoCambio:
            json["idTipoCambio"] != null
                ? BigInt.from(json["idTipoCambio"])
                : BigInt.zero,
        codBanco: json["codBanco"] ?? 0,
        fechaVigencia:
            json["fechaVigencia"] != null
                ? DateTime.parse(json["fechaVigencia"])
                : DateTime.now(),
        idMonedaOrigen: json["idMonedaOrigen"] ?? 0,
        idMonedaDestino: json["idMonedaDestino"] ?? 0,
        tasaCompra: json["tasaCompra"]?.toDouble() ?? 0.0,
        tasaVenta: json["tasaVenta"]?.toDouble() ?? 0.0,
        tasaPromedio: json["tasaPromedio"]?.toDouble() ?? 0.0,
        fuente: json["fuente"] ?? '',
        audUsuario: json["audUsuario"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idTipoCambio": idTipoCambio.toInt(),
    "codBanco": codBanco,
    "fechaVigencia": fechaVigencia
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
    "idMonedaOrigen": idMonedaOrigen,
    "idMonedaDestino": idMonedaDestino,
    "tasaCompra": tasaCompra,
    "tasaVenta": tasaVenta,
    "tasaPromedio": tasaPromedio,
    "fuente": fuente,
    "audUsuario": audUsuario,
  };

  TiposCambioEntity toEntity() => TiposCambioEntity(
    idTipoCambio: idTipoCambio,
    codBanco: codBanco,
    fechaVigencia: fechaVigencia,
    idMonedaOrigen: idMonedaOrigen,
    idMonedaDestino: idMonedaDestino,
    tasaCompra: tasaCompra,
    tasaVenta: tasaVenta,
    tasaPromedio: tasaPromedio,
    fuente: fuente,
    audUsuario: audUsuario,
  );

  factory TiposCambioModel.fromEntity(TiposCambioEntity entity) =>
      TiposCambioModel(
        idTipoCambio: entity.idTipoCambio,
        codBanco: entity.codBanco,
        fechaVigencia: entity.fechaVigencia,
        idMonedaOrigen: entity.idMonedaOrigen,
        idMonedaDestino: entity.idMonedaDestino,
        tasaCompra: entity.tasaCompra,
        tasaVenta: entity.tasaVenta,
        tasaPromedio: entity.tasaPromedio,
        fuente: entity.fuente,
        audUsuario: entity.audUsuario,
      );
}
