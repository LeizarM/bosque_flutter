/// Parámetro del cálculo (divisor del costo hora, minutos mínimos…)
/// con su vigencia. El valor es un número o una fecha, nunca los dos.
class HexParametroEntity {
  final BigInt? idParametro;
  final String clave;
  final double? valorNumero;
  final DateTime? valorFecha;
  final String leyenda;
  final DateTime? vigenteDesde;
  final DateTime? vigenteHasta;
  final bool esVigente;

  /// `VIGENTE`, `PROGRAMADA` o `VENCIDA` y su texto, como los calcula el SP
  /// respecto de la misma fecha que `esVigente`. Nulos si el SP no los manda.
  final String? estadoVigencia;
  final String? textoVigencia;

  /// Textos del catálogo de claves (D33) que arma el SP para quien no es
  /// técnico: qué es, qué pasa si falta, el valor con su unidad y un ejemplo.
  final String? nombre;
  final String? descripcion;
  final String? siFalta;
  final String? valorTexto;
  final String? ejemplo;

  /// Nulo si el SP no lo manda: entonces no se muestra la ficha.
  final bool? obligatorio;

  /// Bandera del SP: la fila admite «Dejar de usar desde…».
  final bool puedeDejarDeUsar;

  const HexParametroEntity({
    this.idParametro,
    this.clave = '',
    this.valorNumero,
    this.valorFecha,
    this.leyenda = '',
    this.vigenteDesde,
    this.vigenteHasta,
    this.esVigente = false,
    this.estadoVigencia,
    this.textoVigencia,
    this.nombre,
    this.descripcion,
    this.siFalta,
    this.valorTexto,
    this.ejemplo,
    this.obligatorio,
    this.puedeDejarDeUsar = false,
  });

  /// Copia con los campos editados. No vacía un campo opcional: para dejarlo
  /// sin valor se construye la entidad de nuevo.
  HexParametroEntity copyWith({
    String? clave,
    double? valorNumero,
    DateTime? valorFecha,
    String? leyenda,
    DateTime? vigenteDesde,
  }) => HexParametroEntity(
    idParametro: idParametro,
    clave: clave ?? this.clave,
    valorNumero: valorNumero ?? this.valorNumero,
    valorFecha: valorFecha ?? this.valorFecha,
    leyenda: leyenda ?? this.leyenda,
    vigenteDesde: vigenteDesde ?? this.vigenteDesde,
    vigenteHasta: vigenteHasta,
    esVigente: esVigente,
    estadoVigencia: estadoVigencia,
    textoVigencia: textoVigencia,
    nombre: nombre,
    descripcion: descripcion,
    siFalta: siFalta,
    valorTexto: valorTexto,
    ejemplo: ejemplo,
    obligatorio: obligatorio,
    puedeDejarDeUsar: puedeDejarDeUsar,
  );

  /// Base de una vigencia nueva: conserva los valores y suelta el id, el cierre
  /// y la bandera de la fila anterior. Se ajusta con [copyWith].
  HexParametroEntity nuevaVigencia() => HexParametroEntity(
    clave: clave,
    valorNumero: valorNumero,
    valorFecha: valorFecha,
    leyenda: leyenda,
    vigenteDesde: vigenteDesde,
  );
}
