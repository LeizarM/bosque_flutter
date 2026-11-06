/// Combinación empresa, sucursal y mes con reportes listos para ejecutar.
class HexPendienteEntity {
  final BigInt? codEmpresa;
  final BigInt? codSucursal;
  final String? nombreSucursal;
  final int anio;
  final int mes;
  final int cantidadReportes;

  const HexPendienteEntity({
    this.codEmpresa,
    this.codSucursal,
    this.nombreSucursal,
    this.anio = 0,
    this.mes = 0,
    this.cantidadReportes = 0,
  });
}

/// Vista previa de la planilla por empleado, antes de ejecutarla.
class HexPrevistaEmpleadoEntity {
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final String? nombreArea;
  final double montoHoras;
  final double montoComidas;
  final double total;
  final bool esProvisional;
  final int cantidadReportes;
  final bool tieneAvisoBiometrico;
  final bool tienePeriodoAnterior;

  /// D39: la combinación de la fila; en el lote del mes hay una por empleado
  /// y combinación, ordenadas por sucursal.
  final BigInt? codEmpresa;
  final BigInt? codSucursal;
  final String? nombreSucursal;

  const HexPrevistaEmpleadoEntity({
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.nombreArea,
    this.montoHoras = 0,
    this.montoComidas = 0,
    this.total = 0,
    this.esProvisional = false,
    this.cantidadReportes = 0,
    this.tieneAvisoBiometrico = false,
    this.tienePeriodoAnterior = false,
    this.codEmpresa,
    this.codSucursal,
    this.nombreSucursal,
  });
}

/// Línea de la vista previa: un tramo o una comida de un reporte, con el
/// haber, el divisor y el costo hora con que se valuó.
class HexPrevistaLineaEntity {
  final BigInt? idReporte;
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final DateTime? fechaJornada;
  final String tipo;
  final String tipoDia;
  final DateTime? inicio;
  final DateTime? fin;
  final String origenInicio;
  final String origenFin;
  final bool esPeriodoAnterior;
  final bool esProvisional;
  final bool avisoBiometrico;
  final double haberBasico;
  final BigInt? codPlanillaSueldo;
  final double? divisor;
  final double costoHora;
  final String concepto;
  final String codigo;
  final String leyenda;
  final int? minutos;
  final double cantidad;
  final double? multiplicador;
  final double valorUnitario;
  final double monto;

  /// D39: la combinación de la línea (en el lote del mes hay varias).
  final BigInt? codEmpresa;
  final BigInt? codSucursal;
  final String? nombreSucursal;

  const HexPrevistaLineaEntity({
    this.idReporte,
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.fechaJornada,
    this.tipo = '',
    this.tipoDia = '',
    this.inicio,
    this.fin,
    this.origenInicio = '',
    this.origenFin = '',
    this.esPeriodoAnterior = false,
    this.esProvisional = false,
    this.avisoBiometrico = false,
    this.haberBasico = 0,
    this.codPlanillaSueldo,
    this.divisor,
    this.costoHora = 0,
    this.concepto = '',
    this.codigo = '',
    this.leyenda = '',
    this.minutos,
    this.cantidad = 0,
    this.multiplicador,
    this.valorUnitario = 0,
    this.monto = 0,
    this.codEmpresa,
    this.codSucursal,
    this.nombreSucursal,
  });
}

/// Aviso que RRHH debe revisar antes de ejecutar (haber en cero, sin
/// biométrico, valor provisional…).
class HexAvisoEntity {
  final BigInt? idReporte;
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final DateTime? fechaJornada;

  /// `BIOMETRICO`, `PROVISIONAL`, `SIN_HABER`, `HABER_CERO`, `SIN_HORAS` o
  /// `ANTES_INICIO`.
  final String tipoAviso;
  final String detalle;

  /// D39: la sucursal del reporte (el lote del mes junta varias).
  final BigInt? codSucursal;
  final String? nombreSucursal;

  const HexAvisoEntity({
    this.idReporte,
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.fechaJornada,
    this.tipoAviso = '',
    this.detalle = '',
    this.codSucursal,
    this.nombreSucursal,
  });
}

/// D39: un reporte del mes que aún no termina de firmarse y bloquea la
/// planilla; [textoPendiente] y [debeFirmar] los redacta el SP.
class HexPlanillaFirmaEntity {
  final BigInt? idReporte;
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final DateTime? fechaJornada;
  final String tipo;
  final String tipoTexto;

  /// `REPORTADO` o `VISTO_BUENO`.
  final String estado;
  final String estadoTexto;
  final BigInt? codEmpresa;
  final BigInt? codSucursal;
  final String? nombreSucursal;

  /// Los nombres de quienes deben firmar, separados por coma.
  final String? debeFirmar;
  final String textoPendiente;

  const HexPlanillaFirmaEntity({
    this.idReporte,
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.fechaJornada,
    this.tipo = '',
    this.tipoTexto = '',
    this.estado = '',
    this.estadoTexto = '',
    this.codEmpresa,
    this.codSucursal,
    this.nombreSucursal,
    this.debeFirmar,
    this.textoPendiente = '',
  });
}
