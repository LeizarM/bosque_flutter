/// Un cambio en el historial del costo de una familia: una aprobacion que le
/// cambio la propuesta aprobada y, si tambien cambio el costo, el costo de
/// antes y el nuevo. Sale de tb_bitacora (p_list_bitCostoProducto), el mismo
/// origen que el dialogo "Bitacora de costo / propuesta" del sistema anterior.
class HistorialCostoFamiliaEntity {
  final int codigoFamilia;

  /// Cuando se aprobo. Null solo si la bitacora no trae la fecha.
  final DateTime? fecha;

  /// Nombre de quien aprobo; vacio si ese usuario ya no tiene empleado.
  final String usuario;

  final BigInt audUsuario;

  /// Cero si la familia no tenia propuesta aprobada antes.
  final BigInt propuestaAnterior;

  final BigInt propuestaNueva;

  /// Null si esa aprobacion no cambio el costo.
  final double? costoAnterior;

  /// Null si esa aprobacion no cambio el costo.
  final double? costoNuevo;

  /// El costo vigente hoy; se repite en cada fila.
  final double costoActual;

  /// La propuesta aprobada vigente hoy; se repite en cada fila.
  final BigInt propuestaActual;

  const HistorialCostoFamiliaEntity({
    required this.codigoFamilia,
    required this.fecha,
    required this.usuario,
    required this.audUsuario,
    required this.propuestaAnterior,
    required this.propuestaNueva,
    required this.costoAnterior,
    required this.costoNuevo,
    required this.costoActual,
    required this.propuestaActual,
  });

  /// La aprobacion movio el costo.
  bool get cambioElCosto => costoNuevo != null;

  /// Variacion del costo en por ciento. Null si no cambio o si antes estaba
  /// en cero (una familia nueva: no hay contra que comparar).
  double? get variacion {
    final antes = costoAnterior;
    final despues = costoNuevo;
    if (antes == null || despues == null || antes == 0) return null;
    return (despues - antes) / antes * 100;
  }
}
