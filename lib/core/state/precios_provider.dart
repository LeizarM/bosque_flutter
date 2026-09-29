import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/precios_impl.dart';
import 'package:bosque_flutter/domain/entities/articulo_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/clasificacion_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/color_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/costo_iva_it_entity.dart';
import 'package:bosque_flutter/domain/entities/costo_sugerido_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_fam_tipo_rango_gram_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_familia_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/historial_costo_familia_entity.dart';
import 'package:bosque_flutter/domain/entities/porcentaje_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/precio_propuesta_entity.dart';
import 'package:bosque_flutter/domain/entities/presentacion_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/propuesta_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_ext_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/rango_gramaje_entity.dart';
import 'package:bosque_flutter/domain/entities/tc_ancla_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/vista_propuesta_entity.dart';
import 'package:bosque_flutter/domain/repositories/precios_repository.dart';

/// Repositorio del módulo de Precios (tpr), declarado UNA vez y tipado contra la
/// interfaz (no `PreciosImpl`): la pantalla no conoce la implementación y una
/// prueba puede sustituirla con un override (TPEX instancia la concreta en
/// más de veinticinco lugares y por eso no se puede probar).
final preciosRepositoryProvider = Provider<PreciosRepository>(
  (ref) => PreciosImpl(),
);

// Claves de los providers family: Riverpod las compara con ==. Sin == y
// hashCode propios, dos filtros idénticos serían dos instancias y cada
// reconstrucción volvería a pedir los datos al backend.

/// Filtro de la búsqueda de familias de producto. Todos los campos son
/// nulables a propósito: null NO filtra; un cero SÍ filtra (por cero) y no
/// devuelve nada, error típico de la pantalla vieja.
@immutable
class FiltroFamilias {
  const FiltroFamilias({
    this.codigoFamilia,
    this.idGrpFamiliaSap,
    this.idProveedorSap,
    this.idPresentacion,
    this.idTipo,
    this.idRangoGram,
    this.formato,
    this.gramaje,
    this.idColor,
    this.estado,
  });

  final int? codigoFamilia;
  final BigInt? idGrpFamiliaSap;
  final BigInt? idProveedorSap;
  final BigInt? idPresentacion;
  final BigInt? idTipo;
  final BigInt? idRangoGram;
  final String? formato;
  final String? gramaje;
  final BigInt? idColor;

  /// 1 activas, 0 inactivas, null todas.
  final int? estado;

  /// Cada campo lleva su bandera de limpieza: un null en `copyWith` no se
  /// distingue de «no lo toques», y aquí quitar un filtro es legítimo.
  FiltroFamilias copyWith({
    int? codigoFamilia,
    BigInt? idGrpFamiliaSap,
    BigInt? idProveedorSap,
    BigInt? idPresentacion,
    BigInt? idTipo,
    BigInt? idRangoGram,
    String? formato,
    String? gramaje,
    BigInt? idColor,
    int? estado,
    bool limpiarCodigoFamilia = false,
    bool limpiarGrupoFamilia = false,
    bool limpiarProveedor = false,
    bool limpiarPresentacion = false,
    bool limpiarTipo = false,
    bool limpiarRangoGram = false,
    bool limpiarFormato = false,
    bool limpiarGramaje = false,
    bool limpiarColor = false,
    bool limpiarEstado = false,
  }) => FiltroFamilias(
    codigoFamilia:
        limpiarCodigoFamilia ? null : (codigoFamilia ?? this.codigoFamilia),
    idGrpFamiliaSap:
        limpiarGrupoFamilia ? null : (idGrpFamiliaSap ?? this.idGrpFamiliaSap),
    idProveedorSap:
        limpiarProveedor ? null : (idProveedorSap ?? this.idProveedorSap),
    idPresentacion:
        limpiarPresentacion ? null : (idPresentacion ?? this.idPresentacion),
    idTipo: limpiarTipo ? null : (idTipo ?? this.idTipo),
    idRangoGram: limpiarRangoGram ? null : (idRangoGram ?? this.idRangoGram),
    formato: limpiarFormato ? null : (formato ?? this.formato),
    gramaje: limpiarGramaje ? null : (gramaje ?? this.gramaje),
    idColor: limpiarColor ? null : (idColor ?? this.idColor),
    estado: limpiarEstado ? null : (estado ?? this.estado),
  );

  /// Si no hay ningun criterio puesto, la consulta trae el catalogo entero.
  bool get sinCriterios =>
      codigoFamilia == null &&
      idGrpFamiliaSap == null &&
      idProveedorSap == null &&
      idPresentacion == null &&
      idTipo == null &&
      idRangoGram == null &&
      (formato == null || formato!.isEmpty) &&
      (gramaje == null || gramaje!.isEmpty) &&
      idColor == null &&
      estado == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroFamilias &&
          other.codigoFamilia == codigoFamilia &&
          other.idGrpFamiliaSap == idGrpFamiliaSap &&
          other.idProveedorSap == idProveedorSap &&
          other.idPresentacion == idPresentacion &&
          other.idTipo == idTipo &&
          other.idRangoGram == idRangoGram &&
          other.formato == formato &&
          other.gramaje == gramaje &&
          other.idColor == idColor &&
          other.estado == estado;

  @override
  int get hashCode => Object.hash(
    codigoFamilia,
    idGrpFamiliaSap,
    idProveedorSap,
    idPresentacion,
    idTipo,
    idRangoGram,
    formato,
    gramaje,
    idColor,
    estado,
  );
}

/// Clave de la consulta de artículos por familias. Envuelve la lista porque
/// `List` compara por identidad: dos listas con los mismos códigos no serían
/// la misma clave y cada rearmado del listado dispararía una descarga nueva.
@immutable
class ClaveFamilias {
  ClaveFamilias(List<int> codigos)
    : codigos = List<int>.unmodifiable(List<int>.of(codigos)..sort());

  /// Ordenados para que el orden en que el usuario marcó las familias no genere
  /// dos entradas distintas de la caché para la misma consulta.
  final List<int> codigos;

