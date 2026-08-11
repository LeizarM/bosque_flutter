// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** tabla `dbo.trs_Sabado`, via `p_list_trs_Sabado @ACCION='L'`.
///
/// `personasTrabajan` no sale de @L sino de @C (cobertura). Si el listado vino
/// por @L el campo queda en 0, y eso es correcto, no un dato perdido.
///
/// Un sábado del período: una COLUMNA de la grilla.
class SabadoEntity {
  final int idSabado;
  final int idRol;
  final DateTime? fecha;
  final int anio;
  final int mes;
  final int trimestre;

  /// 1..53. La paridad de este número es la rotación: impar = A, par = B.
  final int indiceAnio;

  /// 'A' o 'B', ya derivado por el backend.
  final String grupoQueRota;

  /// Resumen, NO la autoridad: un feriado departamental alcanza sólo a algunas
  /// sucursales, y eso se resuelve celda por celda.
  final int esFeriado;

  /// null = sábado normal · TOTAL = vienen todos · SELECTIVA = sólo convocados.
  final String? alcanceEvento;
  final String motivoEspecial;
  final int activo;

  // Sólo en la acción de cobertura.
  final int personasTrabajan;

  const SabadoEntity({
    required this.idSabado,
    required this.idRol,
    this.fecha,
    required this.anio,
    required this.mes,
    required this.trimestre,
    required this.indiceAnio,
    required this.grupoQueRota,
    required this.esFeriado,
    this.alcanceEvento,
    required this.motivoEspecial,
    required this.activo,
    required this.personasTrabajan,
  });

  bool get tieneEvento => alcanceEvento != null && alcanceEvento!.isNotEmpty;
  bool get esFeriadoBool => esFeriado == 1;
}
