/// Comida (desayuno, almuerzo, cena) con su versión doble, su ventana horaria
/// opcional y los montos que paga. Una comida nueva nace activa, como en el SP.
class HexComidaEntity {
  final BigInt? idComida;
  final String codigo;
  final String leyenda;
  final String codigoDoble;
  final String leyendaDoble;
  final String? horaDesde;
  final String? horaHasta;

  /// Nulos si el formulario los deja vacíos: el SP responde pidiendo el monto.
  final double? monto;
  final double? montoDoble;
  final bool activo;

  /// Nulo en una comida nueva: el SP pone el de la vigencia anterior o el siguiente.
  final int? orden;
  final DateTime? vigenteDesde;
  final DateTime? vigenteHasta;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final bool esVigente;

  /// `VIGENTE`, `PROGRAMADA` o `VENCIDA` y su texto, como los calcula el SP
  /// respecto de la misma fecha que `esVigente`. Nulos si el SP no los manda.
  final String? estadoVigencia;
  final String? textoVigencia;

  /// D40: si paga la doble y cuántos minutos hay que cumplir para la simple y
  /// para la doble. [textoDuracion] lo redacta el SP para mostrarlo tal cual.
  final bool conDoble;
  final int? minutosSimple;
  final int? minutosDoble;
  final String? textoDuracion;

  const HexComidaEntity({
    this.idComida,
    this.codigo = '',
    this.leyenda = '',
    this.codigoDoble = '',
    this.leyendaDoble = '',
    this.horaDesde,
    this.horaHasta,
    this.monto,
    this.montoDoble,
    this.activo = true,
    this.orden,
    this.vigenteDesde,
    this.vigenteHasta,
    this.audUsuario,
    this.audFecha,
    this.esVigente = false,
    this.estadoVigencia,
    this.textoVigencia,
    this.conDoble = true,
    this.minutosSimple,
    this.minutosDoble,
    this.textoDuracion,
  });

  /// Copia con los campos editados. No vacía un campo opcional: para dejarlo
  /// sin valor se construye la entidad de nuevo.
  HexComidaEntity copyWith({
    String? codigo,
    String? leyenda,
    String? codigoDoble,
    String? leyendaDoble,
    String? horaDesde,
    String? horaHasta,
    double? monto,
    double? montoDoble,
    bool? activo,
    int? orden,
    DateTime? vigenteDesde,
    bool? conDoble,
    int? minutosSimple,
    int? minutosDoble,
  }) => HexComidaEntity(
    idComida: idComida,
    codigo: codigo ?? this.codigo,
    leyenda: leyenda ?? this.leyenda,
    codigoDoble: codigoDoble ?? this.codigoDoble,
    leyendaDoble: leyendaDoble ?? this.leyendaDoble,
    horaDesde: horaDesde ?? this.horaDesde,
    horaHasta: horaHasta ?? this.horaHasta,
    monto: monto ?? this.monto,
    montoDoble: montoDoble ?? this.montoDoble,
    activo: activo ?? this.activo,
    orden: orden ?? this.orden,
    vigenteDesde: vigenteDesde ?? this.vigenteDesde,
    vigenteHasta: vigenteHasta,
    audUsuario: audUsuario,
    audFecha: audFecha,
    esVigente: esVigente,
    estadoVigencia: estadoVigencia,
    textoVigencia: textoVigencia,
    conDoble: conDoble ?? this.conDoble,
    minutosSimple: minutosSimple ?? this.minutosSimple,
    minutosDoble: minutosDoble ?? this.minutosDoble,
    textoDuracion: textoDuracion,
  );

  /// Base de una vigencia nueva: conserva los valores y suelta el id, el cierre,
  /// la auditoría y la bandera de la fila anterior. Se ajusta con [copyWith].
  HexComidaEntity nuevaVigencia() => HexComidaEntity(
    codigo: codigo,
    leyenda: leyenda,
    codigoDoble: codigoDoble,
    leyendaDoble: leyendaDoble,
    horaDesde: horaDesde,
    horaHasta: horaHasta,
    monto: monto,
    montoDoble: montoDoble,
    activo: activo,
    orden: orden,
    vigenteDesde: vigenteDesde,
    conDoble: conDoble,
    minutosSimple: minutosSimple,
    minutosDoble: minutosDoble,
  );
}
