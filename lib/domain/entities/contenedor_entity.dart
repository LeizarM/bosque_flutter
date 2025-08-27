class ContenedorEntity {
  int idContenedor;
  String codigo;
  int idTipo;
  int codSucursal;
  String descripcion;
  String unidadMedida;
  int audUsuario;
  String clase;

  ContenedorEntity({
    required this.idContenedor,
    required this.codigo,
    required this.idTipo,
    required this.codSucursal,
    required this.descripcion,
    required this.unidadMedida,
    required this.audUsuario,
    required this.clase,
  });
}
