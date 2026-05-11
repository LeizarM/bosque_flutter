class AsientoEntity {
  BigInt idAsiento;
  BigInt idTransaccion;
  int numero;
  String tipoAsiento;      // PR / PE / MP
  int codBancoRef;
  String banco;
  String cuentaDebe;
  String cuentaHaber;
  String descripcion;
  double debitoUs;
  double creditoUs;
  double debitoBs;
  double creditoBs;
  double tcAplicado;
  String estadoTransaccion;
  DateTime? fechaTransaccion;
  // campos de cuadre (solo en ACCION V)
  double totalDebitoUs;
  double totalCreditoUs;
  double totalDebitoBs;
  double totalCreditoBs;
  double diferenciaBs;
  String estadoCuadre;     // "CUADRADO" / "DESCUADRADO"
  int audUsuario;
  DateTime? audFecha;

  AsientoEntity({
    required this.idAsiento,
    required this.idTransaccion,
    required this.numero,
    required this.tipoAsiento,
    required this.codBancoRef,
    required this.banco,
    required this.cuentaDebe,
    required this.cuentaHaber,
    required this.descripcion,
    required this.debitoUs,
    required this.creditoUs,
    required this.debitoBs,
    required this.creditoBs,
    required this.tcAplicado,
    required this.estadoTransaccion,
    this.fechaTransaccion,
    required this.totalDebitoUs,
    required this.totalCreditoUs,
    required this.totalDebitoBs,
    required this.totalCreditoBs,
    required this.diferenciaBs,
    required this.estadoCuadre,
    required this.audUsuario,
    this.audFecha,
  });
}
