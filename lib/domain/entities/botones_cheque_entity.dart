/// Cuales de las cuatro acciones del detalle estan habilitadas para un cheque:
/// el resultado de la rama K de `p_list_Cheque`.
///
/// Lo calcula el backend, no la pantalla: depende de las acciones del cheque y
/// de si existe una verificacion de deposito. El servidor lo vuelve a comprobar
/// al ejecutar cada accion.
class BotonesChequeEntity {
  /// Sin ningun boton habilitado: cheque cerrado o sin traspaso.
  static const BotonesChequeEntity ninguno = BotonesChequeEntity(
    fechaCobro: false,
    devolver: false,
    cerrarConVerificacion: false,
    cerrarSinVerificacion: false,
    codigo: '0000',
  );

  /// Boton 1: nueva fecha de cobro.
  final bool fechaCobro;

  /// Boton 2.
  final bool devolver;

  /// Boton 3.
  final bool cerrarConVerificacion;

  /// Boton 4.
  final bool cerrarSinVerificacion;

  /// Los 4 caracteres crudos de la rama K, en el orden de arriba. Un `1`
  /// habilita.
  final String codigo;

  const BotonesChequeEntity({
    required this.fechaCobro,
    required this.devolver,
    required this.cerrarConVerificacion,
    required this.cerrarSinVerificacion,
    required this.codigo,
  });

  bool get hayAlguno =>
      fechaCobro || devolver || cerrarConVerificacion || cerrarSinVerificacion;
}
