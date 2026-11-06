/// Reporte de horas extra de un empleado en una jornada, con sus montos y las
/// acciones que su estado permite (`puede*`), tal como las decide el SP.
class HexReporteEntity {
  final BigInt? idReporte;
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final DateTime? fechaJornada;
  final String tipo;
  final String tipoTexto;
  final String tipoDia;
  final String tipoDiaTexto;
  final BigInt? codSucursal;
  final String? nombreSucursal;
  final DateTime? inicio;
  final DateTime? fin;

  /// `HORARIO`, `BIOMETRICO`, `APP` o `EDITADO`; nulo = pendiente de biométrico.
  final String? origenInicio;
  final String? origenFin;
  final String? motivo;
  final double? horasPagables;
  final double? montoHoras;
  final double? montoComidas;
  final double? montoTotal;

  /// Códigos de comida separados por coma, por ejemplo `C,DC`.
  final String? comidas;

  /// Nulo, como los montos, si quien consulta no ve dinero (D38).
  final double? costoHora;
  final bool esProvisional;
  final String estado;
  final String estadoTexto;
  final bool esEditado;
  final bool avisoBiometrico;
  final bool puedeAnular;
  final bool puedeEditarMotivo;
  final bool puedeEditarHora;
  final bool puedeVistoBueno;
  final bool puedeAprobar;
  final bool puedeRechazar;
  final int totalFilas;

  /// Solo en la bandeja del jefe: el encargado que dio el visto bueno.
  final BigInt? codEncargado;
  final String? nombreEncargado;

  /// De quién espera el reporte, en palabras del SP; nulo si no llegó.
  final String? textoPendiente;

  /// La observación del último rechazo o anulación; nulo en otros estados.
  final String? motivoRechazo;

  /// Dónde marcó con la app (grados y precisión en metros). Solo el detalle
  /// los trae; son nulos en las listas y en lo que vino del biométrico.
  final double? latInicio;
  final double? lonInicio;
  final double? precisionInicio;
  final double? latFin;
  final double? lonFin;
  final double? precisionFin;

  /// La hora de cada marca por app, aunque la hora efectiva venga del
  /// biométrico. Solo el detalle la trae; nula si no marcó por app.
  final DateTime? inicioApp;
  final DateTime? finApp;

  /// «2 h 30 min en total (2 h con comida · 0,50 h pagadas)», del SP (D36);
  /// nulo si el reporte no tiene inicio o fin, o el SP aún no lo manda.
  final String? resumenTiempo;

  /// D38: lo que el SP deja ver a quien consulta. Sin detalle no se piden las
  /// líneas ni los tramos; sin montos el dinero llega nulo y no se dibuja.
  final bool puedeVerDetalle;
  final bool verMontos;
  final bool verHistorial;

  /// Adenda D37: reportado sin salida por app ni fin corregido. El aviso lo
  /// redacta el SP para quien firma; nulo si no aplica.
  final bool sinSalidaMarcada;
  final String? avisoSalida;

  const HexReporteEntity({
    this.idReporte,
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.fechaJornada,
    this.tipo = '',
    this.tipoTexto = '',
    this.tipoDia = '',
    this.tipoDiaTexto = '',
    this.codSucursal,
    this.nombreSucursal,
    this.inicio,
    this.fin,
    this.origenInicio,
    this.origenFin,
    this.motivo,
    this.horasPagables,
    this.montoHoras,
    this.montoComidas,
    this.montoTotal,
    this.comidas,
    this.costoHora,
    this.esProvisional = false,
    this.estado = '',
    this.estadoTexto = '',
    this.esEditado = false,
    this.avisoBiometrico = false,
    this.puedeAnular = false,
    this.puedeEditarMotivo = false,
    this.puedeEditarHora = false,
    this.puedeVistoBueno = false,
    this.puedeAprobar = false,
    this.puedeRechazar = false,
    this.totalFilas = 0,
    this.codEncargado,
    this.nombreEncargado,
    this.textoPendiente,
    this.motivoRechazo,
    this.latInicio,
    this.lonInicio,
    this.precisionInicio,
    this.latFin,
    this.lonFin,
    this.precisionFin,
    this.inicioApp,
    this.finApp,
    this.resumenTiempo,
    this.puedeVerDetalle = false,
    this.verMontos = false,
    this.verHistorial = false,
    this.sinSalidaMarcada = false,
    this.avisoSalida,
  });

  /// Hay un par lat/lon usable (finito y dentro de rango) en la entrada.
  bool get tieneUbicacionInicio => _par(latInicio, lonInicio);

  /// Hay un par lat/lon usable en la salida.
  bool get tieneUbicacionFin => _par(latFin, lonFin);

  /// Marcó con la app al menos una vez y se guardó dónde.
  bool get tieneUbicacion => tieneUbicacionInicio || tieneUbicacionFin;

  static bool _par(double? lat, double? lon) =>
      lat != null &&
      lon != null &&
      lat.isFinite &&
      lon.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lon >= -180 &&
      lon <= 180;
}
