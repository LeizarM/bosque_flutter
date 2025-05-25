class PrestamoEstadoEntity {
    final int idPE;
    final int idPrestamo;
    final int idEst;
    final String momento;
    final int audUsuario;

    PrestamoEstadoEntity({
        required this.idPE,
        required this.idPrestamo,
        required this.idEst,
        required this.momento,
        required this.audUsuario,
    });

}
