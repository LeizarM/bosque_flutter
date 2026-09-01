/// Origen: tabla `dbo.tbio_bioEmplBosqEmpl`, via `p_list_BioEmplBosqEmpl`.
///
/// Cruce entre un usuario del reloj biometrico y un empleado de Bosque.
class BioEmplBosqEmplEntity {
  final BigInt idEmpleadBio;
  final String datoNombreBiom;
  final BigInt idEmpleado;
  final String datoNombreBosq;
  final int audUsuario;
  final DateTime? audFecha;

  const BioEmplBosqEmplEntity({
    required this.idEmpleadBio,
    required this.datoNombreBiom,
    required this.idEmpleado,
    required this.datoNombreBosq,
    required this.audUsuario,
    this.audFecha,
  });

  /// `idEmpleado == 0` significa que aun no esta enlazado a un empleado Bosque.
  bool get enlazado => idEmpleado > BigInt.zero;
}