  bool get vacia => codigos.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaveFamilias && listEquals(other.codigos, codigos);

  @override
  int get hashCode => Object.hashAll(codigos);
}

/// Clave natural de la configuracion de gramaje: un grupo de familia SAP y un
/// tipo de papel. Los dos son obligatorios porque esa consulta no admite «sin
/// filtro»: un resultado vacio no se distinguiria de «no hay configuracion».
@immutable
class ClaveGrupoTipo {
  const ClaveGrupoTipo({required this.idGrpFamiliaSap, required this.idTipo});

  final int idGrpFamiliaSap;
  final int idTipo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaveGrupoTipo &&
          other.idGrpFamiliaSap == idGrpFamiliaSap &&
          other.idTipo == idTipo;

  @override
  int get hashCode => Object.hash(idGrpFamiliaSap, idTipo);
}

/// Filtro del ABM de grupos de familia SAP. Los tres codigos son texto: admiten
/// letras y ceros a la izquierda, asi que no se convierten a numero.
@immutable
class FiltroGrupoFamiliaSap {
  const FiltroGrupoFamiliaSap({
    this.idGrpFamiliaSap,
    this.codGrpFamSap,
    this.codGrpFamSapEpp,
    this.codGrpFamSapProdPap,
    this.grpFam,
    this.alias,
  });

  final BigInt? idGrpFamiliaSap;
  final String? codGrpFamSap;
  final String? codGrpFamSapEpp;
  final String? codGrpFamSapProdPap;
  final String? grpFam;
  final String? alias;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroGrupoFamiliaSap &&
          other.idGrpFamiliaSap == idGrpFamiliaSap &&
          other.codGrpFamSap == codGrpFamSap &&
          other.codGrpFamSapEpp == codGrpFamSapEpp &&
          other.codGrpFamSapProdPap == codGrpFamSapProdPap &&
          other.grpFam == grpFam &&
          other.alias == alias;

  @override
  int get hashCode => Object.hash(
    idGrpFamiliaSap,
    codGrpFamSap,
    codGrpFamSapEpp,
    codGrpFamSapProdPap,
    grpFam,
    alias,
  );
}

/// Filtro del ABM de proveedores externos SAP.
@immutable
class FiltroProveedorSap {
  const FiltroProveedorSap({
    this.idProveedorSap,
    this.codProvExtSap,
    this.proveedorExtSap,
  });

  final BigInt? idProveedorSap;
  final String? codProvExtSap;
  final String? proveedorExtSap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroProveedorSap &&
          other.idProveedorSap == idProveedorSap &&
          other.codProvExtSap == codProvExtSap &&
          other.proveedorExtSap == proveedorExtSap;

  @override
  int get hashCode =>
      Object.hash(idProveedorSap, codProvExtSap, proveedorExtSap);
}

/// Filtro del ABM de presentaciones.
@immutable
class FiltroPresentaciones {
  const FiltroPresentaciones({
    this.idPresentacion,
    this.presentacion,
    this.estado,
  });

  final BigInt? idPresentacion;
  final String? presentacion;
  final int? estado;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroPresentaciones &&
          other.idPresentacion == idPresentacion &&
          other.presentacion == presentacion &&
          other.estado == estado;

  @override
  int get hashCode => Object.hash(idPresentacion, presentacion, estado);
}

/// Clave de la validacion de vpp de una lista de precios.
///
/// [idClasificacion] es la fila que se esta editando y hay que excluir del
/// choque: una lista no colisiona consigo misma.
@immutable
class ClaveVpp {
  const ClaveVpp({required this.vpp, this.idClasificacion});

  final int vpp;
  final BigInt? idClasificacion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaveVpp &&
          other.vpp == vpp &&
          other.idClasificacion == idClasificacion;

  @override
  int get hashCode => Object.hash(vpp, idClasificacion);
}

/// Filtro de las filas crudas de tpr_porcentaje.
///
/// Los dos campos son nulables: null NO filtra, un cero SI filtra y no
/// devuelve nada.
@immutable
class FiltroPorcentajes {
  const FiltroPorcentajes({this.codigoFamilia, this.idClasificacion});

  final int? codigoFamilia;
  final BigInt? idClasificacion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroPorcentajes &&
          other.codigoFamilia == codigoFamilia &&
          other.idClasificacion == idClasificacion;

  @override
  int get hashCode => Object.hash(codigoFamilia, idClasificacion);
}

/// Filtro del listado plano de listas de precios.
@immutable
class FiltroClasificaciones {
  const FiltroClasificaciones({this.idClasificacion, this.codSucursal});

  final BigInt? idClasificacion;
  final BigInt? codSucursal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroClasificaciones &&
          other.idClasificacion == idClasificacion &&
          other.codSucursal == codSucursal;

  @override
  int get hashCode => Object.hash(idClasificacion, codSucursal);
}

// Lecturas: propuestas y circuito de autorización. Son FutureProvider: la
// pantalla usa .when(...) y no lleva banderas de carga manuales.

/// Propuestas con su estado de autorizacion. Es la grilla principal.
final propuestasParaAutorizarProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerPropuestasParaAutorizar();
    });

/// Estados posibles de una propuesta, para los combos.
final estadosPropuestaProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerEstadosPropuesta();
    });

/// Costo de flete de transporte por sucursal.
final costosFleteProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerCostosFlete();
    });

/// Vista preliminar con las mismas filas que el PDF de la propuesta y los precios
/// por unidad del Excel de la generación (incluye propuestas por artículo).
final vistaPropuestaProvider = FutureProvider.autoDispose
    .family<VistaPropuestaEntity, BigInt>((ref, idPropuesta) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerVistaPropuesta(idPropuesta);
    });

// Lecturas: familias, precios y artículos

/// Familias de producto con su descripcion resuelta, segun el filtro.
final familiasProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, FiltroFamilias>((ref, f) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerFamilias(
            codigoFamilia: f.codigoFamilia,
            idGrpFamiliaSap: f.idGrpFamiliaSap,
            idProveedorSap: f.idProveedorSap,
            idPresentacion: f.idPresentacion,
            idTipo: f.idTipo,
            idRangoGram: f.idRangoGram,
            formato: f.formato,
            gramaje: f.gramaje,
            idColor: f.idColor,
            estado: f.estado,
          );
    });

