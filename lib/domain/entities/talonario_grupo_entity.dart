/// Agrupación de TIPOS de talonario (no de talonarios).
/// Tabla tmto_talonarioGrupo. Sirve para filtrar listados y reportes.
class TalonarioGrupoEntity {
  BigInt codGrupo;
  String nombre;
  String detalle;
  BigInt audUsuario;
  DateTime? audFecha;

  // ---- solo lectura ----
  /// Tipos asignados. Si es > 0 el grupo no se puede eliminar.
  int cantTipos;
  int cantTalonarios;

  TalonarioGrupoEntity({
    required this.codGrupo,
    required this.nombre,
    required this.detalle,
    required this.audUsuario,
    this.audFecha,
    this.cantTipos = 0,
    this.cantTalonarios = 0,
  });

  bool get sePuedeEliminar => cantTipos == 0;
}
