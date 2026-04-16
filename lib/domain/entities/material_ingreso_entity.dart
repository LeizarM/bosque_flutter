class MaterialIngresoEntity {
  int idMi;
  int idLp;
  String codArticulo;
  String descripcion;
  double pesoKilos;
  double balanza;
  String numImportacion;
  int audUsuario;

  MaterialIngresoEntity({
    required this.idMi,
    required this.idLp,
    required this.codArticulo,
    required this.descripcion,
    required this.pesoKilos,
    required this.balanza,
    required this.numImportacion,
    required this.audUsuario,
  });
}
