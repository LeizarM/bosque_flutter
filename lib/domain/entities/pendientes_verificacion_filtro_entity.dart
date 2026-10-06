/// Lo que se pide a `/cheque/verificacion/pendientes`: los criterios del modal
/// «Cheques pendientes sin regularizar» y la pagina.
///
/// Los valores por defecto son los de `inicializarModal` del legacy: estado
/// **pendiente** y solo los cheques con fecha de cobranza de hoy.
class PendientesVerificacionFiltroEntity {
  static const int tamanioPorDefecto = 20;

  /// El estado del **cheque**: `PEN`, `CER` o null = todos. No es el estado de
  /// una verificacion.
  final String? estado;

  /// `true`: solo los de fecha de cobranza de hoy («2» del legacy). `false`:
  /// los de hoy y los anteriores («1»: «Todos (anteriores y con fecha de
  /// cobranza hasta hoy)»).
  final bool soloCobranzaHoy;

  /// Desde 1.
  final int pagina;

  final int tamanio;

  const PendientesVerificacionFiltroEntity({
    this.estado = 'PEN',
    this.soloCobranzaHoy = true,
    this.pagina = 1,
    this.tamanio = tamanioPorDefecto,
  });

  PendientesVerificacionFiltroEntity copyWith({
    String? estado,
    bool todosLosEstados = false,
    bool? soloCobranzaHoy,
    int? pagina,
    int? tamanio,
  }) => PendientesVerificacionFiltroEntity(
    estado: todosLosEstados ? null : (estado ?? this.estado),
    soloCobranzaHoy: soloCobranzaHoy ?? this.soloCobranzaHoy,
    pagina: pagina ?? this.pagina,
    tamanio: tamanio ?? this.tamanio,
  );
}
