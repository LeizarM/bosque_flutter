class LicenciaConducirEntity {
  final int codLicencia;
  final int codPersona;
  final String categoria;
  final DateTime fechaCaducidad;
  final int audUsuario;

  LicenciaConducirEntity({
    required this.codLicencia,
    required this.codPersona,
    required this.categoria,
    required this.fechaCaducidad,
    required this.audUsuario,
  });
}