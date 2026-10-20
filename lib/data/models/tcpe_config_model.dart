import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';

/// Una clave de la configuración del módulo (`p_list_tcpe_Config` L).
class TcpeConfigModel {
  final String clave;
  final String? valor;
  final String? descripcion;

  const TcpeConfigModel({required this.clave, this.valor, this.descripcion});

  factory TcpeConfigModel.fromJson(Map<String, dynamic> json) => TcpeConfigModel(
    clave: tcpeTexto(json['clave']) ?? '',
    valor: tcpeTexto(json['valor']),
    descripcion: tcpeTexto(json['descripcion']),
  );

  Map<String, dynamic> toJson() => {'clave': clave, 'valor': valor, 'descripcion': descripcion};

  TcpeConfigEntity toEntity() => TcpeConfigEntity(clave: clave, valor: valor, descripcion: descripcion);

  factory TcpeConfigModel.fromEntity(TcpeConfigEntity e) =>
      TcpeConfigModel(clave: e.clave, valor: e.valor, descripcion: e.descripcion);
}
