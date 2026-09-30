// Repositorio falso del módulo de depósitos y datos de ejemplo. Lo usan las
// pruebas del notifier y las de las pantallas: sin backend, sin login y con
// contadores de llamadas para comprobar qué se pide y qué no.
import 'dart:async';
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/repositories/deposito_cheques_repository.dart';


final loginAdminFalso = LoginEntity.fromJson(<String, dynamic>{
  'tipoUsuario': 'ROLE_ADM',
  'codUsuario': 34,
});

EmpresaEntity empresaFalsa(int cod) => EmpresaEntity(
  codEmpresa: cod,
  nombre: 'Empresa $cod',
  codPadre: 0,
  sigla: 'E$cod',
  audUsuario: 0,
);

SocioNegocioEntity clienteFalso(String cod) => SocioNegocioEntity(
  codCliente: cod,
  datoCliente: cod,
  razonSocial: 'Cliente $cod',
  nit: '1',
  codCiudad: 1,
  datoCiudad: 'La Paz',
  esVigente: 'Y',
  codEmpresa: 1,
  audUsuario: 0,
  nombreCompleto: 'Cliente $cod',
);

BancoXCuentaEntity bancoFalso(int id) => BancoXCuentaEntity(
  idBxC: id,
  codBanco: id,
  numCuenta: '000$id',
  moneda: 'BS',
  codEmpresa: 1,
  audUsuario: 0,
  nombreBanco: 'Banco $id',
);

NotaRemisionEntity notaFalsa(int docNum) => NotaRemisionEntity(
  idNr: 0,
  idDeposito: 0,
  docNum: docNum,
  fecha: DateTime(2026, 9, 1),
  numFact: docNum,
  totalMonto: 100,
  saldoPendiente: 100,
  audUsuario: 0,
  codCliente: 'C1',
  nombreCliente: 'Cliente C1',
  db: 'SAP',
  codEmpresaBosque: 1,
);

DepositoChequeEntity depositoFalso(int id) => DepositoChequeEntity(
  idDeposito: id,
  codCliente: 'C1',
  codEmpresa: 1,
  idBxC: 1,
  importe: 10,
  moneda: 'BS',
  estado: 1,
  fotoPath: '',
  aCuenta: 0,
  nroTransaccion: '',
  obs: '',
  codEmpleado: 0,
  audUsuario: 0,
  codBanco: 1,
  fechaInicio: DateTime(2026, 9, 1),
  fechaFin: DateTime(2026, 9, 1),
  nombreBanco: 'Banco 1',
  nombreEmpresa: 'Empresa 1',
  nombreVendedor: '',
  esPendiente: 'Pendiente',
  numeroDeDocumentos: '',
  fechasDeDepositos: '',
  numeroDeFacturas: '',
  totalMontos: '',
  estadoFiltro: '',
  nombreCompleto: '',
);

// ── Repositorio falso ──────────────────────────────────────────────────────

class RepoDepositosFalso implements DepositoChequesRepository {
  final List<String> llamadas = [];

  List<EmpresaEntity> empresas = [empresaFalsa(1), empresaFalsa(2), empresaFalsa(3)];
  List<SocioNegocioEntity> clientes = [clienteFalso('C1'), clienteFalso('C2')];
  List<BancoXCuentaEntity> bancos = [bancoFalso(1), bancoFalso(2)];
  List<NotaRemisionEntity> notas = [];
  List<DepositoChequeEntity> depositos = [];

  Object? errorEmpresas;
  Object? errorBancos;
  Object? errorRegistro;
  Object? errorListado;
  Completer<List<SocioNegocioEntity>>? clientesPendientes;

  /// `docNum` cuya nota falla al guardarse.
  int? notaQueFalla;

  final List<int> notasGuardadas = [];
  final List<int> idsDeNotas = [];
  DepositoChequeEntity? ultimoDeposito;
  int _simultaneas = 0;
  int maxNotasSimultaneas = 0;

  int contar(String metodo) => llamadas.where((m) => m == metodo).length;

  @override
  Future<List<EmpresaEntity>> getEmpresas() async {
    llamadas.add('getEmpresas');
    await Future<void>.delayed(Duration.zero);
    if (errorEmpresas != null) throw errorEmpresas!;
    return empresas;
  }

  @override
  Future<List<SocioNegocioEntity>> getSociosNegocio(int codEmpresa) async {
    llamadas.add('getSociosNegocio');
    final pendiente = clientesPendientes;
    if (pendiente != null) return pendiente.future;
    await Future<void>.delayed(Duration.zero);
    return clientes;
  }

  @override
  Future<List<BancoXCuentaEntity>> getBancos(int codEmpresa) async {
    llamadas.add('getBancos');
    await Future<void>.delayed(Duration.zero);
    if (errorBancos != null) throw errorBancos!;
    return bancos;
  }

  @override
  Future<List<NotaRemisionEntity>> getNotasRemision(
    int codEmpresa,
    String codCliente,
  ) async {
    llamadas.add('getNotasRemision');
    await Future<void>.delayed(Duration.zero);
    return notas;
  }

  @override
  Future<bool> registrarDeposito(
    DepositoChequeEntity deposito,
    dynamic imagen,
  ) async {
    llamadas.add('registrarDeposito');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    if (errorRegistro != null) throw errorRegistro!;
    ultimoDeposito = deposito;
    return true;
  }

  @override
  Future<bool> guardarNotaRemision(NotaRemisionEntity notaRemision) async {
    llamadas.add('guardarNotaRemision');
    _simultaneas++;
    if (_simultaneas > maxNotasSimultaneas) maxNotasSimultaneas = _simultaneas;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    _simultaneas--;
    if (notaRemision.docNum == notaQueFalla) {
      throw const DepositoChequesException('No se pudo guardar la nota.');
    }
    notasGuardadas.add(notaRemision.docNum);
    idsDeNotas.add(notaRemision.idDeposito);
    return true;
  }

  @override
  Future<List<DepositoChequeEntity>> obtenerDepositos(
    int codEmpresa,
    int idBxC,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String codCliente,
    String estadoFiltro,
  ) async {
    llamadas.add('obtenerDepositos');
    await Future<void>.delayed(Duration.zero);
    if (errorListado != null) throw errorListado!;
    return depositos;
  }

  @override
  Future<List<DepositoChequeEntity>> lstDepositxIdentificar(
    int idBxC,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String codCliente,
  ) async {
    llamadas.add('lstDepositxIdentificar');
    await Future<void>.delayed(Duration.zero);
    if (errorListado != null) throw errorListado!;
    return depositos;
  }

  @override
  Future<Uint8List> obtenerPdfDeposito(
    int idDeposito,
    DepositoChequeEntity deposito,
  ) => throw UnimplementedError();

  @override
  Future<Uint8List> obtenerImagenDeposito(int idDeposito) =>
      throw UnimplementedError();

  @override
  Future<bool> actualizarNroTransaccion(DepositoChequeEntity deposito) async {
    llamadas.add('actualizarNroTransaccion');
    return true;
  }

  @override
  Future<bool> rechazarNotaRemision(DepositoChequeEntity deposito) async {
    llamadas.add('rechazarNotaRemision');
    return true;
  }
}
