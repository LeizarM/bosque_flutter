/// Origen: tabla `dbo.tbio_bioHrs`, via `p_list_BioHrs`.
///
/// Plantilla de turno (hora de ingreso y salida).
class BioHrsEntity {
  final BigInt idHrs;
  final String nombre;
  final DateTime? ingreso;
  final DateTime? salida;
  final double cantDias;
  final double cantMinutos;
  final String estado;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrsEntity({
    required this.idHrs,
    required this.nombre,
    this.ingreso,
    this.salida,
    required this.cantDias,
    required this.cantMinutos,
    required this.estado,
    required this.audUsuario,
    this.audFecha,
  });
}
