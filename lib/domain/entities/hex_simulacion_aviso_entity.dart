/// Lo que la simulación encontró: qué pasa, qué hacer y quién lo arregla
/// (RRHH, el biométrico o el encargado). Textos del SP.
class HexSimulacionAvisoEntity {
  final int orden;

  /// `ERROR`, `AVISO` o `INFO`.
  final String nivel;
  final String texto;
  final String? queHacer;
  final String? quien;

  const HexSimulacionAvisoEntity({
    this.orden = 0,
    this.nivel = '',
    this.texto = '',
    this.queHacer,
    this.quien,
  });
}
