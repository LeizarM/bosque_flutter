class TiposTransaccionEntity {
  BigInt idTipoTransaccion;
  String codigo;
  String nombre;
  String descripcion;
  int requiereForward;
  int requiereBanco;
  int activo;
  int audUsuario;

  TiposTransaccionEntity({
    required this.idTipoTransaccion,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.requiereForward,
    required this.requiereBanco,
    required this.activo,
    required this.audUsuario,
  });
}
