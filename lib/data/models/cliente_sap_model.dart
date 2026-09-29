import 'package:bosque_flutter/domain/entities/cliente_sap_entity.dart';

/// ClienteSapDto del backend. Solo lectura.
class ClienteSapModel {
  final String codClienteSAP;
  final String datoCliente;

  const ClienteSapModel({
    required this.codClienteSAP,
    required this.datoCliente,
  });

  factory ClienteSapModel.fromJson(Map<String, dynamic> json) =>
      ClienteSapModel(
        codClienteSAP: (json['codClienteSAP'] ?? '').toString().trim(),
        datoCliente: (json['datoCliente'] ?? '').toString().trim(),
      );

  ClienteSapEntity toEntity() =>
      ClienteSapEntity(codClienteSAP: codClienteSAP, datoCliente: datoCliente);
}
