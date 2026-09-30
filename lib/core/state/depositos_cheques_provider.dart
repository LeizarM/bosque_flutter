import 'dart:async';
import 'dart:io';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:bosque_flutter/domain/repositories/deposito_cheques_repository.dart';
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

/// Qué carga produjo `DepositosChequesState.error`. Permite mostrar el fallo
/// donde corresponde y no borrarlo cuando empieza otra carga sin relación.
enum OperacionCarga { empresas, bancos, clientes, notas, listado }

/// Estado del módulo de depósitos.
///
/// **Una bandera por operación, no una para todo.** Con un solo `cargando`, cada
/// petición corta (elegir un cliente, bajar una imagen) bloqueaba o reemplazaba
/// la pantalla entera. Las pantallas deben mostrar el avance donde ocurre y
/// dejar el resto usable; [cargando] queda solo para preguntar «¿hay algo en
/// curso?», nunca para desmontar el formulario.
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

  final bool cargandoEmpresas;
  final bool cargandoClientes;
  final bool cargandoBancos;
  final bool cargandoNotas;

  /// Listado de depósitos en curso (`/listar` o `/listar-dep-identificar`).
  final bool buscando;

  /// Registro o asignación en curso. Los botones de guardar se deshabilitan
  /// con esto; es lo que evita el doble toque.
  final bool guardando;

  /// `idDeposito` con descarga de imagen / de PDF en curso (por fila).
  final Set<int> imagenesEnCurso;
  final Set<int> pdfsEnCurso;

  /// `idDeposito` con edición o rechazo en curso (por fila).
  final Set<int> filasOcupadas;

  /// Último fallo de una carga (empresas, clientes, bancos, notas, listado).
  /// Se pasa tal cual a `MensajeError`. Se limpia al reintentar.
  final Object? error;

  /// Carga que produjo [error].
  final OperacionCarga? errorEn;

  final List<NotaRemisionEntity> notasRemision;
  final List<int> notasSeleccionadas; // docNum de las seleccionadas
  final Map<int, double> saldosEditados; // docNum -> saldoPendiente editado

  /// `docNum` que ya se enviaron en un guardado que quedó a medias: el
  /// reintento no los repite (`/registrar-nota-remision` inserta siempre).
  final Set<int> notasGuardadas;

  /// El depósito ya se creó en el servidor y faltan notas. El siguiente
  /// guardar reintenta solo las notas; si volviera a crear el depósito
  /// quedaría duplicado.
  final bool depositoRegistrado;

  final List<DepositoChequeEntity> depositos;
  final String? selectedEstado;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final int page;
  final int rowsPerPage;
  final int totalRegistros;
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
    this.cargandoEmpresas = false,
    this.cargandoClientes = false,
    this.cargandoBancos = false,
    this.cargandoNotas = false,
    this.buscando = false,
    this.guardando = false,
    this.imagenesEnCurso = const {},
    this.pdfsEnCurso = const {},
    this.filasOcupadas = const {},
    this.error,
    this.errorEn,
    this.notasRemision = const [],
    this.notasSeleccionadas = const [],
    this.saldosEditados = const {},
    this.notasGuardadas = const {},
    this.depositoRegistrado = false,
    this.depositos = const [],
    this.selectedEstado = 'Todos',
    this.fechaDesde,
    this.fechaHasta,
    this.page = 0,
    this.rowsPerPage = 10,
    this.totalRegistros = 0,
    this.obs = '',
  });

  /// Hay alguna operación en curso. Solo para deshabilitar acciones o mostrar
  /// una barra de progreso; no para reemplazar el contenido.
  bool get cargando =>
      cargandoEmpresas ||
      cargandoClientes ||
      cargandoBancos ||
      cargandoNotas ||
      buscando ||
      guardando;

  /// Los campos `clearX` existen porque `x ?? this.x` no puede poner `null`:
  /// sin ellos, cambiar de empresa dejaba seleccionado el banco de la anterior
  /// y Guardar se habilitaba con el `idBxC` equivocado.
  DepositosChequesState copyWith({
    List<EmpresaEntity>? empresas,
    EmpresaEntity? empresaSeleccionada,
    bool clearEmpresa = false,
    List<SocioNegocioEntity>? clientes,
    SocioNegocioEntity? clienteSeleccionado,
    bool clearCliente = false,
    List<BancoXCuentaEntity>? bancos,
    BancoXCuentaEntity? bancoSeleccionado,
    bool clearBanco = false,
    List<String>? monedas,
    String? monedaSeleccionada,
    double? aCuenta,
    double? importeTotal,
    File? imagenDeposito,
    bool clearImagen = false,
    bool? cargandoEmpresas,
    bool? cargandoClientes,
    bool? cargandoBancos,
    bool? cargandoNotas,
    bool? buscando,
    bool? guardando,
    Set<int>? imagenesEnCurso,
    Set<int>? pdfsEnCurso,
    Set<int>? filasOcupadas,
    Object? error,
    OperacionCarga? errorEn,
    bool clearError = false,
    List<NotaRemisionEntity>? notasRemision,
    List<int>? notasSeleccionadas,
    Map<int, double>? saldosEditados,
    Set<int>? notasGuardadas,
    bool? depositoRegistrado,
    List<DepositoChequeEntity>? depositos,
    String? selectedEstado,
    DateTime? fechaDesde,
    bool clearFechaDesde = false,
    DateTime? fechaHasta,
    bool clearFechaHasta = false,
    int? page,
    int? rowsPerPage,
    int? totalRegistros,
    String? obs,
  }) {
    return DepositosChequesState(
      empresas: empresas ?? this.empresas,
      empresaSeleccionada:
          clearEmpresa
              ? null
              : (empresaSeleccionada ?? this.empresaSeleccionada),
      clientes: clientes ?? this.clientes,
      clienteSeleccionado:
          clearCliente
              ? null
              : (clienteSeleccionado ?? this.clienteSeleccionado),
      bancos: bancos ?? this.bancos,
      bancoSeleccionado:
          clearBanco ? null : (bancoSeleccionado ?? this.bancoSeleccionado),
      monedas: monedas ?? this.monedas,
      monedaSeleccionada: monedaSeleccionada ?? this.monedaSeleccionada,
      aCuenta: aCuenta ?? this.aCuenta,
      importeTotal: importeTotal ?? this.importeTotal,
      imagenDeposito:
          clearImagen ? null : (imagenDeposito ?? this.imagenDeposito),
      cargandoEmpresas: cargandoEmpresas ?? this.cargandoEmpresas,
      cargandoClientes: cargandoClientes ?? this.cargandoClientes,
      cargandoBancos: cargandoBancos ?? this.cargandoBancos,
      cargandoNotas: cargandoNotas ?? this.cargandoNotas,
      buscando: buscando ?? this.buscando,
      guardando: guardando ?? this.guardando,
      imagenesEnCurso: imagenesEnCurso ?? this.imagenesEnCurso,
      pdfsEnCurso: pdfsEnCurso ?? this.pdfsEnCurso,
      filasOcupadas: filasOcupadas ?? this.filasOcupadas,
      error: clearError ? null : (error ?? this.error),
      errorEn: clearError ? null : (errorEn ?? this.errorEn),
      notasRemision: notasRemision ?? this.notasRemision,
      notasSeleccionadas: notasSeleccionadas ?? this.notasSeleccionadas,
      saldosEditados: saldosEditados ?? this.saldosEditados,
      notasGuardadas: notasGuardadas ?? this.notasGuardadas,
      depositoRegistrado: depositoRegistrado ?? this.depositoRegistrado,
      depositos: depositos ?? this.depositos,
      selectedEstado: selectedEstado ?? this.selectedEstado,
      fechaDesde: clearFechaDesde ? null : (fechaDesde ?? this.fechaDesde),
      fechaHasta: clearFechaHasta ? null : (fechaHasta ?? this.fechaHasta),
      page: page ?? this.page,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      totalRegistros: totalRegistros ?? this.totalRegistros,
      obs: obs ?? this.obs,
    );
  }
}

