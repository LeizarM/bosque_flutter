class PrestamoChoferEntity {
    final int idPrestamo;
    final int idCoche;
    final int idSolicitud;
    final int codSucursal;
    final DateTime fechaEntrega;
    final int codEmpChoferSolicitado;
    final int codEmpEntregadoPor;
    final double kilometrajeEntrega;
    final double kilometrajeRecepcion;
    final int nivelCombustibleEntrega;
    final int nivelCombustibleRecepcion;
    final int estadoLateralesEntrega;
    final int estadoInteriorEntrega;
    final int estadoDelanteraEntrega;
    final int estadoTraseraEntrega;
    final int estadoCapoteEntrega;
    final int estadoLateralRecepcion;
    final int estadoInteriorRecepcion;
    final int estadoDelanteraRecepcion;
    final int estadoTraseraRecepcion;
    final int estadoCapoteRecepcion;
    final int audUsuario;
    final int requiereChofer;

    PrestamoChoferEntity({
        required this.idPrestamo,
        required this.idCoche,
        required this.idSolicitud,
        required this.codSucursal,
        required this.fechaEntrega,
        required this.codEmpChoferSolicitado,
        required this.codEmpEntregadoPor,
        required this.kilometrajeEntrega,
        required this.kilometrajeRecepcion,
        required this.nivelCombustibleEntrega,
        required this.nivelCombustibleRecepcion,
        required this.estadoLateralesEntrega,
        required this.estadoInteriorEntrega,
        required this.estadoDelanteraEntrega,
        required this.estadoTraseraEntrega,
        required this.estadoCapoteEntrega,
        required this.estadoLateralRecepcion,
        required this.estadoInteriorRecepcion,
        required this.estadoDelanteraRecepcion,
        required this.estadoTraseraRecepcion,
        required this.estadoCapoteRecepcion,
        required this.audUsuario,
        required this.requiereChofer,
    });

}
