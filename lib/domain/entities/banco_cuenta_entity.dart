class BancoXCuentaEntity {
    final int idBxC;
    final int codBanco;
    final String numCuenta;
    final String moneda;
    final int codEmpresa;
    final int audUsuario;
    final String nombreBanco;

    BancoXCuentaEntity({
        required this.idBxC,
        required this.codBanco,
        required this.numCuenta,
        required this.moneda,
        required this.codEmpresa,
        required this.audUsuario,
        required this.nombreBanco,
    });

}
