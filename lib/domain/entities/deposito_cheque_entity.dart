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
    final int audUsuario;
    final int codBanco;
    final DateTime fechaInicio;
    final DateTime fechaFin;
    final String nombreBanco;
    final String nombreEmpresa;
    final String esPendiente;
    final String numeroDeDocumentos;
    final String fechasDeDepositos;
    final String numeroDeFacturas;
    final String totalMontos;
    final String estadoFiltro;

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
        required this.audUsuario,
        required this.codBanco,
        required this.fechaInicio,
        required this.fechaFin,
        required this.nombreBanco,
        required this.nombreEmpresa,
        required this.esPendiente,
        required this.numeroDeDocumentos,
        required this.fechasDeDepositos,
        required this.numeroDeFacturas,
        required this.totalMontos,
        required this.estadoFiltro,
    });

}
