/// Evento de RRHH (aniversario, fiesta, navidad) con sus totales y las
/// acciones que su estado permite (`puede*`), tal como las decide el SP.
class TtkEventoEntity {
  final BigInt? codEvento;
  final String nombre;
  final String? descripcion;
  final DateTime? fecha;
  final String? lugar;
  final bool usaTickets;
  final bool usaBingo;
  final int mesesReciente;
  final String estado;
  final String estadoTexto;
  final int totalParticipantes;
  final int totalEmpleados;
  final int totalRecientes;
  final int totalInvitados;
  final int totalTipos;
  final int totalTickets;
  final BigInt? codBingo;
  final String? estadoBingo;
  final bool puedeEditar;
  final bool puedeEmitir;
  final bool puedeVolverBorrador;
  final bool puedeImprimir;
  final bool puedeCerrar;
  final bool puedeEliminar;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const TtkEventoEntity({
    this.codEvento,
    required this.nombre,
    this.descripcion,
    this.fecha,
    this.lugar,
    this.usaTickets = true,
    this.usaBingo = false,
    this.mesesReciente = 3,
    this.estado = '',
    this.estadoTexto = '',
    this.totalParticipantes = 0,
    this.totalEmpleados = 0,
    this.totalRecientes = 0,
    this.totalInvitados = 0,
    this.totalTipos = 0,
    this.totalTickets = 0,
    this.codBingo,
    this.estadoBingo,
    this.puedeEditar = false,
    this.puedeEmitir = false,
    this.puedeVolverBorrador = false,
    this.puedeImprimir = false,
    this.puedeCerrar = false,
    this.puedeEliminar = false,
    this.audUsuario,
    this.audFecha,
  });

  TtkEventoEntity copyWith({
    String? nombre,
    String? descripcion,
    DateTime? fecha,
    String? lugar,
    bool? usaTickets,
    bool? usaBingo,
    int? mesesReciente,
  }) => TtkEventoEntity(
    codEvento: codEvento,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    fecha: fecha ?? this.fecha,
    lugar: lugar ?? this.lugar,
    usaTickets: usaTickets ?? this.usaTickets,
    usaBingo: usaBingo ?? this.usaBingo,
    mesesReciente: mesesReciente ?? this.mesesReciente,
    estado: estado,
    estadoTexto: estadoTexto,
    totalParticipantes: totalParticipantes,
    totalEmpleados: totalEmpleados,
    totalRecientes: totalRecientes,
    totalInvitados: totalInvitados,
    totalTipos: totalTipos,
    totalTickets: totalTickets,
    codBingo: codBingo,
    estadoBingo: estadoBingo,
    puedeEditar: puedeEditar,
    puedeEmitir: puedeEmitir,
    puedeVolverBorrador: puedeVolverBorrador,
    puedeImprimir: puedeImprimir,
    puedeCerrar: puedeCerrar,
    puedeEliminar: puedeEliminar,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}
