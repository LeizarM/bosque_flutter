class TransaccionParticipanteEntity {
  BigInt idParticipante;
  BigInt idTransaccion;
  String tipoParticipante; // EMPRESA / TERCERO
  String nombre; // IPX, MONRROY RODRIGO, NEMER...
  double porcentaje; // participación s/ montoConvertido
  double montoUs;
  double montoBs;
  double itfUs; // ITF propio del participante
  double itfBs;
  String observaciones;
  String estadoTransaccion;
  DateTime? fechaTransaccion;
  double montoOrigen;
  double montoConvertido;
  // campos de cuadre (solo en ACCION V)
  int cantidadParticipantes;
  double totalPorcentaje;
  double totalMontoUs;
  double totalMontoBs;
  double totalItfUs;
  double totalItfBs;
  double diferenciaUs;
  String estadoCuadre; // "CUADRADO" / "DESCUADRADO"
  int audUsuario;
  DateTime? audFecha;

  TransaccionParticipanteEntity({
    required this.idParticipante,
    required this.idTransaccion,
    required this.tipoParticipante,
    required this.nombre,
    required this.porcentaje,
    required this.montoUs,
    required this.montoBs,
    required this.itfUs,
    required this.itfBs,
    required this.observaciones,
    required this.estadoTransaccion,
    this.fechaTransaccion,
    required this.montoOrigen,
    required this.montoConvertido,
    required this.cantidadParticipantes,
    required this.totalPorcentaje,
    required this.totalMontoUs,
    required this.totalMontoBs,
    required this.totalItfUs,
    required this.totalItfBs,
    required this.diferenciaUs,
    required this.estadoCuadre,
    required this.audUsuario,
    this.audFecha,
  });
}
