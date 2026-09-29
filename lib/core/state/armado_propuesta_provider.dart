/// El estado del asistente "Nueva propuesta" del modulo de precios (tpr).
///
/// Vive en su propio archivo y no en `precios_provider.dart` porque es estado
/// de UNA pantalla: lo que se va escribiendo en el asistente -titulo,
/// observaciones, fletes- antes de que exista la propuesta. Es autoDispose:
/// cerrar el asistente lo tira, y abrirlo de nuevo arranca de cero.
///
/// **Cuando nace la propuesta.** Igual que en el sistema anterior, con la
/// primera familia (o el primer articulo) que se guarda. Hasta ese momento
/// nada viaja a la base: la cabecera y los fletes se mandan junto con esa
/// primera escritura y el servidor los graba en la misma transaccion. Asi un
/// formulario abandonado no deja una propuesta vacia en el listado.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/domain/entities/armado_propuesta_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_propuesto_entity.dart';
import 'package:bosque_flutter/domain/repositories/precios_repository.dart';

/// Los dos tipos de propuesta de `tpr_propuesta.tipo`.
enum TipoArmado {
  /// Reprecio de familias por tonelada: costo, porcentajes, IVA, IT y flete.
  porFamilia(1, 'Por familias'),

  /// Articulos puntuales, tipicamente mercaderia nueva que hay que dar de alta
  /// en SAP con el precio de su familia.
  porArticulo(2, 'Por artículos');

  const TipoArmado(this.codigo, this.etiqueta);

  final int codigo;
  final String etiqueta;

  static TipoArmado desdeCodigo(int codigo) =>
      codigo == 2 ? TipoArmado.porArticulo : TipoArmado.porFamilia;
}

/// Los pasos del asistente, en orden.
enum PasoArmado {
  datos('Datos'),
  contenido('Contenido'),
  revision('Revisión');

  const PasoArmado(this.etiqueta);

  final String etiqueta;
}

/// Largos de `tpr_propuesta`: titulo varchar(200), obs varchar(250).
const int largoMaximoTitulo = 200;
const int largoMaximoObs = 250;

@immutable
class EstadoArmado {
  const EstadoArmado({
    this.idPropuesta,
    this.tipo = TipoArmado.porFamilia,
    this.titulo = '',
    this.obs = '',
    this.fletes = const <FleteArmadoEntity>[],
    this.fletesGuardados = const <FleteArmadoEntity>[],
    this.referenciaFletes,
    this.cargandoFletes = false,
    this.errorFletes,
    this.paso = PasoArmado.datos,
    this.ocupado = false,
  });

  /// Null mientras la propuesta no existe.
  final BigInt? idPropuesta;

  final TipoArmado tipo;
  final String titulo;
  final String obs;

  /// Los fletes tal como estan en pantalla.
  final List<FleteArmadoEntity> fletes;

  /// Los que estan grabados. En un alta, vacia hasta la primera familia.
  final List<FleteArmadoEntity> fletesGuardados;

  /// De que propuesta se copiaron los fletes sugeridos de un alta.
  final BigInt? referenciaFletes;

  final bool cargandoFletes;
  final Object? errorFletes;

  final PasoArmado paso;

  /// Hay una escritura en vuelo: los botones que escriben se deshabilitan.
  final bool ocupado;

  bool get existe => idPropuesta != null;

  bool get esPorFamilia => tipo == TipoArmado.porFamilia;

  /// En una propuesta que ya existe, los fletes en pantalla no son los
  /// grabados.
  bool get fletesModificados {
    if (!existe) return false;
    if (fletes.length != fletesGuardados.length) return true;
    for (var i = 0; i < fletes.length; i++) {
      if (fletes[i].codSucursal != fletesGuardados[i].codSucursal ||
          (fletes[i].valor - fletesGuardados[i].valor).abs() >= 0.005) {
        return true;
      }
    }
    return false;
  }

  /// Hay algo escrito que se perderia al salir: en un alta todo lo del primer
  /// paso, en una existente los fletes sin guardar.
  bool get hayCambiosSinGuardar =>
      existe
          ? fletesModificados
          : titulo.trim().isNotEmpty || obs.trim().isNotEmpty;

