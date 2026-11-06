/// D43: una jornada pasada asignada sin reporte que el encargado puede
/// registrar mientras la regularización está abierta. Los textos, el tipo y
/// las horas sugeridas son del SP; la app solo los muestra.
class HexJornadaPasadaEntity {
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final String? cargo;
  final String? nombreSucursal;
  final DateTime? fechaJornada;
  final String tipoDia;
  final String textoTipoDia;
  final String textoHorario;

  /// `DESPUES`, `ANTES` o `SIN_HORARIO`; el tipo real lo decide el SP.
  final String tipoSugerido;
  final DateTime? inicioSugerido;
  final DateTime? finSugerido;
  final String? motivo;
  final String textoAyuda;

  /// Con `false` se muestra apagada, con [textoAyuda] como razón.
  final bool puedeCrear;
  final String textoRegularizacion;

  const HexJornadaPasadaEntity({
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.cargo,
    this.nombreSucursal,
    this.fechaJornada,
    this.tipoDia = '',
    this.textoTipoDia = '',
    this.textoHorario = '',
    this.tipoSugerido = '',
    this.inicioSugerido,
    this.finSugerido,
    this.motivo,
    this.textoAyuda = '',
    this.puedeCrear = false,
    this.textoRegularizacion = '',
  });
}

/// D43: lo que viaja al crear el reporte de un día pasado: a quién (el
/// empleado, no la identidad de quien crea), la jornada, las horas y la
/// justificación. El tipo lo decide el SP con las horas y el horario.
class HexReportePasadoEntity {
  final BigInt codEmpleado;
  final DateTime fechaJornada;
  final DateTime inicio;
  final DateTime fin;
  final String observacion;

  const HexReportePasadoEntity({
    required this.codEmpleado,
    required this.fechaJornada,
    required this.inicio,
    required this.fin,
    required this.observacion,
  });
}
