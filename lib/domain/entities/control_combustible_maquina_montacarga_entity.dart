class ControlCombustibleMaquinaMontacargaEntity {
    final int idCM;
    final int idMaquinaVehiculoOrigen;
    final int idMaquinaVehiculoDestino;
    final int codSucursalMaqVehiOrigen;
    final int codSucursalMaqVehiDestino;
    final String codigoOrigen;
    final String codigoDestino;
    final DateTime fecha;
    final double litrosIngreso;
    final double litrosSalida;
    final double saldoLitros;
    final int codEmpleado;
    final String codAlmacen;
    final String obs;
    final String tipoTransaccion;
    final int audUsuario;
    final String whsCode;
    final String whsName;
    final String maquina;
    final String nombreCompleto;

    ControlCombustibleMaquinaMontacargaEntity({
        required this.idCM,
        required this.idMaquinaVehiculoOrigen,
        required this.idMaquinaVehiculoDestino,
        required this.codSucursalMaqVehiOrigen,
        required this.codSucursalMaqVehiDestino,
        required this.codigoOrigen,
        required this.codigoDestino,
        required this.fecha,
        required this.litrosIngreso,
        required this.litrosSalida,
        required this.saldoLitros,
        required this.codEmpleado,
        required this.codAlmacen,
        required this.obs,
        required this.tipoTransaccion,
        required this.audUsuario,
        required this.whsCode,
        required this.whsName,
        required this.maquina,
        required this.nombreCompleto,
    });

}

