import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/comisiones_impl.dart';
import 'package:bosque_flutter/domain/entities/comision_dinamica_entity.dart';
import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_x_vendedor_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_periodo_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_pendiente_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_preliminar_entity.dart';
import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';
import 'package:bosque_flutter/domain/entities/politica_bond_entity.dart';
import 'package:bosque_flutter/domain/entities/preliminar_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cambio_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/vendedor_comision_entity.dart';
import 'package:bosque_flutter/domain/repositories/comisiones_repository.dart';

/// Repositorio del modulo. Declarado aparte para poder sustituirlo en pruebas
/// mediante un override en el ProviderScope.
final comisionesRepositoryProvider = Provider<ComisionesRepository>(
  (ref) => ComisionesImpl(),
);

// ═══════════════════════════════════════════════════════════════════════
// Lecturas
//
// Son FutureProvider: la pantalla usa .when(...) y muestra el spinner mientras
// el estado es loading. Nada de banderas de carga manuales.
// ═══════════════════════════════════════════════════════════════════════

/// Grupos activos.
final gruposComisionProvider =
    FutureProvider.autoDispose<List<GrupoComisionEntity>>((ref) async {
      return ref.watch(comisionesRepositoryProvider).obtenerGrupos();
    });

/// Grupos incluyendo los dados de baja.
final gruposComisionTodosProvider =
    FutureProvider.autoDispose<List<GrupoComisionEntity>>((ref) async {
      return ref.watch(comisionesRepositoryProvider).obtenerGruposTodos();
    });

/// Grupos que el vendedor todavia no tiene asignados y vigentes.
final gruposAsignablesProvider = FutureProvider.autoDispose
    .family<List<GrupoComisionEntity>, BigInt>((ref, idVendedor) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerGruposAsignables(idVendedor);
    });

/// Vendedores activos con sus codigos por empresa.
final vendedoresComisionProvider =
    FutureProvider.autoDispose<List<VendedorComisionEntity>>((ref) async {
      return ref.watch(comisionesRepositoryProvider).obtenerVendedores();
    });

/// Vendedores incluyendo los dados de baja.
final vendedoresComisionTodosProvider =
    FutureProvider.autoDispose<List<VendedorComisionEntity>>((ref) async {
      return ref.watch(comisionesRepositoryProvider).obtenerVendedoresTodos();
    });

/// Vendedores de una empresa SAP. Cero devuelve todas.
final vendedoresPorEmpresaProvider = FutureProvider.autoDispose
    .family<List<VendedorComisionEntity>, int>((ref, codEmpresa) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerVendedoresPorEmpresa(codEmpresa);
    });

/// Asignaciones de grupo de un vendedor, vigentes o no.
final gruposPorVendedorProvider = FutureProvider.autoDispose
    .family<List<GrupoXVendedorEntity>, BigInt>((ref, idVendedor) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerGruposPorVendedor(idVendedor);
    });

/// Todas las asignaciones vigentes a la fecha.
final asignacionesVigentesProvider =
    FutureProvider.autoDispose<List<GrupoXVendedorEntity>>((ref) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerAsignacionesVigentes();
    });

/// Escalas de comision dinamica. null trae internas y externas.
final comisionesDinamicasProvider = FutureProvider.autoDispose
    .family<List<ComisionDinamicaEntity>, int?>((ref, esInterno) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerComisionesDinamicas(esInterno: esInterno);
    });

/// Escalas vigentes hoy.
final comisionesDinamicasVigentesProvider = FutureProvider.autoDispose
    .family<List<ComisionDinamicaEntity>, int?>((ref, esInterno) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerComisionesDinamicasVigentes(esInterno: esInterno);
    });

// ═══════════════════════════════════════════════════════════════════════
// Escrituras
// ═══════════════════════════════════════════════════════════════════════

/// Estado de una operacion de guardado.
///
/// Existe para que el boton muestre spinner y quede deshabilitado mientras la
/// peticion viaja: sin esto el usuario vuelve a tocar Guardar y se generan
/// registros duplicados, que es lo que pasaba en la pantalla de Bosque v2.
class EstadoAccion {
  final bool enProceso;
  final String? error;
  final BigInt? idGenerado;

  const EstadoAccion({this.enProceso = false, this.error, this.idGenerado});

  bool get huboError => error != null;
  bool get fueExitosa => !enProceso && error == null && idGenerado != null;
}

class ComisionesAccionesNotifier extends StateNotifier<EstadoAccion> {
  ComisionesAccionesNotifier(this._ref) : super(const EstadoAccion());

