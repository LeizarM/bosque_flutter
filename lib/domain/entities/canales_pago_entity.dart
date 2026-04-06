class CanalesPagoEntity {
  int idCanal;
  String nombre;
  String tipo;
  String contacto;
  int activo;
  int audUsuario;

  CanalesPagoEntity({
    required this.idCanal,
    required this.nombre,
    required this.tipo,
    required this.contacto,
    required this.activo,
    required this.audUsuario,
  });
}
