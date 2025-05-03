class ControlCombustibleMaquinaMontacargaEntity {
    final int idCm;
    final int idMaquina;
    final DateTime fecha;
    final double litrosIngreso;
    final double litrosSalida;
    final double saldoLitros;
    final double horasUso;
    final double horometro;
    final int codEmpleado;
    final String codAlmacen;
    final String obs;
    final int audUsuario;
    final String whsCode;
    final String whsName;

    ControlCombustibleMaquinaMontacargaEntity({
        required this.idCm,
        required this.idMaquina,
        required this.fecha,
        required this.litrosIngreso,
        required this.litrosSalida,
        required this.saldoLitros,
        required this.horasUso,
        required this.horometro,
        required this.codEmpleado,
        required this.codAlmacen,
        required this.obs,
        required this.audUsuario,
        required this.whsCode,
        required this.whsName,
    });

}

