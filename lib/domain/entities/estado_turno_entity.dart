// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** tabla `dbo.trs_EstadoTurno`, via `p_list_trs_EstadoTurno @ACCION='L'`.
///
/// Su PK no es IDENTITY: el id se asigna a mano para que sea el mismo numero en
/// todas las bases.
///
/// Catálogo de letras de la grilla, con su color para pintar la leyenda.
class EstadoTurnoEntity {
  final int idEstadoTurno;
  final String codigoExcel;
  final String nombre;

  /// 1 = suma al total de turnos trabajados (sólo el '1').
  final int cuentaTurno;

  /// 1 = deja un hueco en la cobertura de ese sábado.
  final int afectaCobertura;
  final String color;
  final String estado;

  const EstadoTurnoEntity({
    required this.idEstadoTurno,
    required this.codigoExcel,
    required this.nombre,
    required this.cuentaTurno,
    required this.afectaCobertura,
    required this.color,
    required this.estado,
  });
}
