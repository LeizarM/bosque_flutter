// Destino final: lib/data/models/coche_del_dia_model.dart
import 'package:bosque_flutter/domain/entities/coche_del_dia_entity.dart';

class CocheDelDiaModel {
  final int idCo;
  final int? idTarRuti;
  final int? idBitTarRuti;
  final int? idCoche;
  final String? descripcion;
  final DateTime? fecha;
  final int? llego;
  final String? obs;
  final String? marca;
  final String? clase;
  final String? placa;
  final String? color;
  final int? anio;

  const CocheDelDiaModel({
    required this.idCo,
    this.idTarRuti,
    this.idBitTarRuti,
    this.idCoche,
    this.descripcion,
    this.fecha,
    this.llego,
    this.obs,
    this.marca,
    this.clase,
    this.placa,
    this.color,
    this.anio,
  });

  factory CocheDelDiaModel.fromJson(Map<String, dynamic> json) {
    return CocheDelDiaModel(
      idCo: json['idCo'] ?? 0,
      idTarRuti: json['idTarRuti'],
      idBitTarRuti: json['idBitTarRuti'],
      idCoche: json['idCoche'],
      descripcion: json['descripcion'],
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha']) : null,
      llego: json['llego'],
      obs: json['obs'],
      marca: json['marca'],
      clase: json['clase'],
      placa: json['placa'],
      color: json['color'],
      anio: json['anio'],
    );
  }

  CocheDelDiaEntity toEntity() {
    return CocheDelDiaEntity(
      idCo: idCo,
      idTarRuti: idTarRuti,
      idBitTarRuti: idBitTarRuti,
      idCoche: idCoche,
      descripcion: descripcion,
      fecha: fecha,
      llego: llego,
      obs: obs,
      marca: marca,
      clase: clase,
      placa: placa,
      color: color,
      anio: anio,
    );
  }
}
