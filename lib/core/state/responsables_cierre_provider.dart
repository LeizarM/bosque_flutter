// Destino final: lib/core/state/responsables_cierre_provider.dart
import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';
import 'package:bosque_flutter/data/repositories/responsable_cierre_impl.dart';
import 'package:bosque_flutter/domain/entities/responsable_cierre_entity.dart';
import 'package:bosque_flutter/domain/repositories/responsable_cierre_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _mensaje(Object e) => mensajeError(e);

/// Un responsable con sus filas de la matriz, por sección.
class ResponsableConSecciones {
  final String clave;

  /// "GERENTE ADMINISTRATIVO · CENTRAL" o el nombre de la persona.
  final String titulo;

  /// Quién ocupa hoy el cargo, o el cargo de la persona.
  final String? detalle;
  final bool esCargo;
  final int? codCargoSucursal;
  final int? codEmpleado;

  /// Por código de sección del catálogo.
  final Map<String, List<ResponsableCierre>> porSeccion;

  const ResponsableConSecciones({
    required this.clave,
    required this.titulo,
    this.detalle,
    required this.esCargo,
    this.codCargoSucursal,
    this.codEmpleado,
    required this.porSeccion,
  });

  List<ResponsableCierre> filasDe(String codigo) =>
      porSeccion[codigo] ?? const [];
}

/// La matriz de responsables de Verificar Cierre (archivo SQL 81). Las reglas
/// de cada alta (sección, sucursal, duplicados) son del servidor.
class ResponsablesCierreState {
  final PanelDatos<ResponsableCierre> filas;
  final PanelDatos<CandidatoCierre> candidatos;
  final List<SucursalCaja> sucursales;

  /// El catálogo de secciones y las fuentes para las nuevas (archivo SQL 86).
  final PanelDatos<SeccionCierre> secciones;
  final List<FuenteCierre> fuentes;

  /// El registro de fuentes completo y las consultas sin registrar (87).
  /// Se leen al abrir "Fuentes".
  final PanelDatos<FuenteCierre> fuentesTodas;
  final List<CandidatoFuente> candidatasFuente;
  final Set<int> guardando;
  final String? aviso;
  final String? mensajeError;

  const ResponsablesCierreState({
    this.filas = const PanelDatos<ResponsableCierre>(cargando: true),
    this.candidatos = const PanelDatos<CandidatoCierre>(cargando: true),
    this.sucursales = const [],
    this.secciones = const PanelDatos<SeccionCierre>(cargando: true),
    this.fuentes = const [],
    this.fuentesTodas = const PanelDatos<FuenteCierre>(),
    this.candidatasFuente = const [],
    this.guardando = const {},
    this.aviso,
    this.mensajeError,
  });

  /// Las secciones que se piden hoy, en el orden del catálogo: las columnas.
  List<SeccionCierre> get vigentes =>
      secciones.filas.where((x) => x.vigente).toList();

  SeccionCierre? seccion(String codigo) {
    for (final x in secciones.filas) {
      if (x.codigo == codigo) return x;
    }
    return null;
  }

  /// Solo las filas activas de secciones que se piden, por responsable.
  List<ResponsableConSecciones> get responsables {
    final mapa = <String, List<ResponsableCierre>>{};
    for (final f in filas.filas.where((f) => f.activo && f.seccionVigente)) {
      mapa.putIfAbsent(f.claveResponsable, () => []).add(f);
    }
    final lista = [
      for (final e in mapa.entries)
        () {
          final f = e.value.first;
          final porSeccion = <String, List<ResponsableCierre>>{};
          for (final x in e.value) {
            porSeccion.putIfAbsent(x.codigoSeccion, () => []).add(x);
          }
          final esCargo = f.codCargoSucursal != null;
          return ResponsableConSecciones(
            clave: e.key,
            titulo:
                esCargo
                    ? '${f.cargo ?? 'Cargo'} · ${f.sucursalDelCargo ?? '—'}'
                    : (f.personas ?? 'Persona ${f.codEmpleado}'),
            detalle: esCargo ? f.personas : f.cargo,
            esCargo: esCargo,
            codCargoSucursal: f.codCargoSucursal,
            codEmpleado: f.codEmpleado,
            porSeccion: porSeccion,
          );
        }(),
    ]..sort((a, b) => a.titulo.compareTo(b.titulo));
    return lista;
  }

  /// Cargos que tienen la tarea y ninguna sección: su tarea queda en No aplica.
  List<CandidatoCierre> get sinSecciones =>
      candidatos.filas.where((c) => c.esCargo && c.sinSecciones).toList();

