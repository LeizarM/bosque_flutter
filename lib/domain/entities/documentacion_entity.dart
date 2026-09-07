// Destino final: lib/domain/entities/documentacion_entity.dart
class DocumentacionEntity {
  final int idDoc;
  final String nombre;
  final int audUsuario;
  final DateTime? audFecha;

  DocumentacionEntity({
    required this.idDoc,
    required this.nombre,
    required this.audUsuario,
    this.audFecha,
  });

  DocumentacionEntity copyWith({
    int? idDoc,
    String? nombre,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return DocumentacionEntity(
      idDoc: idDoc ?? this.idDoc,
      nombre: nombre ?? this.nombre,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
