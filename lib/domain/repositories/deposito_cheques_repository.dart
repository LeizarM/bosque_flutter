import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';

/// Fallo de una operación del módulo, con el texto ya listo para la persona.
///
/// Existe para no confundir un error con «no hay datos»: antes cualquier
/// timeout o 500 en un listado devolvía `[]` y la pantalla mostraba «No se
/// encontraron depósitos» tras esperar hasta 45 s. Un 204 (sin registros) sigue
/// siendo una lista vacía; esto se lanza solo cuando algo falló de verdad.
class DepositoChequesException implements Exception {
  const DepositoChequesException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

abstract class DepositoChequesRepository {
  Future<List<EmpresaEntity>> getEmpresas();
  Future<List<SocioNegocioEntity>> getSociosNegocio(int codEmpresa);
  Future<List<BancoXCuentaEntity>> getBancos(int codEmpresa);
  /// [imagen] es un `File` (móvil), un `Uint8List` (web) o `null` (se
  /// actualiza el depósito sin volver a subir la foto).
  Future<bool> registrarDeposito(DepositoChequeEntity deposito, dynamic imagen);

  Future<List<NotaRemisionEntity>> getNotasRemision(
    int codEmpresa,
    String codCliente,
  );

  Future<bool> guardarNotaRemision(NotaRemisionEntity notaRemision);

  Future<List<DepositoChequeEntity>> obtenerDepositos(
    int codEmpresa,
    int idBxC,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String codCliente,
    String estadoFiltro,
  );

  Future<List<DepositoChequeEntity>> lstDepositxIdentificar(
    int idBxC,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String codCliente,
  );

  Future<Uint8List> obtenerPdfDeposito(
    int idDeposito,
    DepositoChequeEntity deposito,
  );

  Future<Uint8List> obtenerImagenDeposito(int idDeposito);

  Future<bool> actualizarNroTransaccion(DepositoChequeEntity deposito);

  Future<bool> rechazarNotaRemision(DepositoChequeEntity deposito);
}
