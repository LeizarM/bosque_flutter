/// Fila de una vista preliminar de comisiones.
///
/// Es la union de las cuatro formas que devuelve p_list_paraPagar. Cada rama
/// trae un subconjunto distinto y los alias no coinciden entre si, porque en un
/// UNION ALL los nombres los fija la primera consulta. Los campos que la rama
/// no devuelve llegan en null.
///
/// El backend ya expone getters normalizados, pero se conservan los campos
/// crudos para no perder informacion que alguna rama si trae, como montoTotalBS.
class PreliminarComisionEntity {
  /// Rol de la fila. 1 detalle, 2 subtotal, 3 grupos que no son de venta,
  /// 4 separador o total. No es dato de negocio: el SP lo usa para ordenar.
  final int ord;

  final int? idVendedor;
  final int? mes;
  final int? anio;

  /// Nombre del grupo, o el tipo de credito en la modalidad vigente.
  final String etiqueta;

  final String nombreVen;

  /// Factor ya dividido entre 100: 0.006 equivale a 0,6%.
  final double comision;

  final int ignoraComision;

  /// Monto base sobre el que se calcula, sea cual sea el alias de la rama.
  final double montoBase;

  /// Solo en la modalidad vigente.
  final double? montoTotalBs;

  /// Solo en la modalidad anterior.
  final double? ventaTotalMesUsd;

  final double bsAPagar;
  final double usdAPagar;

  const PreliminarComisionEntity({
    required this.ord,
    this.idVendedor,
    this.mes,
    this.anio,
    required this.etiqueta,
    required this.nombreVen,
    required this.comision,
    required this.ignoraComision,
    required this.montoBase,
    this.montoTotalBs,
    this.ventaTotalMesUsd,
    required this.bsAPagar,
    required this.usdAPagar,
  });

  /// Las filas de total se muestran destacadas y no se pueden desplegar.
  bool get esTotal => ord >= 2;

  /// Comision en puntos porcentuales, para mostrar.
  double get comisionVisual => comision * 100;

  bool get ignora => ignoraComision == 1;

  /// Periodo legible. Las filas de total llegan sin mes ni anio.
  String get periodo {
    if (mes == null || anio == null || mes == 0 || anio == 0) return '';
    return '${mes.toString().padLeft(2, '0')}/$anio';
  }
}
