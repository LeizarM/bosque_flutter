class DiaNoLaborableEntity {
  BigInt idDiaNoLaborable;
  DateTime fecha;
  String motivo;
  String alcance; // "Global" o "N sucursal(es)" — solo lectura, lo calcula el backend
  int audUsuario;

  DiaNoLaborableEntity({
    required this.idDiaNoLaborable,
    required this.fecha,
    required this.motivo,
    required this.alcance,
    required this.audUsuario,
  });
}
