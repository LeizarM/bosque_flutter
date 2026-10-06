import 'package:bosque_flutter/domain/entities/cheque_entity.dart';

/// Un cheque con lo que el backend resuelve por JOIN: la fila de la grilla y la
/// cabecera del detalle (`ChequeFila` del contrato).
///
/// Envuelve a [ChequeEntity] en vez de repetir sus columnas: la fila de la tabla
/// sigue siendo una sola, y lo que se edita y se manda de vuelta es [cheque].
class ChequeFilaEntity {
  final ChequeEntity cheque;

  /// Dia en que se registro (fecha de la accion REC).
  final DateTime? fechaRecepcion;

  /// Nombre del cliente en `text_SocioNegocio`.
  final String datoCliente;

  /// Descripcion de la moneda: «Bs» o «$us».
  final String descMoneda;

  /// Descripcion del tipo: «PAGO» o «RESPALDO». **Puede ser null**: la mayoria
  /// de los cheques de prueba tiene el tipo corrupto y el JOIN no lo encuentra.
  /// El legacy muestra la celda vacia y aqui es igual.
  final String? descTipo;

  /// «PENDIENTE» o «CERRADO».
  final String descEstado;

  final String nombreBanco;

  /// Quien lo entrego, o « - Entregado por el Cliente -» si codEmpleado es 0.
  final String datoEmpleado;

  /// Observacion de la accion REC, la que se escribe al registrar.
  final String? observacion;

  final String datoEmpresa;

  /// Numero de fila, 1..n, en la pagina de resultados.
  final int fila;

  const ChequeFilaEntity({
    required this.cheque,
    required this.fechaRecepcion,
    required this.datoCliente,
    required this.descMoneda,
    required this.descTipo,
    required this.descEstado,
    required this.nombreBanco,
    required this.datoEmpleado,
    required this.observacion,
    required this.datoEmpresa,
    required this.fila,
  });

  BigInt get codCheque => cheque.codCheque;
  bool get estaCerrado => cheque.estaCerrado;
}
