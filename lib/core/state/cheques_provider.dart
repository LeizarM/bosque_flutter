import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/cheques_impl.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/catalogos_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_pagina_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_resumen_entity.dart';
import 'package:bosque_flutter/domain/entities/custodia_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/dar_custodia_request_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/hora_traspaso_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:bosque_flutter/domain/repositories/cheques_repository.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/domain/utils/rango_recepcion_cheques.dart';

/// Repositorio del modulo de cheques (tch, vista 42).
///
/// Se registra aqui, perezoso, y tipado contra la interfaz: `main.dart` no lo
/// conoce y una prueba puede sustituirlo con
/// `chequesRepositoryProvider.overrideWithValue(falso)`.
final chequesRepositoryProvider = Provider<ChequesRepository>(
  (ref) => ChequesImpl(),
);

// ═══════════════════════════════════════════════════════════════════════════
// MENSAJES DE ERROR
// ═══════════════════════════════════════════════════════════════════════════

final _prefijoException = RegExp(r'^\s*(Exception:\s*)+');

/// El texto de un error para mostrarlo **tal cual**.
///
/// No pasa por `humanizar` (`core/ui/mensajes_usuario.dart`): ese esta
/// escrito para los mensajes de los procedimientos de otros modulos y toma por
/// fallo tecnico frases como «es obligatorio», que aqui son reglas de negocio
/// que el servidor ya redacto para el usuario («El Nro de cheque es
/// obligatorio»). Un 400 con varios errores los trae separados por salto de
/// linea y asi deben llegar.
///
/// Solo se quita el prefijo `Exception: ` que pone `BaseApiRepository` y se
/// traduce un error de red (sin respuesta del backend) a su aviso.
String mensajeDeErrorCheque(Object error) {
  const respaldo = 'No se pudo completar la operación.';
  if (error is DioException) return DioClient.handleDioError(error, respaldo);
  final t = error.toString().replaceFirst(_prefijoException, '').trim();
  return t.isEmpty ? respaldo : t;
}

/// El reloj del modulo. La grilla lo lee para armar el rango de recepcion por
/// defecto («hoy» menos tres meses); una prueba lo fija con
/// `relojChequesProvider.overrideWithValue(() => DateTime(2026, 10, 3))`.
final relojChequesProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

// ═══════════════════════════════════════════════════════════════════════════
// PERMISOS
// ═══════════════════════════════════════════════════════════════════════════

/// Lo que el usuario puede ver y habilitar en el modulo. Sale de dos fuentes:
/// los botones de `buttonPermissionsProvider` y el `tipoUsuario` de
/// `userProvider` (`ROLE_ADM` = administrador). Mientras llegan los permisos o
/// sin sesion no hay ningun boton; el administrador pasa desde el primer
/// instante, como en `tienePermisoDeBoton`.
final permisosChequeProvider = Provider<PermisosCheque>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return PermisosCheque.ninguno;
  final botones =
      ref.watch(buttonPermissionsProvider).valueOrNull ??
      const <UsuarioBtnEntity>[];
  return PermisosCheque.desde(tipoUsuario: user.tipoUsuario, botones: botones);
});

// ═══════════════════════════════════════════════════════════════════════════
// LECTURAS DE APOYO
// ═══════════════════════════════════════════════════════════════════════════

/// Tipos, monedas, estados y combos por boton. Se pide **una vez** por sesion:
/// no es autoDispose. Si falla, `ref.invalidate` lo vuelve a pedir.
final catalogosChequeProvider = FutureProvider<CatalogosChequeEntity>((ref) {
  return ref.watch(chequesRepositoryProvider).obtenerCatalogos();
});

/// Las empresas del combo «Empresa» de la pantalla (hoy IMPEXPAP y ESPPAPEL).
/// Se piden **una vez** por sesion: no es autoDispose. Si falla,
/// `ref.invalidate` lo vuelve a pedir.
///
/// De la empresa elegida salen las sucursales, los clientes y la empresa del
/// cheque que se registra. **Nunca** la de la sesion de login: un usuario puede
/// entrar con una empresa en la que no hay cheques (la 6, GENERAL).
final empresasChequeProvider = FutureProvider<List<EmpresaChequeEntity>>((ref) {
  return ref.watch(chequesRepositoryProvider).listarEmpresas();
});

