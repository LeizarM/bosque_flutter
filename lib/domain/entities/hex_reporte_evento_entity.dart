/// Evento del historial de un reporte: quién hizo qué y cuándo, con el valor
/// anterior y el nuevo cuando algo cambió.
class HexReporteEventoEntity {
  final BigInt? idEvento;
  final String tipo;
  final String tipoTexto;
  final BigInt? codEmpleadoActor;
  final String? nombreActor;
  final String? valorAnterior;
  final String? valorNuevo;
  final String? observacion;
  final DateTime? fecha;

  const HexReporteEventoEntity({
    this.idEvento,
    this.tipo = '',
    this.tipoTexto = '',
    this.codEmpleadoActor,
    this.nombreActor,
    this.valorAnterior,
    this.valorNuevo,
    this.observacion,
    this.fecha,
  });
}
