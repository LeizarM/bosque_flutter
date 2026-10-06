/// Lo que se manda a las tres acciones del detalle: `/cheque/accion/devolver`,
/// `/cheque/accion/cerrar` y `/cheque/accion/fecha-cobro`
/// (`AccionChequeRequest` del contrato).
///
/// No todos los campos aplican a todas:
/// - [fecha]: dia de la accion; no puede ser anterior a hoy. Null = ahora.
/// - [estado]: en cerrar, COB con verificacion o CEF/CCH/PAP/DPR sin ella; en
///   fecha de cobro, VEN o ADE. Devolver siempre es DEV y lo pone el servidor.
/// - [nroSap]: obligatorio al cerrar (2 a 40 caracteres).
/// - [conVerificacion]: solo en cerrar; elige entre COB y los otros cuatro.
/// - [nuevaFechaCobro]: solo en fecha de cobro.
/// - [observacion]: 2 a 200 caracteres; vacia vale.
///
/// Cada accion exige que su boton de la rama K este habilitado: eso lo dice
/// `BotonesChequeEntity`, y el servidor lo vuelve a comprobar.
class AccionChequeRequestEntity {
  final BigInt codCheque;
  final DateTime? fecha;
  final String? estado;
  final String? nroSap;
  final String? observacion;
  final bool? conVerificacion;
  final DateTime? nuevaFechaCobro;

  const AccionChequeRequestEntity({
    required this.codCheque,
    this.fecha,
    this.estado,
    this.nroSap,
    this.observacion,
    this.conVerificacion,
    this.nuevaFechaCobro,
  });
}
