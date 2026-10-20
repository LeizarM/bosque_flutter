/// `tcpe_capacitador`: Capacitador (módulo de capacitaciones, hoy sin uso).
/// Columnas de `p_list_tcpe_Capacitador` (sin `password2`) más `nombreUsuario`.
class TcpeCapacitadorEntity {
  final BigInt codCapacitador;
  final int? sexo;
  final String? telefonos;
  final String? ci;
  final String? nombre;
  final String? apPaterno;
  final String? apMaterno;
  final String? direccion;
  final String? email;
  final String? pais;
  final DateTime? fechaNacimiento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeCapacitadorEntity({
    required this.codCapacitador,
    this.sexo,
    this.telefonos,
    this.ci,
    this.nombre,
    this.apPaterno,
    this.apMaterno,
    this.direccion,
    this.email,
    this.pais,
    this.fechaNacimiento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeCapacitadorEntity copyWith({
    BigInt? codCapacitador,
    int? sexo,
    String? telefonos,
    String? ci,
    String? nombre,
    String? apPaterno,
    String? apMaterno,
    String? direccion,
    String? email,
    String? pais,
    DateTime? fechaNacimiento,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeCapacitadorEntity(
    codCapacitador: codCapacitador ?? this.codCapacitador,
    sexo: sexo ?? this.sexo,
    telefonos: telefonos ?? this.telefonos,
    ci: ci ?? this.ci,
    nombre: nombre ?? this.nombre,
    apPaterno: apPaterno ?? this.apPaterno,
    apMaterno: apMaterno ?? this.apMaterno,
    direccion: direccion ?? this.direccion,
    email: email ?? this.email,
    pais: pais ?? this.pais,
    fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
