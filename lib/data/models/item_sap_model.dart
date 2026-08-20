import 'package:bosque_flutter/domain/entities/item_sap_entity.dart';

class ItemSapModel {
  final String codItem;
  final String datoItem;
  final double cantidadDisponible;
  final int codTipo;
  final String datoTipo;
  final int codFabricante;
  final String datoFabricante;
  final double gramaje;
  final double largo;
  final double ancho;
  final double utm;
  final double cantHojas;
  final String empaque;
  final String formato;

  ItemSapModel({
    required this.codItem,
    required this.datoItem,
    required this.cantidadDisponible,
    required this.codTipo,
    required this.datoTipo,
    required this.codFabricante,
    required this.datoFabricante,
    required this.gramaje,
    required this.largo,
    required this.ancho,
    required this.utm,
    required this.cantHojas,
    required this.empaque,
    required this.formato,
  });

  factory ItemSapModel.fromJson(Map<String, dynamic> json) => ItemSapModel(
    codItem: json['codItem'] ?? '',
    datoItem: json['datoItem'] ?? '',
    cantidadDisponible: (json['cantidadDisponible'] ?? 0).toDouble(),
    codTipo: (json['codTipo'] ?? 0).toInt(),
    datoTipo: json['datoTipo'] ?? '',
    codFabricante: (json['codFabricante'] ?? 0).toInt(),
    datoFabricante: json['datoFabricante'] ?? '',
    gramaje: (json['gramaje'] ?? 0).toDouble(),
    largo: (json['largo'] ?? 0).toDouble(),
    ancho: (json['ancho'] ?? 0).toDouble(),
    utm: (json['utm'] ?? 0).toDouble(),
    cantHojas: (json['cantHojas'] ?? 0).toDouble(),
    empaque: json['empaque'] ?? '',
    formato: json['formato'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'codItem': codItem,
    'datoItem': datoItem,
    'cantidadDisponible': cantidadDisponible,
    'codTipo': codTipo,
    'datoTipo': datoTipo,
    'codFabricante': codFabricante,
    'datoFabricante': datoFabricante,
    'gramaje': gramaje,
    'largo': largo,
    'ancho': ancho,
    'utm': utm,
    'cantHojas': cantHojas,
    'empaque': empaque,
    'formato': formato,
  };

  ItemSapEntity toEntity() => ItemSapEntity(
    codItem: codItem,
    datoItem: datoItem,
    cantidadDisponible: cantidadDisponible,
    codTipo: codTipo,
    datoTipo: datoTipo,
    codFabricante: codFabricante,
    datoFabricante: datoFabricante,
    gramaje: gramaje,
    largo: largo,
    ancho: ancho,
    utm: utm,
    cantHojas: cantHojas,
    empaque: empaque,
    formato: formato,
  );
}
