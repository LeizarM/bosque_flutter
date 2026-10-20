/// Resumen de un lote para el informe por categoría y fechas (`p_list_tcpe_Resultado` C).
class TcpeInformeCategoriaEntity {
  final BigInt codRolExamen;
  final String? titulo;
  final String? nombreArea;
  final String? nombreClasificacion;
  final String? modalidad;
  final DateTime? fecha;
  final int examenes;
  final int rendidos;
  final int calificados;
  final double? promedio;
  final int aprobados;
  final int reprobados;
  final double? notaAprobacion;
  final int ausentes;

  const TcpeInformeCategoriaEntity({
    required this.codRolExamen,
    this.titulo,
    this.nombreArea,
    this.nombreClasificacion,
    this.modalidad,
    this.fecha,
    this.examenes = 0,
    this.rendidos = 0,
    this.calificados = 0,
    this.promedio,
    this.aprobados = 0,
    this.reprobados = 0,
    this.notaAprobacion,
    this.ausentes = 0,
  });

  TcpeInformeCategoriaEntity copyWith({
    BigInt? codRolExamen,
    String? titulo,
    String? nombreArea,
    String? nombreClasificacion,
    String? modalidad,
    DateTime? fecha,
    int? examenes,
    int? rendidos,
    int? calificados,
    double? promedio,
    int? aprobados,
    int? reprobados,
    double? notaAprobacion,
    int? ausentes,
  }) => TcpeInformeCategoriaEntity(
    codRolExamen: codRolExamen ?? this.codRolExamen,
    titulo: titulo ?? this.titulo,
    nombreArea: nombreArea ?? this.nombreArea,
    nombreClasificacion: nombreClasificacion ?? this.nombreClasificacion,
    modalidad: modalidad ?? this.modalidad,
    fecha: fecha ?? this.fecha,
    examenes: examenes ?? this.examenes,
    rendidos: rendidos ?? this.rendidos,
    calificados: calificados ?? this.calificados,
    promedio: promedio ?? this.promedio,
    aprobados: aprobados ?? this.aprobados,
    reprobados: reprobados ?? this.reprobados,
    notaAprobacion: notaAprobacion ?? this.notaAprobacion,
    ausentes: ausentes ?? this.ausentes,
  );
}
