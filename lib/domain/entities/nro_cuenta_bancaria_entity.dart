class NroCuentaBancariaEntity {
    final int codCuenta;
    final int codEmpleado;
    final int codBanco;
    final String nroCuentaBancaria;
    final int estado;
    final int audUsuarioI;
    NroCuentaBancariaEntity({
        required this.codCuenta,
        required this.codEmpleado,
        required this.codBanco,
        required this.nroCuentaBancaria,
        required this.estado,
        required this.audUsuarioI,
    });
    //metodo to json
    Map<String, dynamic> toJson() {
      return {
        'codCuenta': codCuenta,
        'codEmpleado': codEmpleado,
        'codBanco': codBanco,
        'nroCuentaBancaria': nroCuentaBancaria,
        'estado': estado,
        'audUsuarioI': audUsuarioI,
      };
    }
}