/// Resultado de guardar las notas de remisión de un depósito.
class ResultadoNotas {
  const ResultadoNotas({
    this.guardadas = const [],
    this.fallidas = const [],
    this.error,
  });

  final List<int> guardadas;

  /// `docNum` que no se guardaron: los que fallaron y los que no llegaron a
  /// intentarse porque un lote anterior ya había fallado.
  final List<int> fallidas;

  /// Primer error, ya con texto para la persona (`textoParaUsuario`).
  final Object? error;

  bool get ok => fallidas.isEmpty;
}

/// Resultado de un guardado completo (depósito + notas).
class ResultadoGuardado {
  const ResultadoGuardado({
    this.depositoOk = false,
    this.notas = const ResultadoNotas(),
  }) : ignorado = false;

  /// Segundo toque mientras ya hay un guardado en curso: no se hizo nada.
  const ResultadoGuardado.ignorado()
    : depositoOk = false,
      notas = const ResultadoNotas(),
      ignorado = true;

  final bool depositoOk;
  final ResultadoNotas notas;
  final bool ignorado;

  bool get ok => !ignorado && depositoOk && notas.ok;
}

class DepositosChequesNotifier extends StateNotifier<DepositosChequesState> {
  /// Última respuesta cruda del backend al registrar depósito (para depuración)
  dynamic lastResponse;

  final DepositoChequesRepository _repo;
  final Ref ref;

  /// Sin red en el constructor: cada pantalla pide lo que necesita. Antes se
  /// pedían las empresas al crear el notifier, y como hay uno por pantalla (y
  /// uno más en el diálogo de asignar) el mismo listado se descargaba varias
  /// veces al abrir, incluso en pantallas que no lo usan.
  DepositosChequesNotifier(this.ref, {DepositoChequesRepository? repo})
    : _repo = repo ?? DepositoChequesImpl(),
      super(DepositosChequesState());

  // Cada elección invalida las respuestas en vuelo de la anterior: sin esto,
  // una respuesta lenta de la empresa A pisaba a la de la empresa B.
  int _genEmpresa = 0;
  int _genCliente = 0;
  int _genBusqueda = 0;

  /// La última carga fallida, lista para repetirse con los mismos argumentos.
  Future<void> Function()? _reintento;

  /// Hay un error de carga y se sabe cómo repetirlo.
  bool get puedeReintentar => state.error != null && _reintento != null;

  /// Repite la última carga que falló (empresas, bancos, clientes, notas o
  /// listado) sin que la pantalla tenga que adivinar cuál fue.
  Future<void> reintentarUltimaCarga() async {
    final reintento = _reintento;
    if (reintento != null) await reintento();
  }

  /// El error pertenece a algo que una nueva elección de empresa invalida.
  bool get _errorDeSeleccion => switch (state.errorEn) {
    OperacionCarga.bancos ||
    OperacionCarga.clientes ||
    OperacionCarga.notas => true,
    _ => false,
  };

