// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** tabla `dbo.trs_Cambio`, via `p_list_trs_Cambio @ACCION='L'`.
///
/// Los nombres de titular y reemplazo vienen ya resueltos por el @L.
///
/// Permuta o cobertura entre dos compañeros.
///
/// Nace `SOLICITADO` y **no toca la grilla**. Recién al aprobarlo se escriben
/// las tres celdas: el titular pasa a 'C', el que cubre aparece con '1' un
/// sábado que no le tocaba, y si hay reposición se le libera ese otro sábado.
class CambioEntity {
  final int idCambio;
  final int idRol;
  final int idSabado;
  final DateTime? sabadoCubierto;
  final int codEmpleadoTitular;
  final String titular;
  final int codEmpleadoReemplazo;
  final String reemplazo;
  final int idSabadoReposicion;
  final DateTime? fechaReposicion;

  /// COBERTURA (alguien cubre y listo) | PERMUTA (se devuelve otro sábado).
  final String tipo;

  /// SOLICITADO | APROBADO | RECHAZADO | ANULADO.
  final String estado;
  final String motivo;
  final int codAprobador;
  final DateTime? fechaSolicitud;
  final DateTime? fechaResolucion;

  const CambioEntity({
    required this.idCambio,
    required this.idRol,
    required this.idSabado,
    this.sabadoCubierto,
    required this.codEmpleadoTitular,
    required this.titular,
    required this.codEmpleadoReemplazo,
    required this.reemplazo,
    required this.idSabadoReposicion,
    this.fechaReposicion,
    required this.tipo,
    required this.estado,
    required this.motivo,
    required this.codAprobador,
    this.fechaSolicitud,
    this.fechaResolucion,
  });

  bool get pendiente => estado == 'SOLICITADO';
  bool get aplicado => estado == 'APROBADO';
}