/// La empresa en uso: la [elegida] si esta en la lista y, si no (sin eleccion
/// todavia, codEmpresa 0), la **primera**: el legacy arranca en `codEmpresa = 1`.
/// Null mientras no hay lista o esta vacia.
EmpresaChequeEntity? resolverEmpresaCheque(
  List<EmpresaChequeEntity>? empresas,
  int elegida,
) {
  if (empresas == null || empresas.isEmpty) return null;
  if (elegida > 0) {
    for (final e in empresas) {
      if (e.codEmpresa == elegida) return e;
    }
  }
  return empresas.first;
}

/// Sucursales de una empresa (clave: codEmpresa, siempre una real): las
/// parametrizadas de esa empresa y permitidas al usuario. Cambian poco: se piden
/// una vez por empresa.
///
/// **Dependen del usuario** (`p_list_Sucursal` `C` deja a algunos con una sola
/// sucursal), asi que si cambia la sesion se vuelven a pedir: sin esto, quien
/// inicia sesion despues veria la lista de quien salio.
final sucursalesChequeProvider =
    FutureProvider.family<List<SucursalChequeEntity>, int>((ref, codEmpresa) {
      ref.watch(userProvider.select((u) => u?.codUsuario));
      return ref
          .watch(chequesRepositoryProvider)
          .listarSucursales(codEmpresa: codEmpresa);
    });

/// Clientes de una empresa (clave: codEmpresa, siempre una real) para el combo
/// del formulario. Es una lista larga: se pide una vez por empresa y la
/// pantalla filtra en memoria. Es la misma entidad que usa Depositos.
final clientesChequeProvider =
    FutureProvider.family<List<SocioNegocioEntity>, int>((ref, codEmpresa) {
      return ref
          .watch(chequesRepositoryProvider)
          .listarClientes(codEmpresa: codEmpresa);
    });

/// «Entregado por» de una sucursal: jefe de cobranzas, cobradores y choferes.
final personalEntreganProvider = FutureProvider.autoDispose
    .family<List<PersonalChequeEntity>, int>((ref, codSucursal) {
      return ref
          .watch(chequesRepositoryProvider)
          .listarQuienesEntregan(codSucursal);
    });

/// Responsables de custodia de una sucursal: jefe de cobranzas y cobradores.
final personalCustodiaProvider = FutureProvider.autoDispose
    .family<List<PersonalChequeEntity>, int>((ref, codSucursal) {
      return ref
          .watch(chequesRepositoryProvider)
          .listarResponsablesDeCustodia(codSucursal);
    });

// ═══════════════════════════════════════════════════════════════════════════
// DETALLE, TRASPASO Y CUSTODIA (lecturas)
// ═══════════════════════════════════════════════════════════════════════════

/// «Completar»: el cheque, su historial y las cuatro acciones habilitadas. Se
/// relee despues de cada escritura para que los botones de la rama K no queden
/// viejos.
final detalleChequeProvider = FutureProvider.autoDispose
    .family<ChequeDetalleEntity?, BigInt>((ref, codCheque) {
      return ref.watch(chequesRepositoryProvider).obtenerDetalle(codCheque);
    });

/// Si el cheque tiene PDF cargado, su tamano y la fecha. Lo leen el dialogo del
/// documento y el panel del detalle: los dos se refrescan juntos con un
/// `ref.invalidate` despues de cargar un PDF. Es autoDispose: se vuelve a pedir
/// cada vez que se abre, porque otro usuario pudo cargar o reemplazar el archivo.
final estadoPdfChequeProvider = FutureProvider.autoDispose
    .family<PdfChequeEstadoEntity, BigInt>((ref, codCheque) {
      return ref.watch(chequesRepositoryProvider).estadoPdf(codCheque);
    });

/// Las notas de remision de un cheque. Se relee despues de registrar o eliminar
/// una (`operacionesPanelesChequeProvider`) y al pulsar «Actualizar» del detalle.
final notasRemisionChequeProvider = FutureProvider.autoDispose
    .family<List<NotaRemisionChequeEntity>, BigInt>((ref, codCheque) {
      return ref.watch(chequesRepositoryProvider).listarNotasRemision(codCheque);
    });

/// Las transacciones bancarias de un cheque.
final transaccionesChequeProvider = FutureProvider.autoDispose
    .family<List<TransaccionBancariaEntity>, BigInt>((ref, codCheque) {
      return ref.watch(chequesRepositoryProvider).listarTransacciones(codCheque);
    });

/// Las postergaciones de un cheque, con si cada una tiene PDF. Se relee tambien
/// al cargar un PDF, para que la linea de tiempo cambie de «Sin PDF» a «PDF
/// cargado».
final postergacionesChequeProvider = FutureProvider.autoDispose
    .family<List<PostergacionEntity>, BigInt>((ref, codCheque) {
      return ref
          .watch(chequesRepositoryProvider)
          .listarPostergaciones(codCheque);
    });

