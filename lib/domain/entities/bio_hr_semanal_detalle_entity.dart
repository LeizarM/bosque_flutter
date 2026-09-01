/// Origen: tabla `dbo.tbio_bioHrSemanalDetalle`, via
/// `p_list_BioHrSemanalDetalle`.
///
/// Dia de la semana (1-7) -> plantilla de turno, dentro de un horario semanal.
class BioHrSemanalDetalleEntity {
  final BigInt idHrDet;
  final BigInt idHrSemanal;
  final BigInt idHrs;
  final int dia;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrSemanalDetalleEntity({
    required this.idHrDet,
    required this.idHrSemanal,
    required this.idHrs,
    required this.dia,
    required this.audUsuario,
    this.audFecha,
  });
}
