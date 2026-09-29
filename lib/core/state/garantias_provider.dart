import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/data/repositories/garantias_impl.dart';
import 'package:bosque_flutter/domain/entities/accion_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cliente_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_resumen_cliente_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cbr_entity.dart';
import 'package:bosque_flutter/domain/repositories/garantias_repository.dart';

/// Repositorio del modulo de garantias de cobranza (tcbr).
///
/// Se registra aqui, perezoso, y tipado contra la interfaz: `main.dart` no lo
/// conoce y una prueba puede sustituirlo con un override.
final garantiasRepositoryProvider = Provider<GarantiasRepository>(
  (ref) => GarantiasImpl(),
);

// Filtro del reporte de búsqueda

/// Los filtros de `/garantias/listar` y `/garantias/reporte/busqueda`.
/// Todos nulables: null no filtra.
@immutable
class FiltroGarantias {
  const FiltroGarantias({
    this.codClienteSAP,
    this.estado,
    this.tipoGarantia,
    this.vencDesde,
    this.vencHasta,
    this.regDesde,
    this.regHasta,
  });

  final String? codClienteSAP;

  /// VIGENTE, CADUCADO o CERRADO.
  final String? estado;
  final String? tipoGarantia;
  final DateTime? vencDesde;
  final DateTime? vencHasta;
  final DateTime? regDesde;
  final DateTime? regHasta;

  bool get sinCriterios =>
      codClienteSAP == null &&
      estado == null &&
      tipoGarantia == null &&
      vencDesde == null &&
      vencHasta == null &&
      regDesde == null &&
      regHasta == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroGarantias &&
          other.codClienteSAP == codClienteSAP &&
          other.estado == estado &&
          other.tipoGarantia == tipoGarantia &&
          other.vencDesde == vencDesde &&
          other.vencHasta == vencHasta &&
          other.regDesde == regDesde &&
          other.regHasta == regHasta;

  @override
  int get hashCode => Object.hash(
    codClienteSAP,
    estado,
    tipoGarantia,
    vencDesde,
    vencHasta,
    regDesde,
    regHasta,
  );
}

// Lecturas: FutureProvider autoDispose; la pantalla usa .when(...) y al salir
// del módulo se libera todo y la próxima visita vuelve a leer.

/// La grilla principal: una fila por cliente con garantias. Se trae entera
/// (son unos pocos cientos) y el buscador filtra en memoria, sin viajar.
final resumenClientesProvider =
    FutureProvider.autoDispose<List<GarantiaResumenClienteEntity>>((ref) {
      return ref.watch(garantiasRepositoryProvider).obtenerResumenClientes();
    });

/// Las garantias de todos los clientes, filtradas en el servidor por fechas
/// (expiracion o registro) y tipo de documento: la vista «Por garantía» de la
/// pantalla principal. Estado y texto se filtran en memoria, sobre esta lista,
/// porque «por vencer» no es un estado del backend.
final garantiasFiltradasProvider = FutureProvider.autoDispose
    .family<List<GarantiaVistaEntity>, FiltroGarantias>((ref, f) {
      return ref
          .watch(garantiasRepositoryProvider)
          .listarGarantias(
            codClienteSAP: f.codClienteSAP,
            estado: f.estado,
            tipoGarantia: f.tipoGarantia,
            vencDesde: f.vencDesde,
            vencHasta: f.vencHasta,
            regDesde: f.regDesde,
            regHasta: f.regHasta,
          );
    });

/// Las garantias de un cliente, por su CardCode.
final garantiasClienteProvider = FutureProvider.autoDispose
    .family<List<GarantiaVistaEntity>, String>((ref, codClienteSAP) {
      return ref
          .watch(garantiasRepositoryProvider)
          .listarGarantias(codClienteSAP: codClienteSAP);
    });

/// Una garantia con sus datos calculados. Es lo que muestra el detalle: se
/// relee despues de cada escritura para que estado y montos no queden viejos.
final garantiaProvider = FutureProvider.autoDispose
    .family<GarantiaVistaEntity?, BigInt>((ref, codGarantia) {
      return ref
          .watch(garantiasRepositoryProvider)
          .obtenerGarantia(codGarantia);
    });

final detallesGarantiaProvider = FutureProvider.autoDispose
    .family<List<CbrDetalleEntity>, BigInt>((ref, codGarantia) {
      return ref
          .watch(garantiasRepositoryProvider)
          .obtenerDetalles(codGarantia);
    });

final accionesGarantiaProvider = FutureProvider.autoDispose
    .family<List<AccionCbrEntity>, BigInt>((ref, codGarantia) async {
      final acciones = await ref
          .watch(garantiasRepositoryProvider)
          .obtenerAcciones(codGarantia);
      // La mas reciente arriba: es la que dice en que anda la garantia.
      acciones.sort((a, b) {
        final fa = a.fecha ?? DateTime(1900);
        final fb = b.fecha ?? DateTime(1900);
        final c = fb.compareTo(fa);
        return c != 0 ? c : b.codAccion.compareTo(a.codAccion);
      });
      return acciones;
    });

/// Cuantas garantias esperan el traspaso a custodia.
final traspasosPendientesProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(garantiasRepositoryProvider).contarTraspasosPendientes();
});

/// Catalogo de tipos de garantia (grupo 28).
final tiposGarantiaProvider = FutureProvider.autoDispose<List<TipoCbrEntity>>((
  ref,
) {
  return ref.watch(garantiasRepositoryProvider).obtenerTiposGarantia();
});

