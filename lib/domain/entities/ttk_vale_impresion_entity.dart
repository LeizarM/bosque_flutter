/// Un vale numerado listo para imprimir: una fila por vale físico.
class TtkValeImpresionEntity {
  final BigInt? codEvento;
  final String nombreEvento;
  final DateTime? fechaEvento;
  final String? lugar;
  final BigInt? codTipoTicket;
  final String nombreTipo;
  final String? leyenda;
  final String? colorHex;
  final BigInt? codParticipante;
  final String nombreParticipante;
  final String categoriaTexto;
  final int nroTicket;
  final String nroTicketTexto;

  const TtkValeImpresionEntity({
    this.codEvento,
    this.nombreEvento = '',
    this.fechaEvento,
    this.lugar,
    this.codTipoTicket,
    this.nombreTipo = '',
    this.leyenda,
    this.colorHex,
    this.codParticipante,
    this.nombreParticipante = '',
    this.categoriaTexto = '',
    this.nroTicket = 0,
    this.nroTicketTexto = '',
  });
}
