/// La jornada que se simula: quién, qué día, su horario, sus marcas, si tenía
/// asignación o reporte, de dónde salieron la entrada y la salida, el costo
/// hora y los totales. Todo en palabras del SP; la app no calcula.
class HexSimulacionJornadaEntity {
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final String cargo;
  final String nombreSucursal;
  final DateTime? fechaJornada;
  final String tipoDia;
  final String textoTipoDia;
  final DateTime? horarioIngreso;
  final DateTime? horarioSalida;
  final String textoHorario;
  final String textoMarcas;
  final bool conAsignacion;
  final String textoAsignacion;
  final BigInt? idReporte;
  final String textoReporte;

  /// La entrada y la salida con las que se calculó (las elegidas o las del SP).
  final DateTime? inicioUsado;
  final DateTime? finUsado;
  final String textoOrigen;
  final double? haberBasico;
  final double? divisor;
  final double? costoHora;

  /// Bs por horas, Bs por comidas y el total.
  final double totalHoras;
  final double totalComidas;
  final double total;
  final String resumen;

  const HexSimulacionJornadaEntity({
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.cargo = '',
    this.nombreSucursal = '',
    this.fechaJornada,
    this.tipoDia = '',
    this.textoTipoDia = '',
    this.horarioIngreso,
    this.horarioSalida,
    this.textoHorario = '',
    this.textoMarcas = '',
    this.conAsignacion = false,
    this.textoAsignacion = '',
    this.idReporte,
    this.textoReporte = '',
    this.inicioUsado,
    this.finUsado,
    this.textoOrigen = '',
    this.haberBasico,
    this.divisor,
    this.costoHora,
    this.totalHoras = 0,
    this.totalComidas = 0,
    this.total = 0,
    this.resumen = '',
  });
}
