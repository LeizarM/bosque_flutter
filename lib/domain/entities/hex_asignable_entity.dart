/// Un empleado al que el actor puede asignar horas extra en una jornada
/// (D37), con su asignación, su reporte y el aviso que no bloquea. Las
/// banderas `puede*` y los textos los decide el SP.
class HexAsignableEntity {
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final BigInt? codCargo;
  final String? cargo;
  final BigInt? codSucursal;
  final String? nombreSucursal;
  final DateTime? fechaJornada;
  final BigInt? idAsignacion;
  final bool estaAsignado;
  final BigInt? codEmpleadoAsignador;
  final String? nombreAsignador;

  /// D41: lo que escribió quien asignó (antes `observacion`).
  final String? motivo;
  final int cantidadReportes;
  final BigInt? idReporte;
  final String? estadoReporte;
  final String? estadoReporteTexto;

  /// `VACACION`, `BAJA`, `PERMISO` o `SABADO`; nulo sin aviso.
  final String? tipoAviso;
  final String? aviso;
  final bool puedeAsignar;
  final bool puedeQuitar;
  final String textoEstado;

  /// Adenda D37: `CON_REPORTE`, `PENDIENTE`, `FALTA` o `SIN_REPORTE`; nulo si
  /// la asignación no está activa. [avisoResultado] lo redacta el SP.
  final String? resultado;
  final String? avisoResultado;

  /// D42: «Asignada el …, con fecha atrasada (regularización)»; nulo si se
  /// asignó a tiempo. Texto del SP.
  final String? textoAtrasada;

  /// D42: la primera jornada que se asigna hoy (el inicio del módulo con la
  /// regularización abierta); el calendario empieza ahí. Nula: sin límite.
  final DateTime? fechaMinimaAsignable;

  /// D42: aviso de la regularización abierta; nulo si está cerrada.
  final String? textoRegularizacion;

  const HexAsignableEntity({
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.codCargo,
    this.cargo,
    this.codSucursal,
    this.nombreSucursal,
    this.fechaJornada,
    this.idAsignacion,
    this.estaAsignado = false,
    this.codEmpleadoAsignador,
    this.nombreAsignador,
    this.motivo,
    this.cantidadReportes = 0,
    this.idReporte,
    this.estadoReporte,
    this.estadoReporteTexto,
    this.tipoAviso,
    this.aviso,
    this.puedeAsignar = false,
    this.puedeQuitar = false,
    this.textoEstado = '',
    this.resultado,
    this.avisoResultado,
    this.textoAtrasada,
    this.fechaMinimaAsignable,
    this.textoRegularizacion,
  });
}
