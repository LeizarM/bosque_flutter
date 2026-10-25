/// Tipo de vale de un evento (almuerzo, bebida…) con cuántos recibe cada
/// grupo y lo ya repartido.
class TtkTipoTicketEntity {
  final BigInt? codTipoTicket;
  final BigInt? codEvento;
  final String nombre;
  final String? leyenda;
  final int cantEmpleado;
  final int cantReciente;
  final int cantInvitado;
  final String? colorHex;
  final int? orden;
  final int totalVales;
  final int totalParticipantes;
  final bool puedeEditar;
  final bool daCartonBingo;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const TtkTipoTicketEntity({
    this.codTipoTicket,
    this.codEvento,
    required this.nombre,
    this.leyenda,
    this.cantEmpleado = 1,
    this.cantReciente = 0,
    this.cantInvitado = 0,
    this.colorHex,
    this.orden,
    this.totalVales = 0,
    this.totalParticipantes = 0,
    this.puedeEditar = false,
    this.daCartonBingo = false,
    this.audUsuario,
    this.audFecha,
  });

  TtkTipoTicketEntity copyWith({
    BigInt? codEvento,
    String? nombre,
    String? leyenda,
    int? cantEmpleado,
    int? cantReciente,
    int? cantInvitado,
    String? colorHex,
    bool quitarColor = false,
    int? orden,
  }) => TtkTipoTicketEntity(
    codTipoTicket: codTipoTicket,
    codEvento: codEvento ?? this.codEvento,
    nombre: nombre ?? this.nombre,
    leyenda: leyenda ?? this.leyenda,
    cantEmpleado: cantEmpleado ?? this.cantEmpleado,
    cantReciente: cantReciente ?? this.cantReciente,
    cantInvitado: cantInvitado ?? this.cantInvitado,
    colorHex: quitarColor ? null : (colorHex ?? this.colorHex),
    orden: orden ?? this.orden,
    totalVales: totalVales,
    totalParticipantes: totalParticipantes,
    puedeEditar: puedeEditar,
    daCartonBingo: daCartonBingo,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}
