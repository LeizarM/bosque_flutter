// Destino final: lib/domain/entities/accion_tarea_rutinaria_entity.dart
// "accion" (columna real de tac_accionTareaRutinaria) se expone como
// "descripcionAccion" para no colisionar con el parámetro @ACCION del SP
// (ver tac_accionTareaRutinaria.sql).
class AccionTareaRutinariaEntity {
  final int idATR;
  final String descripcionAccion;
  final int? estado;
  final int audUsuario;
  final DateTime? audFecha;

  AccionTareaRutinariaEntity({
    required this.idATR,
    required this.descripcionAccion,
    this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  AccionTareaRutinariaEntity copyWith({
    int? idATR,
    String? descripcionAccion,
    int? estado,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return AccionTareaRutinariaEntity(
      idATR: idATR ?? this.idATR,
      descripcionAccion: descripcionAccion ?? this.descripcionAccion,
      estado: estado ?? this.estado,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