  /// Al quitar las notas solo se descarta lo que ellas aportaban; si no había
  /// notas, el importe puede haberse tecleado (registro por identificar) y se
  /// conserva.
  double _importeTrasVaciarNotas() =>
      state.notasSeleccionadas.isEmpty ? state.importeTotal : state.aCuenta;

  /// Usuario leído al iniciar la operación: con `autoDispose` el `Ref` puede
  /// estar liberado cuando termina un `await` (la pantalla se cerró).
  ({int codUsuario, int codEmpleado}) _usuario() {
    final u = ref.read(userProvider);
    return (codUsuario: u?.codUsuario ?? 0, codEmpleado: u?.codEmpleado ?? 0);
  }

  /// Bancos ya pedidos, por empresa. Editar un depósito pedía los bancos en
  /// cada apertura del diálogo.
  final Map<int, List<BancoXCuentaEntity>> _bancosPorEmpresa = {};

  /// Notas guardadas a la vez. El pool de conexiones del backend es de 5, así
  /// que no conviene ocupar más de unas pocas.
  static const int _concurrenciaNotas = 3;

  // Permite acceso al repositorio para casos específicos.
  DepositoChequesRepository get repo => _repo;

  SocioNegocioEntity _clienteTodos(int codEmpresa) => SocioNegocioEntity(
    codCliente: '',
    datoCliente: '',
    razonSocial: 'Todos',
    nit: '',
    codCiudad: 0,
    datoCiudad: '',
    esVigente: '',
    codEmpresa: codEmpresa,
    audUsuario: 0,
    nombreCompleto: 'Todos',
  );

  // ── Empresas, clientes, bancos, notas ────────────────────────────────────

  /// Pide las empresas solo si aún no están cargadas ni en camino.
  Future<void> cargarEmpresasSiFalta() async {
    if (state.empresas.isNotEmpty || state.cargandoEmpresas) return;
    await cargarEmpresas();
  }

  Future<void> cargarEmpresas() async {
    state = state.copyWith(
      cargandoEmpresas: true,
      clearError: state.errorEn == OperacionCarga.empresas,
    );
    try {
      final empresasRaw = await _repo.getEmpresas();
      if (!mounted) return;
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
      final seleccionada = state.empresaSeleccionada;
      final sigueVigente =
          seleccionada != null &&
          empresas.any((e) => e.codEmpresa == seleccionada.codEmpresa);
      state = state.copyWith(
        empresas: empresas,
        cargandoEmpresas: false,
        clearEmpresa: !sigueVigente,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        cargandoEmpresas: false,
        error: e,
        errorEn: OperacionCarga.empresas,
      );
      _reintento = cargarEmpresas;
    }
  }

  /// Elige la empresa y carga sus bancos y, si [cargarClientes], sus clientes.
  /// Ambas cargas van en paralelo y cada una apaga su propia bandera: los
  /// bancos aparecen sin esperar la lista completa de clientes.
  ///
  /// La pantalla de depósitos por identificar no usa clientes: pasa
  /// `cargarClientes: false` y se ahorra descargar el maestro completo.
  Future<void> seleccionarEmpresa(
    EmpresaEntity? empresa, {
    bool cargarClientes = true,
  }) async {
    final gen = ++_genEmpresa;
    _genCliente++; // una carga de notas en vuelo ya no corresponde

    // "Todos": se limpian los filtros dependientes.
    if (empresa == null || empresa.codEmpresa == 0) {
      final todos = _clienteTodos(0);
      state = state.copyWith(
        empresaSeleccionada:
            state.empresas.isNotEmpty ? state.empresas.first : null,
        clearEmpresa: state.empresas.isEmpty,
        clienteSeleccionado: todos,
        clientes: [todos],
        clearBanco: true,
        bancos: [],
        notasRemision: [],
        notasSeleccionadas: [],
        saldosEditados: {},
        notasGuardadas: {},
        depositoRegistrado: false,
        importeTotal: _importeTrasVaciarNotas(),
        selectedEstado: 'Todos',
        cargandoClientes: false,
        cargandoBancos: false,
        cargandoNotas: false,
        clearError: _errorDeSeleccion,
      );
      return;
    }

    // Empresa concreta: lo que dependía de la anterior se descarta.
    state = state.copyWith(
      empresaSeleccionada: empresa,
      clearCliente: true,
      clearBanco: true,
      clientes: [],
      bancos: [],
      notasRemision: [],
      notasSeleccionadas: [],
      saldosEditados: {},
      notasGuardadas: {},
      depositoRegistrado: false,
      importeTotal: _importeTrasVaciarNotas(),
      selectedEstado: 'Todos',
      cargandoClientes: cargarClientes,
      cargandoBancos: true,
      cargandoNotas: false,
      clearError: _errorDeSeleccion,
    );

    bool vigente() => mounted && gen == _genEmpresa;

    Future<void> cargarBancos() async {
      try {
        final bancos = await bancosDeEmpresa(empresa.codEmpresa);
        if (!vigente()) return;
        state = state.copyWith(bancos: bancos, cargandoBancos: false);
      } catch (e) {
        if (!vigente()) return;
        state = state.copyWith(
          cargandoBancos: false,
          error: e,
          errorEn: OperacionCarga.bancos,
        );
        _reintento =
            () => seleccionarEmpresa(empresa, cargarClientes: cargarClientes);
      }
    }

    Future<void> cargarClientesDeEmpresa() async {
      if (!cargarClientes) return;
      try {
        final clientesRaw = await _repo.getSociosNegocio(empresa.codEmpresa);
        if (!vigente()) return;
        // Inyectar opción "Todos" al inicio y dejarla seleccionada
        final todos = _clienteTodos(empresa.codEmpresa);
        state = state.copyWith(
          clientes: [todos, ...clientesRaw],
          clienteSeleccionado: todos,
          cargandoClientes: false,
        );
      } catch (e) {
        if (!vigente()) return;
        state = state.copyWith(
          cargandoClientes: false,
          error: e,
          errorEn: OperacionCarga.clientes,
        );
        _reintento =
            () => seleccionarEmpresa(empresa, cargarClientes: cargarClientes);
      }
    }

    await Future.wait([cargarBancos(), cargarClientesDeEmpresa()]);
  }

