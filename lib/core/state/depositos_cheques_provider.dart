import 'dart:io';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_entity.dart';
import 'package:bosque_flutter/data/repositories/deposito_cheques_impl.dart';

class DepositosChequesState {
  final List<EmpresaEntity> empresas;
  final EmpresaEntity? empresaSeleccionada;
  final List<SocioNegocioEntity> clientes;
  final SocioNegocioEntity? clienteSeleccionado;
  final List<BancoXCuentaEntity> bancos;
  final BancoXCuentaEntity? bancoSeleccionado;
  final List<String> monedas;
  final String monedaSeleccionada;
  final double aCuenta;
  final double importeTotal;
  final File? imagenDeposito;
  final bool cargando;
  final List<NotaRemisionEntity> notasRemision;
  final List<int> notasSeleccionadas; // docNum de las seleccionadas
  final Map<int, double> saldosEditados; // docNum -> saldoPendiente editado

  DepositosChequesState({
    this.empresas = const [],
    this.empresaSeleccionada,
    this.clientes = const [],
    this.clienteSeleccionado,
    this.bancos = const [],
    this.bancoSeleccionado,
    this.monedas = const ['BS', 'USD'],
    this.monedaSeleccionada = 'BS',
    this.aCuenta = 0.0,
    this.importeTotal = 0.0,
    this.imagenDeposito,
    this.cargando = false,
    this.notasRemision = const [],
    this.notasSeleccionadas = const [],
    this.saldosEditados = const {},
  });

  DepositosChequesState copyWith({
    List<EmpresaEntity>? empresas,
    EmpresaEntity? empresaSeleccionada,
    List<SocioNegocioEntity>? clientes,
    SocioNegocioEntity? clienteSeleccionado,
    List<BancoXCuentaEntity>? bancos,
    BancoXCuentaEntity? bancoSeleccionado,
    List<String>? monedas,
    String? monedaSeleccionada,
    double? aCuenta,
    double? importeTotal,
    File? imagenDeposito,
    bool? cargando,
    List<NotaRemisionEntity>? notasRemision,
    List<int>? notasSeleccionadas,
    Map<int, double>? saldosEditados,
  }) {
    return DepositosChequesState(
      empresas: empresas ?? this.empresas,
      empresaSeleccionada: empresaSeleccionada ?? this.empresaSeleccionada,
      clientes: clientes ?? this.clientes,
      clienteSeleccionado: clienteSeleccionado ?? this.clienteSeleccionado,
      bancos: bancos ?? this.bancos,
      bancoSeleccionado: bancoSeleccionado ?? this.bancoSeleccionado,
      monedas: monedas ?? this.monedas,
      monedaSeleccionada: monedaSeleccionada ?? this.monedaSeleccionada,
      aCuenta: aCuenta ?? this.aCuenta,
      importeTotal: importeTotal ?? this.importeTotal,
      imagenDeposito: imagenDeposito ?? this.imagenDeposito,
      cargando: cargando ?? this.cargando,
      notasRemision: notasRemision ?? this.notasRemision,
      notasSeleccionadas: notasSeleccionadas ?? this.notasSeleccionadas,
      saldosEditados: saldosEditados ?? this.saldosEditados,
    );
  }
}

class DepositosChequesNotifier extends StateNotifier<DepositosChequesState> {
  final DepositoChequesImpl _repo = DepositoChequesImpl();
  DepositosChequesNotifier() : super(DepositosChequesState()) {
    cargarEmpresas();
  }

  Future<void> cargarEmpresas() async {
    state = state.copyWith(cargando: true);
    final empresas = await _repo.getEmpresas();
    state = state.copyWith(empresas: empresas, cargando: false);
  }

  Future<void> seleccionarEmpresa(EmpresaEntity? empresa) async {
    state = state.copyWith(
      empresaSeleccionada: empresa,
      clienteSeleccionado: null,
      bancoSeleccionado: null,
      clientes: [],
      bancos: [],
      cargando: true,
    );
    if (empresa != null) {
      final clientes = await _repo.getSociosNegocio(empresa.codEmpresa);
      final bancos = await _repo.getBancos(empresa.codEmpresa);
      // Si no hay clientes, quitar cargando y dejar la lista vacía
      if (clientes.isEmpty) {
        state = state.copyWith(clientes: [], bancos: bancos, cargando: false);
      } else {
        state = state.copyWith(clientes: clientes, bancos: bancos, cargando: false);
      }
    } else {
      state = state.copyWith(cargando: false);
    }
  }

  Future<void> seleccionarCliente(SocioNegocioEntity? cliente) async {
    state = state.copyWith(
      clienteSeleccionado: cliente,
      notasRemision: [],
      notasSeleccionadas: [],
      saldosEditados: {},
      importeTotal: 0.0,
    );
    if (cliente != null && state.empresaSeleccionada != null) {
      state = state.copyWith(cargando: true);
      final notas = await _repo.getNotasRemision(state.empresaSeleccionada!.codEmpresa, cliente.codCliente);
      state = state.copyWith(notasRemision: notas, cargando: false);
    }
  }

