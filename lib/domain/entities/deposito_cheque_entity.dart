class DepositoChequeEntity {
  final int idDeposito;
  final String codCliente;
  final int codEmpresa;
  final int idBxC;
  final double importe;
  final String moneda;
  final int estado;
  final String fotoPath;
  final double aCuenta;
  final DateTime? fechaI;
  final String nroTransaccion;
  final String obs;
  final int codEmpleado;
  final int audUsuario;
  final int codBanco;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String nombreBanco;
  final String nombreEmpresa;
  final String nombreVendedor;
  final String esPendiente;
  final String numeroDeDocumentos;
  final String fechasDeDepositos;
  final String numeroDeFacturas;
  final String totalMontos;
  final String estadoFiltro;
  final String nombreCompleto;

  DepositoChequeEntity({
    required this.idDeposito,
    required this.codCliente,
    required this.codEmpresa,
    required this.idBxC,
    required this.importe,
    required this.moneda,
    required this.estado,
    required this.fotoPath,
    required this.aCuenta,
    this.fechaI,
    required this.nroTransaccion,
    required this.obs,
    required this.codEmpleado,
    required this.audUsuario,
    required this.codBanco,
    required this.fechaInicio,
    required this.fechaFin,
    required this.nombreBanco,
    required this.nombreEmpresa,
    required this.nombreVendedor,
    required this.esPendiente,
    required this.numeroDeDocumentos,
    required this.fechasDeDepositos,
    required this.numeroDeFacturas,
    required this.totalMontos,
    required this.estadoFiltro,
    required this.nombreCompleto,
  });

  /// Copia con los campos indicados. Conserva `fechaI` y el resto: reconstruir
  /// el depósito campo por campo a mano ya hizo que "Fecha Ingreso" pasara a
  /// «—» tras editar o rechazar.
  DepositoChequeEntity copyWith({
    int? idDeposito,
    String? codCliente,
    int? codEmpresa,
    int? idBxC,
    double? importe,
    String? moneda,
    int? estado,
    String? fotoPath,
    double? aCuenta,
    DateTime? fechaI,
    String? nroTransaccion,
    String? obs,
    int? codEmpleado,
    int? audUsuario,
    int? codBanco,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? nombreBanco,
    String? nombreEmpresa,
    String? nombreVendedor,
    String? esPendiente,
    String? numeroDeDocumentos,
    String? fechasDeDepositos,
    String? numeroDeFacturas,
    String? totalMontos,
    String? estadoFiltro,
    String? nombreCompleto,
  }) {
    return DepositoChequeEntity(
      idDeposito: idDeposito ?? this.idDeposito,
      codCliente: codCliente ?? this.codCliente,
      codEmpresa: codEmpresa ?? this.codEmpresa,
      idBxC: idBxC ?? this.idBxC,
      importe: importe ?? this.importe,
      moneda: moneda ?? this.moneda,
      estado: estado ?? this.estado,
      fotoPath: fotoPath ?? this.fotoPath,
      aCuenta: aCuenta ?? this.aCuenta,
      fechaI: fechaI ?? this.fechaI,
      nroTransaccion: nroTransaccion ?? this.nroTransaccion,
      obs: obs ?? this.obs,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      audUsuario: audUsuario ?? this.audUsuario,
      codBanco: codBanco ?? this.codBanco,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      nombreBanco: nombreBanco ?? this.nombreBanco,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      nombreVendedor: nombreVendedor ?? this.nombreVendedor,
      esPendiente: esPendiente ?? this.esPendiente,
      numeroDeDocumentos: numeroDeDocumentos ?? this.numeroDeDocumentos,
      fechasDeDepositos: fechasDeDepositos ?? this.fechasDeDepositos,
      numeroDeFacturas: numeroDeFacturas ?? this.numeroDeFacturas,
      totalMontos: totalMontos ?? this.totalMontos,
      estadoFiltro: estadoFiltro ?? this.estadoFiltro,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    );
  }
}