/// Si una postergacion tiene PDF, su tamano y la fecha (clave: codPostergacion).
/// Es autoDispose: se vuelve a pedir cada vez que se abre el dialogo, porque otro
/// usuario pudo cargar o reemplazar el archivo.
final estadoPdfPostergacionProvider = FutureProvider.autoDispose
    .family<PdfChequeEstadoEntity, BigInt>((ref, codPostergacion) {
      return ref
          .watch(chequesRepositoryProvider)
          .estadoPdfPostergacion(codPostergacion);
    });

/// Cuantos cheques de la sucursal esperan el traspaso.
final traspasosPendientesChequesProvider = FutureProvider.autoDispose
    .family<int, int>((ref, codSucursal) {
      return ref
          .watch(chequesRepositoryProvider)
          .contarTraspasosPendientes(codSucursal);
    });

/// Cheques de hoy listos para «A Custodio».
final chequesParaCustodiaProvider = FutureProvider.autoDispose
    .family<List<ChequeFilaEntity>, int>((ref, codSucursal) {
      return ref
          .watch(chequesRepositoryProvider)
          .listarChequesParaCustodia(codSucursal);
    });

/// Todos los cheques de la sucursal, para «Dar Custodia» (administrador).
final chequesParaDarCustodiaProvider = FutureProvider.autoDispose
    .family<List<ChequeResumenEntity>, int>((ref, codSucursal) {
      return ref
          .watch(chequesRepositoryProvider)
          .listarChequesParaDarCustodia(codSucursal);
    });

/// Clave de [entregasDelDiaChequeProvider]. [fecha] debe venir sin hora para
/// que dos consultas del mismo dia sean la misma clave.
typedef ConsultaEntregasCheque = ({int codSucursal, DateTime fecha});

/// Las entregas a cobranza de un dia, para elegir cual copiar en «Dar
/// Custodia».
final entregasDelDiaChequeProvider = FutureProvider.autoDispose
    .family<List<EntregaChequeEntity>, ConsultaEntregasCheque>((ref, c) {
      return ref
          .watch(chequesRepositoryProvider)
          .listarEntregasDelDia(codSucursal: c.codSucursal, fecha: c.fecha);
    });

/// Clave de [horasDeTraspasoChequeProvider]. [fecha] debe venir sin hora para
/// que dos consultas del mismo dia sean la misma clave.
typedef ConsultaHorasTraspasoCheque = ({int codSucursal, DateTime fecha});

/// Los traspasos a cobranza de un dia, para elegir cual reimprimir («Imp
/// Traspso», administrador). Es una lectura: no mueve nada y ninguna escritura
/// la invalida.
final horasDeTraspasoChequeProvider = FutureProvider.autoDispose
    .family<List<HoraTraspasoChequeEntity>, ConsultaHorasTraspasoCheque>((
      ref,
      c,
    ) {
      return ref
          .watch(chequesRepositoryProvider)
          .listarHorasDeTraspaso(codSucursal: c.codSucursal, fecha: c.fecha);
    });

// ═══════════════════════════════════════════════════════════════════════════
// GRILLA
// ═══════════════════════════════════════════════════════════════════════════

/// Estado de la grilla: empresa, sucursal, filtros, pagina y lo que devolvio el
/// servidor.
@immutable
class EstadoGrillaCheques {
  const EstadoGrillaCheques({
    this.codEmpresa = 0,
    this.filtro = const ChequeFiltroEntity(codSucursal: 0),
    this.resultado,
    this.cargando = false,
    this.error,
    this.iniciado = false,
  });

  /// La empresa con la que se trabaja (la del combo «Empresa»); 0 mientras no se
  /// resolvio. Esta aqui y no en un provider aparte para que empresa y
  /// sucursal cambien juntas y se liberen juntas al salir de la pantalla.
  /// Para leer la empresa en uso, `empresaChequeActivaProvider`.
  final int codEmpresa;

  /// Sucursal, criterios, orden y pagina que se consultan. Con sucursal 0 no
  /// hay consulta.
  final ChequeFiltroEntity filtro;

  /// La ultima pagina recibida. Null antes de la primera consulta, tras un
  /// error o al cambiar de sucursal; durante una recarga se conserva la
  /// anterior para que la tabla no parpadee.
  final ChequePaginaEntity? resultado;

