// DTO temporal para mapear el response de pendientes de entrega
// del endpoint AppConstants.pendientesDeEntrega
import 'package:bosque_flutter/domain/entities/pendiente_entrega_entity.dart';

class PendienteEntregaModel {
  final String empresa;
  final int docEntry;
  final String cardName;
  final DateTime docDate;
  final String horaCreacion;
  final double weight;
  final double cantidad;
  final String comments;
  final String direccionEntrega;
  final String vendedor;
  final String sistema;
  final String docNum;
  final String seriesName;
  final String? tipoEntrega;

  const PendienteEntregaModel({
    required this.empresa,
    required this.docEntry,
    required this.cardName,
    required this.docDate,
    required this.horaCreacion,
    required this.weight,
    required this.cantidad,
    required this.comments,
    required this.direccionEntrega,
    required this.vendedor,
    required this.sistema,
    required this.docNum,
    required this.seriesName,
    this.tipoEntrega,
  });

  factory PendienteEntregaModel.fromJson(Map<String, dynamic> json) =>
      PendienteEntregaModel(
        empresa: json['empresa'] as String? ?? '',
        docEntry: (json['docEntry'] as num?)?.toInt() ?? 0,
        cardName: json['cardName'] as String? ?? '',
        docDate:
            json['docDate'] != null
                ? DateTime.tryParse(json['docDate'] as String) ?? DateTime.now()
                : DateTime.now(),
        horaCreacion: json['horaCreacion'] as String? ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
        comments: json['comments'] as String? ?? '',
        direccionEntrega: json['direccionEntrega'] as String? ?? '',
        vendedor: json['vendedor'] as String? ?? '',
        sistema: json['sistema'] as String? ?? '',
        docNum: json['docNum'] as String? ?? '',
        seriesName: json['seriesName'] as String? ?? '',
        tipoEntrega: json['tipoEntrega'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'empresa': empresa,
    'docEntry': docEntry,
    'cardName': cardName,
    'docDate':
        '${docDate.year.toString().padLeft(4, '0')}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}',
    'horaCreacion': horaCreacion,
    'weight': weight,
    'cantidad': cantidad,
    'comments': comments,
    'direccionEntrega': direccionEntrega,
    'vendedor': vendedor,
    'sistema': sistema,
    'docNum': docNum,
    'seriesName': seriesName,
    'tipoEntrega': tipoEntrega,
  };

  PendienteEntregaEntity toEntity() => PendienteEntregaEntity(
    empresa: empresa,
    docEntry: docEntry,
    cardName: cardName,
    docDate: docDate,
    horaCreacion: horaCreacion,
    weight: weight,
    cantidad: cantidad,
    comments: comments,
    direccionEntrega: direccionEntrega,
    vendedor: vendedor,
    sistema: sistema,
    docNum: docNum,
    seriesName: seriesName,
    tipoEntrega: tipoEntrega,
  );

  factory PendienteEntregaModel.fromEntity(PendienteEntregaEntity entity) =>
      PendienteEntregaModel(
        empresa: entity.empresa,
        docEntry: entity.docEntry,
        cardName: entity.cardName,
        docDate: entity.docDate,
        horaCreacion: entity.horaCreacion,
        weight: entity.weight,
        cantidad: entity.cantidad,
        comments: entity.comments,
        direccionEntrega: entity.direccionEntrega,
        vendedor: entity.vendedor,
        sistema: entity.sistema,
        docNum: entity.docNum,
        seriesName: entity.seriesName,
        tipoEntrega: entity.tipoEntrega,
      );
}
