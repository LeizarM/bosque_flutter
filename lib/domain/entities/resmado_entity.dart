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
  });
}