/// Familias que pertenecen a un grupo de familia SAP.
final familiasPorGrupoProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, BigInt>((ref, idGrpFamiliaSap) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerFamiliasPorGrupo(idGrpFamiliaSap);
    });

/// Una familia por su codigo. Null si no existe.
final familiaProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, int>((ref, codigoFamilia) async {
      return ref.watch(preciosRepositoryProvider).obtenerFamilia(codigoFamilia);
    });

/// Precios vigentes por tonelada de una familia, listos para la repreciacion.
final preciosTonPorFamiliaProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, codigoFamilia) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerPreciosTonPorFamilia(codigoFamilia);
    });

/// Artículos del catálogo de las familias indicadas. Con la clave vacía devuelve
/// lista vacía sin llamar al backend: «los artículos de ninguna familia» no
/// tiene sentido y el SP contesta con el catálogo entero.
final articulosPorFamiliasProvider = FutureProvider.autoDispose
    .family<List<ArticuloPrecioEntity>, ClaveFamilias>((ref, clave) async {
      if (clave.vacia) return const <ArticuloPrecioEntity>[];
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerArticulosPorFamilias(clave.codigos);
    });

// Catálogos

/// Colores, activos e inactivos. Es la grilla del ABM.
final coloresProvider = FutureProvider.autoDispose<List<ColorProductoEntity>>((
  ref,
) async {
  return ref.watch(preciosRepositoryProvider).obtenerColores();
});

/// Solo los colores activos: la lista que alimenta los combos.
final coloresActivosProvider =
    FutureProvider.autoDispose<List<ColorProductoEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerColoresActivos();
    });

/// Tipos de papel, activos e inactivos.
final tiposProductoProvider =
    FutureProvider.autoDispose<List<TipoProductoEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerTipos();
    });

/// Solo los tipos activos, para los combos.
final tiposProductoActivosProvider =
    FutureProvider.autoDispose<List<TipoProductoEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerTiposActivos();
    });

/// Catalogo completo de presentaciones.
final presentacionesProvider =
    FutureProvider.autoDispose<List<PresentacionProductoEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerPresentaciones();
    });

/// Presentaciones activas, para los combos de familia.
final presentacionesActivasProvider =
    FutureProvider.autoDispose<List<PresentacionProductoEntity>>((ref) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerPresentacionesActivas();
    });

/// Presentaciones filtradas.
final presentacionesFiltradasProvider = FutureProvider.autoDispose
    .family<List<PresentacionProductoEntity>, FiltroPresentaciones>((
      ref,
      f,
    ) async {
      return ref
          .watch(preciosRepositoryProvider)
          .buscarPresentaciones(
            idPresentacion: f.idPresentacion,
            presentacion: f.presentacion,
            estado: f.estado,
          );
    });

/// Rangos de gramaje, ordenados por limite inferior.
final rangosGramajeProvider =
    FutureProvider.autoDispose<List<RangoGramajeEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerRangosGramaje();
    });

/// Los mismos rangos, pensados para combos.
final rangosGramajeComboProvider =
    FutureProvider.autoDispose<List<RangoGramajeEntity>>((ref) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerRangosGramajeParaCombo();
    });

/// Rangos configurados para un grupo de familia SAP y un tipo de papel.
final rangosPorGrupoYTipoProvider = FutureProvider.autoDispose
    .family<List<RangoGramajeEntity>, ClaveGrupoTipo>((ref, clave) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerRangosPorGrupoFamiliaYTipo(
            idGrpFamiliaSap: clave.idGrpFamiliaSap,
            idTipo: clave.idTipo,
          );
    });

/// Grupos de familia SAP con su equivalencia de codigo por empresa.
final gruposFamiliaSapProvider =
    FutureProvider.autoDispose<List<GrupoFamiliaSapEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerGruposFamiliaSap();
    });

/// Grupos de familia SAP filtrados.
final gruposFamiliaSapFiltradosProvider = FutureProvider.autoDispose
    .family<List<GrupoFamiliaSapEntity>, FiltroGrupoFamiliaSap>((ref, f) async {
      return ref
          .watch(preciosRepositoryProvider)
          .buscarGruposFamiliaSap(
            idGrpFamiliaSap: f.idGrpFamiliaSap,
            codGrpFamSap: f.codGrpFamSap,
            codGrpFamSapEpp: f.codGrpFamSapEpp,
            codGrpFamSapProdPap: f.codGrpFamSapProdPap,
            grpFam: f.grpFam,
            alias: f.alias,
          );
    });

/// Proveedores SAP para el combo de familias: solo id y nombre vienen con dato.
final proveedoresSapComboProvider =
    FutureProvider.autoDispose<List<ProveedorExtSapEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerProveedoresSap();
    });

/// Proveedores externos SAP completos. Es la grilla del ABM.
final proveedoresSapProvider =
    FutureProvider.autoDispose<List<ProveedorExtSapEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerProveedores();
    });

// Sincronización de los catálogos con SAP: p_abm_producto 'H' trae de SAP los
// proveedores y grupos de familia nuevos. El sistema anterior la corría sola
// al abrir la pantalla de precios; aquí corre una vez por sesión (al abrir la
// ficha de una familia) y a petición desde Catálogos ("Traer de SAP").

enum FaseSincronizacionSap { sinCorrer, corriendo, lista, fallo }

@immutable
class EstadoSincronizacionSap {
  const EstadoSincronizacionSap(this.fase, {this.error});

  final FaseSincronizacionSap fase;

  /// El error crudo del ultimo intento; la pantalla lo traduce.
  final Object? error;
}