  final Ref _ref;

  ComisionesRepository get _repo => _ref.read(comisionesRepositoryProvider);

  /// Envuelve cualquier escritura: marca en proceso, ejecuta e invalida las
  /// lecturas afectadas para que las tablas se refresquen solas.
  Future<bool> _ejecutar(
    Future<BigInt> Function() accion,
    List<ProviderOrFamily> aInvalidar,
  ) async {
    state = const EstadoAccion(enProceso: true);
    try {
      final id = await accion();
      for (final p in aInvalidar) {
        _ref.invalidate(p);
      }
      state = EstadoAccion(idGenerado: id);
      return true;
    } catch (e) {
      // El backend manda el mensaje del SP listo para mostrar al usuario.
      state = EstadoAccion(error: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  void limpiar() => state = const EstadoAccion();

  // ---------- Grupos ----------

  Future<bool> guardarGrupo(GrupoComisionEntity grupo) => _ejecutar(
    () => _repo.registrarGrupo(grupo),
    [gruposComisionProvider, gruposComisionTodosProvider],
  );

  Future<bool> eliminarGrupo(GrupoComisionEntity grupo) => _ejecutar(
    () => _repo.eliminarGrupo(grupo),
    [gruposComisionProvider, gruposComisionTodosProvider],
  );

  // ---------- Vendedores ----------

  Future<bool> guardarVendedor(VendedorComisionEntity vendedor) =>
      _ejecutar(() => _repo.registrarVendedor(vendedor), [
        vendedoresComisionProvider,
        vendedoresComisionTodosProvider,
        vendedoresPorEmpresaProvider,
      ]);

  Future<bool> eliminarVendedor(VendedorComisionEntity vendedor) =>
      _ejecutar(() => _repo.eliminarVendedor(vendedor), [
        vendedoresComisionProvider,
        vendedoresComisionTodosProvider,
        vendedoresPorEmpresaProvider,
      ]);

  // ---------- Asignacion grupo / vendedor ----------

  Future<bool> guardarAsignacion(GrupoXVendedorEntity asignacion) =>
      _ejecutar(() => _repo.registrarGrupoVendedor(asignacion), [
        asignacionesVigentesProvider,
        gruposPorVendedorProvider,
        gruposAsignablesProvider,
      ]);

  Future<bool> eliminarAsignacion(GrupoXVendedorEntity asignacion) =>
      _ejecutar(() => _repo.eliminarGrupoVendedor(asignacion), [
        asignacionesVigentesProvider,
        gruposPorVendedorProvider,
        gruposAsignablesProvider,
      ]);

  // ---------- Comision dinamica ----------

  Future<bool> guardarComisionDinamica(ComisionDinamicaEntity escala) =>
      _ejecutar(() => _repo.registrarComisionDinamica(escala), [
        comisionesDinamicasProvider,
        comisionesDinamicasVigentesProvider,
      ]);

  Future<bool> eliminarComisionDinamica(ComisionDinamicaEntity escala) =>
      _ejecutar(() => _repo.eliminarComisionDinamica(escala), [
        comisionesDinamicasProvider,
        comisionesDinamicasVigentesProvider,
      ]);

  // ---------- Carga y ejecucion del periodo ----------

  /// Prepara las notas del periodo. Reversible.
  Future<bool> cargarNotas({
    required int mes,
    required int anio,
    required int esInterno,
    required int audUsuario,
  }) => _ejecutar(
    () => _repo.cargarNotas(
      mes: mes,
      anio: anio,
      esInterno: esInterno,
      audUsuario: audUsuario,
    ),
    [estadoPeriodoProvider, preliminarProvider],
  );

  // ---------- Politica del descuento por familia ----------
  //
  // Toda escritura invalida ademas los providers del preliminar: cambiar un
  // porcentaje cambia lo que se va a pagar, y dejar la pantalla mostrando el
  // numero viejo seria peor que no mostrarlo.

  Future<bool> guardarPoliticaFamilia(FamiliaPoliticaEntity mb, int uid) =>
      _ejecutar(() => _repo.guardarPoliticaFamilia(mb, uid), [
        politicaFamiliasProvider,
        politicaFamiliasVigentesProvider,
      ]);

  Future<bool> eliminarPoliticaFamilia(FamiliaPoliticaEntity mb, int uid) =>
      _ejecutar(() => _repo.eliminarPoliticaFamilia(mb, uid), [
        politicaFamiliasProvider,
        politicaFamiliasVigentesProvider,
      ]);

  Future<bool> guardarVendedorExento(VendedorExentoEntity mb, int uid) =>
      _ejecutar(() => _repo.guardarVendedorExento(mb, uid), [
        vendedoresExentosProvider,
      ]);

  Future<bool> eliminarVendedorExento(VendedorExentoEntity mb, int uid) =>
      _ejecutar(() => _repo.eliminarVendedorExento(mb, uid), [
        vendedoresExentosProvider,
      ]);

  Future<bool> guardarClienteExcluido(ClienteExcluidoEntity mb, int uid) =>
      _ejecutar(() => _repo.guardarClienteExcluido(mb, uid), [
        clientesExcluidosProvider,
      ]);

  Future<bool> eliminarClienteExcluido(ClienteExcluidoEntity mb, int uid) =>
      _ejecutar(() => _repo.eliminarClienteExcluido(mb, uid), [
        clientesExcluidosProvider,
      ]);

  // ---------- Comision por rango de dias ----------

  Future<bool> guardarRango(ComisionPorRangoEntity rango) => _ejecutar(
    () => _repo.registrarRangoComision(rango),
    [rangosComisionProvider],
  );

  Future<bool> eliminarRango(ComisionPorRangoEntity rango) => _ejecutar(
    () => _repo.eliminarRangoComision(rango),
    [rangosComisionProvider],
  );

  /// Realiza el corte. NO ES REVERSIBLE.
  Future<bool> ejecutarPago({
    required int mes,
    required int anio,
    required int esInterno,
    required int audUsuario,
  }) => _ejecutar(
    () => _repo.ejecutarPago(
      mes: mes,
      anio: anio,
      esInterno: esInterno,
      audUsuario: audUsuario,
    ),
    [
      estadoPeriodoProvider,
      preliminarProvider,
      // Ejecutar el pago es lo que ESCRIBE tcom_pagadoItem y su corte. Sin
      // invalidar estos tres, el dialogo del detalle congelado sigue mostrando
      // lo que leyo antes de la ejecucion -en el caso normal, que el periodo
      // no tiene corte- justo despues del unico momento en que ese detalle
      // cambia.
      itemsPagadosProvider,
      resumenItemsPagadosProvider,
      corteItemsPagadosProvider,
    ],
  );
}

final comisionesAccionesProvider =
    StateNotifierProvider<ComisionesAccionesNotifier, EstadoAccion>(
      (ref) => ComisionesAccionesNotifier(ref),
    );

// ═══════════════════════════════════════════════════════════════════════
// Filtros de pantalla
//
// Locales al modulo: se reinician al salir, para que un filtro de una visita
// no reaparezca en la siguiente.
// ═══════════════════════════════════════════════════════════════════════

/// Texto de busqueda de la tabla activa.
final filtroBusquedaComisionProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Empresa SAP seleccionada. Cero significa todas.
final filtroEmpresaComisionProvider = StateProvider.autoDispose<int>(
  (ref) => 0,
);

/// null = internas y externas, 1 = internas, 0 = externas.
final filtroEsInternoProvider = StateProvider.autoDispose<int?>((ref) => null);

// ═══════════════════════════════════════════════════════════════════════
// Vistas preliminares
//
// Los cuatro providers son family porque dependen del periodo y del tipo de
// cambio. Se declara == y hashCode para que Riverpod reconozca dos filtros
// iguales como el mismo y no vuelva a pedir los datos al backend.
// ═══════════════════════════════════════════════════════════════════════

/// Modalidad de calculo. Cada una corresponde a una rama del SP heredado y a
/// un permiso de tb_vistaBtn sobre la vista 82.
enum ModalidadPreliminar {
  interno(
    'Internos',
    'tabPreliminar',
    'Padron interno con la escala por dias de pago.',
  ),
  externo(
    'Externos',
    'tabPreliminarExt',
    'Padron externo. Es el unico que no es interno.',
  ),
  dinamicaAnterior(
    'Internos dinamica anterior',
    'tabPreliminarComDinamica',
    'Padron interno, calculado con la escala por meta anterior a 2022.',
  ),
  dinamicaVigente(
    'Internos dinamica vigente',
    'tabPreliminarComDinamicaNew',
    'Padron interno, calculado con la escala por meta vigente.',
  );

  const ModalidadPreliminar(this.etiqueta, this.permiso, this.detalle);

  /// El rotulo del boton.
  ///
  /// Las tres internas lo dicen: lo que cambia entre ellas es el CALCULO, no a
  /// quien se le paga, y con «Internos / Dinamica anterior / Dinamica vigente»
  /// parecia que solo la primera era del padron interno.
  final String etiqueta;

  /// Una linea que explica en que se diferencia de las otras. El nombre agrupa;
  /// esto es lo que deja elegir.
  final String detalle;

  /// nombreBtn en tb_vistaBtn, el mismo que usaba esAutorizado() en el XHTML.
  final String permiso;

  /// Contra que mitad del periodo se paga esta modalidad: 1 internos, 0
  /// externos.
  ///
  /// Las tres modalidades internas -la de siempre, la dinamica anterior y la
  /// vigente- son tres formas de CALCULAR lo mismo, no tres periodos: el pago
  /// de internos es uno solo. Por eso las tres van a 1 y solo `externo` va a 0.
  int get esInterno => this == ModalidadPreliminar.externo ? 0 : 1;

  /// Como se llama el reporte de lo ya pagado para esta modalidad. Es el
  /// rotulo literal del boton de la barra de arriba, para poder nombrarselo a
  /// quien esta mirando una pantalla vacia.
  String get reportePagadas =>
      this == ModalidadPreliminar.externo
          ? 'Pagadas externas'
          : 'Pagadas internas';
}

/// Permisos de botón del módulo, definidos en tb_vistaBtn para la vista 82.
///
/// Los dos primeros vienen del legacy y ya existían en la tabla; los cinco
/// siguientes se crean con el script 01_botones_comisiones.sql y cubren las
/// pestañas que en Comisiones.xhtml no vivían sueltas, sino dentro de un tab
/// o un diálogo ya protegido. Sin esas filas nadie salvo `adm` ve la pestaña:
/// correr el script antes de desplegar.
class PermisosComision {
  const PermisosComision._();

  /// Crear o ver grupos por vendedor.
  static const asignaciones = 'btnGrpVen';

  /// Cargar y ejecutar el pago del período.
  static const ejecutar = 'TabEjecutar';

  /// ABM del padrón de vendedores.
  static const vendedores = 'btnComVendedores';

  /// ABM de grupos de comisión.
  static const grupos = 'btnComGrupos';

  /// ABM de porcentajes de comisión dinámica.
  static const comisionDinamica = 'btnComDinamica';

  /// Escala por días. El ABM lo corta el backend a ROLE_ADM; esto es la lectura.
  static const rangos = 'btnComRangos';

  /// Notas pendientes de pago.
  static const pendientes = 'btnComPendientes';

  /// Administrar la politica del descuento por familia. Va aparte de los
  /// demas a proposito: cambiar un numero aca mueve la nomina del mes.
  static const politica = 'btnComPolitica';
}

/// Las pestanias del modulo, sin widgets de por medio.
///
/// Es un enum y no una lista de titulos porque quien lo consume tiene que
/// mapear cada una a su pestania, y un typo en un String no lo detecta nadie.
enum PestanaComision {
  vendedores('Vendedores'),
  grupos('Grupos'),
  asignaciones('Asignaciones'),
  escala('Escala por dias'),
  politica('Politica'),
  preliminar('Preliminar'),
  ejecutar('Ejecutar'),
  pendientes('Pendientes');

  const PestanaComision(this.titulo);
  final String titulo;
}

/// Lo que un usuario tiene derecho a ver en el modulo.
@immutable
class SuperficiesComision {
  const SuperficiesComision({
    required this.pestanias,
    required this.modalidades,
  });

  /// En el orden en que se dibujan.
  final List<PestanaComision> pestanias;

  /// Las modalidades del preliminar que quedaron habilitadas. Puede estar
  /// vacia aunque `pestanias` no lo este.
  final List<ModalidadPreliminar> modalidades;

  bool get vacio => pestanias.isEmpty;
}

/// Que ve este usuario, dados sus botones autorizados.
///
/// Funcion pura a proposito: es la regla de acceso del modulo y tiene que
/// poder probarse contra filas reales de `tb_usuarioBtn` sin montar un arbol de
/// widgets ni falsear a Riverpod.
///
/// El mapeo con Comisiones.xhtml, que es lo que hay que replicar:
///
///   XHTML                                     -> pestania nueva
///   tab EJECUTAR COMISIONES (TabEjecutar)     -> Ejecutar
///   tab PRELIMINAR (tabPreliminar)            -> Preliminar / Internos
///   tab PRELIMINAR EXT (tabPreliminarExt)     -> Preliminar / Externos
///   tab DINAMICA (tabPreliminarComDinamica)   -> Preliminar / Internos dinamica anterior
///   tab DINAMICA NEW (…ComDinamicaNew)        -> Preliminar / Internos dinamica vigente
///   boton Grupo Vendedor (btnGrpVen)          -> Asignaciones
///
/// OJO con la ultima linea: en el XHTML `btnGrpVen` abria `dlgGrpVen`, y ese
/// dialogo traia TAMBIEN el alta de vendedores y la de grupos. Aca eso se
/// partio en tres pestanias con tres permisos, asi que `btnGrpVen` solo ya no
/// alcanza para administrar vendedores ni grupos: hacen falta
/// `btnComVendedores` y `btnComGrupos`. Hoy no se lo lleva nadie por delante
/// -no hay un solo usuario con `btnGrpVen` en `nivelAcceso != 0`-, pero quien
/// otorgue ese boton esperando el comportamiento viejo va a recibir un tercio.
///
/// Escala por dias, Politica y Pendientes no existian en el XHTML: son
/// superficie nueva, con permiso propio desde el primer dia.
SuperficiesComision superficiesComision(bool Function(String) tiene) {
  final modalidades =
      ModalidadPreliminar.values.where((m) => tiene(m.permiso)).toList();

  return SuperficiesComision(
    pestanias: [
      // ---- Configuracion ----
      if (tiene(PermisosComision.vendedores)) PestanaComision.vendedores,
      if (tiene(PermisosComision.grupos)) PestanaComision.grupos,
      if (tiene(PermisosComision.asignaciones)) PestanaComision.asignaciones,
      if (tiene(PermisosComision.rangos)) PestanaComision.escala,
      if (tiene(PermisosComision.politica)) PestanaComision.politica,

      // ---- El mes ----
      if (modalidades.isNotEmpty) PestanaComision.preliminar,
      if (tiene(PermisosComision.ejecutar)) PestanaComision.ejecutar,
      if (tiene(PermisosComision.pendientes)) PestanaComision.pendientes,
    ],
    modalidades: modalidades,
  );
}

@immutable
class FiltroPreliminar {
  const FiltroPreliminar({
    required this.modalidad,
    required this.mes,
    required this.anio,
    required this.tc,
  });

  final ModalidadPreliminar modalidad;
  final int mes;
  final int anio;
  final double tc;

  FiltroPreliminar copyWith({
    ModalidadPreliminar? modalidad,
    int? mes,
    int? anio,
    double? tc,
  }) => FiltroPreliminar(
    modalidad: modalidad ?? this.modalidad,
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
    tc: tc ?? this.tc,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroPreliminar &&
          other.modalidad == modalidad &&
          other.mes == mes &&
          other.anio == anio &&
          other.tc == tc;

  @override
  int get hashCode => Object.hash(modalidad, mes, anio, tc);
}

/// Filtro activo de la pestana de preliminares.
final filtroPreliminarProvider = StateProvider.autoDispose<FiltroPreliminar>((
  ref,
) {
  final hoy = DateTime.now();
  return FiltroPreliminar(
    modalidad: ModalidadPreliminar.interno,
    mes: hoy.month,
    anio: hoy.year,
    // Valor de arranque; tipoCambioSugeridoProvider lo reemplaza al resolverse.
    tc: 6.96,
  );
});

/// Tipo de cambio que sugiere el backend, con el que arranca el preliminar.
///
/// Sale de la misma cotizacion de SAP que aplica el calculo, de modo que el
/// numero de la pantalla y el que se usa al convertir a dolares coinciden. No
/// es autoDispose: cambiar de pestana no deberia volver a pedirlo.
final tipoCambioSugeridoProvider = FutureProvider<TipoCambioComisionEntity>((
  ref,
) async {
  return ref.watch(comisionesRepositoryProvider).obtenerTipoCambio();
});

/// Resultado del preliminar para el filtro indicado.
final preliminarProvider = FutureProvider.autoDispose
    .family<List<PreliminarComisionEntity>, FiltroPreliminar>((ref, f) async {
      final repo = ref.watch(comisionesRepositoryProvider);
      switch (f.modalidad) {
        case ModalidadPreliminar.interno:
          return repo.preliminarInterno(mes: f.mes, anio: f.anio, tc: f.tc);
        case ModalidadPreliminar.externo:
          return repo.preliminarExterno(mes: f.mes, anio: f.anio, tc: f.tc);
        case ModalidadPreliminar.dinamicaAnterior:
          return repo.preliminarDinamicaAnterior(
            mes: f.mes,
            anio: f.anio,
            tc: f.tc,
          );
        case ModalidadPreliminar.dinamicaVigente:
          return repo.preliminarDinamicaVigente(
            mes: f.mes,
            anio: f.anio,
            tc: f.tc,
          );
      }
    });

// ═══════════════════════════════════════════════════════════════════════
// Carga y ejecucion del periodo
// ═══════════════════════════════════════════════════════════════════════

@immutable
class ClavePeriodo {
  const ClavePeriodo({
    required this.mes,
    required this.anio,
    required this.esInterno,
  });

  final int mes;
  final int anio;

  /// 1 vendedores internos, 0 externos.
  final int esInterno;

  ClavePeriodo copyWith({int? mes, int? anio, int? esInterno}) => ClavePeriodo(
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
    esInterno: esInterno ?? this.esInterno,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClavePeriodo &&
          other.mes == mes &&
          other.anio == anio &&
          other.esInterno == esInterno;

  @override
  int get hashCode => Object.hash(mes, anio, esInterno);
}

/// Periodo seleccionado en la pestana de ejecucion.
final periodoEjecucionProvider = StateProvider.autoDispose<ClavePeriodo>((ref) {
  final hoy = DateTime.now();
  return ClavePeriodo(mes: hoy.month, anio: hoy.year, esInterno: 1);
});

/// Estado del periodo: si ya se ejecuto, cuantos registros y por cuanto.
final estadoPeriodoProvider = FutureProvider.autoDispose
    .family<EstadoPeriodoEntity?, ClavePeriodo>((ref, clave) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerEstadoPeriodo(
            mes: clave.mes,
            anio: clave.anio,
            esInterno: clave.esInterno,
          );
    });

/// Notas cerradas sin pagar, con sus totales por vendedor.
///
/// El SP filtra internamente por bd = 1 y excluye al codVendedor 2: son reglas
/// escritas dentro del SP, no parametros que la pantalla pueda cambiar.
final notasPendientesProvider =
    FutureProvider.autoDispose<List<NotaPendienteEntity>>((ref) async {
      return ref.watch(comisionesRepositoryProvider).obtenerNotasPendientes();
    });

/// Tramos de comision por dias de pago. La lectura es libre; la escritura la
/// restringe el backend a ROLE_ADM.
final rangosComisionProvider =
    FutureProvider.autoDispose<List<ComisionPorRangoEntity>>((ref) async {
      return ref.watch(comisionesRepositoryProvider).obtenerRangosComision();
    });

/// Identifica UNA fila del preliminar, para pedir su desglose de notas.
///
/// Lleva == y hashCode porque es la clave de un provider family: sin eso cada
/// apertura del dialogo seria una instancia nueva y volveria a pegarle al
/// backend aunque sea la misma fila.
@immutable
class FiltroNotaPreliminar {
  const FiltroNotaPreliminar({
    required this.idVendedor,
    required this.mes,
    required this.anio,
    required this.comision,
    required this.modalidad,
  });

  final int idVendedor;
  final int mes;
  final int anio;

  /// Factor en base 1, tal como vino en la fila.
  final double comision;

  /// La pestana desde la que se pide. El backend autoriza con su boton.
  final ModalidadPreliminar modalidad;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroNotaPreliminar &&
          other.idVendedor == idVendedor &&
          other.mes == mes &&
          other.anio == anio &&
          other.comision == comision &&
          other.modalidad == modalidad;

  @override
  int get hashCode => Object.hash(idVendedor, mes, anio, comision, modalidad);
}

/// Las notas que componen una fila del preliminar.
final notasDeFilaProvider = FutureProvider.autoDispose
    .family<List<NotaPreliminarEntity>, FiltroNotaPreliminar>((ref, f) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .notasDeFila(
            idVendedor: f.idVendedor,
            mes: f.mes,
            anio: f.anio,
            comision: f.comision,
            modalidad: f.modalidad.name,
          );
    });

/// Politicas por familia, con su historial de vigencias.
final politicaFamiliasProvider =
    FutureProvider.autoDispose<List<FamiliaPoliticaEntity>>((ref) async {
      return ref.watch(comisionesRepositoryProvider).obtenerPoliticaFamilias();
    });

/// Solo lo que rige hoy. Sirve para que la pantalla pueda decir «esto es lo que
/// se esta aplicando» sin que el usuario tenga que interpretar las vigencias.
final politicaFamiliasVigentesProvider =
    FutureProvider.autoDispose<List<FamiliaPoliticaEntity>>((ref) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerPoliticaFamiliasVigentes();
    });

final vendedoresExentosProvider =
    FutureProvider.autoDispose<List<VendedorExentoEntity>>((ref) async {
      return ref.watch(comisionesRepositoryProvider).obtenerVendedoresExentos();
    });

final clientesExcluidosProvider =
    FutureProvider.autoDispose<List<ClienteExcluidoEntity>>((ref) async {
      return ref.watch(comisionesRepositoryProvider).obtenerClientesExcluidos();
    });

/// Familias de SAP que todavia no tienen politica. Es lo que se ofrece al
/// agregar: mostrar las que ya estan registradas invitaria a crear una segunda
/// regla para la misma familia.
final familiasSapDisponiblesProvider =
    FutureProvider.autoDispose<List<FamiliaSapOpcionEntity>>((ref) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerFamiliasSap(soloDisponibles: true);
    });

/// Filtro del detalle de lo descontado. Lleva == y hashCode porque es la clave
/// de un provider family: sin eso cada rebuild pediria de nuevo al backend.
@immutable
class FiltroDescuento {
  const FiltroDescuento({
    required this.accion,
    this.mes,
    this.anio,
    this.origen,
    this.idVendedor,
  });

