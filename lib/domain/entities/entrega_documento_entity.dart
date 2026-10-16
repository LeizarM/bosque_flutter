/// Una entrega a un empleado (`tarc_entrega`); su número es [codEntrega]. Lo
/// que se llevó, cajas completas o documentos de cualquier caja, son sus
/// renglones (préstamos). La fecha la pone el servidor y llega como texto.
class EntregaDocumentoEntity {
  final int codEntrega;
  final int codEmpleado;
  final String? fechaEntrega;
  final String? observacion;
  final int audUsuario;
  final DateTime? audFecha;

  /// Solo lectura: lo que trae el listado.
  final String? nombreEmpleado;
  final int cajas;
  final int documentos;

  /// Renglones que siguen afuera; 0 = ya volvió todo.
  final int pendientes;

  /// La última devolución, solo cuando ya volvió todo.
  final String? fechaDevolucion;

  /// Quién registró la entrega.
  final String? nombreUsuario;

  const EntregaDocumentoEntity({
    required this.codEntrega,
    required this.codEmpleado,
    this.fechaEntrega,
    this.observacion,
    this.audUsuario = 0,
    this.audFecha,
    this.nombreEmpleado,
    this.cajas = 0,
    this.documentos = 0,
    this.pendientes = 0,
    this.fechaDevolucion,
    this.nombreUsuario,
  });

  bool get abierta => pendientes > 0;
  int get renglones => cajas + documentos;
}