class SincronizacionSapNotifier
    extends StateNotifier<EstadoSincronizacionSap> {
  SincronizacionSapNotifier(this._ref)
    : super(const EstadoSincronizacionSap(FaseSincronizacionSap.sinCorrer));

  final Ref _ref;

  /// Corre si en esta sesion todavia no corrio bien. Es lo que llama la ficha
  /// al abrirse: no vuelve a consultar SAP cada vez que se abre una familia.
  Future<void> asegurar() async {
    if (state.fase == FaseSincronizacionSap.lista) return;
    await correr();
  }

  /// Corre siempre (salvo que ya este corriendo). Devuelve si salio bien.
  Future<bool> correr() async {
    if (state.fase == FaseSincronizacionSap.corriendo) return false;
    state = const EstadoSincronizacionSap(FaseSincronizacionSap.corriendo);
    try {
      await _ref.read(preciosRepositoryProvider).sincronizarCatalogosSap();
      if (!mounted) return true;
      state = const EstadoSincronizacionSap(FaseSincronizacionSap.lista);
      // Lo que SAP pudo haber agregado: los combos de la ficha y las
      // pestanias de Catalogos.
      _ref.invalidate(gruposFamiliaSapProvider);
      _ref.invalidate(proveedoresSapComboProvider);
      _ref.invalidate(proveedoresSapProvider);
      return true;
    } catch (e) {
      if (mounted) {
        state = EstadoSincronizacionSap(FaseSincronizacionSap.fallo, error: e);
      }
      return false;
    }
  }
}

/// Sin autoDispose a proposito: el estado dura la sesion.
final sincronizacionSapProvider = StateNotifierProvider<
  SincronizacionSapNotifier,
  EstadoSincronizacionSap
>((ref) => SincronizacionSapNotifier(ref));

/// Proveedores externos SAP filtrados.
final proveedoresSapFiltradosProvider = FutureProvider.autoDispose
    .family<List<ProveedorExtSapEntity>, FiltroProveedorSap>((ref, f) async {
      return ref
          .watch(preciosRepositoryProvider)
          .buscarProveedores(
            idProveedorSap: f.idProveedorSap,
            codProvExtSap: f.codProvExtSap,
            proveedorExtSap: f.proveedorExtSap,
          );
    });

// Parámetros de gramaje (tpr_grupoFamTipoRangoGram): sin PK ni IDENTITY, la fila
// se identifica por la clave natural (idGrpFamiliaSap, idTipo).

/// Todas las asignaciones cargadas, crudas.
final parametrosGramajeProvider =
    FutureProvider.autoDispose<List<GrupoFamTipoRangoGramEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerParametrosGramaje();
    });

/// Las asignaciones de un grupo de familia, una por tipo de papel.
final parametrosPorGrupoFamiliaProvider = FutureProvider.autoDispose
    .family<List<GrupoFamTipoRangoGramEntity>, BigInt>((
      ref,
      idGrpFamiliaSap,
    ) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerParametrosPorGrupoFamilia(idGrpFamiliaSap);
    });

/// La fila de una clave natural. Null si ese par todavia no esta configurado.
final parametroGramajeProvider = FutureProvider.autoDispose
    .family<GrupoFamTipoRangoGramEntity?, ClaveGrupoTipo>((ref, clave) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerParametroGramaje(
            idGrpFamiliaSap: clave.idGrpFamiliaSap,
            idTipo: clave.idTipo,
          );
    });

/// La tabla pivoteada: un renglon por grupo con sus columnas Liviano, Mediano
/// y Pesado. Es lo que se muestra; el listado crudo es para editar.
final parametrosGramajePivoteProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerParametrosGramajePivote();
    });

// Listas de precios

/// Listado plano de listas de precios.
final clasificacionesPrecioProvider = FutureProvider.autoDispose
    .family<List<ClasificacionPrecioEntity>, FiltroClasificaciones>((
      ref,
      f,
    ) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerClasificacionesPrecio(
            idClasificacion: f.idClasificacion,
            codSucursal: f.codSucursal,
          );
    });

/// Listas de precios con el nombre de su sucursal. Es la grilla del ABM.
final clasificacionesConSucursalProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerClasificacionesConSucursal();
    });

/// Los vpp ya usados. Sirve para proponer el siguiente y para validar en
/// pantalla antes de guardar.
final vppsUsadosProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  return ref.watch(preciosRepositoryProvider).obtenerVppsUsados();
});

/// Si el vpp ya esta tomado por otra lista. Que exista no es un error: es la
/// respuesta, y la pantalla decide que hacer con ella.
final existeVppProvider = FutureProvider.autoDispose.family<bool, ClaveVpp>((
  ref,
  clave,
) async {
  return ref
      .watch(preciosRepositoryProvider)
      .existeVpp(vpp: clave.vpp, idClasificacion: clave.idClasificacion);
});

// Porcentajes por familia y lista de precios (tpr_porcentaje).
// El margen está en PUNTOS PORCENTUALES: 12.5 es 12,5%.
// Las tres grillas devuelven mapas porque muestran el cruce con tb_sucursal y
// tpr_clasificacionPrecio (nombre de sucursal, de lista, vpp), que no son
// columnas de la tabla; además el margen llega en la clave `porcentaje` y no
// en `porcen`. La lectura de la tabla cruda sí devuelve la entity.

/// Grilla de porcentajes de una familia: una fila por sucursal y lista de precios
/// (dlgPorcen del sistema anterior). Claves: codSucursal, nombre, idClasificacion,
/// nombrePrecio, vpp, idPorcen, porcentaje. Las listas sin porcentaje vuelven con
/// idPorcen y porcentaje en cero: son altas pendientes, no un error.
final porcentajesPorFamiliaProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, codigoFamilia) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerPorcentajesPorFamilia(codigoFamilia);
    });

/// Las listas de precio activas con el porcentaje en cero: la grilla
/// "Porcentaje por familia" del alta de una familia. Mismas claves que
/// [porcentajesPorFamiliaProvider], sin idPorcen.
final listasParaPorcentajeProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerListasParaPorcentaje();
    });

/// El historial del costo de una familia, la aprobacion mas reciente primero.
final historialCostoFamiliaProvider = FutureProvider.autoDispose
    .family<List<HistorialCostoFamiliaEntity>, int>((ref, codigoFamilia) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerHistorialCosto(codigoFamilia);
    });

