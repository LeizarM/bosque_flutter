class ResmadoEntity {
  int idRes;
  int idGrupo;
  int codEmpleado;
  DateTime fecha;
  double total;
  String hraInicio;
  String hraFin;
  int codEmpresa;
  int docNumOrdFab;
  int audUsuario;

  /// Campos de solo lectura: llegan resueltos desde el listado, no se escriben.
  String descripcion; // grupo de resmado
  String nombreCompleto; // empleado que resmo
  String empresa;

  ResmadoEntity({
    required this.idRes,
    required this.idGrupo,
    required this.codEmpleado,
    required this.fecha,
    required this.total,
    required this.hraInicio,
    required this.hraFin,
    required this.codEmpresa,
    required this.docNumOrdFab,
    required this.audUsuario,
    this.descripcion = '',
    this.nombreCompleto = '',
    this.empresa = '',
  });

  ResmadoEntity copyWith({int? codEmpresa, int? docNumOrdFab, String? empresa}) {
    return ResmadoEntity(
      idRes: idRes,
      idGrupo: idGrupo,
      codEmpleado: codEmpleado,
      fecha: fecha,
      total: total,
      hraInicio: hraInicio,
      hraFin: hraFin,
      codEmpresa: codEmpresa ?? this.codEmpresa,
      docNumOrdFab: docNumOrdFab ?? this.docNumOrdFab,
      audUsuario: audUsuario,
      descripcion: descripcion,
      nombreCompleto: nombreCompleto,
      empresa: empresa ?? this.empresa,
    );
  }
}
