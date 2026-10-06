/// Una baja médica de la Planilla de Incapacidad (`tac_planillaIncapacidad`).
///
/// Los importes y los días los calcula el SP al cargar la baja; desde la app
/// solo cambia [fueRevisado]. [desde] y [hasta] llevan la hora del permiso.
class PlanillaIncapacidadEntity {
  final int idPIT;
  final int? codPermiso;
  final String numSeguro;
  final String motivo;
  final String datoEmpleado;
  final double salarioMensual;
  final double salarioDiario;
  final double porcentajeAl75;
  final int nroBaja;
  final DateTime? desde;
  final DateTime? hasta;
  final int diasBaja;

  /// Días que cubre el seguro (desde el 4.º). La columna dice "Cordes" por
  /// historia; vale para cualquier caja.
  final int diasAsumidosCordes;
  final double totalDescuento;
  final bool fueRevisado;
  final DateTime? fechaRevisado;
  final int? audUsuario;
  final DateTime? audFecha;

  /// Del JOIN con la afiliación (`trh_seguro`): 'CORDES ESPPAPEL - LA PAZ'.
  final int? codSeguro;
  final String seguro;

  const PlanillaIncapacidadEntity({
    required this.idPIT,
    this.codPermiso,
    required this.numSeguro,
    required this.motivo,
    required this.datoEmpleado,
    required this.salarioMensual,
    required this.salarioDiario,
    required this.porcentajeAl75,
    required this.nroBaja,
    this.desde,
    this.hasta,
    required this.diasBaja,
    required this.diasAsumidosCordes,
    required this.totalDescuento,
    required this.fueRevisado,
    this.fechaRevisado,
    this.audUsuario,
    this.audFecha,
    this.codSeguro,
    this.seguro = '',
  });

  /// La misma baja con otra marca de revisión. Desmarcar borra la fecha, igual
  /// que el SP.
  PlanillaIncapacidadEntity conRevision(bool revisado, {DateTime? fecha}) =>
      PlanillaIncapacidadEntity(
        idPIT: idPIT,
        codPermiso: codPermiso,
        numSeguro: numSeguro,
        motivo: motivo,
        datoEmpleado: datoEmpleado,
        salarioMensual: salarioMensual,
        salarioDiario: salarioDiario,
        porcentajeAl75: porcentajeAl75,
        nroBaja: nroBaja,
        desde: desde,
        hasta: hasta,
        diasBaja: diasBaja,
        diasAsumidosCordes: diasAsumidosCordes,
        totalDescuento: totalDescuento,
        fueRevisado: revisado,
        fechaRevisado: revisado ? (fecha ?? DateTime.now()) : null,
        audUsuario: audUsuario,
        audFecha: audFecha,
        codSeguro: codSeguro,
        seguro: seguro,
      );
}