/// Destinos de la edición masiva por grupo de familia SAP: listas de precios
/// activas con el porcentaje en cero (el grid de dlgPorcGrupo). No lee
/// tpr_porcentaje (todas las filas son altas) ni depende del grupo, aunque el
/// id se exija. Las familias alcanzadas (excluibles con una marca) salen de
/// [familiasPorGrupoProvider]. El backend no ordena: el orden por vpp y
/// sucursal lo pone la pantalla.
final destinosPorcentajeGrupoProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, BigInt>((ref, idGrpFamiliaSap) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerDestinosPorcentajeGrupo(idGrpFamiliaSap);
    });

/// Las listas de precios que todavia no tienen porcentaje para una familia.
final porcentajesFaltantesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, codigoFamilia) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerPorcentajesFaltantes(codigoFamilia);
    });

/// Las filas crudas de tpr_porcentaje. No completa las listas faltantes.
final porcentajesProvider = FutureProvider.autoDispose
    .family<List<PorcentajePrecioEntity>, FiltroPorcentajes>((ref, f) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerPorcentajes(
            codigoFamilia: f.codigoFamilia,
            idClasificacion: f.idClasificacion,
          );
    });

/// Convierte una fila de cualquiera de las grillas en la entity que se guarda.
///
/// [codigoFamilia] viene aparte porque las grillas no lo traen: la de dlgPorcen
/// es de UNA familia y la de dlgPorcGrupo vale para todas las del grupo
/// (edición masiva). `audUsuario` va en cero: el backend lo toma del token JWT
/// y la capa de datos lo saca del cuerpo antes de enviarlo.
PorcentajePrecioEntity porcentajeDesdeFila(
  Map<String, dynamic> fila, {
  required int codigoFamilia,
}) => PorcentajePrecioEntity(
  // En la grilla de dlgPorcGrupo idPorcen no viene: queda en cero y la
  // escritura es un alta, que es lo correcto para esa pantalla.
  idPorcen: BigInt.from((fila['idPorcen'] as num?)?.toInt() ?? 0),
  codigoFamilia: codigoFamilia,
  idClasificacion: BigInt.from((fila['idClasificacion'] as num?)?.toInt() ?? 0),
  // La clave de la grilla es `porcentaje`; la de la tabla, `porcen`.
  porcen: (fila['porcentaje'] as num?)?.toDouble() ?? 0.0,
  audUsuario: BigInt.zero,
);

/// Una violacion de la regla de porcentajes ascendentes por sucursal.
@immutable
class ConflictoPorcentaje {
  const ConflictoPorcentaje({
    required this.codSucursal,
    required this.nombreSucursal,
    required this.nombrePrecio,
    required this.porcen,
    required this.nombrePrecioAnterior,
    required this.porcenAnterior,
  });

  final BigInt codSucursal;
  final String nombreSucursal;

  /// La lista de precios que rompe el orden, y su margen.
  final String nombrePrecio;
  final double porcen;

  /// La lista inmediatamente anterior por vpp en la misma sucursal.
  final String nombrePrecioAnterior;
  final double porcenAnterior;

  /// Mensaje listo para mostrar, con los dos valores que no cierran: sin
  /// decir cual es cual, el usuario no sabe cual de los dos corregir.
  String get mensaje =>
      '$nombreSucursal: "$nombrePrecio" tiene '
      '${porcen.toStringAsFixed(2)} % y viene despues de '
      '"$nombrePrecioAnterior", que tiene '
      '${porcenAnterior.toStringAsFixed(2)} %.';
}

/// Comprueba que, dentro de cada sucursal, el margen no baje al subir el vpp.
/// El sistema anterior tenía esta regla ROTA (`validaPorcentaje()` devolvía
/// siempre 0) y nunca bloqueó una escritura; aquí
/// [PorcentajesNotifier.guardarGrilla] **no escribe nada** si la lista devuelta
/// no está vacía. Devuelve TODOS los choques (no solo el primero) y ordena por
/// sucursal y vpp: la rama de dlgPorcGrupo llega sin ordenar.
List<ConflictoPorcentaje> validarPorcentajesAscendentes(
  List<Map<String, dynamic>> filas,
) {
  final ordenadas = List<Map<String, dynamic>>.of(filas)..sort((a, b) {
    final sucA = (a['codSucursal'] as num?)?.toInt() ?? 0;
    final sucB = (b['codSucursal'] as num?)?.toInt() ?? 0;
    if (sucA != sucB) return sucA.compareTo(sucB);
    final vppA = (a['vpp'] as num?)?.toInt() ?? 0;
    final vppB = (b['vpp'] as num?)?.toInt() ?? 0;
    return vppA.compareTo(vppB);
  });

  final conflictos = <ConflictoPorcentaje>[];
  int? sucursalActual;
  double? porcenAnterior;
  String nombrePrecioAnterior = '';

  for (final fila in ordenadas) {
    final suc = (fila['codSucursal'] as num?)?.toInt() ?? 0;
    final porcen = (fila['porcentaje'] as num?)?.toDouble() ?? 0.0;
    final nombrePrecio = (fila['nombrePrecio'] as String?) ?? '';

    // Cada sucursal arranca su propia serie: la regla compara listas de una
    // misma sucursal entre si, nunca de una sucursal contra otra.
    if (suc != sucursalActual) {
      sucursalActual = suc;
      porcenAnterior = porcen;
      nombrePrecioAnterior = nombrePrecio;
      continue;
    }

    if (porcenAnterior != null && porcen < porcenAnterior) {
      conflictos.add(
        ConflictoPorcentaje(
          codSucursal: BigInt.from(suc),
          nombreSucursal: (fila['nombre'] as String?) ?? 'Sucursal $suc',
          nombrePrecio: nombrePrecio,
          porcen: porcen,
          nombrePrecioAnterior: nombrePrecioAnterior,
          porcenAnterior: porcenAnterior,
        ),
      );
    }

    // Se sigue con el valor de esta fila aunque haya fallado: asi cada salto
    // hacia abajo se reporta una sola vez y no arrastra a todas las de abajo.
    porcenAnterior = porcen;
    nombrePrecioAnterior = nombrePrecio;
  }

  return conflictos;
}

