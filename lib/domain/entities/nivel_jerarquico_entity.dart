class NivelJerarquicoEntity {
  int codNivel;
  int nivel;
  int haberBasico;
  int bonoProduccion;
  DateTime fecha;
  int audUsuario;
  int activo;

  NivelJerarquicoEntity({
    required this.codNivel,
    required this.nivel,
    required this.haberBasico,
    required this.bonoProduccion,
    required this.fecha,
    required this.audUsuario,
    required this.activo,
  });
}
