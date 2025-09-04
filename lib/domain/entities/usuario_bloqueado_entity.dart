class UsuarioBloqueadoEntity {
  final int codUsuario;
  final DateTime fechaAdvertencia;
  final DateTime fechaLimite;
  final int bloqueado;
  final int audUsuario;

  UsuarioBloqueadoEntity({
    required this.codUsuario,
    required this.fechaAdvertencia,
    required this.fechaLimite,
    required this.bloqueado,
    required this.audUsuario,
  });
  Map<String, dynamic> toJson() {
    return {
      'codUsuario': codUsuario,
      'fechaAdvertencia': fechaAdvertencia.toIso8601String(),
      'fechaLimite': fechaLimite.toIso8601String(),
      'bloqueado': bloqueado,
      'audUsuario': audUsuario,
    };
  }
  //metodo copyWith
  UsuarioBloqueadoEntity copyWith({
    int? codUsuario,
    DateTime? fechaAdvertencia,
    DateTime? fechaLimite,
    int? bloqueado,
    int? audUsuario,
  }) {
    return UsuarioBloqueadoEntity(
      codUsuario: codUsuario ?? this.codUsuario,
      fechaAdvertencia: fechaAdvertencia ?? this.fechaAdvertencia,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      bloqueado: bloqueado ?? this.bloqueado,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
}