/// Lo que la pantalla de porcentajes necesita saber de la escritura en curso.
@immutable
class EstadoPorcentajes {
  const EstadoPorcentajes({
    this.cargando = false,
    this.error,
    this.conflictos = const <ConflictoPorcentaje>[],
    this.filasEscritas = 0,
    this.filasPedidas = 0,
  });

  /// Hay una escritura en vuelo. Deshabilita el boton de guardar: sin esto el
  /// usuario vuelve a tocarlo y se escriben las mismas filas dos veces.
  final bool cargando;

  /// Mensaje de negocio del backend, listo para mostrar sin traducir.
  final String? error;

  /// Los choques de la regla ascendente que impidieron guardar. Si hay alguno,
  /// no se escribio NADA.
  final List<ConflictoPorcentaje> conflictos;

  /// Cuántas filas alcanzó a escribir el último guardado de grilla y cuántas se
  /// pidieron. Cada fila viaja en su propia llamada (no hay escritura masiva), así
  /// que un fallo a mitad deja las anteriores guardadas: la pantalla debe poder
  /// decir «se guardaron 4 de 7» y no un «error» que sugiera que no se escribió nada.
  final int filasEscritas;
  final int filasPedidas;

  bool get huboError => error != null;

  bool get hayConflictos => conflictos.isNotEmpty;

  /// El ultimo guardado de grilla quedo por la mitad.
  bool get guardadoParcial =>
      filasPedidas > 0 && filasEscritas > 0 && filasEscritas < filasPedidas;

  EstadoPorcentajes copyWith({
    bool? cargando,
    String? error,
    List<ConflictoPorcentaje>? conflictos,
    int? filasEscritas,
    int? filasPedidas,
    bool limpiarError = false,
  }) => EstadoPorcentajes(
    cargando: cargando ?? this.cargando,
    error: limpiarError ? null : (error ?? this.error),
    conflictos: conflictos ?? this.conflictos,
    filasEscritas: filasEscritas ?? this.filasEscritas,
    filasPedidas: filasPedidas ?? this.filasPedidas,
  );
}

/// Escrituras de tpr_porcentaje. Va aparte de [PropuestaNotifier]: los porcentajes
/// no son un paso del armado de una propuesta (se editan con o sin propuesta
/// abierta) y su estado lleva conflictos de validación y cuántas filas de la
/// grilla se escribieron.
class PorcentajesNotifier extends StateNotifier<EstadoPorcentajes> {
  PorcentajesNotifier(this._ref) : super(const EstadoPorcentajes());

  final Ref _ref;

  PreciosRepository get _repo => _ref.read(preciosRepositoryProvider);

  /// Lecturas que cualquier escritura de porcentaje deja viejas.
  /// [destinosPorcentajeGrupoProvider] NO está: no consulta tpr_porcentaje
  /// (devuelve listas activas con margen en cero), refrescarla no cambiaría nada.
  List<ProviderOrFamily> get _lecturasAfectadas => [
    porcentajesPorFamiliaProvider,
    porcentajesFaltantesProvider,
    porcentajesProvider,
    // La grilla de repreciacion muestra el margen en su columna `porcentaje`:
    // dejarla con el anterior seria peor que no mostrarla.
    preciosTonPorFamiliaProvider,
  ];

  void _invalidarLecturas() {
    for (final p in _lecturasAfectadas) {
      _ref.invalidate(p);
    }
  }

  /// Borra el error y los conflictos, tipicamente al cerrar el aviso.
  void limpiarAvisos() {
    state = state.copyWith(
      limpiarError: true,
      conflictos: const <ConflictoPorcentaje>[],
    );
  }

  /// Alta o modificación de UNA fila. idPorcen en cero inserta.
  ///
  /// No valida el orden ascendente y no puede: esa regla compara las listas de
  /// una misma sucursal y aquí llega una sola fila. Para guardar con la
  /// validación puesta, [guardarGrilla].
  Future<bool> guardarPorcentaje(PorcentajePrecioEntity porcentaje) async {
    state = state.copyWith(
      cargando: true,
      limpiarError: true,
      conflictos: const <ConflictoPorcentaje>[],
      filasEscritas: 0,
      filasPedidas: 1,
    );
    try {
      await _repo.registrarPorcentaje(porcentaje);
      _invalidarLecturas();
      state = state.copyWith(cargando: false, filasEscritas: 1);
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, error: _mensaje(e));
      return false;
    }
  }

  /// Guarda una grilla completa de porcentajes de una familia. Primero valida que
  /// el margen no baje al subir el vpp por sucursal: **si falla no se escribe una
  /// sola fila** y los choques quedan en `state.conflictos`. Luego escribe fila
  /// por fila (el backend no tiene escritura masiva), lo que NO es atómico: el
  /// estado publica cuántas entraron y se corta en la primera que falla. [filas]
  /// son las de la grilla, con el margen en `porcentaje`.
  Future<bool> guardarGrilla({
    required int codigoFamilia,
    required List<Map<String, dynamic>> filas,
  }) async {
    final conflictos = validarPorcentajesAscendentes(filas);
    if (conflictos.isNotEmpty) {
      state = state.copyWith(
        cargando: false,
        conflictos: conflictos,
        error:
            'Los porcentajes tienen que ser ascendentes por sucursal. '
            'No se guardo ninguna fila.',
        filasEscritas: 0,
        filasPedidas: filas.length,
      );
      return false;
    }

    state = state.copyWith(
      cargando: true,
      limpiarError: true,
      conflictos: const <ConflictoPorcentaje>[],
      filasEscritas: 0,
      filasPedidas: filas.length,
    );

    var escritas = 0;
    try {
      for (final fila in filas) {
        await _repo.registrarPorcentaje(
          porcentajeDesdeFila(fila, codigoFamilia: codigoFamilia),
        );
        escritas++;
      }
      _invalidarLecturas();
      state = state.copyWith(cargando: false, filasEscritas: escritas);
      return true;
    } catch (e) {
      // Lo ya escrito quedo en la base: refrescar las lecturas igual, porque
      // la grilla en pantalla ya no coincide con la tabla.
      if (escritas > 0) _invalidarLecturas();
      state = state.copyWith(
        cargando: false,
        filasEscritas: escritas,
        error: _mensaje(e),
      );
      return false;
    }
  }

  /// El backend manda el mensaje del procedimiento listo para mostrar; solo
  /// hay que sacarle el prefijo que le agrega Exception.
  static String _mensaje(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}

