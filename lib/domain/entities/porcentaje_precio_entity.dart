/// Porcentaje de incremento por familia de producto y lista de precios
/// (tabla tpr_porcentaje). Es el margen que se le carga al costo para armar el
/// precio de venta de esa familia en esa lista.
///
/// OJO con la escala: [porcen] esta en PUNTOS PORCENTUALES, donde 12.5 es
/// 12,5%. No es base 1 como la comision del modulo tcom, donde 0.008 es 0,8%.
/// Son dos convenciones distintas en el mismo sistema.
///
/// OJO con el tipo: en el backend [porcen] es BigDecimal a proposito, porque el
/// float binario no representa 0.01 y al aplicarse sobre precios se perderian
/// centavos. Dart no tiene BigDecimal, asi que aca viaja en double: no comparar
/// con == contra un literal ni acumular sumas largas sin redondear.
///
/// Esta entidad tiene EXACTAMENTE las columnas de la tabla. Los campos de
/// presentacion que devuelve el listado (codSucursal, nombre de sucursal,
/// nombrePrecio, vpp) no viven aca: son de la grilla, no de la tabla.
class PorcentajePrecioEntity {
  /// PK, bigint IDENTITY. En un alta todavia no existe y llega en 0: el
  /// listado devuelve 0 o null en las filas que aun no tienen porcentaje.
  final BigInt idPorcen;

  /// FK a la familia de producto. Es INT en la base, no BIGINT como el resto
  /// de los ids del modulo.
  final int codigoFamilia;

  /// FK a la lista de precios (tpr_clasificacionPrecio).
  final BigInt idClasificacion;

  /// Margen sobre el costo, en puntos porcentuales. Para 12,5% vale 12.5.
  final double porcen;

  final BigInt audUsuario;

  /// Fecha de auditoria. Es de solo lectura: el procedimiento la pisa siempre
  /// con GETDATE() en el alta y en la modificacion.
  final DateTime? audFecha;

  const PorcentajePrecioEntity({
    required this.idPorcen,
    required this.codigoFamilia,
    required this.idClasificacion,
    required this.porcen,
    required this.audUsuario,
    this.audFecha,
  });

  /// Fila que todavia no existe en la tabla: el guardado tiene que ser un alta.
  bool get esAlta => idPorcen == BigInt.zero;

  /// Sin margen cargado. Las filas pendientes del listado llegan con porcen 0.
  bool get sinMargen => porcen == 0;

  /// Margen negativo: el precio quedaria por debajo del costo. Conviene
  /// resaltarlo en la pantalla, casi siempre es un error de carga.
  bool get esNegativo => porcen < 0;

  /// Margen listo para mostrar, en puntos porcentuales.
  String get porcenTexto => '${porcen.toStringAsFixed(2)} %';

  /// Multiplicador a aplicar sobre el costo: 12.5 puntos da 1.125.
  /// Solo para previsualizar en la pantalla, el precio real lo calcula la base.
  double get factorSobreCosto => 1 + (porcen / 100);

  /// La fila ya quedo asociada a una lista de precios.
  bool get tieneClasificacion => idClasificacion != BigInt.zero;

  /// Fecha de auditoria legible. Vacia si la fila nunca se grabo.
  String get audFechaTexto {
    final f = audFecha;
    if (f == null) return '';
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year}';
  }

  PorcentajePrecioEntity copyWith({
    BigInt? idPorcen,
    int? codigoFamilia,
    BigInt? idClasificacion,
    double? porcen,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => PorcentajePrecioEntity(
    idPorcen: idPorcen ?? this.idPorcen,
    codigoFamilia: codigoFamilia ?? this.codigoFamilia,
    idClasificacion: idClasificacion ?? this.idClasificacion,
    porcen: porcen ?? this.porcen,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
