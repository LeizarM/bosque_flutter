class MonedasEntity {
  int idMoneda;
  String codigo;
  String nombre;
  String simbolo;
  int decimales;
  int activo;
  int audUsuario;

  MonedasEntity({
    required this.idMoneda,
    required this.codigo,
    required this.nombre,
    required this.simbolo,
    required this.decimales,
    required this.activo,
    required this.audUsuario,
  });
}
