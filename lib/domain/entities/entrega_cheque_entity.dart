/// Una entrega a cobranza del dia, para elegir cual copiar en «Dar Custodia»
/// (`/cheque/dar-custodia/entregas`). [codAccion] es una de las acciones CUS de
/// esa entrega y [hora] el texto a mostrar: «HH:mm», con «Entregado a ...».
class EntregaChequeEntity {
  final BigInt codAccion;
  final String hora;

  const EntregaChequeEntity({required this.codAccion, required this.hora});
}
