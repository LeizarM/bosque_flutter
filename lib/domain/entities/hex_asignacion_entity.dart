/// Asignación de horas extra (`thex_asignacion`, D37): un empleado y una
/// jornada, sin horas. [puedeQuitar] y los textos los decide el SP.
class HexAsignacionEntity {
  final BigInt? idAsignacion;
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final DateTime? fechaJornada;

  /// `ACTIVA` o `QUITADA`.
  final String estado;
  final String estadoTexto;
  final BigInt? codEmpleadoAsignador;
  final String nombreAsignador;

  /// D41: lo que escribió quien asignó (antes `observacion`).
  final String? motivo;
  final DateTime? fechaAsignacion;
  final DateTime? fechaQuitada;
  final BigInt? codEmpleadoQuita;
  final String? nombreQuita;
  final int cantidadReportes;
  final bool puedeQuitar;
  final int totalFilas;

  /// Adenda D37: `CON_REPORTE`, `PENDIENTE`, `FALTA` o `SIN_REPORTE`; nulo si
  /// la asignación no está activa. [avisoResultado] lo redacta el SP.
  final String? resultado;
  final String? avisoResultado;

  /// D42: «Asignada el …, con fecha atrasada (regularización)»; nulo si se
  /// asignó a tiempo o ya no está activa. Texto del SP.
  final String? textoAtrasada;

  const HexAsignacionEntity({
    this.idAsignacion,
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.fechaJornada,
    this.estado = '',
    this.estadoTexto = '',
    this.codEmpleadoAsignador,
    this.nombreAsignador = '',
    this.motivo,
    this.fechaAsignacion,
    this.fechaQuitada,
    this.codEmpleadoQuita,
    this.nombreQuita,
    this.cantidadReportes = 0,
    this.puedeQuitar = false,
    this.totalFilas = 0,
    this.resultado,
    this.avisoResultado,
    this.textoAtrasada,
  });
}
