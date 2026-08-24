/// Asignacion de un grupo a un vendedor, con vigencia (tabla tcom_GrupoXVendedor).
class GrupoXVendedorEntity {
  final BigInt idGrpVen;
  final BigInt idVendedor;
  final BigInt idGrupo;
  final int estado;
  final int ignoraComision;
  final DateTime fechaInicio;
  final DateTime? fechaFinalizacion;
  final BigInt audUsuario;

  // Campos de solo lectura que llegan del join.
  final String nomVenSap;
  final String grupo;
  final double porcentaje;
  final double porcenComision;
  final int esParaVenta;
  final int esInterno;
  final int vigente;

  const GrupoXVendedorEntity({
    required this.idGrpVen,
    required this.idVendedor,
    required this.idGrupo,
    required this.estado,
    required this.ignoraComision,
    required this.fechaInicio,
    this.fechaFinalizacion,
    required this.audUsuario,
    required this.nomVenSap,
    required this.grupo,
    required this.porcentaje,
    required this.porcenComision,
    required this.esParaVenta,
    required this.esInterno,
    required this.vigente,
  });

  bool get estaVigente => vigente == 1;

  double get porcentajeVisual => porcentaje;

  bool get ignora => ignoraComision == 1;

  GrupoXVendedorEntity copyWith({
    BigInt? idGrpVen,
    BigInt? idVendedor,
    BigInt? idGrupo,
    int? estado,
    int? ignoraComision,
    DateTime? fechaInicio,
    DateTime? fechaFinalizacion,
    BigInt? audUsuario,
    String? nomVenSap,
    String? grupo,
    double? porcentaje,
    double? porcenComision,
    int? esParaVenta,
    int? esInterno,
    int? vigente,
  }) => GrupoXVendedorEntity(
    idGrpVen: idGrpVen ?? this.idGrpVen,
    idVendedor: idVendedor ?? this.idVendedor,
    idGrupo: idGrupo ?? this.idGrupo,
    estado: estado ?? this.estado,
    ignoraComision: ignoraComision ?? this.ignoraComision,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFinalizacion: fechaFinalizacion ?? this.fechaFinalizacion,
    audUsuario: audUsuario ?? this.audUsuario,
    nomVenSap: nomVenSap ?? this.nomVenSap,
    grupo: grupo ?? this.grupo,
    porcentaje: porcentaje ?? this.porcentaje,
    porcenComision: porcenComision ?? this.porcenComision,
    esParaVenta: esParaVenta ?? this.esParaVenta,
    esInterno: esInterno ?? this.esInterno,
    vigente: vigente ?? this.vigente,
  );
}
