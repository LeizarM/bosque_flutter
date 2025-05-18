import 'dart:io';
import 'dart:typed_data';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_entity.dart';
import 'package:bosque_flutter/data/repositories/deposito_cheques_impl.dart';
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

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
  final List<DepositoChequeEntity> depositos;
  final String? selectedEstado;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final int page;
  final int rowsPerPage;
  final int totalRegistros;

  final bool setFechaDesdeNull;
  final bool setFechaHastaNull;

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
    this.depositos = const [],
    this.selectedEstado = 'Todos',
    this.fechaDesde,
    this.fechaHasta,
    this.page = 0,
    this.rowsPerPage = 10,
    this.totalRegistros = 0,

    this.setFechaDesdeNull = false,
    this.setFechaHastaNull = false,
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
    List<DepositoChequeEntity>? depositos,
    String? selectedEstado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? page,
    int? rowsPerPage,
    int? totalRegistros,
    bool? setFechaDesdeNull,
    bool? setFechaHastaNull,
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
      depositos: depositos ?? this.depositos,
      selectedEstado: selectedEstado ?? this.selectedEstado,
      fechaDesde: setFechaDesdeNull == true ? null : (fechaDesde ?? this.fechaDesde),
      fechaHasta: setFechaHastaNull == true ? null : (fechaHasta ?? this.fechaHasta),
      page: page ?? this.page,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      totalRegistros: totalRegistros ?? this.totalRegistros,
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
    try {
      final empresasRaw = await _repo.getEmpresas();
      // Inyectar opción "Todos" al inicio
      final empresas = [
        EmpresaEntity(
          codEmpresa: 0,
          nombre: 'Todos',
          codPadre: 0,
          sigla: '',
          audUsuario: 0,
        ),
        ...empresasRaw
      ];
      state = state.copyWith(
        empresas: empresas,
        cargando: false,
        // Asegurarse de que empresaSeleccionada sea válida
        empresaSeleccionada: state.empresaSeleccionada != null &&
                empresas.any((e) => e.codEmpresa == state.empresaSeleccionada!.codEmpresa)
            ? state.empresaSeleccionada
            : null,
      );
    } catch (e) {
      // En caso de error, al menos quitar el indicador de carga
      state = state.copyWith(cargando: false);
    }
  }

  Future<void> seleccionarEmpresa(EmpresaEntity? empresa) async {
    // Si empresa es null (Todos) o codEmpresa==0, limpiar todos los filtros dependientes y seleccionar "Todos"
    if (empresa == null || empresa.codEmpresa == 0) {
      final clientesTodos = [
        SocioNegocioEntity(
          codCliente: '',
          datoCliente: '',
          razonSocial: 'Todos',
          nit: '',
          codCiudad: 0,
          datoCiudad: '',
          esVigente: '',
          codEmpresa: 0,
          audUsuario: 0,
          nombreCompleto: 'Todos',
        ),
      ];
      state = state.copyWith(
        empresaSeleccionada: state.empresas.isNotEmpty ? state.empresas.first : null, // Selecciona "Todos"
        clienteSeleccionado: clientesTodos.first, // Selecciona "Todos"
        bancoSeleccionado: null,
        clientes: clientesTodos,
        bancos: [],
        selectedEstado: 'Todos',
        cargando: false,
      );
      return;
    }
    // Si se selecciona una empresa específica
    state = state.copyWith(
      empresaSeleccionada: empresa,
      clienteSeleccionado: null,
      bancoSeleccionado: null,
      clientes: [],
      bancos: [],
      selectedEstado: 'Todos',
      cargando: true,
    );
    final clientesRaw = await _repo.getSociosNegocio(empresa.codEmpresa);
    // Inyectar opción "Todos" al inicio
    final clientes = [
      SocioNegocioEntity(
        codCliente: '',
        datoCliente: '',
        razonSocial: 'Todos',
        nit: '',
        codCiudad: 0,
        datoCiudad: '',
        esVigente: '',
        codEmpresa: empresa.codEmpresa,
        audUsuario: 0,
        nombreCompleto: 'Todos',
      ),
      ...clientesRaw
    ];
    final bancos = await _repo.getBancos(empresa.codEmpresa);
    state = state.copyWith(
      clientes: clientes,
      bancos: bancos,
      clienteSeleccionado: clientes.first, // Selecciona "Todos" por defecto
      cargando: false,
    );
  }

  Future<void> seleccionarCliente(SocioNegocioEntity? cliente) async {
    // Si cliente es null (Todos), limpiar selección y seleccionar "Todos"
    if (cliente == null || cliente.codCliente == '') {
      state = state.copyWith(
        clienteSeleccionado: state.clientes.isNotEmpty ? state.clientes.first : null, // Selecciona "Todos"
        notasRemision: [],
        notasSeleccionadas: [],
        saldosEditados: {},
        importeTotal: 0.0,
      );
      return;
    }
    if (cliente != null && state.empresaSeleccionada != null) {
      state = state.copyWith(clienteSeleccionado: cliente, cargando: true);
      final notas = await _repo.getNotasRemision(state.empresaSeleccionada!.codEmpresa, cliente.codCliente);
      state = state.copyWith(notasRemision: notas, cargando: false);
    }
  }

  void seleccionarBanco(BancoXCuentaEntity? banco) {
    // Si banco es null (Todos), limpiar selección
    if (banco == null) {
      state = state.copyWith(bancoSeleccionado: null);
      return;
    }
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

  void setEstado(String? estado) {
    // Si estado es null o 'Todos', limpiar selección
    state = state.copyWith(selectedEstado: estado ?? 'Todos');
  }

  void setFechaDesde(DateTime? fecha) {
  if (fecha == null) {
    state = state.copyWith(setFechaDesdeNull: true);
  } else {
    state = state.copyWith(fechaDesde: fecha);
  }
}

Future<void> descargarPdfDeposito(int idDeposito, BuildContext context) async {
  state = state.copyWith(cargando: true);
  try {
    // Buscamos el depósito por ID
    final deposito = state.depositos.firstWhere(
      (d) => d.idDeposito == idDeposito,
      orElse: () => throw Exception('Depósito no encontrado'),
    );
    
    // Mostrar mensaje de inicio para depuración
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Descargando PDF del depósito $idDeposito...')),
    );
    
    // Descargamos el PDF
    final pdfBytes = await _repo.obtenerPdfDeposito(idDeposito, deposito);
    
    // Verificar que los bytes parecen ser un PDF (comienzan con %PDF)
    if (pdfBytes.length > 4 && 
        String.fromCharCodes(pdfBytes.sublist(0, 4)) == '%PDF') {
      // Procesamos el PDF según la plataforma
      procesarPdfDescargado(pdfBytes, context, idDeposito);
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF descargado correctamente')),
      );
    } else {
      throw Exception('Los datos recibidos no parecen ser un PDF válido');
    }
    
    state = state.copyWith(cargando: false);
  } catch (e) {
    state = state.copyWith(cargando: false);
    
    // Mostrar mensaje de error detallado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al descargar PDF: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
    
    print('Error detallado: $e');
  }
}

