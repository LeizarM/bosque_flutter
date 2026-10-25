/// Quien puede recibir un cartón: con bingo por vales, cualquier participante
/// con vales de bingo (también invitados); sin vale, los empleados activos.
class TtkEmpleadoBingoEntity {
  final BigInt? codParticipante;
  final BigInt? codEmpleado;
  final String nombreCompleto;
  final String? cargo;
  final String categoriaTexto;
  final int valesBingo;
  final int cartonesAsignados;
  final bool puedeRecibir;

  const TtkEmpleadoBingoEntity({
    this.codParticipante,
    this.codEmpleado,
    this.nombreCompleto = '',
    this.cargo,
    this.categoriaTexto = '',
    this.valesBingo = 0,
    this.cartonesAsignados = 0,
    this.puedeRecibir = false,
  });
}
