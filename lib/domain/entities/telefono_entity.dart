class TelefonoEntity {
  final int codTelefono;
  final int codPersona;
  final int codTipoTel;
  final String telefono;
  final String? tipo;
  final int audUsuario;
  TelefonoEntity({
    required this.codTelefono,
    required this.codPersona,
    required this.codTipoTel,
    required this.telefono,
    this.tipo,
    required this.audUsuario,
  });
  Map<String, dynamic> toJson() {
    return {
      'codTelefono': codTelefono,
      'codPersona': codPersona,
      'codTipoTel': codTipoTel,
      'telefono': telefono,
      'tipo': tipo,
      'audUsuario': audUsuario,
    };
  }
  //metodo copyWith
  TelefonoEntity copyWith({
    int? codTelefono,
    int? codPersona,
    int? codTipoTel,
    String? telefono,
    String? tipo,
    int? audUsuario,
  }) {
    return TelefonoEntity(
      codTelefono: codTelefono ?? this.codTelefono,
      codPersona: codPersona ?? this.codPersona,
      codTipoTel: codTipoTel ?? this.codTipoTel,
      telefono: telefono ?? this.telefono,
      tipo: tipo ?? this.tipo,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
}