  /// Bancos de una empresa, con caché por empresa. Lanza
  /// [DepositoChequesException] si falla (no devuelve `[]` disfrazado).
  Future<List<BancoXCuentaEntity>> bancosDeEmpresa(int codEmpresa) async {
    final enCache = _bancosPorEmpresa[codEmpresa];
    if (enCache != null) return enCache;
    final bancos = await _repo.getBancos(codEmpresa);
    _bancosPorEmpresa[codEmpresa] = bancos;
    return bancos;
  }

  /// Elige el cliente. Con [cargarNotas] (el registro) pide sus notas de
  /// remisión; la pantalla de consulta solo lo usa como filtro y pasa `false`.
  /// Cambiar de cliente descarta las notas y saldos del anterior.
  Future<void> seleccionarCliente(
    SocioNegocioEntity? cliente, {
    bool cargarNotas = true,
  }) async {
    final gen = ++_genCliente;

    // Si cliente es null ("Todos"), se limpia la selección.
    if (cliente == null || cliente.codCliente == '') {
      state = state.copyWith(
        clienteSeleccionado:
            state.clientes.isNotEmpty ? state.clientes.first : null,
        clearCliente: state.clientes.isEmpty,
        notasRemision: [],
        notasSeleccionadas: [],
        saldosEditados: {},
        notasGuardadas: {},
        depositoRegistrado: false,
        importeTotal: _importeTrasVaciarNotas(),
        cargandoNotas: false,
      );
      return;
    }
    final empresa = state.empresaSeleccionada;
    if (empresa == null) return;

    state = state.copyWith(
      clienteSeleccionado: cliente,
      notasRemision: [],
      notasSeleccionadas: [],
      saldosEditados: {},
      notasGuardadas: {},
      depositoRegistrado: false,
      importeTotal: _importeTrasVaciarNotas(),
      cargandoNotas: cargarNotas,
      clearError: state.errorEn == OperacionCarga.notas,
    );
    if (!cargarNotas) return;

    try {
      final notas = await _repo.getNotasRemision(
        empresa.codEmpresa,
        cliente.codCliente,
      );
      if (!mounted || gen != _genCliente) return;
      state = state.copyWith(notasRemision: notas, cargandoNotas: false);
    } catch (e) {
      if (!mounted || gen != _genCliente) return;
      state = state.copyWith(
        cargandoNotas: false,
        error: e,
        errorEn: OperacionCarga.notas,
      );
      _reintento = () => seleccionarCliente(cliente);
    }
  }

  void seleccionarBanco(BancoXCuentaEntity? banco) {
    // Si banco es null (Todos), limpiar selección
    state = state.copyWith(bancoSeleccionado: banco, clearBanco: banco == null);
  }

  void seleccionarMoneda(String? moneda) {
    if (moneda != null) {
      state = state.copyWith(monedaSeleccionada: moneda);
    }
  }

  void seleccionarNota(int docNum, bool selected) {
    // Nueva lista para no mutar la del estado.
    final nuevasSeleccionadas = List<int>.from(state.notasSeleccionadas);
    if (selected) {
      if (!nuevasSeleccionadas.contains(docNum)) {
        nuevasSeleccionadas.add(docNum);
      }
    } else {
      nuevasSeleccionadas.remove(docNum);
    }

    state = state.copyWith(
      notasSeleccionadas: nuevasSeleccionadas,
      importeTotal: _calcularImporteTotal(
        nuevasSeleccionadas,
        state.saldosEditados,
        state.notasRemision,
        state.aCuenta,
      ),
    );
  }

