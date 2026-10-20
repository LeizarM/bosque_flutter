/// `tcpe_personaPost`: Persona que se postula (sin uso).
/// Columnas de `p_list_tcpe_PersonaPost` (sin `password2`) más `nombreUsuario`.
class TcpePersonaPostEntity {
  final BigInt codPersonaPost;
  final String? ci;
  final String? nombre;
  final String? apPaterno;
  final String? apMaterno;
  final String? email;
  final String? ciudad;
  final String? pais;
  final DateTime? fechaNacimiento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpePersonaPostEntity({
    required this.codPersonaPost,
    this.ci,
    this.nombre,
    this.apPaterno,
    this.apMaterno,
    this.email,
    this.ciudad,
    this.pais,
    this.fechaNacimiento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpePersonaPostEntity copyWith({
    BigInt? codPersonaPost,
    String? ci,
    String? nombre,
    String? apPaterno,
    String? apMaterno,
    String? email,
    String? ciudad,
    String? pais,
    DateTime? fechaNacimiento,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpePersonaPostEntity(
    codPersonaPost: codPersonaPost ?? this.codPersonaPost,
    ci: ci ?? this.ci,
    nombre: nombre ?? this.nombre,
    apPaterno: apPaterno ?? this.apPaterno,
    apMaterno: apMaterno ?? this.apMaterno,
    email: email ?? this.email,
    ciudad: ciudad ?? this.ciudad,
    pais: pais ?? this.pais,
    fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
