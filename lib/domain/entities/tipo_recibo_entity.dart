/// Catálogo de tipos de talonario. Tabla tmto_tipoRecibo.
///
/// La sigla arma el prefijo del nroTalonario y está atada a la empresa:
/// IR1/IR3/NPI son de Impexpap, ER1/EC2 de Esppapel, PR2/R4 del resto.
///
/// [estado] sale de v_tipos grupo 11: '0' Inactivo, '1' Activo.
class TipoReciboEntity {
  BigInt codTipoRecibo;
  String nombre;
  String detalle;
  String estado;
  String sigla;
  BigInt audUsuario;
  DateTime? audFecha;

  // ---- solo lectura, los llena el backend ----
  String datoEstado;
  String datoTipo;

  /// Si es > 0 el tipo no se puede eliminar.
  int cantTalonarios;
  int cantGrupos;

  /// Último folio usado por este tipo. Con esto el alta propone el bloque
  /// siguiente, para no duplicar números de recibo.
  int ultimoFolio;

  TipoReciboEntity({
    required this.codTipoRecibo,
    required this.nombre,
    required this.detalle,
    required this.estado,
    required this.sigla,
    required this.audUsuario,
    this.audFecha,
    this.datoEstado = '',
    this.datoTipo = '',
    this.cantTalonarios = 0,
    this.cantGrupos = 0,
    this.ultimoFolio = 0,
  });

  /// Primer bloque de 50 folios que todavía no se usó.
  int get bloqueSugerido => (ultimoFolio ~/ 50) + 1;

  bool get activo => estado == '1';
  bool get sePuedeEliminar => cantTalonarios == 0 && cantGrupos == 0;
}
