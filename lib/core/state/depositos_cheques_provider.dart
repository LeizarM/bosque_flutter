import 'dart:io';
import 'dart:typed_data';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_entity.dart';
import 'package:bosque_flutter/data/repositories/deposito_cheques_impl.dart';
import 'package:path_provider/path_provider.dart';
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
  final String obs; // Almacenar las observaciones

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
    this.obs = '',
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
    String? obs,
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
      fechaDesde:
          setFechaDesdeNull == true ? null : (fechaDesde ?? this.fechaDesde),
      fechaHasta:
          setFechaHastaNull == true ? null : (fechaHasta ?? this.fechaHasta),
      page: page ?? this.page,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      totalRegistros: totalRegistros ?? this.totalRegistros,
      obs: obs ?? this.obs,
    );
  }
}

class DepositosChequesNotifier extends StateNotifier<DepositosChequesState> {
  /// Última respuesta cruda del backend al registrar depósito (para depuración)
  dynamic lastResponse;
  final DepositoChequesImpl _repo = DepositoChequesImpl();
  final Ref ref;

  DepositosChequesNotifier(this.ref) : super(DepositosChequesState()) {
    cargarEmpresas();
  }

  /// Busca depósitos pendientes por identificar usando el método lstDepositxIdentificar del repositorio
  Future<void> buscarDepositosPorIdentificar({
    required int idBxC,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? codCliente,
  }) async {
    state = state.copyWith(cargando: true);
    try {
      final depositos = await _repo.lstDepositxIdentificar(
        idBxC,
        fechaDesde,
        fechaHasta,
        codCliente ?? '',
      );
      state = state.copyWith(
        depositos: depositos,
        totalRegistros: depositos.length,
        cargando: false,
        page: 0,
      );
    } catch (e) {
      state = state.copyWith(cargando: false);
    }
  }

  // Permite acceso al repositorio para casos específicos como cargar bancos
  DepositoChequesImpl get repo => _repo;

