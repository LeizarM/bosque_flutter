import 'dart:io';

import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';

abstract class DepositoChequesRepository {
  
  Future<List<EmpresaEntity>> getEmpresas();
  Future<List<SocioNegocioEntity>> getSociosNegocio(int codEmpresa);
  Future<List<BancoXCuentaEntity>> getBancos(int codEmpresa);
  Future<bool> registrarDeposito(DepositoChequeEntity deposito, File imagen);

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
}
