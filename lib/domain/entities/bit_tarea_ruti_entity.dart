// Destino final: lib/domain/entities/bit_tarea_ruti_entity.dart
class BitTareaRutiEntity {
  final int idBitTarea;
  final DateTime? fechaActivo;
  final DateTime? fechaPresentacion;
  final int? idTarRuti;
  final String? nombreTareaRutinaria;
  final int? codEmpleado;
  final String? descripCargo;
  final DateTime? fechaCompletado;
  final int? fueRealizado;
  final String? obs;
  final int? estado;
  final int audUsuario;
  final DateTime? audFecha;
  // Proyectadas desde tac_tareaRutinaria (LEFT JOIN en el p_list): dicen QUÉ
  // clase de tarea es esta ocurrencia, para poder enrutar a su mini-flujo
  // (ver TareaRutinariaEntity.idATR) y colorear por frecuencia.
  final int? idATR;
  final int? idFrec;

  BitTareaRutiEntity({
    required this.idBitTarea,
    this.fechaActivo,
    this.fechaPresentacion,
    this.idTarRuti,
    this.nombreTareaRutinaria,
    this.codEmpleado,
    this.descripCargo,
    this.fechaCompletado,
    this.fueRealizado,
    this.obs,
    this.estado,
    required this.audUsuario,
    this.audFecha,
    this.idATR,
    this.idFrec,
  });

  BitTareaRutiEntity copyWith({
    int? idBitTarea,
    DateTime? fechaActivo,
    DateTime? fechaPresentacion,
    int? idTarRuti,
    String? nombreTareaRutinaria,
    int? codEmpleado,
    String? descripCargo,
    DateTime? fechaCompletado,
    int? fueRealizado,
    String? obs,
    int? estado,
    int? audUsuario,
    DateTime? audFecha,
    int? idATR,
    int? idFrec,
  }) {
    return BitTareaRutiEntity(
      idBitTarea: idBitTarea ?? this.idBitTarea,
      fechaActivo: fechaActivo ?? this.fechaActivo,
      fechaPresentacion: fechaPresentacion ?? this.fechaPresentacion,
      idTarRuti: idTarRuti ?? this.idTarRuti,
      nombreTareaRutinaria: nombreTareaRutinaria ?? this.nombreTareaRutinaria,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      descripCargo: descripCargo ?? this.descripCargo,
      fechaCompletado: fechaCompletado ?? this.fechaCompletado,
      fueRealizado: fueRealizado ?? this.fueRealizado,
      obs: obs ?? this.obs,
      estado: estado ?? this.estado,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
      idATR: idATR ?? this.idATR,
      idFrec: idFrec ?? this.idFrec,
    );
  }
}
