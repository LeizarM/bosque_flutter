class NotaRemisionEntity {
    final int idNr;
    final int idDeposito;
    final int docNum;
    final DateTime fecha;
    final int numFact;
    final int totalMonto;
    final int saldoPendiente;
    final int audUsuario;
    final String codCliente;
    final String nombreCliente;
    final String db;
    final int codEmpresaBosque;

    NotaRemisionEntity({
        required this.idNr,
        required this.idDeposito,
        required this.docNum,
        required this.fecha,
        required this.numFact,
        required this.totalMonto,
        required this.saldoPendiente,
        required this.audUsuario,
        required this.codCliente,
        required this.nombreCliente,
        required this.db,
        required this.codEmpresaBosque,
    });

}
