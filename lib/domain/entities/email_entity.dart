class EmailEntity {
  final int codEmail;
  final int codPersona;
  final String email;
  final int audUsuario;
  EmailEntity({
    required this.codEmail,
    required this.codPersona,
    required this.email,
    required this.audUsuario,
  });
  Map<String, dynamic> toJson() {
    return {
      'codEmail': codEmail,
      'codPersona': codPersona,
      'email': email,
      'audUsuario': audUsuario,
    };
  }
  // Método copyWith
  EmailEntity copyWith({
    int? codEmail,
    int? codPersona,
    String? email,
    int? audUsuario,
  }) {
    return EmailEntity(
      codEmail: codEmail ?? this.codEmail,
      codPersona: codPersona ?? this.codPersona,
      email: email ?? this.email,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
}