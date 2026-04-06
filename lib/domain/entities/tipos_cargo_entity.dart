class TiposCargoEntity {
  BigInt idTipoCargo;
  String nombre;
  int esPorcentaje;
  int activo;
  int audUsuario;

  TiposCargoEntity({
    required this.idTipoCargo,
    required this.nombre,
    required this.esPorcentaje,
    required this.activo,
    required this.audUsuario,
  });
}