  final bool cargando;

  /// El mensaje del backend de la ultima consulta fallida, listo para mostrar.
  final String? error;

  /// Ya se resolvio la sucursal inicial. Falso al abrir y tras un fallo de esa
  /// consulta, que se reintenta con `iniciar()`.
  final bool iniciado;

  int get codSucursal => filtro.codSucursal;

  /// Hay una sucursal elegida. Si `iniciado` y no hay, el usuario no tiene
  /// sucursal inicial y tiene que elegir una.
  bool get haySucursal => filtro.codSucursal > 0;

  int get pagina => filtro.pagina;
  List<ChequeFilaEntity> get filas => resultado?.filas ?? const [];
  int get total => resultado?.total ?? 0;
  int get totalPaginas => resultado?.totalPaginas ?? 0;
  bool get hayAnterior => filtro.pagina > 1;
  bool get haySiguiente => filtro.pagina < totalPaginas;

  /// Consulto bien y no hubo ninguna fila: estado vacio, no un error.
  bool get sinResultados =>
      haySucursal &&
      !cargando &&
      error == null &&
      resultado != null &&
      resultado!.filas.isEmpty;

  EstadoGrillaCheques copyWith({
    int? codEmpresa,
    ChequeFiltroEntity? filtro,
    ChequePaginaEntity? resultado,
    bool? cargando,
    String? error,
    bool? iniciado,
    bool limpiarResultado = false,
    bool limpiarError = false,
  }) => EstadoGrillaCheques(
    codEmpresa: codEmpresa ?? this.codEmpresa,
    filtro: filtro ?? this.filtro,
    resultado: limpiarResultado ? null : (resultado ?? this.resultado),
    cargando: cargando ?? this.cargando,
    error: limpiarError ? null : (error ?? this.error),
    iniciado: iniciado ?? this.iniciado,
  );
}

/// La grilla de cheques: empresa y sucursal elegidas, criterios de busqueda,
/// orden y pagina. Toda la paginacion y el filtrado son del servidor.
///
/// **Abre acotada a los cheques recibidos en los ultimos tres meses**
/// ([rangoRecepcionPorDefecto]): una sucursal tiene miles. Las fechas de
/// recepcion son parte de los criterios: cambiar de empresa o de sucursal las
/// conserva, quitarlas las dos pide todos los cheques y [limpiarCriterios]
/// vuelve al rango por defecto, no a «todo».
///
/// Vive en `core/state` pero es autoDispose: al salir de la pantalla se libera
/// y la proxima visita empieza limpia, con la primera empresa y la sucursal
/// inicial del usuario en ella.
///
/// Si dos consultas se cruzan (el usuario cambia de pagina o de filtro antes de
/// que llegue la primera), solo vale la ultima: la respuesta vieja se descarta
/// en vez de pisar a la nueva. Lo mismo vale para dos cambios de empresa
/// seguidos.
class GrillaChequesNotifier extends StateNotifier<EstadoGrillaCheques> {
  GrillaChequesNotifier(Ref ref)
    : _ref = ref,
      super(EstadoGrillaCheques(filtro: _filtroInicial(ref)));

  final Ref _ref;

  /// Sin sucursal todavia y con el rango por defecto: asi lo ven `iniciar` y los
  /// cambios de empresa o sucursal, que solo mueven la sucursal.
  static ChequeFiltroEntity _filtroInicial(Ref ref) {
    final r = rangoRecepcionPorDefecto(ref.read(relojChequesProvider)());
    return ChequeFiltroEntity(
      codSucursal: 0,
      fechaRecepcionDesde: r.desde,
      fechaRecepcionHasta: r.hasta,
    );
  }

  /// De hace tres meses a hoy, segun el reloj del modulo.
  RangoRecepcionCheques get rangoPorDefecto =>
      rangoRecepcionPorDefecto(_ref.read(relojChequesProvider)());

  int _consulta = 0;

  /// Cuenta las elecciones manuales de empresa o de sucursal: la sucursal
  /// inicial que viaja de una eleccion anterior ya no vale.
  int _eleccion = 0;
  bool _iniciando = false;

  ChequesRepository get _repo => _ref.read(chequesRepositoryProvider);

