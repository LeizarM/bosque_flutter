import 'dart:convert';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';

DetalleSolicitudModel detalleSolicitudModelFromJson(String str) =>
    DetalleSolicitudModel.fromJson(json.decode(str));

String detalleSolicitudModelToJson(DetalleSolicitudModel data) =>
    json.encode(data.toJson());

class DetalleSolicitudModel {
  BigInt idDetalle;
  BigInt idSolicitudProveedor;
  String tipoDocumento;
  String numeroDocumento;
  int facturaProvSap;
  String codigoImportacion;
  double montoFacturaUsd;
  double montoAmortizadoUsd;
  double montoAPagarUsd;
  DateTime fechaFactura;
  DateTime fechaVencimiento;
  String concepto;
  String obs;
  int esAprobado;
  int audUsuario;

  int codEmpresa;

  DetalleSolicitudModel({
    required this.idDetalle,
    required this.idSolicitudProveedor,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.facturaProvSap,
    required this.codigoImportacion,
    required this.montoFacturaUsd,
    required this.montoAmortizadoUsd,
    required this.montoAPagarUsd,
    required this.fechaFactura,
    required this.fechaVencimiento,
    required this.concepto,
    required this.obs,
    required this.esAprobado,
    required this.audUsuario,
    required this.codEmpresa,
  });

  factory DetalleSolicitudModel.fromJson(Map<String, dynamic> json) =>
      DetalleSolicitudModel(
        idDetalle:
            json["idDetalle"] != null
                ? BigInt.from(json["idDetalle"])
                : BigInt.zero,
        idSolicitudProveedor:
            json["idSolicitudProveedor"] != null
                ? BigInt.from(json["idSolicitudProveedor"])
                : BigInt.zero,
        tipoDocumento: json["tipoDocumento"] ?? '',
        numeroDocumento: json["numeroDocumento"] ?? '',
        facturaProvSap: json["facturaProvSap"] ?? 0,
        codigoImportacion: json["codigoImportacion"] ?? '',
        montoFacturaUsd: json["montoFacturaUsd"]?.toDouble() ?? 0.0,
        montoAmortizadoUsd: json["montoAmortizadoUsd"]?.toDouble() ?? 0.0,
        montoAPagarUsd: json["montoAPagarUsd"]?.toDouble() ?? 0.0,
        fechaFactura:
            json["fechaFactura"] != null
                ? DateTime.parse(json["fechaFactura"])
                : DateTime.now(),
        fechaVencimiento:
            json["fechaVencimiento"] != null
                ? DateTime.parse(json["fechaVencimiento"])
                : DateTime.now(),
        concepto: json["concepto"] ?? '',
        obs: json["obs"] ?? '',
        esAprobado: json["esAprobado"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
        codEmpresa: json["codEmpresa"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idDetalle": idDetalle.toInt(),
    "idSolicitudProveedor": idSolicitudProveedor.toInt(),
    "tipoDocumento": tipoDocumento,
    "numeroDocumento": numeroDocumento,
    "facturaProvSap": facturaProvSap,
    "codigoImportacion": codigoImportacion,
    "montoFacturaUsd": montoFacturaUsd,
    "montoAmortizadoUsd": montoAmortizadoUsd,
    "montoAPagarUsd": montoAPagarUsd,
    "fechaFactura": fechaFactura.toIso8601String(),
    "fechaVencimiento": fechaVencimiento.toIso8601String(),
    "concepto": concepto,
    "obs": obs,
    "esAprobado": esAprobado,
    "audUsuario": audUsuario,
    "codEmpresa": codEmpresa,
  };

  // Método para convertir de Model a Entity
  DetalleSolicitudEntity toEntity() => DetalleSolicitudEntity(
    idDetalle: idDetalle,
    idSolicitudProveedor: idSolicitudProveedor,
    tipoDocumento: tipoDocumento,
    numeroDocumento: numeroDocumento,
    facturaProvSap: facturaProvSap,
    codigoImportacion: codigoImportacion,
    montoFacturaUsd: montoFacturaUsd,
    montoAmortizadoUsd: montoAmortizadoUsd,
    montoAPagarUsd: montoAPagarUsd,
    fechaFactura: fechaFactura,
    fechaVencimiento: fechaVencimiento,
    concepto: concepto,
    obs: obs,
    esAprobado: esAprobado,
    audUsuario: audUsuario,
    codEmpresa: codEmpresa,
  );

  // Método factory para convertir de Entity a Model
  factory DetalleSolicitudModel.fromEntity(DetalleSolicitudEntity entity) =>
      DetalleSolicitudModel(
        idDetalle: entity.idDetalle,
        idSolicitudProveedor: entity.idSolicitudProveedor,
        tipoDocumento: entity.tipoDocumento,
        numeroDocumento: entity.numeroDocumento,
        facturaProvSap: entity.facturaProvSap,
        codigoImportacion: entity.codigoImportacion,
        montoFacturaUsd: entity.montoFacturaUsd,
        montoAmortizadoUsd: entity.montoAmortizadoUsd,
        montoAPagarUsd: entity.montoAPagarUsd,
        fechaFactura: entity.fechaFactura,
        fechaVencimiento: entity.fechaVencimiento,
        concepto: entity.concepto,
        obs: entity.obs,
        esAprobado: entity.esAprobado,
        audUsuario: entity.audUsuario,
        codEmpresa: entity.codEmpresa,
      );
}
