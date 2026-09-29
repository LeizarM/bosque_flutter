/// Lista de precios por sucursal (tabla tpr_clasificacionPrecio).
///
/// Contiene EXACTAMENTE las columnas de la tabla. El nombre de la sucursal NO
/// vive aca: viene de un JOIN y el backend lo expone en un DTO aparte, porque
/// el SP de ABM recibe cada campo del model como parametro y un campo extra
/// haria fallar el EXEC.
///
/// OJO con [estado]: 1 = activa, 0 = inactiva. En la base hay varias inactivas,
/// asi que los combos deben filtrar con [esActiva] antes de listar.
class ClasificacionPrecioEntity {
  /// PK. En alta va en cero: el SP genera el id y lo devuelve.
  final BigInt idClasificacion;

  /// FK a tb_sucursal.codSucursal.
  ///
  /// TRAMPA historica del backend: el SP declara el parametro como
  /// `@idSucursal`, no como `@codSucursal`. El ALTER lo resuelve con COALESCE,
  /// de modo que desde el frontend el campo siempre viaja como `codSucursal`.
  final BigInt codSucursal;

  /// Numero de lista de precios en SAP (Business One). No es un id interno.
  final BigInt listNum;

  /// Nombre de la lista. La columna admite hasta 100 caracteres.
  final String nombrePrecio;

  /// Numero de la lista de precios de la vista de precios (VPP).
  final int vpp;

  /// 1 = activa, 0 = inactiva.
  final int estado;

  final BigInt audUsuario;

  /// Fecha de auditoria. La sella el SP con GETDATE(), el cliente no la manda.
  final DateTime? audFecha;

  const ClasificacionPrecioEntity({
    required this.idClasificacion,
    required this.codSucursal,
    required this.listNum,
    required this.nombrePrecio,
    required this.vpp,
    required this.estado,
    required this.audUsuario,
    required this.audFecha,
  });

  /// Lista habilitada. Es el filtro que deben aplicar los combos.
  bool get esActiva => estado == 1;

  /// Estado en texto, listo para mostrar en tabla o tarjeta.
  String get estadoLegible => esActiva ? 'Activa' : 'Inactiva';

  /// Indica si la lista esta enlazada a una lista de precios de SAP.
  bool get tieneListaSap => listNum > BigInt.zero;

  /// Numero de lista SAP legible. Evita mostrar el cero cuando no hay enlace.
  String get listNumLegible =>
      tieneListaSap ? listNum.toString() : 'Sin enlace';

  /// Etiqueta corta para combos y encabezados: "VPP 3 - Precio Mayorista".
  String get etiquetaCombo =>
      nombrePrecio.isEmpty ? 'VPP $vpp' : 'VPP $vpp - $nombrePrecio';

  ClasificacionPrecioEntity copyWith({
    BigInt? idClasificacion,
    BigInt? codSucursal,
    BigInt? listNum,
    String? nombrePrecio,
    int? vpp,
    int? estado,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => ClasificacionPrecioEntity(
    idClasificacion: idClasificacion ?? this.idClasificacion,
    codSucursal: codSucursal ?? this.codSucursal,
    listNum: listNum ?? this.listNum,
    nombrePrecio: nombrePrecio ?? this.nombrePrecio,
    vpp: vpp ?? this.vpp,
    estado: estado ?? this.estado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
