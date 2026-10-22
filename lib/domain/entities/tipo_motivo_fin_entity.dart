class TipoMotivoFinEntity {
  final String codTipos;
  final String nombre;
  final int codGrupo;
  final dynamic listTipos;

  TipoMotivoFinEntity({
    required this.codTipos,
    required this.nombre,
    required this.codGrupo,
    this.listTipos,
  });
}
