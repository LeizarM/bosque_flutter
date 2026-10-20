/// `tcpe_tipo`: Catálogo genérico de tipos (sin uso).
/// Columnas de `p_list_tcpe_Tipo` (sin `password2`) más `nombreUsuario`.
class TcpeTipoEntity {
  final BigInt codTipo;
  final String? nombre;
  final bool? esVigente;
  final int? idGrupo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeTipoEntity({
    required this.codTipo,
    this.nombre,
    this.esVigente,
    this.idGrupo,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeTipoEntity copyWith({
    BigInt? codTipo,
    String? nombre,
    bool? esVigente,
    int? idGrupo,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeTipoEntity(
    codTipo: codTipo ?? this.codTipo,
    nombre: nombre ?? this.nombre,
    esVigente: esVigente ?? this.esVigente,
    idGrupo: idGrupo ?? this.idGrupo,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