  /// P periodo abierto, H historico, R resumen.
  final String accion;
  final int? mes;
  final int? anio;
  final String? origen;
  final int? idVendedor;

  FiltroDescuento copyWith({
    String? accion,
    int? mes,
    int? anio,
    String? origen,
    bool limpiarOrigen = false,
  }) => FiltroDescuento(
    accion: accion ?? this.accion,
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
    origen: limpiarOrigen ? null : (origen ?? this.origen),
    idVendedor: idVendedor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroDescuento &&
          other.accion == accion &&
          other.mes == mes &&
          other.anio == anio &&
          other.origen == origen &&
          other.idVendedor == idVendedor;

  @override
  int get hashCode => Object.hash(accion, mes, anio, origen, idVendedor);
}

final descuentoDetalleProvider = FutureProvider.autoDispose
    .family<List<DescuentoDetalleEntity>, FiltroDescuento>((ref, f) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerDescuentoDetalle(
            accion: f.accion,
            mes: f.mes,
            anio: f.anio,
            origen: f.origen,
            idVendedor: f.idVendedor,
          );
    });

// ═══════════════════════════════════════════════════════════════════════
// Items congelados al ejecutar el pago
//
// Es el otro lado del preliminar. El preliminar lista notas cerradas y SIN
// pagar; esto lee lo que quedo escrito UNA vez al ejecutar el periodo y nunca
// mas se toca.
// ═══════════════════════════════════════════════════════════════════════

/// Identifica el detalle de items congelados que se quiere ver.
///
/// Lleva == y hashCode porque es la clave de un provider family: sin eso cada
/// apertura del dialogo seria una instancia nueva y volveria a pegarle al
/// backend aunque sea el mismo periodo.
///
/// QUE ENTRA EN LA CLAVE Y QUE NO. Entra lo que cambia lo que DEVUELVE el SP y
/// no se puede derivar de lo ya traido; no entra lo que es un recorte de un
/// payload que ya esta en memoria.
///
///   - [docNum] y [origen] entran. Son parametros del SP -@docNum y @origen,
///     que aplican tanto en la rama 'L' como en la 'R'- y son la unica forma
///     de que el listado y el resumen hablen de la MISMA nota: con el resumen
///     clavado al periodo, la lista mostraba una linea y el titular seguia
///     contando el mes entero.
///   - [origen] no es decorativo: docNum NO es unico entre empresas -198 casos
///     medidos en un mismo periodo- asi que una nota se identifica con el par
///     (origen, docNum) y no con el numero solo. Ademas es lo unico que separa
///     ESPPAPEL de IMPEXPAP/PAPIRUS/PRODUCTIVA PAPEL, que se congelan las
///     cuatro con esInterno = 1.
///   - «solo lo excluido» NO entra, y esa es la diferencia con la version
///     anterior. Es un `where` sobre `excluido`, que viene en cada fila: con
///     el filtro en la clave, tildar el chip destruia la entrada del cache
///     -el provider es autoDispose- y destildarlo volvia a bajar el mes
///     entero. Ida y vuelta eran dos descargas para no traer un solo dato
///     nuevo.
@immutable
class FiltroItemsPagados {
  const FiltroItemsPagados({
    required this.mes,
    required this.anio,
    required this.esInterno,
    this.idPagado,
    this.docNum,
    this.origen,
  });