  /// Que le falta al primer paso para poder seguir. Null si esta completo.
  ///
  /// Son las mismas reglas que valida el servidor: se repiten aca para que el
  /// boton diga que falta antes de viajar, no para reemplazarlas.
  String? get faltaEnDatos {
    if (existe) return null;
    if (titulo.trim().isEmpty) return 'Escriba el título de la propuesta.';
    if (titulo.trim().length > largoMaximoTitulo) {
      return 'El título admite hasta $largoMaximoTitulo caracteres.';
    }
    if (obs.trim().isEmpty) return 'Escriba las observaciones.';
    if (obs.trim().length > largoMaximoObs) {
      return 'Las observaciones admiten hasta $largoMaximoObs caracteres.';
    }
    if (esPorFamilia) {
      if (cargandoFletes) return 'Esperando los fletes por sucursal.';
      if (fletes.isEmpty) return 'No se pudieron cargar las sucursales.';
      // El campo no deja escribir el signo menos: un negativo es la marca de
      // un texto que no se pudo leer como importe.
      if (fletes.any((f) => f.valor < 0)) {
        return 'Revise los fletes: hay uno que no es un importe válido.';
      }
    }
    return null;
  }

  EstadoArmado copyWith({
    BigInt? idPropuesta,
    TipoArmado? tipo,
    String? titulo,
    String? obs,
    List<FleteArmadoEntity>? fletes,
    List<FleteArmadoEntity>? fletesGuardados,
    BigInt? referenciaFletes,
    bool? cargandoFletes,
    Object? errorFletes,
    PasoArmado? paso,
    bool? ocupado,
    bool limpiarErrorFletes = false,
  }) => EstadoArmado(
    idPropuesta: idPropuesta ?? this.idPropuesta,
    tipo: tipo ?? this.tipo,
    titulo: titulo ?? this.titulo,
    obs: obs ?? this.obs,
    fletes: fletes ?? this.fletes,
    fletesGuardados: fletesGuardados ?? this.fletesGuardados,
    referenciaFletes: referenciaFletes ?? this.referenciaFletes,
    cargandoFletes: cargandoFletes ?? this.cargandoFletes,
    errorFletes: limpiarErrorFletes ? null : (errorFletes ?? this.errorFletes),
    paso: paso ?? this.paso,
    ocupado: ocupado ?? this.ocupado,
  );
}

/// El resultado de una escritura, para que la pantalla avise sin tener que
/// atrapar excepciones: o salio, o trae el mensaje listo para mostrar.
@immutable
class Resultado<T> {
  const Resultado.ok(T this.valor) : error = null;
  const Resultado.fallo(String this.error) : valor = null;

  final T? valor;
  final String? error;

  bool get salio => error == null;
}

class ArmadoNotifier extends StateNotifier<EstadoArmado> {
  ArmadoNotifier(this._ref) : super(const EstadoArmado());

  final Ref _ref;

  PreciosRepository get _repo => _ref.read(preciosRepositoryProvider);

  // ---------- Arranque ----------

  /// Un alta: los fletes arrancan con los de la ultima propuesta por familia.
  Future<void> iniciarNueva() async {
    state = const EstadoArmado(cargandoFletes: true);
    await _cargarFletes();
  }

  /// Una propuesta pendiente que se sigue armando. Arranca en el paso de
  /// contenido: los datos ya estan y lo que se viene a hacer es cargar.
  Future<void> abrirExistente({
    required BigInt idPropuesta,
    required TipoArmado tipo,
    required String titulo,
  }) async {
    state = EstadoArmado(
      idPropuesta: idPropuesta,
      tipo: tipo,
      titulo: titulo,
      paso: PasoArmado.contenido,
      cargandoFletes: tipo == TipoArmado.porFamilia,
    );
    if (tipo == TipoArmado.porFamilia) await _cargarFletes();
  }

  Future<void> recargarFletes() async {
    state = state.copyWith(cargandoFletes: true, limpiarErrorFletes: true);
    await _cargarFletes();
  }

  Future<void> _cargarFletes() async {
    try {
      final r = await _repo.obtenerFletesArmado(state.idPropuesta);
      if (!mounted) return;
      state = state.copyWith(
        fletes: r.fletes,
        fletesGuardados: r.deLaPropuesta ? r.fletes : const [],
        referenciaFletes: r.deLaPropuesta ? null : r.idPropuestaReferencia,
        cargandoFletes: false,
        limpiarErrorFletes: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargandoFletes: false, errorFletes: e);
    }
  }

  // ---------- Paso de datos ----------

  /// El tipo solo se elige en un alta: una propuesta existente no cambia de
  /// tipo, porque cada uno escribe en tablas distintas.
  void fijarTipo(TipoArmado tipo) {
    if (state.existe) return;
    state = state.copyWith(tipo: tipo);
  }

  void fijarTitulo(String titulo) => state = state.copyWith(titulo: titulo);

  void fijarObs(String obs) => state = state.copyWith(obs: obs);

  void fijarFlete(BigInt codSucursal, double valor) {
    state = state.copyWith(
      fletes: [
        for (final f in state.fletes)
          f.codSucursal == codSucursal ? f.conValor(valor) : f,
      ],
    );
  }

  void descartarCambiosDeFletes() =>
      state = state.copyWith(fletes: state.fletesGuardados);

  void irA(PasoArmado paso) => state = state.copyWith(paso: paso);