/// Catalogo de estados de accion (grupo 29).
final estadosAccionProvider = FutureProvider.autoDispose<List<TipoCbrEntity>>((
  ref,
) {
  return ref.watch(garantiasRepositoryProvider).obtenerEstadosAccion();
});

/// Nombre legible de un codigo de catalogo; el codigo mismo si no esta.
String nombreDeTipo(List<TipoCbrEntity>? catalogo, String codigo) {
  if (catalogo == null) return codigo;
  for (final t in catalogo) {
    if (t.codTipos == codigo) return t.nombre;
  }
  return codigo;
}

/// Busqueda de clientes SAP para el alta. Con menos de 3 caracteres no
/// consulta: el backend lo rechazaria y la lista seria inmanejable.
Future<List<ClienteSapEntity>> buscarClientesSap(
  WidgetRef ref,
  String texto,
) async {
  final t = texto.trim();
  if (t.length < 3) return const [];
  return ref.read(garantiasRepositoryProvider).buscarClientesSap(t);
}

// Escrituras

@immutable
class EstadoOperacionGarantia {
  const EstadoOperacionGarantia({this.ocupado = false, this.error});

  /// Hay una escritura en vuelo. Una sola a la vez: dos guardados cruzados
  /// dejan la pantalla contando algo que no paso.
  final bool ocupado;

  /// El mensaje del backend de la ultima escritura fallida, listo para
  /// mostrar.
  final String? error;
}

/// Todas las escrituras del modulo. Cada una, al salir bien, invalida las
/// lecturas que deja viejas: la pantalla se refresca sola.
class OperacionesGarantiasNotifier
    extends StateNotifier<EstadoOperacionGarantia> {
  OperacionesGarantiasNotifier(this._ref)
    : super(const EstadoOperacionGarantia());

  final Ref _ref;

  GarantiasRepository get _repo => _ref.read(garantiasRepositoryProvider);

  /// Corre [accion]; devuelve su resultado o null si fallo (el motivo queda
  /// en `state.error`).
  Future<T?> _ejecutar<T>(Future<T> Function() accion) async {
    if (state.ocupado) return null;
    state = const EstadoOperacionGarantia(ocupado: true);
    try {
      final r = await accion();
      state = const EstadoOperacionGarantia();
      _refrescar();
      return r;
    } catch (e) {
      state = EstadoOperacionGarantia(error: textoParaUsuario(e));
      return null;
    }
  }

  /// Toda escritura puede mover el resumen del cliente (montos, estado,
  /// vencimiento), la lista de sus garantias y el detalle abierto.
  void _refrescar() {
    _ref.invalidate(resumenClientesProvider);
    _ref.invalidate(garantiasFiltradasProvider);
    _ref.invalidate(garantiasClienteProvider);
    _ref.invalidate(garantiaProvider);
    _ref.invalidate(detallesGarantiaProvider);
    _ref.invalidate(accionesGarantiaProvider);
    _ref.invalidate(traspasosPendientesProvider);
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoOperacionGarantia();
  }

  Future<BigInt?> registrarGarantia(GarantiaRegistroEntity registro) =>
      _ejecutar(() => _repo.registrarGarantia(registro));

  Future<BigInt?> actualizarGarantia(GarantiaCbrEntity garantia) =>
      _ejecutar(() => _repo.actualizarGarantia(garantia));

  Future<BigInt?> registrarExtension({
    required BigInt codGarantia,
    required DateTime fecha,
    required String? observacion,
    required DateTime fechaExpiracion,
  }) => _ejecutar(
    () => _repo.registrarExtension(
      codGarantia: codGarantia,
      fecha: fecha,
      observacion: observacion,
      fechaExpiracion: fechaExpiracion,
    ),
  );

  Future<BigInt?> registrarDetalle(CbrDetalleEntity detalle) =>
      _ejecutar(() => _repo.registrarDetalle(detalle));

  Future<BigInt?> eliminarDetalle(BigInt codDetalle) =>
      _ejecutar(() => _repo.eliminarDetalle(codDetalle));

  Future<BigInt?> registrarAccion(AccionCbrEntity accion) =>
      _ejecutar(() => _repo.registrarAccion(accion));

  Future<BigInt?> eliminarAccion(BigInt codAccion) =>
      _ejecutar(() => _repo.eliminarAccion(codAccion));

  Future<int?> generarTraspaso() => _ejecutar(_repo.generarTraspaso);

  // Los PDF no cambian nada: van directo al repositorio, sin tocar el estado.
  Future<Uint8List> reporteRecibo(BigInt codGarantia) =>
      _repo.reporteRecibo(codGarantia);

  Future<Uint8List> reporteTraspaso() => _repo.reporteTraspaso();

  Future<Uint8List> reporteBusqueda(FiltroGarantias f) => _repo.reporteBusqueda(
    codClienteSAP: f.codClienteSAP,
    estado: f.estado,
    tipoGarantia: f.tipoGarantia,
    vencDesde: f.vencDesde,
    vencHasta: f.vencHasta,
    regDesde: f.regDesde,
    regHasta: f.regHasta,
  );
}

final operacionesGarantiasProvider = StateNotifierProvider.autoDispose<
  OperacionesGarantiasNotifier,
  EstadoOperacionGarantia
>((ref) => OperacionesGarantiasNotifier(ref));