  final int mes;
  final int anio;

  /// 1 internos, 0 externos. Sale de ModalidadPreliminar.esInterno o de
  /// ClavePeriodo.esInterno, que son las dos formas en que el modulo ya lo
  /// tiene resuelto.
  final int esInterno;

  /// Una nota puntual de tcom_pagado. Null = todo el periodo, que es el caso
  /// normal: hoy ninguna pantalla conoce el idPagado.
  final int? idPagado;

  /// Numero de documento SAP. Se acompania SIEMPRE de [origen]: el mismo
  /// docNum aparece en dos empresas distintas dentro del mismo periodo.
  final int? docNum;

  /// Sistema de origen de la nota: ESPPAPEL, IMPEXPAP, PAPIRUS, PRODUCTIVA
  /// PAPEL. Null = todos.
  final String? origen;

  /// [limpiarNota] existe porque un `docNum: null` en copyWith no se distingue
  /// de «no lo toques»: es el mismo criterio que ya usa FiltroDescuento con
  /// limpiarOrigen.
  FiltroItemsPagados copyWith({
    int? mes,
    int? anio,
    int? esInterno,
    int? idPagado,
    int? docNum,
    String? origen,
    bool limpiarNota = false,
  }) => FiltroItemsPagados(
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
    esInterno: esInterno ?? this.esInterno,
    idPagado: idPagado ?? this.idPagado,
    docNum: limpiarNota ? null : (docNum ?? this.docNum),
    origen: limpiarNota ? null : (origen ?? this.origen),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroItemsPagados &&
          other.mes == mes &&
          other.anio == anio &&
          other.esInterno == esInterno &&
          other.idPagado == idPagado &&
          other.docNum == docNum &&
          other.origen == origen;

  @override
  int get hashCode => Object.hash(mes, anio, esInterno, idPagado, docNum, origen);
}

/// Los items que quedaron congelados al ejecutar el pago.
final itemsPagadosProvider = FutureProvider.autoDispose
    .family<List<PagadoItemEntity>, FiltroItemsPagados>((ref, f) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerItemsPagados(
            mes: f.mes,
            anio: f.anio,
            esInterno: f.esInterno,
            idPagado: f.idPagado,
            docNum: f.docNum,
            origen: f.origen,
          );
    });

/// El reparto por motivo. Es lo que dice de un vistazo cuanto quedo AFUERA.
///
/// Se pide al SP y no se cuenta sobre el listado porque el listado es la
/// respuesta a una pregunta y el resumen a otra: el SP suma sobre la tabla,
/// que es la fuente, y no sobre lo que este dialogo haya decidido mostrar.
///
/// Va con la MISMA clave que el listado a proposito: con @docNum y @origen en
/// las dos ramas, la lista y el titular no pueden hablar de notas distintas.
final resumenItemsPagadosProvider = FutureProvider.autoDispose
    .family<List<PagadoItemResumenEntity>, FiltroItemsPagados>((ref, f) async {
      return ref
          .watch(comisionesRepositoryProvider)
          .obtenerResumenItemsPagados(
            mes: f.mes,
            anio: f.anio,
            esInterno: f.esInterno,
            idPagado: f.idPagado,
            docNum: f.docNum,
            origen: f.origen,
          );
    });

/// El corte del periodo: la fila que explica un cero.
///
/// Va con ClavePeriodo y no con FiltroItemsPagados porque el corte es por
/// periodo: ni idPagado ni la nota elegida lo cambian, y con la clave entera
/// se volveria a pedir cada vez que se toca un filtro del listado.
final corteItemsPagadosProvider = FutureProvider.autoDispose
    .family<PagadoItemCorteEntity?, ClavePeriodo>((ref, clave) async {
      final cortes = await ref
          .watch(comisionesRepositoryProvider)
          .obtenerCorteItemsPagados(
            mes: clave.mes,
            anio: clave.anio,
            esInterno: clave.esInterno,
          );
      // Con los tres filtros puestos hay a lo sumo una fila: la tabla tiene
      // UNIQUE (anioPago, mesPago, esInterno). Vacio significa que ese periodo
      // nunca se congelo, que es informacion distinta de un corte en cero.
      return cortes.isEmpty ? null : cortes.first;
    });