  /// La empresa con la que se trabaja: la ya elegida o, al abrir, la primera de
  /// la lista. Si la lista fallo antes, se vuelve a pedir: el provider guarda el
  /// error y sin invalidarlo el reintento recibiria el mismo.
  Future<EmpresaChequeEntity> _empresaDeTrabajo() async {
    final actual = _ref.read(empresasChequeProvider);
    if (actual.hasError && !actual.isLoading) {
      _ref.invalidate(empresasChequeProvider);
    }
    final empresas = await _ref.read(empresasChequeProvider.future);
    final e = resolverEmpresaCheque(empresas, state.codEmpresa);
    if (e == null) throw Exception('No hay empresas disponibles para cheques.');
    return e;
  }

  /// Abre la pantalla: toma la primera empresa, pide la sucursal inicial del
  /// usuario **en ella** y, si tiene, carga la primera pagina. Si no tiene (0),
  /// deja `iniciado` en true y sin sucursal para que la pantalla pida elegir
  /// una. Repetirla no hace nada, salvo para reintentar tras un fallo.
  Future<void> iniciar() async {
    if (state.iniciado || _iniciando) return;
    _iniciando = true;
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final empresa = await _empresaDeTrabajo();
      if (!mounted || state.iniciado) return;
      final cod = await _repo.obtenerSucursalInicial(
        codEmpresa: empresa.codEmpresa,
      );
      // Si el usuario ya eligio empresa o sucursal a mano mientras esto
      // viajaba, su eleccion manda.
      if (!mounted || state.iniciado) return;
      state = state.copyWith(
        iniciado: true,
        codEmpresa: empresa.codEmpresa,
        filtro: state.filtro.copyWith(codSucursal: cod, pagina: 1),
        limpiarResultado: true,
      );
      // Sin sucursal (0) `_cargar` solo apaga el indicador de carga.
      await _cargar();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(cargando: false, error: mensajeDeErrorCheque(e));
      }
    } finally {
      _iniciando = false;
    }
  }

  /// Cambia de empresa, como `trasSeleccionEmpresa()` del legacy: la sucursal
  /// vuelve a 0, se pide la sucursal inicial del usuario **en la empresa nueva**,
  /// se descarta la lista (eran cheques de otra empresa) y se carga la pagina 1.
  /// Los criterios de busqueda se conservan.
  ///
  /// Si el usuario cambia de empresa (o de sucursal) otra vez antes de que
  /// llegue la respuesta, solo vale lo ultimo.
  Future<void> elegirEmpresa(int codEmpresa) async {
    if (codEmpresa <= 0) return;
    // Tras un fallo (`iniciado` en false) elegir la misma empresa reintenta.
    if (codEmpresa == state.codEmpresa && state.iniciado) return;
    final eleccion = ++_eleccion;
    // Lo que viajaba de la empresa anterior no debe pintar nada.
    _consulta++;
    state = state.copyWith(
      iniciado: true,
      codEmpresa: codEmpresa,
      filtro: state.filtro.copyWith(codSucursal: 0, pagina: 1),
      cargando: true,
      limpiarResultado: true,
      limpiarError: true,
    );
    try {
      final cod = await _repo.obtenerSucursalInicial(codEmpresa: codEmpresa);
      if (!mounted || eleccion != _eleccion) return;
      state = state.copyWith(
        filtro: state.filtro.copyWith(codSucursal: cod, pagina: 1),
      );
      await _cargar();
    } catch (e) {
      if (!mounted || eleccion != _eleccion) return;
      // Sin iniciar, «Reintentar» vuelve a pedir la sucursal de esta empresa
      // (`iniciar` respeta la empresa ya elegida) en vez de releer una lista de
      // sucursal 0.
      state = state.copyWith(
        iniciado: false,
        cargando: false,
        error: mensajeDeErrorCheque(e),
      );
    }
  }

  /// Cambia de sucursal y vuelve a la pagina 1. Los criterios se conservan. La
  /// lista anterior se descarta: eran cheques de otra sucursal.
  Future<void> elegirSucursal(int codSucursal) {
    // Una sucursal elegida a mano gana a la inicial que aun viaje.
    _eleccion++;
    state = state.copyWith(
      iniciado: true,
      filtro: state.filtro.copyWith(codSucursal: codSucursal, pagina: 1),
      limpiarResultado: true,
    );
    return _cargar();
  }

  /// **Reemplaza** los criterios de busqueda (un null quita ese criterio) y
  /// vuelve a la pagina 1. Sin fechas de recepcion se piden todos los cheques.
  Future<void> aplicarCriterios({
    String? nroCheque,
    String? cliente,
    String? tipo,
    String? estado,
    int? codBanco,
    DateTime? fechaCobro,
    DateTime? fechaRecepcionDesde,
    DateTime? fechaRecepcionHasta,
  }) {
    state = state.copyWith(
      filtro: state.filtro.conCriterios(
        nroCheque: nroCheque,
        cliente: cliente,
        tipo: tipo,
        estado: estado,
        codBanco: codBanco,
        fechaCobro: fechaCobro,
        fechaRecepcionDesde: fechaRecepcionDesde,
        fechaRecepcionHasta: fechaRecepcionHasta,
      ),
    );
    return _cargar();
  }

  /// Quita todos los criterios y vuelve al rango de recepcion por defecto.
  Future<void> limpiarCriterios() {
    final r = rangoPorDefecto;
    return aplicarCriterios(
      fechaRecepcionDesde: r.desde,
      fechaRecepcionHasta: r.hasta,
    );
  }

  Future<void> cambiarOrden(OrdenCheques orden) {
    if (orden == state.filtro.orden) return Future.value();
    state = state.copyWith(
      filtro: state.filtro.copyWith(orden: orden, pagina: 1),
    );
    return _cargar();
  }

  /// Va a la pagina [pagina] (desde 1). Ignora una pagina fuera de rango o la
  /// que ya se esta viendo; para releer la actual esta [recargar].
  Future<void> irAPagina(int pagina) {
    if (pagina < 1 || pagina == state.filtro.pagina) return Future.value();
    if (state.totalPaginas > 0 && pagina > state.totalPaginas) {
      return Future.value();
    }
    state = state.copyWith(filtro: state.filtro.copyWith(pagina: pagina));
    return _cargar();
  }

  Future<void> siguiente() =>
      state.haySiguiente ? irAPagina(state.filtro.pagina + 1) : Future.value();

  Future<void> anterior() =>
      state.hayAnterior ? irAPagina(state.filtro.pagina - 1) : Future.value();

  /// Vuelve a pedir la pagina actual con los mismos filtros.
  Future<void> recargar() => _cargar();

  Future<void> _cargar() async {
    final filtro = state.filtro;
    if (filtro.codSucursal <= 0) {
      // Invalida lo que haya en vuelo: no debe llegar a pintar nada.
      _consulta++;
      state = state.copyWith(
        cargando: false,
        limpiarResultado: true,
        limpiarError: true,
      );
      return;
    }
    final consulta = ++_consulta;
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final r = await _repo.listar(filtro);
      if (!mounted || consulta != _consulta) return;

      // La pagina pedida ya no existe (por ejemplo, se vacio la ultima): se
      // retrocede a la ultima que si.
      final ultima = r.totalPaginas;
      if (r.filas.isEmpty && ultima >= 1 && filtro.pagina > ultima) {
        state = state.copyWith(filtro: filtro.copyWith(pagina: ultima));
        await _cargar();
        return;
      }
      state = state.copyWith(
        resultado: r,
        cargando: false,
        limpiarError: true,
        filtro:
            (r.total == 0 && filtro.pagina > 1)
                ? filtro.copyWith(pagina: 1)
                : null,
      );
    } catch (e) {
      if (!mounted || consulta != _consulta) return;
      state = state.copyWith(
        cargando: false,
        error: mensajeDeErrorCheque(e),
        limpiarResultado: true,
      );
    }
  }
}

