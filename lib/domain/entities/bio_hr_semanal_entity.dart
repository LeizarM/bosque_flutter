/// Origen: tabla `dbo.tbio_bioHrSemanal`, via `p_list_BioHrSemanal`.
///
/// Horario semanal con nombre, compuesto por 7 filas de
/// `BioHrSemanalDetalleEntity` (una por dia).
class BioHrSemanalEntity {
  final BigInt idHrSemanal;
  final String nombre;
  final String estado;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrSemanalEntity({
    required this.idHrSemanal,
    required this.nombre,
    required this.estado,
    required this.audUsuario,
    this.audFecha,
  });
}
