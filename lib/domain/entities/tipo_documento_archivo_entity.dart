/// Un tipo de documento del archivo (`tarc_tipoDocumento`): Facturas, Notas de entrega…
class TipoDocumentoArchivoEntity {
  static const int activo = 1;
  static const int inactivo = 0;

  final int codTipoDocumento;
  final String nombre;
  final int estado;
  final int audUsuario;
  final DateTime? audFecha;

  /// Solo lectura: cuántas líneas de contenido lo usan.
  final int usos;

  const TipoDocumentoArchivoEntity({
    required this.codTipoDocumento,
    required this.nombre,
    this.estado = activo,
    this.audUsuario = 0,
    this.audFecha,
    this.usos = 0,
  });

  bool get esActivo => estado == activo;

  TipoDocumentoArchivoEntity copyWith({
    String? nombre,
    int? estado,
    int? audUsuario,
  }) => TipoDocumentoArchivoEntity(
    codTipoDocumento: codTipoDocumento,
    nombre: nombre ?? this.nombre,
    estado: estado ?? this.estado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha,
    usos: usos,
  );
}
