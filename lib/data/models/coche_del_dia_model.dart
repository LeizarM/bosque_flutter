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

  // Archivo SQL 45: la marca que hizo OTRA persona sobre el mismo coche hoy.
  final int? otroLlego;
  final String? otroQuien;
  final DateTime? otroCuando;

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
    this.otroLlego,
    this.otroQuien,
    this.otroCuando,
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
      otroLlego: json['otroLlego'],
      otroQuien: json['otroQuien'],
      // Llega null mientras no se corra el archivo 45: la pantalla
      // simplemente no muestra la linea de "ya lo marco fulano".
      otroCuando:
          json['otroCuando'] != null
              ? DateTime.tryParse(json['otroCuando'])
              : null,
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
      otroLlego: otroLlego,
      otroQuien: otroQuien,
      otroCuando: otroCuando,
    );
  }
}
