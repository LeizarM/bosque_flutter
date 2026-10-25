/// Cuántos vales de un tipo recibe un participante y, ya emitidos, su rango.
class TtkParticipanteTicketEntity {
  final BigInt? codParticipanteTicket;
  final BigInt? codParticipante;
  final BigInt? codTipoTicket;
  final String nombreTipo;
  final String? colorHex;
  final int cantidad;
  final int cantidadDefecto;
  final bool cantidadManual;
  final int? nroDesde;
  final int? nroHasta;
  final String rangoTexto;
  final bool puedeEditar;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const TtkParticipanteTicketEntity({
    this.codParticipanteTicket,
    this.codParticipante,
    this.codTipoTicket,
    this.nombreTipo = '',
    this.colorHex,
    this.cantidad = 0,
    this.cantidadDefecto = 0,
    this.cantidadManual = false,
    this.nroDesde,
    this.nroHasta,
    this.rangoTexto = '',
    this.puedeEditar = false,
    this.audUsuario,
    this.audFecha,
  });

  TtkParticipanteTicketEntity copyWith({int? cantidad}) =>
      TtkParticipanteTicketEntity(
        codParticipanteTicket: codParticipanteTicket,
        codParticipante: codParticipante,
        codTipoTicket: codTipoTicket,
        nombreTipo: nombreTipo,
        colorHex: colorHex,
        cantidad: cantidad ?? this.cantidad,
        cantidadDefecto: cantidadDefecto,
        cantidadManual: cantidadManual,
        nroDesde: nroDesde,
        nroHasta: nroHasta,
        rangoTexto: rangoTexto,
        puedeEditar: puedeEditar,
        audUsuario: audUsuario,
        audFecha: audFecha,
      );
}
