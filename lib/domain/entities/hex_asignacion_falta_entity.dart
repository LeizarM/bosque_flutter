/// Una asignación activa que terminó en falta (adenda D37): no marcó salida
/// ni entrada al día siguiente, y esas horas no se pagan. El texto es del SP.
class HexAsignacionFaltaEntity {
  final BigInt? idAsignacion;
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final DateTime? fechaJornada;

  /// Siempre `FALTA`.
  final String resultado;
  final String avisoResultado;

  const HexAsignacionFaltaEntity({
    this.idAsignacion,
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.fechaJornada,
    this.resultado = '',
    this.avisoResultado = '',
  });
}