final grillaChequesProvider = StateNotifierProvider.autoDispose<
  GrillaChequesNotifier,
  EstadoGrillaCheques
>((ref) => GrillaChequesNotifier(ref));

/// La sucursal con la que se trabaja (0 = ninguna elegida todavia). Los
/// dialogos de traspaso y custodia la leen de aqui.
final sucursalChequeProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(grillaChequesProvider.select((s) => s.codSucursal)),
);

/// La empresa activa de la pantalla (la del combo «Empresa»): la que eligio el
/// usuario y, mientras no elija, la primera de [empresasChequeProvider]. Null
/// mientras la lista carga, si fallo o si esta vacia.
///
/// Es la unica fuente de la empresa en el modulo: de ella salen las sucursales,
/// los clientes y la empresa del cheque nuevo. Nunca la del login.
final empresaChequeActivaProvider = Provider.autoDispose<EmpresaChequeEntity?>((
  ref,
) {
  final empresas = ref.watch(empresasChequeProvider).valueOrNull;
  final elegida = ref.watch(grillaChequesProvider.select((s) => s.codEmpresa));
  return resolverEmpresaCheque(empresas, elegida);
});

/// Las sucursales de la empresa activa, para los combos y los subtitulos de los
/// dialogos. Vacia mientras no hay empresa activa o la lista carga.
final sucursalesChequeActivasProvider =
    Provider.autoDispose<List<SucursalChequeEntity>>((ref) {
      final empresa = ref.watch(empresaChequeActivaProvider);
      if (empresa == null) return const <SucursalChequeEntity>[];
      return ref
              .watch(sucursalesChequeProvider(empresa.codEmpresa))
              .valueOrNull ??
          const <SucursalChequeEntity>[];
    });

