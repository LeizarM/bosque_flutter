/// Las entidades de la bitácora de configuración, como las compara el SP.
abstract final class EntidadConfiguracionHex {
  static const parametro = 'PARAMETRO';
  static const tramo = 'TRAMO';
  static const comida = 'COMIDA';
  static const aprobador = 'APROBADOR';
}

/// Un cambio de configuración en la bitácora (D22): qué registro, qué acción,
/// qué campo, el valor anterior y el nuevo, quién y cuándo. Solo lectura; los
/// textos (`*Texto`) vienen del SP.
class HexConfiguracionEventoEntity {
  final BigInt? idEvento;
  final String entidad;
  final String entidadTexto;
  final BigInt? idRegistro;
  final String? descripcion;
  final String accion;
  final String accionTexto;

  /// Nulo: el cambio fue la fila completa.
  final String? campo;
  final String? campoTexto;
  final String? valorAnterior;
  final String? valorNuevo;

  /// Nulo en un cambio hecho por script.
  final BigInt? audUsuario;
  final String? nombreUsuario;
  final DateTime? audFecha;
  final int totalFilas;

  const HexConfiguracionEventoEntity({
    this.idEvento,
    this.entidad = '',
    this.entidadTexto = '',
    this.idRegistro,
    this.descripcion,
    this.accion = '',
    this.accionTexto = '',
    this.campo,
    this.campoTexto,
    this.valorAnterior,
    this.valorNuevo,
    this.audUsuario,
    this.nombreUsuario,
    this.audFecha,
    this.totalFilas = 0,
  });
}
