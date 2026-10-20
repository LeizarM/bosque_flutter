/// `tcpe_examen`: Examen generado para un usuario dentro de un lote.
/// Columnas de `p_list_tcpe_Examen` (sin `password2`) más `nombreUsuario`.
class TcpeExamenEntity {
  final BigInt codExamen;
  final BigInt? codRolExamen;
  final BigInt? codUsuario;
  final BigInt? codPostulacion;
  final bool? esPostulacion;
  final double? resultado;
  final String? observaciones;
  final String? titulo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final BigInt? preguntaActual;
  final DateTime? ultimaActividad;
  final int? salidasPestana;
  final DateTime? ultimaSalida;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeExamenEntity({
    required this.codExamen,
    this.codRolExamen,
    this.codUsuario,
    this.codPostulacion,
    this.esPostulacion,
    this.resultado,
    this.observaciones,
    this.titulo,
    this.fechaInicio,
    this.fechaFin,
    this.preguntaActual,
    this.ultimaActividad,
    this.salidasPestana,
    this.ultimaSalida,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeExamenEntity copyWith({
    BigInt? codExamen,
    BigInt? codRolExamen,
    BigInt? codUsuario,
    BigInt? codPostulacion,
    bool? esPostulacion,
    double? resultado,
    String? observaciones,
    String? titulo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    BigInt? preguntaActual,
    DateTime? ultimaActividad,
    int? salidasPestana,
    DateTime? ultimaSalida,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeExamenEntity(
    codExamen: codExamen ?? this.codExamen,
    codRolExamen: codRolExamen ?? this.codRolExamen,
    codUsuario: codUsuario ?? this.codUsuario,
    codPostulacion: codPostulacion ?? this.codPostulacion,
    esPostulacion: esPostulacion ?? this.esPostulacion,
    resultado: resultado ?? this.resultado,
    observaciones: observaciones ?? this.observaciones,
    titulo: titulo ?? this.titulo,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    preguntaActual: preguntaActual ?? this.preguntaActual,
    ultimaActividad: ultimaActividad ?? this.ultimaActividad,
    salidasPestana: salidasPestana ?? this.salidasPestana,
    ultimaSalida: ultimaSalida ?? this.ultimaSalida,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
