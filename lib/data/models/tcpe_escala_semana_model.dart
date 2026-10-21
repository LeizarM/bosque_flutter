import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_escala_semana_entity.dart';

/// Un número de la escala con cuántos lo eligieron
/// (`/examenes/pregunta-semana/distribucion`: `p_list_tcpe_PreguntaSemana` E).
class TcpeEscalaSemanaModel {
  final int valor;
  final String? etiqueta;
  final int cantidad;
  final double porcentaje;
  final int total;
  final double? promedio;

  const TcpeEscalaSemanaModel({
    required this.valor,
    this.etiqueta,
    this.cantidad = 0,
    this.porcentaje = 0,
    this.total = 0,
    this.promedio,
  });

  factory TcpeEscalaSemanaModel.fromJson(Map<String, dynamic> json) => TcpeEscalaSemanaModel(
    valor: tcpeInt(json['valor']) ?? 0,
    etiqueta: tcpeTexto(json['etiqueta']),
    cantidad: tcpeInt(json['cantidad']) ?? 0,
    porcentaje: tcpeDouble(json['porcentaje']) ?? 0,
    total: tcpeInt(json['total']) ?? 0,
    promedio: tcpeDouble(json['promedio']),
  );

  Map<String, dynamic> toJson() => {
    'valor': valor,
    'etiqueta': etiqueta,
    'cantidad': cantidad,
    'porcentaje': porcentaje,
    'total': total,
    'promedio': promedio,
  };

  TcpeEscalaSemanaEntity toEntity() => TcpeEscalaSemanaEntity(
    valor: valor,
    etiqueta: etiqueta,
    cantidad: cantidad,
    porcentaje: porcentaje,
    total: total,
    promedio: promedio,
  );

  factory TcpeEscalaSemanaModel.fromEntity(TcpeEscalaSemanaEntity e) => TcpeEscalaSemanaModel(
    valor: e.valor,
    etiqueta: e.etiqueta,
    cantidad: e.cantidad,
    porcentaje: e.porcentaje,
    total: e.total,
    promedio: e.promedio,
  );
}
