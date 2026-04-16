class MaterialSalidaEntity {
  int idMs;
  int idLp;
  String codArticulo;
  String descripcion;
  int nroPaleta;
  double pesoResma;
  double pesoPaleta;
  double pesoMaterial;
  int cantidadResma;
  int cantidadHojas;
  int audUsuario;

  MaterialSalidaEntity({
    required this.idMs,
    required this.idLp,
    required this.codArticulo,
    required this.descripcion,
    required this.nroPaleta,
    required this.pesoResma,
    required this.pesoPaleta,
    required this.pesoMaterial,
    required this.cantidadResma,
    required this.cantidadHojas,
    required this.audUsuario,
  });
}