final porcentajesNotifierProvider =
    StateNotifierProvider<PorcentajesNotifier, EstadoPorcentajes>(
      (ref) => PorcentajesNotifier(ref),
    );

// IVA / IT y ancla del tipo de cambio

/// Las filas de IVA/IT, de la mas nueva a la mas vieja. En una base sana es una
/// sola: mas de una avisa que el invariante de fila unica se rompio.
final costosIvaItProvider = FutureProvider.autoDispose<List<CostoIvaItEntity>>((
  ref,
) async {
  return ref.watch(preciosRepositoryProvider).obtenerCostosIvaIt();
});

/// La fila vigente. Null si todavia no hay IVA ni IT configurados.
final costoIvaItVigenteProvider = FutureProvider.autoDispose<CostoIvaItEntity?>(
  (ref) async {
    return ref.watch(preciosRepositoryProvider).obtenerCostoIvaItVigente();
  },
);

/// IVA/IT asociados a una propuesta.
final costosIvaItPorPropuestaProvider = FutureProvider.autoDispose
    .family<List<CostoIvaItEntity>, BigInt>((ref, idPropuesta) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerCostosIvaItPorPropuesta(idPropuesta);
    });

/// Anclas del tipo de cambio, una por empresa. SOLO LECTURA: quien las escribe
/// es el job del reprecio nocturno y tocarlas desde aquí lo descalibraría.
final anclasTipoCambioProvider =
    FutureProvider.autoDispose<List<TcAnclaEntity>>((ref) async {
      return ref.watch(preciosRepositoryProvider).obtenerAnclasTipoCambio();
    });

/// El ancla de una empresa por su base de datos SAP. Null si no tiene.
final anclaTipoCambioProvider = FutureProvider.autoDispose
    .family<TcAnclaEntity?, String>((ref, companyDB) async {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerAnclaTipoCambio(companyDB);
    });

// Armado de una propuesta

/// Lo que se está armando en pantalla antes de enviarlo al backend. Es inmutable
/// y se reemplaza entero con [copyWith]: la propuesta se arma en varios pasos y
/// con un objeto mutable un paso pisaba lo escrito por el anterior sin que la
/// pantalla se enterara.
@immutable
class EstadoPropuesta {
  const EstadoPropuesta({
    this.propuesta,
    this.costoSugerido,
    this.porcentajes = const <PorcentajePrecioEntity>[],
    this.preciosPropuestos = const <PrecioPropuestaEntity>[],
    this.articulosSeleccionados = const <ArticuloPrecioEntity>[],
    this.cargando = false,
    this.error,
    this.ultimoId,
  });

  /// La cabecera en edicion. Null mientras no se abrio ninguna.
  final PropuestaPrecioEntity? propuesta;

  /// El costo en USD por tonelada de la familia que se esta repreciando.
  final CostoSugeridoEntity? costoSugerido;

  /// Porcentajes por lista de precios de la familia en edicion.
  final List<PorcentajePrecioEntity> porcentajes;

  /// Los precios por tonelada ya propuestos para esta propuesta.
  final List<PrecioPropuestaEntity> preciosPropuestos;

  /// Los articulos que el usuario incluyo en la propuesta.
  final List<ArticuloPrecioEntity> articulosSeleccionados;

  /// Hay una escritura en vuelo: deshabilita Guardar para no generar registros
  /// duplicados.
  final bool cargando;

  /// Mensaje de negocio del backend, listo para mostrar sin traducir.
  final String? error;

  /// El id que devolvio la ultima escritura exitosa.
  final BigInt? ultimoId;

  bool get huboError => error != null;

  bool get hayPropuesta => propuesta != null;

  /// Cuantos articulos entran en la propuesta.
  int get cantidadArticulos => articulosSeleccionados.length;

  /// Banderas de limpieza: mismo motivo que en [FiltroFamilias.copyWith].
  EstadoPropuesta copyWith({
    PropuestaPrecioEntity? propuesta,
    CostoSugeridoEntity? costoSugerido,
    List<PorcentajePrecioEntity>? porcentajes,
    List<PrecioPropuestaEntity>? preciosPropuestos,
    List<ArticuloPrecioEntity>? articulosSeleccionados,
    bool? cargando,
    String? error,
    BigInt? ultimoId,
    bool limpiarPropuesta = false,
    bool limpiarCostoSugerido = false,
    bool limpiarError = false,
    bool limpiarUltimoId = false,
  }) => EstadoPropuesta(
    propuesta: limpiarPropuesta ? null : (propuesta ?? this.propuesta),
    costoSugerido:
        limpiarCostoSugerido ? null : (costoSugerido ?? this.costoSugerido),
    porcentajes: porcentajes ?? this.porcentajes,
    preciosPropuestos: preciosPropuestos ?? this.preciosPropuestos,
    articulosSeleccionados:
        articulosSeleccionados ?? this.articulosSeleccionados,
    cargando: cargando ?? this.cargando,
    error: limpiarError ? null : (error ?? this.error),
    ultimoId: limpiarUltimoId ? null : (ultimoId ?? this.ultimoId),
  );
}

/// Escrituras del módulo de precios. Cada método invalida las lecturas que su
/// escritura deja viejas: la pantalla no tiene que recargar nada.
class PropuestaNotifier extends StateNotifier<EstadoPropuesta> {
  PropuestaNotifier(this._ref) : super(const EstadoPropuesta());

  final Ref _ref;

  PreciosRepository get _repo => _ref.read(preciosRepositoryProvider);

