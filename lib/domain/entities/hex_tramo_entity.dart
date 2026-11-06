/// Tramo horario con su multiplicador por tipo de día. Las horas son `HH:mm:ss`;
/// `horaHasta` en `00:00:00` significa las 24:00.
class HexTramoEntity {
  final BigInt? idTramo;
  final String codigo;
  final String leyenda;
  final String tipoDia;
  final String? horaDesde;
  final String? horaHasta;
  final double multiplicador;

  /// Nulo en un tramo nuevo: el SP pone el de la vigencia anterior o el siguiente.
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

  const HexTramoEntity({
    this.idTramo,
    this.codigo = '',
    this.leyenda = '',
    this.tipoDia = '',
    this.horaDesde,
    this.horaHasta,
    this.multiplicador = 0,
    this.orden,
    this.vigenteDesde,
    this.vigenteHasta,
    this.audUsuario,
    this.audFecha,
    this.esVigente = false,
    this.estadoVigencia,
    this.textoVigencia,
  });

  /// Copia con los campos editados. No vacía un campo opcional: para dejarlo
  /// sin valor se construye la entidad de nuevo.
  HexTramoEntity copyWith({
    String? codigo,
    String? leyenda,
    String? tipoDia,
    String? horaDesde,
    String? horaHasta,
    double? multiplicador,
    int? orden,
    DateTime? vigenteDesde,
  }) => HexTramoEntity(
    idTramo: idTramo,
    codigo: codigo ?? this.codigo,
    leyenda: leyenda ?? this.leyenda,
    tipoDia: tipoDia ?? this.tipoDia,
    horaDesde: horaDesde ?? this.horaDesde,
    horaHasta: horaHasta ?? this.horaHasta,
    multiplicador: multiplicador ?? this.multiplicador,
    orden: orden ?? this.orden,
    vigenteDesde: vigenteDesde ?? this.vigenteDesde,
    vigenteHasta: vigenteHasta,
    audUsuario: audUsuario,
    audFecha: audFecha,
    esVigente: esVigente,
    estadoVigencia: estadoVigencia,
    textoVigencia: textoVigencia,
  );

  /// Base de una vigencia nueva: conserva los valores y suelta el id, el cierre,
  /// la auditoría y la bandera de la fila anterior. Se ajusta con [copyWith].
  HexTramoEntity nuevaVigencia() => HexTramoEntity(
    codigo: codigo,
    leyenda: leyenda,
    tipoDia: tipoDia,
    horaDesde: horaDesde,
    horaHasta: horaHasta,
    multiplicador: multiplicador,
    orden: orden,
    vigenteDesde: vigenteDesde,
  );
}