  // ---------- Familias ----------

  /// La vista previa de una familia. No escribe: se puede llamar cuantas veces
  /// haga falta mientras el usuario prueba costos.
  Future<Resultado<CalculoFamiliaEntity>> calcularFamilia(
    int codigoFamilia, {
    double? costo,
    Map<BigInt, double>? porcentajes,
  }) async {
    try {
      final r = await _repo.calcularFamiliaArmado(
        idPropuesta: state.idPropuesta,
        codigoFamilia: codigoFamilia,
        costo: costo,
        fletes: state.existe ? null : state.fletes,
        porcentajes: porcentajes,
      );
      return Resultado.ok(r);
    } catch (e) {
      return Resultado.fallo(textoParaUsuario(e));
    }
  }

  /// Carga la familia en la propuesta. Si es la primera, la propuesta nace aca
  /// con su cabecera y sus fletes. Los [porcentajes] cambiados en el editor
  /// quedan registrados para la familia en la misma transaccion.
  Future<Resultado<CalculoFamiliaEntity>> guardarFamilia(
    int codigoFamilia,
    double costo, {
    Map<BigInt, double>? porcentajes,
  }) => _escribir(() async {
    final alta = !state.existe;
    final r = await _repo.guardarFamiliaArmado(
      idPropuesta: state.idPropuesta,
      titulo: alta ? state.titulo.trim() : null,
      obs: alta ? state.obs.trim() : null,
      fletes: alta ? state.fletes : null,
      codigoFamilia: codigoFamilia,
      costo: costo,
      porcentajes: porcentajes,
    );
    // Los porcentajes quedaron registrados en tpr_porcentaje: lo que la
    // pantalla «Porcentajes» tenga leido de la familia ya es viejo.
    if (r.porcentajesCambiados > 0) {
      _ref.invalidate(porcentajesPorFamiliaProvider(codigoFamilia));
      _ref.invalidate(porcentajesFaltantesProvider(codigoFamilia));
      _ref.invalidate(porcentajesProvider);
    }
    if (alta && r.idPropuesta != null && mounted) {
      state = state.copyWith(
        idPropuesta: r.idPropuesta,
        fletesGuardados: state.fletes,
      );
    }
    return r;
  });

  /// Cuantas familias viajan por pedido en la carga en lote: pocas como para
  /// que cada tanda tarde unos segundos y el avance se vea moverse.
  static const int familiasPorTanda = 20;

  /// Vista previa de varias familias, en tandas. [alAvanzar] recibe cuantas
  /// van calculadas. No escribe.
  Future<Resultado<List<CalculoFamiliaEntity>>> calcularFamilias(
    Map<int, double> costos, {
    void Function(int hechas, int total)? alAvanzar,
  }) async {
    final todas = costos.entries.toList();
    final calculos = <CalculoFamiliaEntity>[];
    try {
      for (var i = 0; i < todas.length; i += familiasPorTanda) {
        final tanda = Map.fromEntries(todas.skip(i).take(familiasPorTanda));
        calculos.addAll(
          await _repo.calcularFamiliasArmado(
            idPropuesta: state.idPropuesta,
            fletes: state.existe ? null : state.fletes,
            costos: tanda,
          ),
        );
        alAvanzar?.call(calculos.length, todas.length);
      }
      return Resultado.ok(calculos);
    } catch (e) {
      return Resultado.fallo(textoParaUsuario(e));
    }
  }

  /// Guarda varias familias en tandas. Cada tanda es una transaccion: si falla
  /// una, las anteriores ya quedaron en la propuesta -que sigue pendiente y se
  /// puede corregir- y el mensaje dice cuantas entraron. Si la propuesta no
  /// existe, nace con la primera tanda.
  Future<Resultado<ResultadoArmadoEntity>> guardarFamilias(
    Map<int, double> costos, {
    void Function(int hechas, int total)? alAvanzar,
  }) async {
    final todas = costos.entries.toList();
    state = state.copyWith(ocupado: true);
    // Lo que manda cada tanda se toma aca, una vez, y el id que devuelve la
    // primera se guarda en una variable: si el asistente se cerrara a mitad,
    // `state` ya no se puede leer y las tandas siguientes irian sin id, cada
    // una creando otra propuesta.
    var id = state.idPropuesta;
    final titulo = state.titulo.trim();
    final obs = state.obs.trim();
    final fletes = state.fletes;
    var familias = 0;
    var lineas = 0;
    try {
      for (var i = 0; i < todas.length; i += familiasPorTanda) {
        final tanda = Map.fromEntries(todas.skip(i).take(familiasPorTanda));
        final alta = id == null;
        final r = await _repo.guardarFamiliasArmado(
          idPropuesta: id,
          titulo: alta ? titulo : null,
          obs: alta ? obs : null,
          fletes: alta ? fletes : null,
          costos: tanda,
        );
        if (alta && r.idPropuesta > BigInt.zero) {
          id = r.idPropuesta;
          if (mounted) {
            state = state.copyWith(idPropuesta: id, fletesGuardados: fletes);
          }
        }
        familias += r.familiasRecalculadas;
        lineas += r.lineasEscritas;
        alAvanzar?.call(familias, todas.length);
      }
      _refrescar(id);
      if (mounted) state = state.copyWith(ocupado: false);
      return Resultado.ok(
        ResultadoArmadoEntity(
          idPropuesta: id ?? BigInt.zero,
          articulos: 0,
          omitidos: 0,
          familiasRecalculadas: familias,
          lineasEscritas: lineas,
        ),
      );
    } catch (e) {
      if (familias > 0) _refrescar(id);
      if (mounted) state = state.copyWith(ocupado: false);
      final parcial =
          familias == 0
              ? ''
              : 'Se guardaron $familias de ${todas.length} familias; las '
                  'demás no. ';
      return Resultado.fallo('$parcial${textoParaUsuario(e)}');
    }
  }

