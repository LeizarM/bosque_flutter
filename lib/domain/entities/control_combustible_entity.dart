class CombustibleControlEntity {
    final int idC;
    final int idCoche;
    final DateTime fecha;
    final String estacionServicio;
    final String nroFactura;
    final double importe;
    final double kilometraje;
    final int codEmpleado;
    final double diferencia;
    final int codSucursalCoche;
    final String obs;
    final double litros;
    final String tipoCombustible;
    final int audUsuario;
    final String coche;
    final double kilometrajeAnterior;

    CombustibleControlEntity({
        required this.idC,
        required this.idCoche,
        required this.fecha,
        required this.estacionServicio,
        required this.nroFactura,
        required this.importe,
        required this.kilometraje,
        required this.codEmpleado,
        required this.diferencia,
        required this.codSucursalCoche,
        required this.obs,
        required this.litros,
        required this.tipoCombustible,
        required this.audUsuario,
        required this.coche,
        required this.kilometrajeAnterior,
    });

}
