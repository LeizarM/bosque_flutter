/// Un traspaso a cobranza ya hecho, para elegir cual reimprimir
/// (`/cheque/traspaso/horas`). Es un dato de combo, no una tabla.
///
/// [codAccion] es una de las acciones TRASP de ese traspaso y solo viaja de vuelta
/// al servidor (`/cheque/reporte/reimpresion-traspaso`); [hora] es el texto
/// «HH:mm» que se muestra.
class HoraTraspasoChequeEntity {
  final int codAccion;
  final String hora;

  const HoraTraspasoChequeEntity({required this.codAccion, required this.hora});
}