  /// Envuelve cualquier escritura: marca en proceso, ejecuta e invalida las
  /// lecturas afectadas. Devuelve true si el backend acepto.
  Future<bool> _ejecutar(
    Future<BigInt> Function() accion,
    List<ProviderOrFamily> aInvalidar,
  ) async {
    state = state.copyWith(
      cargando: true,
      limpiarError: true,
      limpiarUltimoId: true,
    );
    try {
      final id = await accion();
      for (final p in aInvalidar) {
        _ref.invalidate(p);
      }
      state = state.copyWith(cargando: false, ultimoId: id);
      return true;
    } catch (e) {
      // El backend manda el mensaje del procedimiento listo para mostrar.
      state = state.copyWith(
        cargando: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // Manejo del estado en pantalla

  /// Abre una propuesta para editarla.
  void abrirPropuesta(PropuestaPrecioEntity propuesta) {
    state = EstadoPropuesta(propuesta: propuesta);
  }

  /// Cierra el armado y vuelve al estado inicial.
  void cerrarPropuesta() => state = const EstadoPropuesta();

  /// Borra el mensaje de error, tipicamente al cerrar el aviso.
  void limpiarError() => state = state.copyWith(limpiarError: true);

  /// Fija el costo sugerido que se esta editando, sin mandarlo todavia.
  void fijarCostoSugerido(CostoSugeridoEntity costo) {
    state = state.copyWith(costoSugerido: costo);
  }

  /// Reemplaza la tabla de porcentajes de la familia en edicion.
  void fijarPorcentajes(List<PorcentajePrecioEntity> porcentajes) {
    state = state.copyWith(
      porcentajes: List<PorcentajePrecioEntity>.unmodifiable(porcentajes),
    );
  }

  /// Reemplaza los precios propuestos que se estan editando.
  void fijarPreciosPropuestos(List<PrecioPropuestaEntity> precios) {
    state = state.copyWith(
      preciosPropuestos: List<PrecioPropuestaEntity>.unmodifiable(precios),
    );
  }

  /// Reemplaza la seleccion de articulos.
  void fijarArticulos(List<ArticuloPrecioEntity> articulos) {
    state = state.copyWith(
      articulosSeleccionados: List<ArticuloPrecioEntity>.unmodifiable(
        articulos,
      ),
    );
  }

  /// Agrega o quita un articulo de la seleccion. El codigo de articulo es la
  /// identidad: comparar la entity entera haria que dos lecturas del mismo
  /// articulo se contaran como dos.
  void alternarArticulo(ArticuloPrecioEntity articulo) {
    final actuales = List<ArticuloPrecioEntity>.of(
      state.articulosSeleccionados,
    );
    final indice = actuales.indexWhere(
      (a) => a.codArticulo == articulo.codArticulo,
    );
    if (indice >= 0) {
      actuales.removeAt(indice);
    } else {
      actuales.add(articulo);
    }
    fijarArticulos(actuales);
  }

  /// Vacia la seleccion de articulos sin cerrar la propuesta.
  void limpiarArticulos() => fijarArticulos(const <ArticuloPrecioEntity>[]);

  // Escrituras del armado

  // El armado (propuesta, costo sugerido, precios, flete) lo escribe el asistente
  // (armadoProvider).

  // Circuito de autorización

  /// Aprueba o rechaza una propuesta. Es la operacion mas sensible del modulo:
  /// con [esAprobada] en 1 los precios propuestos pasan a ser los precios de
  /// venta vigentes de toda la empresa. 0 pendiente, 1 aprobada, 2 no aprobada,
  /// 3 en espera.
  Future<bool> resolverPropuesta({
    required BigInt idPropuesta,
    required int esAprobada,
  }) => _ejecutar(
    () => _repo.resolverPropuesta(
      idPropuesta: idPropuesta,
      esAprobada: esAprobada,
    ),
    [
      propuestasParaAutorizarProvider,
      vistaPropuestaProvider,
      // Aprobar reescribe los precios de venta vigentes: dejar la grilla de
      // precios mostrando los anteriores seria peor que no mostrarlos.
      preciosTonPorFamiliaProvider,
      familiasProvider,
    ],
  );

  /// Deja la propuesta en espera y se la devuelve a quien la genero.
  Future<bool> marcarEnEspera(BigInt idPropuesta) => _ejecutar(
    () => _repo.marcarEnEspera(idPropuesta),
    [propuestasParaAutorizarProvider],
  );

  /// Genera una propuesta aprobada: el servidor arma CambioDePrecios.xlsx y
  /// registra quien lo genero. Devuelve el archivo, o null si el backend lo
  /// rechazo; el motivo queda en `error`.
  Future<Uint8List?> generar(BigInt idPropuesta) async {
    Uint8List? archivo;
    final ok = await _ejecutar(() async {
      archivo = await _repo.generarPropuesta(idPropuesta);
      return BigInt.zero;
    }, [propuestasParaAutorizarProvider]);
    return ok ? archivo : null;
  }
}

final propuestaProvider =
    StateNotifierProvider<PropuestaNotifier, EstadoPropuesta>(
      (ref) => PropuestaNotifier(ref),
    );

// Filtros de pantalla: locales al módulo, se reinician al salir para que un
// filtro de una visita no reaparezca en la siguiente.

/// Texto del buscador de la tabla activa.
final filtroBusquedaPrecioProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Con lo que arranca el buscador de familias y a lo que vuelve «Limpiar»: las
/// activas (las que se reprecian); las inactivas quedan a un toque.
const filtroFamiliasInicial = FiltroFamilias(estado: 1);

/// Criterios activos del buscador de familias.
final filtroFamiliasProvider = StateProvider.autoDispose<FiltroFamilias>(
  (ref) => filtroFamiliasInicial,
);

/// Estado de propuesta elegido en el combo. null = todos.
final filtroEstadoPropuestaProvider = StateProvider.autoDispose<int?>(
  (ref) => null,
);

/// La familia que se esta repreciando. null = ninguna abierta.
final familiaSeleccionadaProvider = StateProvider.autoDispose<int?>(
  (ref) => null,
);
