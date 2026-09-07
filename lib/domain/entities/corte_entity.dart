// Destino final: lib/domain/entities/corte_entity.dart
class CorteEntity {
  final int idCorte;
  final String? descripcion;
  final double? corte;
  final String? tipoCorte;
  final int audUsuario;
  final DateTime? audFecha;

  CorteEntity({
    required this.idCorte,
    this.descripcion,
    this.corte,
    this.tipoCorte,
    required this.audUsuario,
    this.audFecha,
  });

  CorteEntity copyWith({
    int? idCorte,
    String? descripcion,
    double? corte,
    String? tipoCorte,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return CorteEntity(
      idCorte: idCorte ?? this.idCorte,
      descripcion: descripcion ?? this.descripcion,
      corte: corte ?? this.corte,
      tipoCorte: tipoCorte ?? this.tipoCorte,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