  // Método para actualizar número de transacción y banco de un depósito
  Future<void> actualizarDepositoTransaccionYBanco({
    required DepositoChequeEntity deposito,
    required String nuevoNroTransaccion,
    required BancoXCuentaEntity nuevoBanco,
    required BuildContext context,
  }) async {
    state = state.copyWith(cargando: true);
    try {
      // Crear una nueva instancia del depósito con los valores actualizados
      final depositoActualizado = DepositoChequeEntity(
        idDeposito: deposito.idDeposito,
        codCliente: deposito.codCliente,
        codEmpresa: deposito.codEmpresa,
        idBxC: nuevoBanco.idBxC, // Nuevo banco
        importe: deposito.importe,
        moneda: deposito.moneda,
        estado: deposito.estado,
        fotoPath: deposito.fotoPath,
        aCuenta: deposito.aCuenta,
        //fechaI: deposito.fechaI,
        nroTransaccion: nuevoNroTransaccion, // Nuevo número de transacción
        obs: deposito.obs,
        audUsuario: deposito.audUsuario,
        codBanco: nuevoBanco.codBanco, // Nuevo banco
        fechaInicio: deposito.fechaInicio,
        fechaFin: deposito.fechaFin,
        nombreBanco: nuevoBanco.nombreBanco, // Nuevo nombre de banco
        nombreEmpresa: deposito.nombreEmpresa,
        esPendiente: deposito.esPendiente,
        numeroDeDocumentos: deposito.numeroDeDocumentos,
        fechasDeDepositos: deposito.fechasDeDepositos,
        numeroDeFacturas: deposito.numeroDeFacturas,
        totalMontos: deposito.totalMontos,
        estadoFiltro: deposito.estadoFiltro,
      );

      // Llamar al método existente para actualizar
      final resultado = await _repo.actualizarNroTransaccion(
        depositoActualizado,
      );

      // Actualizar lista de depósitos si fue exitoso
      if (resultado) {
        // Buscar y actualizar el depósito en la lista actual
        final listaActualizada =
            state.depositos.map((d) {
              if (d.idDeposito == deposito.idDeposito) {
                return depositoActualizado;
              }
              return d;
            }).toList();

        state = state.copyWith(depositos: listaActualizada, cargando: false);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Depósito actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        state = state.copyWith(cargando: false);
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar el depósito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(cargando: false);
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar depósito: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        ...empresasRaw,
      ];
      state = state.copyWith(
        empresas: empresas,
        cargando: false,
        // Asegurarse de que empresaSeleccionada sea válida
        empresaSeleccionada:
            state.empresaSeleccionada != null &&
                    empresas.any(
                      (e) =>
                          e.codEmpresa == state.empresaSeleccionada!.codEmpresa,
                    )
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
        empresaSeleccionada:
            state.empresas.isNotEmpty
                ? state.empresas.first
                : null, // Selecciona "Todos"
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
      ...clientesRaw,
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
        clienteSeleccionado:
            state.clientes.isNotEmpty
                ? state.clientes.first
                : null, // Selecciona "Todos"
        notasRemision: [],
        notasSeleccionadas: [],
        saldosEditados: {},
        importeTotal: 0.0,
      );
      return;
    }
    if (cliente != null && state.empresaSeleccionada != null) {
      state = state.copyWith(clienteSeleccionado: cliente, cargando: true);
      final notas = await _repo.getNotasRemision(
        state.empresaSeleccionada!.codEmpresa,
        cliente.codCliente,
      );
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
    state = state.copyWith(
      notasSeleccionadas: seleccionadas,
      importeTotal: nuevoImporteTotal,
    );
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
    state = state.copyWith(
      saldosEditados: nuevosSaldos,
      importeTotal: nuevoImporteTotal,
    );
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

  // Método para actualizar el importe total directamente (para pantalla de depósitos sin identificar)
  void setImporteTotal(double value) {
    state = state.copyWith(importeTotal: value);
  }

  // Método para actualizar observaciones
  void setObservaciones(String valor) {
    state = state.copyWith(obs: valor);
  }

  double _calcularImporteTotal(
    List<int> seleccionadas,
    Map<int, double> saldosEditados,
    List<NotaRemisionEntity> notas,
    double aCuenta,
  ) {
    double totalSeleccionados = 0;
    for (var nota in notas) {
      if (seleccionadas.contains(nota.docNum)) {
        totalSeleccionados +=
            saldosEditados[nota.docNum]?.toDouble() ??
            nota.saldoPendiente.toDouble();
      }
    }
    return totalSeleccionados + (aCuenta);
  }

  void limpiarFormulario() {
    state = DepositosChequesState(empresas: state.empresas);
  }

  Future<bool> registrarDeposito(
    dynamic imagen, {
    int? idDepositoActualizacion,
  }) async {
    state = state.copyWith(cargando: true);
    lastResponse = null;

    try {
      // Usar el ID pasado como parámetro para actualizaciones, 0 para nuevos registros
      final idDeposito = idDepositoActualizacion ?? 0;

      // Obtener codUsuario correctamente desde userProvider
      final user = ref.read(userProvider);
      final codUsuario = user?.codUsuario ?? 0;

      final deposito = DepositoChequeEntity(
        idDeposito: idDeposito,
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
        obs: state.obs, // Usar las observaciones guardadas en el estado
        audUsuario: codUsuario, // <-- Aquí se llena correctamente
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
      
      bool result = false;
     
      try {
        result = await _repo.registrarDeposito(deposito, imagen);
       
      } catch (e, st) {
        debugPrint('[DEBUG][provider] Error al registrar depósito: $e; ${st.toString()}');
      }
      state = state.copyWith(cargando: false);
      return result;
    } catch (e) {
      state = state.copyWith(cargando: false);
      lastResponse = e.toString();
      rethrow;
    }
  }

  /// Útil para mantener las selecciones hechas en el modal
  void sincronizarClienteSeleccionado(SocioNegocioEntity? cliente) {
    
    state = state.copyWith(clienteSeleccionado: cliente);
  }

  /// Sincroniza la empresa seleccionada sin recargar clientes/bancos
  /// Útil para mantener las selecciones hechas en el modal
  void sincronizarEmpresaSeleccionada(EmpresaEntity? empresa) {
    
    state = state.copyWith(empresaSeleccionada: empresa);
  }

  /// Sincroniza el banco seleccionado
  void sincronizarBancoSeleccionado(BancoXCuentaEntity? banco) {
    
    state = state.copyWith(bancoSeleccionado: banco);
  }

  /// Método para verificar el estado de las notas seleccionadas (debug)
  void mostrarEstadoNotasSeleccionadas() {
    

    for (final docNum in state.notasSeleccionadas) {
      final nota = state.notasRemision.firstWhere(
        (n) => n.docNum == docNum,
        orElse:
            () => NotaRemisionEntity(
              idNr: 0,
              idDeposito: 0,
              docNum: docNum,
              totalMonto: 0,
              saldoPendiente: 0,
              audUsuario: 0,
              codCliente: '',
              nombreCliente: '',
              db: '',
              codEmpresaBosque: 0,
              fecha: DateTime.now(),
              numFact: 0,
            ),
      );

      
    }
  }

  Future<bool> guardarNotasRemision({int? idDepositoParaNotas}) async {
    state = state.copyWith(cargando: true);

    try {
      if (state.notasSeleccionadas.isEmpty) {
        state = state.copyWith(cargando: false);
        return true; // Si no hay notas, consideramos exitoso
      }

      bool allOk = true;
      int notasGuardadas = 0;

      // Obtener codUsuario desde userProvider
      final user = ref.read(userProvider);
      final codUsuario = user?.codUsuario ?? 0;

      for (final docNum in state.notasSeleccionadas) {
        try {
          final nota = state.notasRemision.firstWhere(
            (n) => n.docNum == docNum,
            orElse: () {
              throw Exception('Nota no encontrada: $docNum');
            },
          );

          final saldoEditado = state.saldosEditados[docNum] ?? nota.saldoPendiente;

          final notaEditada = NotaRemisionEntity(
            idNr: nota.idNr,
            idDeposito: idDepositoParaNotas ?? nota.idDeposito, // USAR EL ID CORRECTO
            docNum: nota.docNum,
            fecha: nota.fecha,
            numFact: nota.numFact,
            totalMonto: nota.totalMonto,
            saldoPendiente: saldoEditado,
            audUsuario: codUsuario, // <-- Aquí se llena correctamente
            codCliente: nota.codCliente,
            nombreCliente: nota.nombreCliente,
            db: nota.db,
            codEmpresaBosque: nota.codEmpresaBosque,
          );

          final ok = await _repo.guardarNotaRemision(notaEditada);

          if (ok) {
            notasGuardadas++;
          } else {
            allOk = false;
          }
        } catch (e) {
          allOk = false;
        }
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

  Future<void> descargarPdfDeposito(
    int idDeposito,
    BuildContext context,
  ) async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF descargado correctamente')));
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

  void procesarPdfDescargado(
    Uint8List pdfBytes,
    BuildContext context,
    int idDeposito,
  ) {
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
    final anchor =
        html.AnchorElement(href: url)
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
      final estadoFiltro =
          state.selectedEstado == 'Todos' ? '' : state.selectedEstado;
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

  Future<void> descargarImagenDeposito(
    int idDeposito,
    BuildContext context,
  ) async {
    state = state.copyWith(cargando: true);
    try {
      // Descargamos la imagen
      final imageBytes = await _repo.obtenerImagenDeposito(idDeposito);

      // Procesamos la imagen según la plataforma
      await manejarArchivoImagen(
        imageBytes,
        'deposito_$idDeposito.jpg',
        context,
      );

      state = state.copyWith(cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false);
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> manejarArchivoImagen(
    Uint8List bytes,
    String fileName,
    BuildContext context,
  ) async {
    if (kIsWeb) {
      // En web, imitar el comportamiento de Angular
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Descarga iniciada: $fileName')));
    } else {
      // En móvil, guardar la imagen y permitir verla
      try {
        // Mostrar cuadro de diálogo con opciones
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('Imagen descargada'),
              content: Image.memory(bytes, fit: BoxFit.contain, height: 200),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Cerrar'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _guardarImagenEnDispositivo(bytes, fileName);
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        throw Exception('Error al manejar la imagen: $e');
      }
    }
  }

  Future<void> _guardarImagenEnDispositivo(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      // Implementación específica según la plataforma
      if (Platform.isAndroid || Platform.isIOS) {
        // Usar path_provider para obtener directorio temporal
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        // Usar un plugin como share_plus para compartir la imagen
        // await Share.shareFiles([file.path], text: 'Imagen de depósito');

        // O simplemente mostrar un mensaje de éxito
        print('Imagen guardada en: ${file.path}');
      } else {
        throw Exception(
          'Plataforma no soportada para guardar imágenes localmente',
        );
      }
    } catch (e) {
      throw Exception('Error al guardar imagen: $e');
    }
  }

  Future<void> rechazarDepositoCheque({
    required DepositoChequeEntity deposito,
    required BuildContext context,
  }) async {
    state = state.copyWith(cargando: true);
    try {
      // Actualizar el estado del depósito a rechazado (3)
      final depositoRechazado = DepositoChequeEntity(
        idDeposito: deposito.idDeposito,
        codCliente: deposito.codCliente,
        codEmpresa: deposito.codEmpresa,
        idBxC: deposito.idBxC,
        importe: deposito.importe,
        moneda: deposito.moneda,
        estado: 3, // Rechazado (1: Pendiente, 2: Verificado, 3: Rechazado)
        fotoPath: deposito.fotoPath,
        aCuenta: deposito.aCuenta,
        nroTransaccion: deposito.nroTransaccion,
        obs: deposito.obs,
        audUsuario: deposito.audUsuario,
        codBanco: deposito.codBanco,
        fechaInicio: deposito.fechaInicio,
        fechaFin: deposito.fechaFin,
        nombreBanco: deposito.nombreBanco,
        nombreEmpresa: deposito.nombreEmpresa,
        esPendiente: deposito.esPendiente,
        numeroDeDocumentos: deposito.numeroDeDocumentos,
        fechasDeDepositos: deposito.fechasDeDepositos,
        numeroDeFacturas: deposito.numeroDeFacturas,
        totalMontos: deposito.totalMontos,
        estadoFiltro: deposito.estadoFiltro,
      );

      // Llamar al método existente en el repositorio para rechazar
      final resultado = await _repo.rechazarNotaRemision(depositoRechazado);

      // Actualizar lista de depósitos si fue exitoso
      if (resultado) {
        // Buscar y actualizar el depósito en la lista actual
        final listaActualizada =
            state.depositos.map((d) {
              if (d.idDeposito == deposito.idDeposito) {
                return depositoRechazado;
              }
              return d;
            }).toList();

        state = state.copyWith(depositos: listaActualizada, cargando: false);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Depósito rechazado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        state = state.copyWith(cargando: false);
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo rechazar el depósito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(cargando: false);
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al rechazar depósito: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void clearState() {
    // Restablecer el estado manteniendo solo las empresas
    state = DepositosChequesState(
      empresas:
          state
              .empresas, // Mantener empresas para no tener que cargarlas nuevamente
      depositos: [], // Vaciar lista de depósitos
      clientes: [],
      bancos: [],
      cargando: false,
      page: 0,
      rowsPerPage: 10,
      totalRegistros: 0,
      selectedEstado: 'Todos',
      fechaDesde: DateTime.now(),
      fechaHasta: DateTime.now(),
    );
  }

  // Nuevo método para limpiar solo los resultados de búsqueda de depósitos
  void clearDepositosResults() {
    state = state.copyWith(
      depositos: [],
      totalRegistros: 0,
      page: 0,
      selectedEstado: 'Todos',
      fechaDesde: null,
      fechaHasta: null,
      setFechaDesdeNull: true,
      setFechaHastaNull: true,
    );
  }

  // Nuevo método para limpiar específicamente el estado de registro de depósitos
  void clearRegistroDepositos() {
    state = state.copyWith(
      clienteSeleccionado: null,
      notasSeleccionadas: [],
      saldosEditados: {},
      aCuenta: 0.0,
      importeTotal: 0.0,
      obs: '',
    );
  }
}

final depositosChequesProvider =
    StateNotifierProvider<DepositosChequesNotifier, DepositosChequesState>((
      ref,
    ) {
      return DepositosChequesNotifier(ref);
    });
