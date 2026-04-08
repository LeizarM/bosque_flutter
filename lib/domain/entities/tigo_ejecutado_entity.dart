class TigoEjecutadoEntity {
  final int codCuenta;
  final String? corporativo;
  final int codEmpleado;
  final String nombreCompleto;
  final String descripcion;
  final String? ciNumero;
  final String? empresa;
  final String periodoCobrado;
  final String estado;
  final double totalCobradoXCuenta;
  final double montoCubiertoXEmpresa;
  final double montoEmpleado;
  final int audUsuarioI;
  final int fila;
  final int codEmpleadoPadre;
  final List<TigoEjecutadoEntity> items;
  final String? listaCodEmpleado;

  TigoEjecutadoEntity({
    required this.codCuenta,
    required this.corporativo,
    required this.codEmpleado,
    required this.nombreCompleto,
    required this.descripcion,
    required this.ciNumero,
    required this.empresa,
    required this.periodoCobrado,
    required this.estado,
    required this.totalCobradoXCuenta,
    required this.montoCubiertoXEmpresa,
    required this.montoEmpleado,
    required this.audUsuarioI,
    required this.fila,
    required this.codEmpleadoPadre,
    required this.items,
    this.listaCodEmpleado,
  });
  //metodo toJson
  Map<String, dynamic> toJson() {
    return {
      'codCuenta': codCuenta,
      'nroCuenta': corporativo,
      'codEmpleado': codEmpleado,
      'nombreCompleto': nombreCompleto,
      'descripcion': descripcion,
      'ciNumero': ciNumero,
      'empresa': empresa,
      'periodoCobrado': periodoCobrado,
      'estado': estado,
      'totalCobradoXCuenta': totalCobradoXCuenta,
      'montoCubiertoXEmpresa': montoCubiertoXEmpresa,
      'montoEmpleado': montoEmpleado,
      'audUsuario': audUsuarioI,
      'fila': fila,
      'codEmpleadoPadre': codEmpleadoPadre,
      'items': items.map((item) => item.toJson()).toList(),
      'listaCodEmpleado': listaCodEmpleado,
    };
  }
  //meoto copywith
  TigoEjecutadoEntity copyWith({
    int? codCuenta,
    int? nroCuenta,
    int? codEmpleado,
    String? nombreCompleto,
    String? descripcion,
    String? ciNumero,
    String? empresa,
    String? periodoCobrado,
    String? estado,
    double? totalCobradoXCuenta,
    double? montoCubiertoXEmpresa,
    double? montoEmpleado,
    int? audUsuarioI,
    int? fila,
    int? codEmpleadoPadre,
    List<TigoEjecutadoEntity>? items,
    String? listaCodEmpleado,
  }) {
    return TigoEjecutadoEntity(
      codCuenta: codCuenta ?? this.codCuenta,
      corporativo: corporativo ?? corporativo,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      descripcion: descripcion ?? this.descripcion,
      ciNumero: ciNumero ?? this.ciNumero,
      empresa: empresa ?? this.empresa,
      periodoCobrado: periodoCobrado ?? this.periodoCobrado,
      estado: estado ?? this.estado,
      totalCobradoXCuenta: totalCobradoXCuenta ?? this.totalCobradoXCuenta,
      montoCubiertoXEmpresa: montoCubiertoXEmpresa ?? this.montoCubiertoXEmpresa,
      montoEmpleado: montoEmpleado ?? this.montoEmpleado,
      audUsuarioI: audUsuarioI ?? this.audUsuarioI,
      fila: fila ?? this.fila,
      codEmpleadoPadre: codEmpleadoPadre ?? this.codEmpleadoPadre,
      items: items ?? this.items,
      listaCodEmpleado: listaCodEmpleado ?? this.listaCodEmpleado,
    );
  }
}