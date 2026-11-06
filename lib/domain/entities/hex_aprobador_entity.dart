/// Rol de aprobador de una persona. Nivel 1: encargado de su rama del
/// organigrama (D34). Nivel 2: jefe de área de un encargado asignado a mano,
/// sin organigrama (D35): una fila por cada par jefe → encargado. Nivel 3:
/// observador de un encargado (D45), con la misma forma pero solo lectura.
class HexAprobadorEntity {
  final BigInt? idAprobador;
  final BigInt? codEmpleadoAprobador;
  final String nombreAprobador;
  final int nivel;
  final String nivelTexto;

  /// El cargo vigente del aprobador en el organigrama.
  final BigInt? codCargo;
  final String? cargo;

  /// Empleados activos de su rama hoy, contados por el SP.
  final int cantidadRama;

  /// Texto del SP si no tiene cargo vigente en el organigrama; si no, nulo.
  final String? avisoCargo;

  /// En nivel 2 o 3, el encargado que aprueba u observa; nulo en nivel 1.
  final BigInt? codEmpleadoAprobado;
  final String? nombreAprobado;

  /// Texto del SP: «Su rama: N empleados» o «Aprueba lo que firma X (…)».
  final String? textoAlcance;

  /// Solo de escritura: los encargados al asignar un jefe u observador.
  final List<BigInt> codEmpleadosAprobados;
  final DateTime? vigenteDesde;
  final DateTime? vigenteHasta;
  final bool esVigente;
  final bool aprobadorActivo;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const HexAprobadorEntity({
    this.idAprobador,
    this.codEmpleadoAprobador,
    this.nombreAprobador = '',
    this.nivel = 0,
    this.nivelTexto = '',
    this.codCargo,
    this.cargo,
    this.cantidadRama = 0,
    this.avisoCargo,
    this.codEmpleadoAprobado,
    this.nombreAprobado,
    this.textoAlcance,
    this.codEmpleadosAprobados = const [],
    this.vigenteDesde,
    this.vigenteHasta,
    this.esVigente = false,
    this.aprobadorActivo = false,
    this.audUsuario,
    this.audFecha,
  });

  /// Copia con los campos editados. No vacía un campo opcional: para dejarlo
  /// sin valor se construye la entidad de nuevo.
  HexAprobadorEntity copyWith({
    BigInt? codEmpleadoAprobador,
    int? nivel,
    List<BigInt>? codEmpleadosAprobados,
    DateTime? vigenteDesde,
    DateTime? vigenteHasta,
  }) => HexAprobadorEntity(
    idAprobador: idAprobador,
    codEmpleadoAprobador: codEmpleadoAprobador ?? this.codEmpleadoAprobador,
    nombreAprobador: nombreAprobador,
    nivel: nivel ?? this.nivel,
    nivelTexto: nivelTexto,
    codCargo: codCargo,
    cargo: cargo,
    cantidadRama: cantidadRama,
    avisoCargo: avisoCargo,
    codEmpleadoAprobado: codEmpleadoAprobado,
    nombreAprobado: nombreAprobado,
    textoAlcance: textoAlcance,
    codEmpleadosAprobados: codEmpleadosAprobados ?? this.codEmpleadosAprobados,
    vigenteDesde: vigenteDesde ?? this.vigenteDesde,
    vigenteHasta: vigenteHasta ?? this.vigenteHasta,
    esVigente: esVigente,
    aprobadorActivo: aprobadorActivo,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  /// Base de un rol nuevo: conserva aprobador, nivel, cargo y encargado y
  /// suelta el id, el cierre, la auditoría y la bandera.
  HexAprobadorEntity nuevaVigencia() => HexAprobadorEntity(
    codEmpleadoAprobador: codEmpleadoAprobador,
    nombreAprobador: nombreAprobador,
    nivel: nivel,
    nivelTexto: nivelTexto,
    codCargo: codCargo,
    cargo: cargo,
    cantidadRama: cantidadRama,
    avisoCargo: avisoCargo,
    codEmpleadoAprobado: codEmpleadoAprobado,
    nombreAprobado: nombreAprobado,
    textoAlcance: textoAlcance,
    codEmpleadosAprobados: [if (codEmpleadoAprobado case final cod?) cod],
    vigenteDesde: vigenteDesde,
    aprobadorActivo: aprobadorActivo,
  );
}