  void editarSaldoPendiente(int docNum, double nuevoSaldo) {
    final nuevosSaldos = Map<int, double>.from(state.saldosEditados);
    nuevosSaldos[docNum] = nuevoSaldo;
    state = state.copyWith(
      saldosEditados: nuevosSaldos,
      importeTotal: _calcularImporteTotal(
        state.notasSeleccionadas,
        nuevosSaldos,
        state.notasRemision,
        state.aCuenta,
      ),
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
    final marcadas = seleccionadas.toSet();
    double totalSeleccionados = 0;
    for (final nota in notas) {
      if (marcadas.contains(nota.docNum)) {
        totalSeleccionados +=
            saldosEditados[nota.docNum]?.toDouble() ??
            nota.saldoPendiente.toDouble();
      }
    }
    return totalSeleccionados + aCuenta;
  }

  void limpiarFormulario() {
    _genEmpresa++;
    _genCliente++;
    _reintento = null;
    state = DepositosChequesState(empresas: state.empresas);
  }

  // ── Registro y asignación ────────────────────────────────────────────────

  /// Registra (o actualiza, con [idDepositoActualizacion]) un depósito.
  /// Lanza [DepositoChequesException] con el motivo real si falla.
  Future<bool> registrarDeposito(
    dynamic imagen, {
    int? idDepositoActualizacion,
  }) async {
    final usuario = _usuario();
    final snap = state;
    state = state.copyWith(guardando: true);
    try {
      return await _registrarDepositoInterno(
        snap,
        imagen,
        usuario: usuario,
        idDepositoActualizacion: idDepositoActualizacion,
      );
    } finally {
      if (mounted) state = state.copyWith(guardando: false);
    }
  }

  Future<bool> _registrarDepositoInterno(
    DepositosChequesState snap,
    dynamic imagen, {
    required ({int codUsuario, int codEmpleado}) usuario,
    int? idDepositoActualizacion,
  }) async {
    lastResponse = null;
    try {
      // Usar el ID pasado como parámetro para actualizaciones, 0 para nuevos registros
      final idDeposito = idDepositoActualizacion ?? 0;

      final codUsuario = usuario.codUsuario;
      final codEmpleado = usuario.codEmpleado;

      final deposito = DepositoChequeEntity(
        idDeposito: idDeposito,
        codCliente: snap.clienteSeleccionado?.codCliente ?? '',
        codEmpresa: snap.empresaSeleccionada?.codEmpresa ?? 0,
        idBxC: snap.bancoSeleccionado?.idBxC ?? 0,
        importe: snap.importeTotal,
        moneda: snap.monedaSeleccionada,
        estado: 1,
        fotoPath: '',
        aCuenta: snap.aCuenta,
        fechaI: null, // Enviar como null
        nroTransaccion: '',
        obs: snap.obs, // Usar las observaciones guardadas en el estado
        codEmpleado: codEmpleado,
        audUsuario: codUsuario,
        codBanco: snap.bancoSeleccionado?.codBanco ?? 0,
        fechaInicio: DateTime.now(),
        fechaFin: DateTime.now(),
        nombreBanco: snap.bancoSeleccionado?.nombreBanco ?? '',
        nombreEmpresa: snap.empresaSeleccionada?.nombre ?? '',
        nombreVendedor: '',
        esPendiente: '',
        numeroDeDocumentos: snap.notasSeleccionadas.length.toString(),
        fechasDeDepositos: '',
        numeroDeFacturas: '',
        totalMontos: '',
        estadoFiltro: '',
        nombreCompleto: '',
      );

      return await _repo.registrarDeposito(deposito, imagen);
    } catch (e) {
      lastResponse = e.toString();
      rethrow;
    }
  }

  /// Sincroniza el cliente seleccionado sin recargar notas.
  /// Útil para mantener las selecciones hechas en el modal
  void sincronizarClienteSeleccionado(SocioNegocioEntity? cliente) {
    state = state.copyWith(
      clienteSeleccionado: cliente,
      clearCliente: cliente == null,
    );
  }

  /// Sincroniza la empresa seleccionada sin recargar clientes/bancos
  /// Útil para mantener las selecciones hechas en el modal
  void sincronizarEmpresaSeleccionada(EmpresaEntity? empresa) {
    state = state.copyWith(
      empresaSeleccionada: empresa,
      clearEmpresa: empresa == null,
    );
  }

  /// Sincroniza el banco seleccionado
  void sincronizarBancoSeleccionado(BancoXCuentaEntity? banco) {
    state = state.copyWith(bancoSeleccionado: banco, clearBanco: banco == null);
  }

  /// Guarda las notas seleccionadas. Público para quien solo necesite eso;
  /// los flujos completos usan [guardarDepositoConNotas] o [asignarDeposito].
  Future<ResultadoNotas> guardarNotasRemision({
    int? idDepositoParaNotas,
  }) async {
    final codUsuario = _usuario().codUsuario;
    final snap = state;
    state = state.copyWith(guardando: true);
    try {
      return await _guardarNotasInterno(snap, idDepositoParaNotas, codUsuario);
    } finally {
      if (mounted) state = state.copyWith(guardando: false);
    }
  }

  /// Guarda las notas pendientes en lotes de [_concurrenciaNotas] en paralelo.
  /// Trabaja sobre la foto [snap] del estado al iniciar: si la pantalla se cierra
  /// a mitad (el notifier se descarta), leer `state` lanzaría y el guardado
  /// quedaría a medias.
  ///
  /// - Salta las que ya se guardaron en un intento anterior ([notasGuardadas]).
  /// - Al primer fallo no lanza más lotes; lo no guardado vuelve en `fallidas`.
  /// - No lanza: el resultado dice qué quedó pendiente.
  Future<ResultadoNotas> _guardarNotasInterno(
    DepositosChequesState snap,
    int? idDepositoParaNotas,
    int codUsuario,
  ) async {
    final pendientes =
        snap.notasSeleccionadas
            .where((d) => !snap.notasGuardadas.contains(d))
            .toList();
    if (pendientes.isEmpty) return const ResultadoNotas();

    final guardadas = <int>[];
    final fallidas = <int>[];
    Object? primerError;

    var siguiente = 0;
    while (siguiente < pendientes.length && primerError == null) {
      final lote = pendientes.skip(siguiente).take(_concurrenciaNotas).toList();
      siguiente += lote.length;
      final resultados = await Future.wait(
        lote.map(
          (d) => _guardarUnaNota(snap, d, idDepositoParaNotas, codUsuario),
        ),
      );
      for (var i = 0; i < lote.length; i++) {
        final error = resultados[i];
        if (error == null) {
          guardadas.add(lote[i]);
        } else {
          fallidas.add(lote[i]);
          primerError ??= error;
        }
      }
    }
    fallidas.addAll(pendientes.skip(siguiente));

    if (mounted && guardadas.isNotEmpty) {
      state = state.copyWith(
        notasGuardadas: {...state.notasGuardadas, ...guardadas},
      );
    }
    return ResultadoNotas(
      guardadas: guardadas,
      fallidas: fallidas,
      error: primerError,
    );
  }

  /// `null` si se guardó; si no, el error.
  Future<Object?> _guardarUnaNota(
    DepositosChequesState snap,
    int docNum,
    int? idDepositoParaNotas,
    int codUsuario,
  ) async {
    try {
      final nota = snap.notasRemision.firstWhere(
        (n) => n.docNum == docNum,
        orElse: () => throw DepositoChequesException('Nota no encontrada: $docNum'),
      );
      final notaEditada = NotaRemisionEntity(
        idNr: nota.idNr,
        idDeposito: idDepositoParaNotas ?? nota.idDeposito,
        docNum: nota.docNum,
        fecha: nota.fecha,
        numFact: nota.numFact,
        totalMonto: nota.totalMonto,
        saldoPendiente: snap.saldosEditados[docNum] ?? nota.saldoPendiente,
        audUsuario: codUsuario,
        codCliente: nota.codCliente,
        nombreCliente: nota.nombreCliente,
        db: nota.db,
        codEmpresaBosque: nota.codEmpresaBosque,
      );
      final ok = await _repo.guardarNotaRemision(notaEditada);
      return ok
          ? null
          : DepositoChequesException('No se pudo guardar la nota $docNum.');
    } catch (e) {
      return e;
    }
  }

  /// Registro nuevo: crea el depósito y luego sus notas.
  ///
  /// Si el depósito se creó y alguna nota falló, `depositoRegistrado` queda en
  /// `true`: el siguiente llamado reintenta solo las notas pendientes en vez de
  /// crear un segundo depósito.
  ///
  /// Un segundo toque mientras hay un guardado en curso devuelve
  /// [ResultadoGuardado.ignorado]. Si crear el depósito falla, lanza
  /// [DepositoChequesException] con el motivo real.
  Future<ResultadoGuardado> guardarDepositoConNotas(dynamic imagen) async {
    if (state.guardando) return const ResultadoGuardado.ignorado();
    final usuario = _usuario();
    final snap = state;
    state = state.copyWith(guardando: true);
    try {
      if (!snap.depositoRegistrado) {
        final ok = await _registrarDepositoInterno(
          snap,
          imagen,
          usuario: usuario,
        );
        if (!ok) return const ResultadoGuardado();
        // Si la pantalla se cerró, se siguen guardando las notas igual: el
        // depósito ya existe y no debe quedar sin ellas.
        if (mounted) state = state.copyWith(depositoRegistrado: true);
      }
      final notas = await _guardarNotasInterno(
        snap,
        null,
        usuario.codUsuario,
      );
      if (mounted && notas.ok) {
        state = state.copyWith(depositoRegistrado: false, notasGuardadas: {});
      }
      return ResultadoGuardado(depositoOk: true, notas: notas);
    } finally {
      if (mounted) state = state.copyWith(guardando: false);
    }
  }

  /// Asignación de un depósito existente (por identificar): primero las notas,
  /// ya con su `idDeposito`, y solo si todas se guardaron actualiza el depósito.
  /// Si algo falla, el reintento envía únicamente lo pendiente.
  Future<ResultadoGuardado> asignarDeposito({
    required int idDeposito,
    dynamic imagen,
  }) async {
    if (state.guardando) return const ResultadoGuardado.ignorado();
    final usuario = _usuario();
    final snap = state;
    state = state.copyWith(guardando: true);
    try {
      final notas = await _guardarNotasInterno(
        snap,
        idDeposito > 0 ? idDeposito : null,
        usuario.codUsuario,
      );
      if (!notas.ok) return ResultadoGuardado(notas: notas);

      final ok = await _registrarDepositoInterno(
        snap,
        imagen,
        usuario: usuario,
        idDepositoActualizacion: idDeposito > 0 ? idDeposito : null,
      );
      if (mounted && ok) state = state.copyWith(notasGuardadas: {});
      return ResultadoGuardado(depositoOk: ok, notas: notas);
    } finally {
      if (mounted) state = state.copyWith(guardando: false);
    }
  }

  // ── Listados ─────────────────────────────────────────────────────────────

  void setEstado(String? estado) {
    // Si estado es null o 'Todos', limpiar selección
    state = state.copyWith(selectedEstado: estado ?? 'Todos');
  }

  void setFechaDesde(DateTime? fecha) {
    state = state.copyWith(fechaDesde: fecha, clearFechaDesde: fecha == null);
  }

  void setFechaHasta(DateTime? fecha) {
    state = state.copyWith(fechaHasta: fecha, clearFechaHasta: fecha == null);
  }

  /// Rango inicial de la consulta: los últimos [dias] días. Sin fechas, el
  /// servidor devuelve todo el historial y lo pagina el cliente. Solo aplica si
  /// la persona no eligió fechas.
  void aplicarRangoPorDefecto({int dias = 30}) {
    if (state.fechaDesde != null || state.fechaHasta != null) return;
    final ahora = DateTime.now();
    // Aritmética de calendario: restar una `Duration` de horas corre la fecha
    // en los cambios de horario de verano.
    state = state.copyWith(
      fechaDesde: DateTime(ahora.year, ahora.month, ahora.day - dias),
      fechaHasta: DateTime(ahora.year, ahora.month, ahora.day),
    );
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
    final gen = ++_genBusqueda;
    state = state.copyWith(
      buscando: true,
      clearError: state.errorEn == OperacionCarga.listado,
    );
    try {
      final estadoFiltro =
          state.selectedEstado == 'Todos' ? '' : state.selectedEstado;
      final depositos = await _repo.obtenerDepositos(
        state.empresaSeleccionada?.codEmpresa ?? 0,
        state.bancoSeleccionado?.idBxC ?? 0,
        state.fechaDesde,
        state.fechaHasta,
        state.clienteSeleccionado?.codCliente ?? '',
        estadoFiltro ?? '',
      );
      if (!mounted || gen != _genBusqueda) return;
      state = state.copyWith(
        depositos: depositos,
        totalRegistros: depositos.length,
        page: 0,
        buscando: false,
      );
    } catch (e) {
      if (!mounted || gen != _genBusqueda) return;
      state = state.copyWith(
        buscando: false,
        error: e,
        errorEn: OperacionCarga.listado,
      );
      _reintento = buscarDepositos;
    }
  }

  /// Busca depósitos pendientes por identificar.
  Future<void> buscarDepositosPorIdentificar({
    required int idBxC,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? codCliente,
  }) async {
    final gen = ++_genBusqueda;
    state = state.copyWith(
      buscando: true,
      clearError: state.errorEn == OperacionCarga.listado,
    );
    try {
      final depositos = await _repo.lstDepositxIdentificar(
        idBxC,
        fechaDesde,
        fechaHasta,
        codCliente ?? '',
      );
      if (!mounted || gen != _genBusqueda) return;
      state = state.copyWith(
        depositos: depositos,
        totalRegistros: depositos.length,
        buscando: false,
        page: 0,
      );
    } catch (e) {
      if (!mounted || gen != _genBusqueda) return;
      state = state.copyWith(
        buscando: false,
        error: e,
        errorEn: OperacionCarga.listado,
      );
      _reintento =
          () => buscarDepositosPorIdentificar(
            idBxC: idBxC,
            fechaDesde: fechaDesde,
            fechaHasta: fechaHasta,
            codCliente: codCliente,
          );
    }
  }

  /// Saca un depósito de la lista en memoria (p. ej. uno ya identificado), sin
  /// volver a pedir el listado completo.
  void quitarDeposito(int idDeposito) {
    final restantes =
        state.depositos.where((d) => d.idDeposito != idDeposito).toList();
    final ultimaPagina =
        restantes.isEmpty ? 0 : (restantes.length - 1) ~/ state.rowsPerPage;
    state = state.copyWith(
      depositos: restantes,
      totalRegistros: restantes.length,
      page: state.page > ultimaPagina ? ultimaPagina : state.page,
    );
  }

  // ── Acciones sobre una fila ──────────────────────────────────────────────

  Set<int> _con(Set<int> conjunto, int id) => {...conjunto, id};
  Set<int> _sin(Set<int> conjunto, int id) => Set<int>.of(conjunto)..remove(id);

  /// Cambia banco y nro. de transacción de un depósito. Devuelve si se aplicó.
  Future<bool> actualizarDepositoTransaccionYBanco({
    required DepositoChequeEntity deposito,
    required String nuevoNroTransaccion,
    required BancoXCuentaEntity nuevoBanco,
    required BuildContext context,
  }) async {
    final id = deposito.idDeposito;
    if (state.filasOcupadas.contains(id)) return false;
    state = state.copyWith(filasOcupadas: _con(state.filasOcupadas, id));
    try {
      final actualizado = deposito.copyWith(
        idBxC: nuevoBanco.idBxC,
        nroTransaccion: nuevoNroTransaccion,
        codBanco: nuevoBanco.codBanco,
        nombreBanco: nuevoBanco.nombreBanco,
      );
      final ok = await _repo.actualizarNroTransaccion(actualizado);
      if (!mounted) return ok;
      if (ok) {
        state = state.copyWith(
          depositos:
              state.depositos
                  .map((d) => d.idDeposito == id ? actualizado : d)
                  .toList(),
        );
        mostrarAviso(context, 'Depósito actualizado correctamente.');
      } else {
        mostrarAviso(
          context,
          'No se pudo actualizar el depósito.',
          tono: TonoAviso.error,
        );
      }
      return ok;
    } catch (e) {
      mostrarAviso(
        context,
        'Error al actualizar el depósito: ${textoParaUsuario(e)}',
        tono: TonoAviso.error,
      );
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(filasOcupadas: _sin(state.filasOcupadas, id));
      }
    }
  }

