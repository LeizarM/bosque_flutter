/// Un lote para monitorear: con exámenes en curso o la ventana abierta (`p_list_tcpe_Monitor` D).
class TcpeMonitorLoteEntity {
  final BigInt codRolExamen;
  final String? titulo;
  final String? nombreClasificacion;
  final String? modalidad;
  final DateTime? inicioVentana;
  final DateTime? finVentana;
  final int examenes;
  final int sinIniciar;
  final int enCurso;
  final int entregados;

  const TcpeMonitorLoteEntity({
    required this.codRolExamen,
    this.titulo,
    this.nombreClasificacion,
    this.modalidad,
    this.inicioVentana,
    this.finVentana,
    this.examenes = 0,
    this.sinIniciar = 0,
    this.enCurso = 0,
    this.entregados = 0,
  });

  TcpeMonitorLoteEntity copyWith({
    BigInt? codRolExamen,
    String? titulo,
    String? nombreClasificacion,
    String? modalidad,
    DateTime? inicioVentana,
    DateTime? finVentana,
    int? examenes,
    int? sinIniciar,
    int? enCurso,
    int? entregados,
  }) => TcpeMonitorLoteEntity(
    codRolExamen: codRolExamen ?? this.codRolExamen,
    titulo: titulo ?? this.titulo,
    nombreClasificacion: nombreClasificacion ?? this.nombreClasificacion,
    modalidad: modalidad ?? this.modalidad,
    inicioVentana: inicioVentana ?? this.inicioVentana,
    finVentana: finVentana ?? this.finVentana,
    examenes: examenes ?? this.examenes,
    sinIniciar: sinIniciar ?? this.sinIniciar,
    enCurso: enCurso ?? this.enCurso,
    entregados: entregados ?? this.entregados,
  );
}