// ═══════════════════════════════════════════════════════════════════════════
// ESCRITURAS
// ═══════════════════════════════════════════════════════════════════════════

@immutable
class EstadoOperacionCheque {
  const EstadoOperacionCheque({this.ocupado = false, this.error});

  /// Hay una escritura en vuelo. Una sola a la vez: dos guardados cruzados
  /// dejan la pantalla contando algo que no paso.
  final bool ocupado;

  /// El mensaje del backend de la ultima escritura fallida, tal cual, listo
  /// para mostrar. Varios errores vienen separados por salto de linea.
  final String? error;
}

/// Todas las escrituras del modulo. Cada una devuelve su resultado o null si
/// fallo (el motivo queda en `state.error`) y, al salir bien, refresca lo que
/// deja viejo: la grilla, el detalle abierto y las listas de traspaso y
/// custodia.
///
/// No es autoDispose: una escritura en vuelo no puede quedar huerfana porque la
/// pantalla que la lanzo ya no escucha. Quien muestre el error debe llamar a
/// [limpiarError] al abrir un formulario.
class OperacionesChequesNotifier extends StateNotifier<EstadoOperacionCheque> {
  OperacionesChequesNotifier(this._ref) : super(const EstadoOperacionCheque());

  final Ref _ref;

  ChequesRepository get _repo => _ref.read(chequesRepositoryProvider);

  Future<T?> _ejecutar<T>(Future<T> Function() accion) async {
    if (state.ocupado) return null;
    state = const EstadoOperacionCheque(ocupado: true);
    try {
      final r = await accion();
      if (!mounted) return r;
      state = const EstadoOperacionCheque();
      _refrescar();
      return r;
    } catch (e) {
      if (mounted) {
        state = EstadoOperacionCheque(error: mensajeDeErrorCheque(e));
      }
      return null;
    }
  }

  /// Toda escritura puede mover la grilla (estado, fecha de cobro, filas que
  /// entran o salen), el detalle abierto, los pendientes de traspaso y las
  /// listas de custodia. La grilla solo se relee si hay una pantalla usandola.
  void _refrescar() {
    if (_ref.exists(grillaChequesProvider)) {
      _ref.read(grillaChequesProvider.notifier).recargar();
    }
    _ref.invalidate(detalleChequeProvider);
    _ref.invalidate(traspasosPendientesChequesProvider);
    _ref.invalidate(chequesParaCustodiaProvider);
    _ref.invalidate(chequesParaDarCustodiaProvider);
    _ref.invalidate(entregasDelDiaChequeProvider);
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoOperacionCheque();
  }

  /// Alta o edicion; devuelve el codCheque.
  Future<BigInt?> registrar(ChequeRegistroEntity registro) =>
      _ejecutar(() => _repo.registrar(registro));

  /// Devuelve el codAccion.
  Future<BigInt?> cambiarFechaCobro(AccionChequeRequestEntity accion) =>
      _ejecutar(() => _repo.cambiarFechaCobro(accion));

  Future<BigInt?> devolver(AccionChequeRequestEntity accion) =>
      _ejecutar(() => _repo.devolver(accion));

  Future<BigInt?> cerrar(AccionChequeRequestEntity accion) =>
      _ejecutar(() => _repo.cerrar(accion));

  Future<BigInt?> eliminarAccion(BigInt codAccion) =>
      _ejecutar(() => _repo.eliminarAccion(codAccion));

  /// Devuelve cuantos cheques se traspasaron.
  Future<int?> traspasar(int codSucursal) =>
      _ejecutar(() => _repo.traspasar(codSucursal));

  /// Devuelve cuantos cheques se entregaron.
  Future<int?> entregarEnCustodia(CustodiaChequeRequestEntity pedido) =>
      _ejecutar(() => _repo.entregarEnCustodia(pedido));

  /// Devuelve el codAccion nuevo.
  Future<BigInt?> darCustodia(DarCustodiaRequestEntity pedido) =>
      _ejecutar(() => _repo.darCustodia(pedido));
}

