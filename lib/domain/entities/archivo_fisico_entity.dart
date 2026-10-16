/// Un archivo físico de documentos (`tarc_archivo`): ACHOCALLA, OFICINA CENTRAL.
class ArchivoFisicoEntity {
  static const int activo = 1;
  static const int inactivo = 0;

  final int codArchivo;
  final String nombre;

  /// La sucursal (`tb_sucursal`) donde está; null = sin sucursal.
  final int? codSucursal;
  final int estado;
  final int audUsuario;
  final DateTime? audFecha;

  /// El empleado responsable (`tb_empleado`); obligatorio al guardar.
  final int? codEmpleado;

  /// Cuándo se le asignó: la pone el servidor y llega como texto «dd/mm/aaaa hh:mm».
  final String? fechaAsignacion;

  /// Solo lectura: el responsable y la sucursal en palabras, y cuántas cajas y
  /// líneas tiene (estas dos deciden si se puede eliminar).
  final String? nombreResponsable;
  final String? nombreSucursal;
  final String? ciudadSucursal;
  final int cajas;
  final int lineas;

  const ArchivoFisicoEntity({
    required this.codArchivo,
    required this.nombre,
    this.codSucursal,
    this.estado = activo,
    this.audUsuario = 0,
    this.audFecha,
    this.codEmpleado,
    this.fechaAsignacion,
    this.nombreResponsable,
    this.nombreSucursal,
    this.ciudadSucursal,
    this.cajas = 0,
    this.lineas = 0,
  });

  bool get esActivo => estado == activo;

  ArchivoFisicoEntity copyWith({
    String? nombre,
    int? codSucursal,
    bool sinSucursal = false,
    int? estado,
    int? audUsuario,
    int? codEmpleado,
  }) => ArchivoFisicoEntity(
    codArchivo: codArchivo,
    nombre: nombre ?? this.nombre,
    codSucursal: sinSucursal ? null : (codSucursal ?? this.codSucursal),
    estado: estado ?? this.estado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha,
    codEmpleado: codEmpleado ?? this.codEmpleado,
    fechaAsignacion: fechaAsignacion,
    nombreResponsable: nombreResponsable,
    nombreSucursal: nombreSucursal,
    ciudadSucursal: ciudadSucursal,
    cajas: cajas,
    lineas: lineas,
  );
}
