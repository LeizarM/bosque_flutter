// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** tabla `dbo.trs_Rol`, via `p_list_trs_Rol @ACCION='L'`.
///
/// `sabados`, `participantes` y `celdas` NO son columnas de la tabla: son
/// subqueries COUNT dentro del mismo @L.
///
/// Cabecera anual del rol. Un rol es un año y un alcance (empresa/sucursal).
class RolSabadosEntity {
  final int idRol;
  final int codEmpresa;
  final int codSucursal;
  final String sucursal;
  final int anio;
  final String nombre;
  final int turnosObjetivoA;
  final int turnosObjetivoB;
  final int coberturaObjetivo;

  /// 1 = si a alguien le cae el cumpleaños un sábado que le tocaba, queda en 'A'.
  final int aplicaAsuetoCumple;

  /// BORRADOR | PUBLICADO | CERRADO. En CERRADO no se acepta ningún cambio.
  final String estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  // Contadores que trae el listado.
  final int sabados;
  final int participantes;
  final int celdas;

  const RolSabadosEntity({
    required this.idRol,
    required this.codEmpresa,
    required this.codSucursal,
    required this.sucursal,
    required this.anio,
    required this.nombre,
    required this.turnosObjetivoA,
    required this.turnosObjetivoB,
    required this.coberturaObjetivo,
    required this.aplicaAsuetoCumple,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    required this.sabados,
    required this.participantes,
    required this.celdas,
  });

  bool get estaCerrado => estado == 'CERRADO';
}
