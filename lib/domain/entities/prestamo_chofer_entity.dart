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
    final String fechaSolicitud; // Cambiar de DateTime a String
    final String motivo;
    final String solicitante;
    final String cargo;
    final String coche;
    final String estadoDisponibilidad;
    final int requiereChofer;

    final String estadoLateralesEntregaAux;
    final String estadoInteriorEntregaAux;
    final String estadoDelanteraEntregaAux;
    final String estadoTraseraEntregaAux;
    final String estadoCapoteEntregaAux;
    final String estadoLateralRecepcionAux;
    final String estadoInteriorRecepcionAux;
    final String estadoDelanteraRecepcionAux;
    final String estadoTraseraRecepcionAux;
    final String estadoCapoteRecepcionAux;

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
        required this.fechaSolicitud,
        required this.motivo,
        required this.solicitante,
        required this.cargo,
        required this.coche,
        required this.estadoDisponibilidad,
        required this.requiereChofer,
        required this.estadoLateralesEntregaAux,
        required this.estadoInteriorEntregaAux,
        required this.estadoDelanteraEntregaAux,
        required this.estadoTraseraEntregaAux,
        required this.estadoCapoteEntregaAux,
        required this.estadoLateralRecepcionAux,
        required this.estadoInteriorRecepcionAux,
        required this.estadoDelanteraRecepcionAux,
        required this.estadoTraseraRecepcionAux,
        required this.estadoCapoteRecepcionAux,
    });

}