  void seleccionarBanco(BancoXCuentaEntity? banco) {
    state = state.copyWith(bancoSeleccionado: banco);
  }

  void seleccionarMoneda(String? moneda) {
    if (moneda != null) {
      state = state.copyWith(monedaSeleccionada: moneda);
    }
  }

  void seleccionarNota(int docNum, bool selected) {
    final seleccionadas = [...state.notasSeleccionadas];
    if (selected) {
      if (!seleccionadas.contains(docNum)) seleccionadas.add(docNum);
    } else {
      seleccionadas.remove(docNum);
    }
    final nuevoImporteTotal = _calcularImporteTotal(
      seleccionadas,
      state.saldosEditados,
      state.notasRemision,
      state.aCuenta,
    );
    state = state.copyWith(notasSeleccionadas: seleccionadas, importeTotal: nuevoImporteTotal);
  }

  void editarSaldoPendiente(int docNum, double nuevoSaldo) {
    final nuevosSaldos = Map<int, double>.from(state.saldosEditados);
    nuevosSaldos[docNum] = nuevoSaldo;
    final nuevoImporteTotal = _calcularImporteTotal(
      state.notasSeleccionadas,
      nuevosSaldos,
      state.notasRemision,
      state.aCuenta,
    );
    state = state.copyWith(saldosEditados: nuevosSaldos, importeTotal: nuevoImporteTotal);
  }

  void setACuenta(double value) {
    final nuevoImporteTotal = _calcularImporteTotal(
      state.notasSeleccionadas,
      state.saldosEditados,
      state.notasRemision,
      value,
    );
    state = state.copyWith(aCuenta: value, importeTotal: nuevoImporteTotal);
  }

  double _calcularImporteTotal(List<int> seleccionadas, Map<int, double> saldosEditados, List<NotaRemisionEntity> notas, double aCuenta) {
    double totalSeleccionados = 0;
    for (var nota in notas) {
      if (seleccionadas.contains(nota.docNum)) {
        totalSeleccionados += saldosEditados[nota.docNum]?.toDouble() ?? nota.saldoPendiente.toDouble();
      }
    }
    return totalSeleccionados + (aCuenta);
  }

  void limpiarFormulario() {
    state = DepositosChequesState(empresas: state.empresas);
  }

  Future<bool> registrarDeposito(dynamic imagen) async {
    state = state.copyWith(cargando: true);
    try {
      // Construir entidad DepositoChequeEntity (sin fechaI, el backend la genera)
      final deposito = DepositoChequeEntity(
        idDeposito: 0,
        codCliente: state.clienteSeleccionado?.codCliente ?? '',
        codEmpresa: state.empresaSeleccionada?.codEmpresa ?? 0,
        idBxC: state.bancoSeleccionado?.idBxC ?? 0,
        importe: state.importeTotal,
        moneda: state.monedaSeleccionada,
        estado: 1,
        fotoPath: '',
        aCuenta: state.aCuenta,
        fechaI: null, // Enviar como null
        nroTransaccion: '',
        obs: '',
        audUsuario: 0,
        codBanco: state.bancoSeleccionado?.codBanco ?? 0,
        fechaInicio: DateTime.now(),
        fechaFin: DateTime.now(),
        nombreBanco: state.bancoSeleccionado?.nombreBanco ?? '',
        nombreEmpresa: state.empresaSeleccionada?.nombre ?? '',
        esPendiente: '',
        numeroDeDocumentos: state.notasSeleccionadas.length.toString(),
        fechasDeDepositos: '',
        numeroDeFacturas: '',
        totalMontos: '',
        estadoFiltro: '',
      );
      final result = await _repo.registrarDeposito(deposito, imagen);
      state = state.copyWith(cargando: false);
      return result;
    } catch (e) {
      state = state.copyWith(cargando: false);
      rethrow;
    }
  }

  Future<bool> guardarNotasRemision() async {
    state = state.copyWith(cargando: true);
    try {
      bool allOk = true;
      for (final docNum in state.notasSeleccionadas) {
        final nota = state.notasRemision.firstWhere((n) => n.docNum == docNum);
        final saldoEditado = state.saldosEditados[docNum] ?? nota.saldoPendiente;
        final notaEditada = NotaRemisionEntity(
          idNr: nota.idNr,
          idDeposito: nota.idDeposito,
          docNum: nota.docNum,
          fecha: nota.fecha,
          numFact: nota.numFact,
          totalMonto: nota.totalMonto,
          saldoPendiente: saldoEditado,
          audUsuario: nota.audUsuario,
          codCliente: nota.codCliente,
          nombreCliente: nota.nombreCliente,
          db: nota.db,
          codEmpresaBosque: nota.codEmpresaBosque,
        );
        final ok = await _repo.guardarNotaRemision(notaEditada);
        if (!ok) allOk = false;
      }
      state = state.copyWith(cargando: false);
      return allOk;
    } catch (e) {
      state = state.copyWith(cargando: false);
      rethrow;
    }
  }
}

final depositosChequesProvider = StateNotifierProvider<DepositosChequesNotifier, DepositosChequesState>((ref) {
  return DepositosChequesNotifier();
});
