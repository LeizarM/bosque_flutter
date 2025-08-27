class CompraGarrafaEntity {
  int idCG;
  int codSucursal;
  String descripcion;
  int cantidad;
  double monto;
  int audUsuario;

  CompraGarrafaEntity({
    required this.idCG,
    required this.codSucursal,
    required this.descripcion,
    required this.cantidad,
    required this.monto,
    required this.audUsuario,
  });
}
