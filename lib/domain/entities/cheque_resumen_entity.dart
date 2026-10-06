/// Un cheque en una lista de seleccion de «Dar Custodia»
/// (`/cheque/dar-custodia/cheques`): el codigo y una linea de texto del tipo
/// «Nro Cheque : ..., Cliente : ..., Monto (BS) : ...».
class ChequeResumenEntity {
  final BigInt codCheque;
  final String datoCheque;

  const ChequeResumenEntity({
    required this.codCheque,
    required this.datoCheque,
  });
}
