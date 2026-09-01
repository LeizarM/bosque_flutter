/// Origen: `POST /biometrico/bitacora/listar` — una entrada de la bitácora de
/// cambios manuales (Marcaciones olvidadas y Horarios). Sólo lectura: nadie la
/// registra desde la app, la escriben los propios `p_abm_Bio*` afectados.
class BitacoraEntity {
  final int idBitacora;
  final String tabla;
  final String idRegistro;
  final String accion;
  final String? motivo;
  final int audUsuario;
  final String nombreUsuario;
  final DateTime? audFecha;

  const BitacoraEntity({
    required this.idBitacora,
    required this.tabla,
    required this.idRegistro,
    required this.accion,
    this.motivo,
    required this.audUsuario,
    required this.nombreUsuario,
    this.audFecha,
  });
}