  /// Rechaza un depósito y refleja el cambio en la fila.
  Future<bool> rechazarDepositoCheque({
    required DepositoChequeEntity deposito,
    required BuildContext context,
  }) async {
    final id = deposito.idDeposito;
    if (state.filasOcupadas.contains(id)) return false;
    state = state.copyWith(filasOcupadas: _con(state.filasOcupadas, id));
    try {
      // estado: 1 Pendiente, 2 Verificado, 3 Rechazado. La UI lee `esPendiente`
      // (texto que arma el SP del listado) para pintar la fila y sus acciones.
      final rechazado = deposito.copyWith(estado: 3, esPendiente: 'Rechazado');
      final ok = await _repo.rechazarNotaRemision(rechazado);
      if (!mounted) return ok;
      if (ok) {
        state = state.copyWith(
          depositos:
              state.depositos
                  .map((d) => d.idDeposito == id ? rechazado : d)
                  .toList(),
        );
        mostrarAviso(context, 'Depósito rechazado correctamente.');
      } else {
        mostrarAviso(
          context,
          'No se pudo rechazar el depósito.',
          tono: TonoAviso.error,
        );
      }
      return ok;
    } catch (e) {
      mostrarAviso(
        context,
        'Error al rechazar el depósito: ${textoParaUsuario(e)}',
        tono: TonoAviso.error,
      );
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(filasOcupadas: _sin(state.filasOcupadas, id));
      }
    }
  }

  // ── Imagen y PDF (por fila) ──────────────────────────────────────────────

  Future<void> descargarImagenDeposito(
    int idDeposito,
    BuildContext context,
  ) async {
    if (state.imagenesEnCurso.contains(idDeposito)) return;
    state = state.copyWith(
      imagenesEnCurso: _con(state.imagenesEnCurso, idDeposito),
    );
    try {
      final imageBytes = await _repo.obtenerImagenDeposito(idDeposito);
      if (!context.mounted) return;
      await manejarArchivoImagen(
        imageBytes,
        'deposito_$idDeposito.jpg',
        context,
      );
    } catch (e) {
      mostrarAviso(
        context,
        'Error al descargar la imagen: ${textoParaUsuario(e)}',
        tono: TonoAviso.error,
      );
    } finally {
      if (mounted) {
        state = state.copyWith(
          imagenesEnCurso: _sin(state.imagenesEnCurso, idDeposito),
        );
      }
    }
  }

  Future<void> manejarArchivoImagen(
    Uint8List bytes,
    String fileName,
    BuildContext context,
  ) async {
    if (kIsWeb) {
      // En web, abrir la imagen en una nueva pestaña
      final blob = html.Blob([bytes], 'image/jpeg');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.window.open(url, '_blank');

      // Revocar la URL después de un tiempo para liberar memoria
      Future.delayed(
        const Duration(minutes: 1),
        () => html.Url.revokeObjectUrl(url),
      );
    } else {
      if (!context.mounted) return;
      // En móvil, mostrar la imagen y permitir guardarla. `cacheHeight`:
      // se ve a 200 px, no hace falta decodificar la foto completa.
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Imagen descargada'),
            content: Image.memory(
              bytes,
              fit: BoxFit.contain,
              height: 200,
              cacheHeight: 400,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _guardarImagenEnDispositivo(bytes, fileName);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _guardarImagenEnDispositivo(
    Uint8List bytes,
    String fileName,
  ) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Usar path_provider para obtener directorio temporal
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Pendiente: compartir con share_plus (Share.shareFiles); por ahora solo se
      // registra la ruta.
      console('Imagen guardada en: ${file.path}');
    }
  }

  Future<void> descargarPdfDeposito(
    int idDeposito,
    BuildContext context,
  ) async {
    if (state.pdfsEnCurso.contains(idDeposito)) return;
    state = state.copyWith(pdfsEnCurso: _con(state.pdfsEnCurso, idDeposito));
    try {
      final deposito = state.depositos.firstWhere(
        (d) => d.idDeposito == idDeposito,
        orElse: () => throw const DepositoChequesException(
          'Depósito no encontrado.',
        ),
      );

      final pdfBytes = await _repo.obtenerPdfDeposito(idDeposito, deposito);
      if (!context.mounted) return;

      // Verificar que los bytes parecen ser un PDF (comienzan con %PDF)
      if (pdfBytes.length > 4 &&
          String.fromCharCodes(pdfBytes.sublist(0, 4)) == '%PDF') {
        procesarPdfDescargado(pdfBytes, context, idDeposito);
        // En móvil se abre la vista previa; el aviso solo tiene sentido en web.
        if (kIsWeb) mostrarAviso(context, 'PDF descargado.');
      } else {
        throw const DepositoChequesException(
          'Los datos recibidos no parecen ser un PDF válido.',
        );
      }
    } catch (e) {
      mostrarAviso(
        context,
        'Error al descargar el PDF: ${textoParaUsuario(e)}',
        tono: TonoAviso.error,
      );
    } finally {
      if (mounted) {
        state = state.copyWith(pdfsEnCurso: _sin(state.pdfsEnCurso, idDeposito));
      }
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
      unawaited(
        Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'Depósito $idDeposito',
        ),
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

  // ── Limpieza ─────────────────────────────────────────────────────────────

  /// Estado inicial conservando las empresas ya descargadas.
  void clearState() {
    _genEmpresa++;
    _genCliente++;
    _genBusqueda++;
    _reintento = null;
    state = DepositosChequesState(empresas: state.empresas);
  }

  // Limpia solo los resultados de búsqueda de depósitos
  void clearDepositosResults() {
    _genBusqueda++;
    state = state.copyWith(
      depositos: [],
      totalRegistros: 0,
      page: 0,
      selectedEstado: 'Todos',
      buscando: false,
      clearFechaDesde: true,
      clearFechaHasta: true,
      clearError: state.errorEn == OperacionCarga.listado,
    );
  }

  // Limpia el estado de registro de depósitos
  void clearRegistroDepositos() {
    _genCliente++;
    state = state.copyWith(
      clearCliente: true,
      notasSeleccionadas: [],
      saldosEditados: {},
      notasGuardadas: {},
      depositoRegistrado: false,
      aCuenta: 0.0,
      importeTotal: 0.0,
      obs: '',
    );
  }

  // Permite fijar la imagen desde la UI (null la quita)
  void setImagenDeposito(File? imagen) {
    state = state.copyWith(imagenDeposito: imagen, clearImagen: imagen == null);
  }
}

/// Un notifier por pantalla, y se descarta al salir: el estado anterior (lista,
/// selección, foto a medias) ya no sobrevive entre visitas ni entre usuarios.
final depositosChequesProvider = StateNotifierProvider.autoDispose<
  DepositosChequesNotifier,
  DepositosChequesState
>((ref) => DepositosChequesNotifier(ref));
