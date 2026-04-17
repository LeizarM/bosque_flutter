class PendienteEntregaEntity {
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

  const PendienteEntregaEntity({
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
}
