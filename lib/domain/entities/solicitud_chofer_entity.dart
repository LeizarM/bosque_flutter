class SolicitudChoferEntity {
    final int idSolicitud;
    final DateTime fechaSolicitud;
    final String motivo;
    final int codEmpSoli;
    final String cargo;
    final int estado;
    final int idCocheSol;
    final int idES;
    final int requiereChofer;
    final int audUsuario;
    final String fechaSolicitudCad;
    final String estadoCad;
    final int codSucursal;
    final String coche;

    SolicitudChoferEntity({
        required this.idSolicitud,
        required this.fechaSolicitud,
        required this.motivo,
        required this.codEmpSoli,
        required this.cargo,
        required this.estado,
        required this.idCocheSol,
        required this.idES,
        required this.requiereChofer,
        required this.audUsuario,
        required this.fechaSolicitudCad,
        required this.estadoCad,
        required this.codSucursal,
        required this.coche,
    });

}
