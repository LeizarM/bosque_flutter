/// Reporte dentro de una planilla ejecutada: el anexo con el origen de cada
/// hora, el haber con que se calculó y el desglose por tipo de hora.
class HexPlanillaDetalleEntity {
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final String? nombreArea;

  /// D39: la planilla y la sucursal por la que se agrupa y ordena el anexo.
  final BigInt? idPlanilla;
  final BigInt? codSucursal;
  final String? nombreSucursal;
  final int ordenSucursal;
  final BigInt? idReporte;
  final DateTime? fechaJornada;
  final String tipo;
  final String tipoTexto;
  final String? tipoDia;
  final String? motivo;
  final DateTime? inicio;
  final DateTime? fin;
  final String origenInicio;
  final String origenFin;

  /// El origen de cada hora en palabras, como lo arma el SP para el anexo.
  final String origenInicioTexto;
  final String origenFinTexto;
  final bool esPeriodoAnterior;
  final double haberBasico;
  final BigInt? codPlanillaSueldo;
  final double? divisor;
  final double costoHora;

  /// Horas simples, al 50 %, al 100 %, domingo, feriado y otras.
  final double hHS;
  final double hH50;
  final double hH100;
  final double hHD;
  final double hHF;
  final double hOtros;
  final String? comidas;
  final double montoHoras;
  final double montoComidas;
  final double total;

  const HexPlanillaDetalleEntity({
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.nombreArea,
    this.idPlanilla,
    this.codSucursal,
    this.nombreSucursal,
    this.ordenSucursal = 0,
    this.idReporte,
    this.fechaJornada,
    this.tipo = '',
    this.tipoTexto = '',
    this.tipoDia,
    this.motivo,
    this.inicio,
    this.fin,
    this.origenInicio = '',
    this.origenFin = '',
    this.origenInicioTexto = '',
    this.origenFinTexto = '',
    this.esPeriodoAnterior = false,
    this.haberBasico = 0,
    this.codPlanillaSueldo,
    this.divisor,
    this.costoHora = 0,
    this.hHS = 0,
    this.hH50 = 0,
    this.hH100 = 0,
    this.hHD = 0,
    this.hHF = 0,
    this.hOtros = 0,
    this.comidas,
    this.montoHoras = 0,
    this.montoComidas = 0,
    this.total = 0,
  });
}
