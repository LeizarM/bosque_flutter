class ContenedorEntity {
  int idContenedor;
  String codigo;
  int idTipo;
  int codSucursal;
  String descripcion;
  String unidadMedida;
  int audUsuario;
  String clase;
  double saldoActualCombustible;

  ContenedorEntity({
    required this.idContenedor,
    required this.codigo,
    required this.idTipo,
    required this.codSucursal,
    required this.descripcion,
    required this.unidadMedida,
    required this.audUsuario,
    required this.clase,
    required this.saldoActualCombustible,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContenedorEntity &&
          runtimeType == other.runtimeType &&
          idContenedor == other.idContenedor &&
          codigo == other.codigo;

  @override
  int get hashCode => idContenedor.hashCode ^ codigo.hashCode;
}
