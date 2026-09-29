/// Precio VIGENTE de una familia de producto para una clasificacion de precio
/// (tabla tpr_precio). Son exactamente las 6 columnas de la tabla, ni una mas.
///
/// Todo lo demas que muestra la pantalla —nombre de sucursal, proveedor, grupo
/// de familia, vpp, iva, it— viene de los DTO PrecioDto del backend, no de aca.
/// No agregar campos de display a esta entidad: el ABM p_abm_precio falla
/// entero si le llega un parametro que no existe en el procedimiento.
class PrecioEntity {
  /// PK, bigint IDENTITY. En un alta todavia no existe y vale BigInt.zero.
  final BigInt idPrecio;

  /// FK -> tpr_producto.codigoFamilia. Trampa: aca es int, pero en
  /// tpr_precioPropuesta la columna homonima es varchar(15).
  final int codigoFamilia;

  /// FK -> tpr_clasificacionPrecio.idClasificacion (bigint).
  final BigInt idClasificacion;

  /// Es dinero. En la base es float(53) y el backend lo expone como BigDecimal;
  /// Dart no tiene BigDecimal, asi que viaja en double. Formatear siempre a dos
  /// decimales al mostrar y no usarlo para acumular totales largos.
  final double precio;

  /// Usuario que hizo el ultimo movimiento. bigint NULL en la base.
  final BigInt audUsuario;

  /// Solo lectura. El ABM la pisa con GETDATE() en alta y en modificacion, asi
  /// que lo que mande el cliente se ignora. Puede venir null en filas viejas.
  final DateTime? audFecha;

  const PrecioEntity({
    required this.idPrecio,
    required this.codigoFamilia,
    required this.idClasificacion,
    required this.precio,
    required this.audUsuario,
    this.audFecha,
  });

  /// Todavia no se guardo: el backend no le asigno el IDENTITY.
  bool get esNuevo => idPrecio == BigInt.zero;

  /// Precio cargado y utilizable. Un cero aca significa sin precio definido.
  bool get tienePrecio => precio > 0;

  /// Precio listo para mostrar, con dos decimales.
  String get precioFormateado => 'Bs ${precio.toStringAsFixed(2)}';

  /// Estado legible para la grilla y las tarjetas del movil.
  String get estadoLegible => tienePrecio ? 'Vigente' : 'Sin precio';

  /// Fecha del ultimo movimiento en dd/mm/aaaa. Vacia si la fila nunca se
  /// audito.
  String get audFechaLegible {
    final f = audFecha;
    if (f == null) return '';
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year}';
  }

  PrecioEntity copyWith({
    BigInt? idPrecio,
    int? codigoFamilia,
    BigInt? idClasificacion,
    double? precio,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => PrecioEntity(
    idPrecio: idPrecio ?? this.idPrecio,
    codigoFamilia: codigoFamilia ?? this.codigoFamilia,
    idClasificacion: idClasificacion ?? this.idClasificacion,
    precio: precio ?? this.precio,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
