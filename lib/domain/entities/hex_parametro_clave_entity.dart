/// Una clave del catálogo de parámetros (D33): qué es, de qué tipo, si es
/// obligatoria y, si falta su valor vigente, el [aviso] que arma el SP.
class HexParametroClaveEntity {
  final String clave;
  final String nombre;

  /// `NUMERO` o `FECHA`.
  final String tipoValor;

  /// Nula en las fechas.
  final String? unidad;
  final bool obligatorio;
  final String? descripcion;
  final String? siFalta;
  final bool tieneVigente;

  /// Nulo salvo que la clave sea obligatoria y no tenga una fila vigente.
  final String? aviso;

  /// El valor se elige de una lista (`opcionesParametro`), no se escribe.
  final bool conOpciones;

  const HexParametroClaveEntity({
    this.clave = '',
    this.nombre = '',
    this.tipoValor = '',
    this.unidad,
    this.obligatorio = false,
    this.descripcion,
    this.siFalta,
    this.tieneVigente = false,
    this.aviso,
    this.conOpciones = false,
  });
}
