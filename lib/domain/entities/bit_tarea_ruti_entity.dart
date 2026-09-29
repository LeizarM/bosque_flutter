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
  // Días de plazo de la tarea (archivo SQL 65). 0 = solo su propio día, que es
  // el caso de todas hoy y lo que hacía el sistema anterior con las diarias.
  final int? diasPlazo;
  // Hasta cuándo se puede responder, YA CALCULADO por la base
  // (`fn_tac_fechaLimite`: fechaPresentacion + diasPlazo). Llega resuelto a
  // propósito: el criterio de "vencida" estaba copiado en tres lugares del
  // cliente, cada copia comparando contra el reloj del dispositivo.
  final DateTime? fechaLimite;

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
    this.diasPlazo,
    this.fechaLimite,
  });

  /// El día hasta el que esta ocurrencia acepta respuesta.
  ///
  /// Si el backend todavía no manda `fechaLimite` —una versión anterior a la
  /// del archivo 65— se cae a `fechaPresentacion`, que es el plazo estricto.
  /// Falla hacia el lado seguro: nunca inventa margen que la base no dio.
  DateTime? get venceEl => fechaLimite ?? fechaPresentacion;

  /// Si el plazo ya pasó.
  ///
  /// `hoy` se recibe en vez de leer el reloj aquí adentro: así hay UN solo
  /// criterio en toda la app y las pruebas pueden fijar el día en vez de
  /// depender de cuándo se ejecutan.
  ///
  /// Comparación a granularidad de DÍA, no de instante: `venceEl` es una fecha
  /// sin hora (medianoche local), así que compararla contra un momento exacto
  /// marcaría la tarea vencida desde la medianoche de su propio día de
  /// vencimiento, horas antes de que ese día termine.
  bool fueraDePlazo(DateTime hoy) {
    final limite = venceEl;
    if (limite == null) return false;
    return limite.isBefore(DateTime(hoy.year, hoy.month, hoy.day));
  }

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
    int? diasPlazo,
    DateTime? fechaLimite,
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
      diasPlazo: diasPlazo ?? this.diasPlazo,
      fechaLimite: fechaLimite ?? this.fechaLimite,
    );
  }
}
