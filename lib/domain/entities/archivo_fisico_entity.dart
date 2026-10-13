/// Un archivo físico de documentos (`tarc_archivo`): ACHOCALLA, OFICINA CENTRAL.
class ArchivoFisicoEntity {
  static const int activo = 1;
  static const int inactivo = 0;

  final int codArchivo;
  final String nombre;
  final String? responsable;

  /// La sucursal (`tb_sucursal`) donde está; null = sin sucursal.
  final int? codSucursal;
  final int estado;
  final int audUsuario;
  final DateTime? audFecha;

  /// Solo lectura: la sucursal en palabras y cuántas cajas y líneas tiene
  /// (estas dos deciden si se puede eliminar).
  final String? nombreSucursal;
  final String? ciudadSucursal;
  final int cajas;
  final int lineas;

  const ArchivoFisicoEntity({
    required this.codArchivo,
    required this.nombre,
    this.responsable,
    this.codSucursal,
    this.estado = activo,
    this.audUsuario = 0,
    this.audFecha,
    this.nombreSucursal,
    this.ciudadSucursal,
    this.cajas = 0,
    this.lineas = 0,
  });

  bool get esActivo => estado == activo;

  ArchivoFisicoEntity copyWith({
    String? nombre,
    String? responsable,
    int? codSucursal,
    bool sinSucursal = false,
    int? estado,
    int? audUsuario,
  }) => ArchivoFisicoEntity(
    codArchivo: codArchivo,
    nombre: nombre ?? this.nombre,
    responsable: responsable ?? this.responsable,
    codSucursal: sinSucursal ? null : (codSucursal ?? this.codSucursal),
    estado: estado ?? this.estado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha,
    nombreSucursal: nombreSucursal,
    ciudadSucursal: ciudadSucursal,
    cajas: cajas,
    lineas: lineas,
  );
}