  /// Graba los fletes de una propuesta existente; el servidor recalcula todas
  /// sus familias en la misma transaccion.
  Future<Resultado<ResultadoArmadoEntity>> guardarFletes() =>
      _escribir(() async {
        final r = await _repo.guardarFletesArmado(
          idPropuesta: state.idPropuesta!,
          fletes: state.fletes,
        );
        if (mounted) state = state.copyWith(fletesGuardados: state.fletes);
        return r;
      });

  // ---------- Articulos ----------

  Future<Resultado<ResultadoArmadoEntity>> agregarArticulos(
    List<String> codigos,
  ) => _escribir(() async {
    final alta = !state.existe;
    final r = await _repo.agregarArticulosArmado(
      idPropuesta: state.idPropuesta,
      titulo: alta ? state.titulo.trim() : null,
      obs: alta ? state.obs.trim() : null,
      codArticulos: codigos,
    );
    if (alta && r.idPropuesta > BigInt.zero && mounted) {
      state = state.copyWith(idPropuesta: r.idPropuesta);
    }
    return r;
  });

  Future<Resultado<ResultadoArmadoEntity>> quitarArticulo(
    ArticuloPropuestoEntity articulo,
  ) => _escribir(
    () => _repo.quitarArticuloArmado(
      idPropuesta: state.idPropuesta!,
      idArticulo: articulo.idArticulo,
    ),
  );

  /// Trae de SAP los articulos nuevos. Puede tardar varios minutos.
  Future<Resultado<void>> sincronizarArticulosSap() => _escribir(() async {
    await _repo.sincronizarArticulosSap();
    _ref.invalidate(articulosPorFamiliasProvider);
  });

  // ---------- Apoyo ----------

  /// Una escritura a la vez: marca ocupado, ejecuta y refresca lo que la
  /// escritura dejo viejo. El listado de propuestas se invalida siempre: una
  /// propuesta recien nacida tiene que aparecer al volver.
  Future<Resultado<T>> _escribir<T>(Future<T> Function() accion) async {
    state = state.copyWith(ocupado: true);
    try {
      final r = await accion();
      _refrescar(mounted ? state.idPropuesta : null);
      if (mounted) state = state.copyWith(ocupado: false);
      return Resultado.ok(r);
    } catch (e) {
      if (mounted) state = state.copyWith(ocupado: false);
      return Resultado.fallo(textoParaUsuario(e));
    }
  }

  /// Recibe el id y no lo lee de `state`: se llama tambien cuando el
  /// asistente ya se cerro.
  void _refrescar(BigInt? id) {
    _ref.invalidate(propuestasParaAutorizarProvider);
    _ref.invalidate(vistaPropuestaProvider);
    if (id != null) {
      _ref.invalidate(familiasArmadasProvider(id));
      _ref.invalidate(articulosArmadosProvider(id));
    }
  }
}

final armadoProvider =
    StateNotifierProvider.autoDispose<ArmadoNotifier, EstadoArmado>(
      (ref) => ArmadoNotifier(ref),
    );

/// Las familias ya cargadas en una propuesta.
final familiasArmadasProvider = FutureProvider.autoDispose
    .family<List<FamiliaArmadaEntity>, BigInt>((ref, idPropuesta) {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerFamiliasArmadas(idPropuesta);
    });

/// Los articulos de una propuesta por articulo.
final articulosArmadosProvider = FutureProvider.autoDispose
    .family<List<ArticuloPropuestoEntity>, BigInt>((ref, idPropuesta) {
      return ref
          .watch(preciosRepositoryProvider)
          .obtenerArticulosArmados(idPropuesta);
    });
