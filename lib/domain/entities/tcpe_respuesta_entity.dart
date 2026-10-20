/// `tcpe_respuesta`: Respuesta de una pregunta del banco: modelo (abierta) o cabecera de opciones (cerrada).
/// Columnas de `p_list_tcpe_Respuesta` (sin `password2`) más `nombreUsuario`.
class TcpeRespuestaEntity {
  final BigInt codRespuesta;
  final BigInt? codPregunta;
  final int? prioridad;
  final String? respuesta;
  final bool esCerrada;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeRespuestaEntity({
    required this.codRespuesta,
    this.codPregunta,
    this.prioridad,
    this.respuesta,
    this.esCerrada = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeRespuestaEntity copyWith({
    BigInt? codRespuesta,
    BigInt? codPregunta,
    int? prioridad,
    String? respuesta,
    bool? esCerrada,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeRespuestaEntity(
    codRespuesta: codRespuesta ?? this.codRespuesta,
    codPregunta: codPregunta ?? this.codPregunta,
    prioridad: prioridad ?? this.prioridad,
    respuesta: respuesta ?? this.respuesta,
    esCerrada: esCerrada ?? this.esCerrada,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
