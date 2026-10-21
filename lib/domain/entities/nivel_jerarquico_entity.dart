/// Una escala salarial de `tb_nivelJerarquico`: nivel, haber, bono y desde
/// cuándo rige. [activo] es 1 si es la vigente de su nivel; [cargos] (solo en
/// la pantalla de mantenimiento) cuántos cargos la usan.
class NivelJerarquicoEntity {
  int codNivel;
  int nivel;
  double haberBasico;
  double bonoProduccion;
  DateTime fecha;
  int audUsuario;
  int activo;
  int cargos;

  NivelJerarquicoEntity({
    required this.codNivel,
    required this.nivel,
    required this.haberBasico,
    required this.bonoProduccion,
    required this.fecha,
    required this.audUsuario,
    required this.activo,
    this.cargos = 0,
  });

  bool get esVigente => activo == 1;
}
