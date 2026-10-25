/// Persona en la lista de un evento: empleado (categoría E o R) o invitado (I),
/// con el resumen de sus vales.
class TtkParticipanteEntity {
  final BigInt? codParticipante;
  final BigInt? codEvento;
  final BigInt? codEmpleado;
  final String nombreCompleto;
  final String? nombreInvitado;
  final String? documento;
  final BigInt? codEmpleadoAnfitrion;
  final String? nombreAnfitrion;
  final String? cargo;
  final DateTime? fechaIngreso;
  final String? categoria;
  final String categoriaTexto;
  final bool categoriaManual;
  final int totalVales;
  final String resumenVales;
  final String? observacion;
  final bool puedeEditar;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const TtkParticipanteEntity({
    this.codParticipante,
    this.codEvento,
    this.codEmpleado,
    this.nombreCompleto = '',
    this.nombreInvitado,
    this.documento,
    this.codEmpleadoAnfitrion,
    this.nombreAnfitrion,
    this.cargo,
    this.fechaIngreso,
    this.categoria,
    this.categoriaTexto = '',
    this.categoriaManual = false,
    this.totalVales = 0,
    this.resumenVales = '',
    this.observacion,
    this.puedeEditar = false,
    this.audUsuario,
    this.audFecha,
  });

  bool get esInvitado => codEmpleado == null;

  TtkParticipanteEntity copyWith({
    BigInt? codEvento,
    String? nombreInvitado,
    String? documento,
    BigInt? codEmpleadoAnfitrion,
    bool quitarAnfitrion = false,
    String? categoria,
    String? observacion,
  }) => TtkParticipanteEntity(
    codParticipante: codParticipante,
    codEvento: codEvento ?? this.codEvento,
    codEmpleado: codEmpleado,
    nombreCompleto: nombreCompleto,
    nombreInvitado: nombreInvitado ?? this.nombreInvitado,
    documento: documento ?? this.documento,
    codEmpleadoAnfitrion:
        quitarAnfitrion
            ? null
            : (codEmpleadoAnfitrion ?? this.codEmpleadoAnfitrion),
    nombreAnfitrion: nombreAnfitrion,
    cargo: cargo,
    fechaIngreso: fechaIngreso,
    categoria: categoria ?? this.categoria,
    categoriaTexto: categoriaTexto,
    categoriaManual: categoriaManual,
    totalVales: totalVales,
    resumenVales: resumenVales,
    observacion: observacion ?? this.observacion,
    puedeEditar: puedeEditar,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}
