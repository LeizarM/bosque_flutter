class DetalleResmadoEntity {
  int idRetRes;
  int idRes;
  String codArticulo;
  String descripcion;
  int cantResma;
  int audUsuario;

  DetalleResmadoEntity({
    required this.idRetRes,
    required this.idRes,
    required this.codArticulo,
    required this.descripcion,
    required this.cantResma,
    required this.audUsuario,
  });
}