void procesarPdfDescargado(Uint8List pdfBytes, BuildContext context, int idDeposito) {
  if (kIsWeb) {
    // En web, iniciamos la descarga
    downloadWebPdf(pdfBytes, 'deposito_$idDeposito.pdf');
  } else {
    // En móvil, mostramos la pantalla de previsualización
    Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Depósito $idDeposito',
    );
  }
}

// Método para descargar PDF en web
void downloadWebPdf(Uint8List pdfBytes, String fileName) {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  
  // Simular click para iniciar descarga
  anchor.click();
  
  // Limpiar
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

void setFechaHasta(DateTime? fecha) {
  if (fecha == null) {
    state = state.copyWith(setFechaHastaNull: true);
  } else {
    state = state.copyWith(fechaHasta: fecha);
  }
}

  void setRowsPerPage(int? rows) {
    if (rows != null) {
      state = state.copyWith(rowsPerPage: rows, page: 0);
    }
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  Future<void> buscarDepositos() async {
    state = state.copyWith(cargando: true);
    try {
      final empresa = state.empresaSeleccionada;
      final banco = state.bancoSeleccionado;
      final cliente = state.clienteSeleccionado;
      final estadoFiltro = state.selectedEstado == 'Todos' ? '' : state.selectedEstado;
      final codEmpresa = empresa?.codEmpresa ?? 0;
      final idBxC = banco?.idBxC ?? 0;
      final fechaInicio = state.fechaDesde; // Puede ser null
      final fechaFin = state.fechaHasta; // Puede ser null
      final codCliente = cliente?.codCliente ?? '';
      final depositos = await _repo.obtenerDepositos(
        codEmpresa,
        idBxC,
        fechaInicio,
        fechaFin,
        codCliente,
        estadoFiltro ?? '',
      );
      state = state.copyWith(
        depositos: depositos,
        totalRegistros: depositos.length,
        cargando: false,
      );
    } catch (e) {
      state = state.copyWith(cargando: false);
    }

  }

  
}

final depositosChequesProvider = StateNotifierProvider<DepositosChequesNotifier, DepositosChequesState>((ref) {
  return DepositosChequesNotifier();
});
