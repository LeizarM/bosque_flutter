/// Código de la leyenda impresa en la planilla: un tramo o una comida con el
/// multiplicador o el valor con que se pagó.
class HexCodigoLeyendaEntity {
  /// `TRAMO` o `COMIDA`.
  final String concepto;
  final String codigo;
  final String leyenda;
  final double? multiplicador;
  final double? valorUnitario;

  const HexCodigoLeyendaEntity({
    this.concepto = '',
    this.codigo = '',
    this.leyenda = '',
    this.multiplicador,
    this.valorUnitario,
  });
}