final operacionesChequesProvider =
    StateNotifierProvider<OperacionesChequesNotifier, EstadoOperacionCheque>(
      (ref) => OperacionesChequesNotifier(ref),
    );


// ═══════════════════════════════════════════════════════════════════════════
// ESCRITURAS DE LOS PANELES DEL DETALLE
// ═══════════════════════════════════════════════════════════════════════════

/// Las escrituras de los tres paneles del detalle (notas de remision,
/// transacciones bancarias y postergaciones). Aparte de [OperacionesChequesNotifier]
/// a proposito: escribir una nota no mueve la grilla ni los pendientes de
/// traspaso, asi que solo refresca la lista que cambio.
///
/// Cada metodo devuelve su resultado o null si fallo (el motivo queda en
/// `state.error`, completo y tal cual lo redacto el servidor). Una sola escritura
/// a la vez. No es autoDispose: una escritura en vuelo no puede quedar huerfana
/// porque el dialogo que la lanzo ya no escucha.
class OperacionesPanelesChequeNotifier
    extends StateNotifier<EstadoOperacionCheque> {
  OperacionesPanelesChequeNotifier(this._ref)
    : super(const EstadoOperacionCheque());

  final Ref _ref;

  ChequesRepository get _repo => _ref.read(chequesRepositoryProvider);

  Future<T?> _ejecutar<T>(
    Future<T> Function() accion,
    void Function() refrescar,
  ) async {
    if (state.ocupado) return null;
    state = const EstadoOperacionCheque(ocupado: true);
    try {
      final r = await accion();
      if (!mounted) return r;
      state = const EstadoOperacionCheque();
      refrescar();
      return r;
    } catch (e) {
      if (mounted) {
        state = EstadoOperacionCheque(error: mensajeDeErrorCheque(e));
      }
      return null;
    }
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoOperacionCheque();
  }

  /// Devuelve true si quedo guardada.
  Future<bool> registrarNotaRemision(NotaRemisionChequeEntity nota) async {
    final r = await _ejecutar(
      () async {
        await _repo.registrarNotaRemision(nota);
        return true;
      },
      () => _ref.invalidate(notasRemisionChequeProvider(nota.codCheque)),
    );
    return r ?? false;
  }

  /// Devuelve cuantas filas se eliminaron (mas de una si la nota estaba
  /// repetida), o null si fallo.
  Future<int?> eliminarNotaRemision({
    required BigInt codCheque,
    required String notaRemision,
  }) => _ejecutar(
    () => _repo.eliminarNotaRemision(
      codCheque: codCheque,
      notaRemision: notaRemision,
    ),
    () => _ref.invalidate(notasRemisionChequeProvider(codCheque)),
  );

  Future<bool> registrarTransaccion(TransaccionBancariaEntity t) async {
    final r = await _ejecutar(
      () async {
        await _repo.registrarTransaccion(t);
        return true;
      },
      () => _ref.invalidate(transaccionesChequeProvider(t.codCheque)),
    );
    return r ?? false;
  }

  /// Devuelve cuantas filas se eliminaron, o null si fallo.
  Future<int?> eliminarTransaccion({
    required BigInt codCheque,
    required String nroTransaccion,
  }) => _ejecutar(
    () => _repo.eliminarTransaccion(
      codCheque: codCheque,
      nroTransaccion: nroTransaccion,
    ),
    () => _ref.invalidate(transaccionesChequeProvider(codCheque)),
  );

  /// Devuelve el codPostergacion nuevo, o null si fallo.
  Future<BigInt?> registrarPostergacion(PostergacionEntity p) => _ejecutar(
    () => _repo.registrarPostergacion(p),
    () => _ref.invalidate(postergacionesChequeProvider(p.codCheque)),
  );

  /// Devuelve el codPostergacion eliminado, o null si fallo. El PDF no se borra
  /// (como en el legacy), pero ya nadie lo ve.
  Future<BigInt?> eliminarPostergacion({
    required BigInt codCheque,
    required BigInt codPostergacion,
  }) => _ejecutar(
    () => _repo.eliminarPostergacion(
      codCheque: codCheque,
      codPostergacion: codPostergacion,
    ),
    () {
      _ref.invalidate(postergacionesChequeProvider(codCheque));
      _ref.invalidate(estadoPdfPostergacionProvider(codPostergacion));
    },
  );
}

final operacionesPanelesChequeProvider = StateNotifierProvider<
  OperacionesPanelesChequeNotifier,
  EstadoOperacionCheque
>((ref) => OperacionesPanelesChequeNotifier(ref));
