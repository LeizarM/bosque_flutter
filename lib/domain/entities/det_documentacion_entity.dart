// Destino final: lib/domain/entities/det_documentacion_entity.dart
class DetDocumentacionEntity {
  final int idDetDoc;
  final int? idAC;
  final int? idDoc;
  final double? monto;
  final int audUsuario;
  final DateTime? audFecha;

  DetDocumentacionEntity({
    required this.idDetDoc,
    this.idAC,
    this.idDoc,
    this.monto,
    required this.audUsuario,
    this.audFecha,
  });

  DetDocumentacionEntity copyWith({
    int? idDetDoc,
    int? idAC,
    int? idDoc,
    double? monto,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return DetDocumentacionEntity(
      idDetDoc: idDetDoc ?? this.idDetDoc,
      idAC: idAC ?? this.idAC,
      idDoc: idDoc ?? this.idDoc,
      monto: monto ?? this.monto,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
