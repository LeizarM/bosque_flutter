import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';

class ProveedorEmpresaModel {
  final String cardCode;
  final String cardName;

  const ProveedorEmpresaModel({required this.cardCode, required this.cardName});

  factory ProveedorEmpresaModel.fromJson(Map<String, dynamic> json) =>
      ProveedorEmpresaModel(
        cardCode: json['cardCode'] as String? ?? '',
        cardName: json['cardName'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'cardCode': cardCode, 'cardName': cardName};

  ProveedorEmpresaEntity toEntity() =>
      ProveedorEmpresaEntity(cardCode: cardCode, cardName: cardName);

  factory ProveedorEmpresaModel.fromEntity(ProveedorEmpresaEntity entity) =>
      ProveedorEmpresaModel(
        cardCode: entity.cardCode,
        cardName: entity.cardName,
      );
}