  ResponsablesCierreState copyWith({
    PanelDatos<ResponsableCierre>? filas,
    PanelDatos<CandidatoCierre>? candidatos,
    List<SucursalCaja>? sucursales,
    PanelDatos<SeccionCierre>? secciones,
    List<FuenteCierre>? fuentes,
    PanelDatos<FuenteCierre>? fuentesTodas,
    List<CandidatoFuente>? candidatasFuente,
    Set<int>? guardando,
    String? aviso,
    String? mensajeError,
  }) => ResponsablesCierreState(
    filas: filas ?? this.filas,
    candidatos: candidatos ?? this.candidatos,
    sucursales: sucursales ?? this.sucursales,
    secciones: secciones ?? this.secciones,
    fuentes: fuentes ?? this.fuentes,
    fuentesTodas: fuentesTodas ?? this.fuentesTodas,
    candidatasFuente: candidatasFuente ?? this.candidatasFuente,
    guardando: guardando ?? this.guardando,
    aviso: aviso,
    mensajeError: mensajeError,
  );
}

class ResponsablesCierreNotifier
    extends StateNotifier<ResponsablesCierreState> {
  final ResponsableCierreRepository _repo;
  final int idTarRuti;

  ResponsablesCierreNotifier(this._repo, this.idTarRuti)
    : super(const ResponsablesCierreState()) {
    Future.microtask(cargar);
  }

  Future<void> cargar() async {
    state = state.copyWith(
      filas: state.filas.leyendo(limpiar: false),
      candidatos: state.candidatos.leyendo(limpiar: false),
      secciones: state.secciones.leyendo(limpiar: false),
    );
    await Future.wait([
      _leerFilas(),
      _leerCandidatos(),
      _leerSucursales(),
      _leerSecciones(),
      _leerFuentes(),
    ]);
  }

  Future<void> _leerSecciones() async {
    try {
      final x = await _repo.secciones(idTarRuti);
      if (mounted) {
        state = state.copyWith(secciones: PanelDatos(filas: x, cargado: true));
      }
    } catch (e) {
      if (mounted) state = state.copyWith(secciones: PanelDatos(error: e));
    }
  }

  Future<void> _leerFuentes() async {
    try {
      final x = await _repo.fuentes();
      if (mounted) state = state.copyWith(fuentes: x);
    } catch (_) {
      // Sin fuentes, el formulario de una sección nueva lo dice.
    }
  }

  /// Alta ([codigo] null) o cambio de una sección. Devuelve el motivo si el
  /// servidor no la aceptó, para mostrarlo en el mismo formulario.
  Future<String?> guardarSeccion({
    String? codigo,
    required String nombre,
    String? queRevisar,
    bool? porSucursal,
    String? fuente,
    bool? marcaPorFila,
    bool? firmaSola,
    int? obsDesde,
    String? diaRevisado,
    int? orden,
  }) async {
    try {
      await _repo.guardarSeccion(
        codigo: codigo,
        nombre: nombre,
        queRevisar: queRevisar,
        porSucursal: porSucursal,
        fuente: fuente,
        marcaPorFila: marcaPorFila,
        firmaSola: firmaSola,
        obsDesde: obsDesde,
        diaRevisado: diaRevisado,
        orden: orden,
      );
      if (!mounted) return null;
      await cargar();
      if (mounted) {
        state = state.copyWith(
          aviso:
              codigo == null
                  ? 'Sección creada: asígnale responsables.'
                  : 'Sección guardada.',
        );
      }
      return null;
    } catch (e) {
      return _mensaje(e);
    }
  }

  /// El registro de fuentes y las consultas que faltan registrar (archivo
  /// SQL 87). Las candidatas son un extra: si fallan, la lista queda vacía.
  Future<void> cargarFuentes() async {
    state = state.copyWith(
      fuentesTodas: state.fuentesTodas.leyendo(limpiar: false),
    );
    try {
      final todas = await _repo.fuentesTodas();
      if (!mounted) return;
      state = state.copyWith(
        fuentesTodas: PanelDatos(filas: todas, cargado: true),
      );
    } catch (e) {
      if (mounted) state = state.copyWith(fuentesTodas: PanelDatos(error: e));
    }
    try {
      final candidatas = await _repo.candidatasFuente();
      if (mounted) state = state.copyWith(candidatasFuente: candidatas);
    } catch (_) {
      if (mounted) state = state.copyWith(candidatasFuente: const []);
    }
  }

  /// Registra o cambia una fuente. Devuelve el motivo si el servidor no la
  /// aceptó, para mostrarlo en el formulario.
  Future<String?> guardarFuente({
    required String fuente,
    required String nombre,
    String? descripcion,
    String? spMarcar,
    bool alta = false,
  }) => _escribirFuente(
    () => _repo.guardarFuente(
      fuente: fuente,
      nombre: nombre,
      descripcion: descripcion,
      spMarcar: spMarcar,
    ),
    alta
        ? 'Fuente registrada: ya se puede elegir en una sección.'
        : 'Fuente guardada.',
  );

  Future<String?> activarFuente(FuenteCierre f, {required bool activa}) =>
      _escribirFuente(
        () => _repo.activarFuente(f.fuente, activa: activa),
        activa
            ? '${f.nombre}: activada.'
            : '${f.nombre}: ya no se puede elegir.',
      );

  Future<String?> borrarFuente(FuenteCierre f) => _escribirFuente(
    () => _repo.borrarFuente(f.fuente),
    '${f.nombre}: borrada del registro.',
  );

  Future<String?> _escribirFuente(
    Future<void> Function() hacer,
    String aviso,
  ) async {
    try {
      await hacer();
      if (!mounted) return null;
      // La lista de "De dónde salen las filas" y la de administrar.
      await Future.wait([_leerFuentes(), cargarFuentes()]);
      if (mounted) state = state.copyWith(aviso: aviso);
      return null;
    } catch (e) {
      return _mensaje(e);
    }
  }

  /// [quitar]: desde hoy ya no se pide (sus responsables quedan guardados);
  /// si no, se vuelve a pedir.
  Future<String?> quitarSeccion(SeccionCierre x, {required bool quitar}) async {
    try {
      await _repo.quitarSeccion(x.codigo, quitar: quitar);
      if (!mounted) return null;
      await cargar();
      if (mounted) {
        state = state.copyWith(
          aviso:
              quitar
                  ? 'Desde hoy ya no se pide ${x.nombre}.'
                  : 'Desde hoy se vuelve a pedir ${x.nombre}.',
        );
      }
      return null;
    } catch (e) {
      return _mensaje(e);
    }
  }

  Future<void> _leerFilas() async {
    try {
      final f = await _repo.lista(idTarRuti);
      if (mounted) {
        state = state.copyWith(filas: PanelDatos(filas: f, cargado: true));
      }
    } catch (e) {
      if (mounted) state = state.copyWith(filas: PanelDatos(error: e));
    }
  }

  Future<void> _leerCandidatos() async {
    try {
      final c = await _repo.candidatos(idTarRuti);
      if (mounted) {
        state = state.copyWith(candidatos: PanelDatos(filas: c, cargado: true));
      }
    } catch (e) {
      if (mounted) state = state.copyWith(candidatos: PanelDatos(error: e));
    }
  }

  Future<void> _leerSucursales() async {
    try {
      final s = await _repo.sucursales();
      if (mounted) state = state.copyWith(sucursales: s);
    } catch (_) {
      // Sin la lista, el diálogo solo ofrece "Todas"; el servidor valida igual.
    }
  }

  /// Devuelve el mensaje del servidor si no lo aceptó, para mostrarlo en el
  /// mismo diálogo sin perder lo elegido.
  Future<String?> agregar({
    required String seccion,
    int? codSucursal,
    int? codCargoSucursal,
    int? codEmpleado,
    bool puedeAutorrevisar = false,
  }) async {
    try {
      await _repo.agregar(
        idTarRuti: idTarRuti,
        seccion: seccion,
        codSucursal: codSucursal,
        codCargoSucursal: codCargoSucursal,
        codEmpleado: codEmpleado,
        puedeAutorrevisar: puedeAutorrevisar,
      );
      if (!mounted) return null;
      await cargar();
      if (mounted) state = state.copyWith(aviso: 'Responsable agregado.');
      return null;
    } catch (e) {
      return _mensaje(e);
    }
  }

  Future<void> cambiarAutorrevision(ResponsableCierre f, bool puede) =>
      _escribir(f.idRC, () => _repo.cambiarAutorrevision(f, puede), null);

  Future<void> quitar(ResponsableCierre f) => _escribir(
    f.idRC,
    () => _repo.quitar(f.idRC),
    'Se quitó ${f.nombreSeccion.toLowerCase()} · ${f.nombreSucursal}.',
  );

  Future<void> _escribir(
    int idRC,
    Future<void> Function() hacer,
    String? aviso,
  ) async {
    if (state.guardando.contains(idRC)) return;
    state = state.copyWith(guardando: {...state.guardando, idRC});
    try {
      await hacer();
      if (!mounted) return;
      await cargar();
      if (mounted) {
        state = state.copyWith(guardando: _sin(idRC), aviso: aviso);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          guardando: _sin(idRC),
          mensajeError: _mensaje(e),
        );
      }
    }
  }

  Set<int> _sin(int idRC) => {...state.guardando}..remove(idRC);
}

/// Se expone para poder reemplazarlo en las pruebas.
final responsableCierreRepoProvider = Provider<ResponsableCierreRepository>(
  (ref) => ResponsableCierreImpl(),
);

/// `family` por tarea (hoy solo la 39 tiene matriz).
final responsablesCierreProvider = StateNotifierProvider.autoDispose
    .family<ResponsablesCierreNotifier, ResponsablesCierreState, int>(
      (ref, idTarRuti) => ResponsablesCierreNotifier(
        ref.read(responsableCierreRepoProvider),
        idTarRuti,
      ),
    );
