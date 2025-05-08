import 'dart:io';
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
    this.monedas = const ['Bolivianos', 'Dólares'],
    this.monedaSeleccionada = 'Bolivianos',
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
      state = state.copyWith(clientes: clientes, bancos: bancos, cargando: false);
    } else {
      state = state.copyWith(cargando: false);
    }
  }

  Future<void> seleccionarCliente(SocioNegocioEntity? cliente) async {
    state = state.copyWith(clienteSeleccionado: cliente, notasRemision: [], notasSeleccionadas: [], saldosEditados: {});
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

  void setACuenta(double value) {
    state = state.copyWith(aCuenta: value);
  }

  void setImporteTotal(double value) {
    state = state.copyWith(importeTotal: value);
  }

  void setImagenDeposito(File? file) {
    state = state.copyWith(imagenDeposito: file);
  }

  void seleccionarNota(int docNum, bool selected) {
    final seleccionadas = [...state.notasSeleccionadas];
    if (selected) {
      if (!seleccionadas.contains(docNum)) seleccionadas.add(docNum);
    } else {
      seleccionadas.remove(docNum);
    }
    state = state.copyWith(notasSeleccionadas: seleccionadas);
  }

  void editarSaldoPendiente(int docNum, double nuevoSaldo) {
    final nuevosSaldos = Map<int, double>.from(state.saldosEditados);
    nuevosSaldos[docNum] = nuevoSaldo;
    state = state.copyWith(saldosEditados: nuevosSaldos);
  }

  void limpiarFormulario() {
    state = DepositosChequesState(empresas: state.empresas);
  }
}

final depositosChequesProvider = StateNotifierProvider<DepositosChequesNotifier, DepositosChequesState>((ref) {
  return DepositosChequesNotifier();
});
