import 'dart:typed_data';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/data/repositories/consumo_tigo_impl.dart';
import 'package:bosque_flutter/domain/entities/cambio_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/chip_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/factura_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_renovacion_chip_tigo_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final consumoTigoRepositoryProvider = Provider((ref) => ConsumoTigoImpl());

final subirExcelFacturasTigoProvider = FutureProvider.family<Map<String, dynamic>, (Uint8List, String, int)>(
  (ref, params) async {
    final repo = ConsumoTigoImpl();
    final resultado = await repo.subirExcel(params.$1, params.$2, params.$3);
    return resultado;
  },
);
//obtener excel de facturas tigo
final facturasTigoProvider = FutureProvider<List<FacturaTigoEntity>>((ref) async {
  final repo = ConsumoTigoImpl();
  final facturas = await repo.obtenerFacturaTigo();
  return facturas;
});
//subir socios tigo
final subirExcelSociosTigoProvider = FutureProvider.family<Map<String, dynamic>, (Uint8List, String, int)>(
  (ref, params) async {
    final repo = ConsumoTigoImpl();
    final resultado = await repo.subirExcelSocios(params.$1, params.$2, params.$3);
    return resultado;
  },
);
//obtener excel de facturas tigo
final tigoTotalXCuenta = FutureProvider.family<List<TigoEjecutadoEntity>,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final totalXCuenta = await repo.obtenerTotalXcuenta(periodoCobrado);
  return totalXCuenta;
});
//OBTENER GRUPOS (SOCIOS TIGO)

final obtenerSociosTigo = FutureProvider<List<SocioTigoEntity>>((ref) async {
  final repo = ConsumoTigoImpl();
  final sociosTigo = await repo.obtenerSociosTigo();
  return sociosTigo;
});
//registrar socio tigo
final registrarSocioTigo = FutureProvider.family<List<SocioTigoEntity>, SocioTigoEntity>(
  (ref, socio) async {
    final repo = ConsumoTigoImpl();
    return await repo.registrarSocio(socio);
  },
);
//obtener resumen por cuenta tigo
final tigoResumenXCuenta = FutureProvider.family<List<TigoEjecutadoEntity>,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final resumenXCuenta = await repo.obtenerResumenCuentas(periodoCobrado);
  return resumenXCuenta;
});
//obtener resumen DETALLADO por cuenta tigo
final tigoResumenDetallado = FutureProvider.family<List<TigoEjecutadoEntity>, String>((ref, periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final resumenDetallado = await repo.obtenerResumenDetallado(periodoCobrado);
  return resumenDetallado;
});
//INSERTAR ANTICIPOS TIGO
final insertarAnticipoTigo = FutureProvider.family<bool, String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  return await repo.generarAnticiposTigo(periodoCobrado);
});
//descargar reporte tigo
final jasperPdfFacturasTigoProvider = FutureProvider.family<Uint8List,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  return await repo.descargarReporteFacturasTigo(periodoCobrado); // Este método debe retornar Uint8List
});
//OBTENER grupos TIGO
final obtenerGruposTigo = FutureProvider.family<List<SocioTigoEntity>,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final sociosTigo = await repo.obtenerGruposTigo(periodoCobrado);
  return sociosTigo;
});
//ELIMINAR GRUPO TIGO
final eliminarGrupoTigo = FutureProvider.family<void, int>(
  (ref, codCuenta) async {
    final repo = ConsumoTigoImpl();
    await repo.eliminarGrupo(codCuenta);
  },
);
//INSERTAR TIGO EJECUTADO
final ejecutarTigo = FutureProvider.family<bool, (String,int)>((ref,params) async {
  final repo = ConsumoTigoImpl();
  return await repo.insertarTigoEjectuado(params.$1,params.$2);
});
//obtener tigo ejecutado
final obtenerTigoEjecutado= FutureProvider.family<List<TigoEjecutadoEntity>,(String?, String)>((ref,params) async {
  final repo = ConsumoTigoImpl();
  final getTigoEjecutado = await repo.obtenerTigoEjecutado(params.$1,params.$2);
  return getTigoEjecutado;
});
//obtener nros sin asignar
final obtenerNroSinAsignar= FutureProvider.family<List<SocioTigoEntity>,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  final getNrosSinAsignar = await repo.obtenerNroSinAsignar(periodoCobrado);
  return getNrosSinAsignar;
});
final tigoArbolDetallado = FutureProvider.family<List<TigoEjecutadoEntity>,(String?, String)>((ref, params) async {
  final repo = ConsumoTigoImpl();
  final arbolResumenDetallado = await repo.obtenerArbolDetallado(params.$1,params.$2);
  return arbolResumenDetallado;
});
//descargar reporte cambios tigo
final rptCambiosTigo = FutureProvider.family<Uint8List,String>((ref,periodoCobrado) async {
  final repo = ConsumoTigoImpl();
  return await repo.descargarRptCambiosTigo(periodoCobrado); // Este método debe retornar Uint8List
});
// PARA ACTUALIZAR EMPRESA EN LOTES - tigo ejecutado
final actualizarEmpresaLoteProvider = FutureProvider.family<bool, TigoEjecutadoEntity>(
  (ref, tigoEjecutado) async {
    final repo = ConsumoTigoImpl();
    return await repo.actualizarEmpresaLote(tigoEjecutado);
  },
);
//provider para obtener tipo renovacion de chip tigo
final obtenerTipoRenovacionChip = FutureProvider<List<TipoRenovacionChipTigoEntity>>((ref) async {
  final repo = ConsumoTigoImpl();
  final tipoRenovacion = await repo.obtenerTipoRenovacion();
  return tipoRenovacion;
});
final rptCorporativosPersonal = FutureProvider.family<Uint8List, String>((ref, periodo) async {
  // Es mejor usar ref.watch para dependencias de otros providers
  final repo = ref.watch(consumoTigoRepositoryProvider); 
  return await repo.descargarRptCorporativosPersonal(periodo);
});

final rptComparacionEmpresas = FutureProvider<Uint8List>((ref) async {
  final repo = ref.watch(consumoTigoRepositoryProvider);
  return await repo.descargarRptComparacionEmpresas();
});
// ───────────────────────────────────────────────────────────────────────
// PROVIDER GLOBAL
// ───────────────────────────────────────────────────────────────────────
final chipTigoProvider = StateNotifierProvider.autoDispose<ChipTigoNotifier, ChipTigoState>((ref) {
  return ChipTigoNotifier(ref);
});


// ═══════════════════════════════════════════════════════════════════════
// CAMBIOS DE LINEAS CORPORATIVAS TIGO
// Pegar al final del archivo de providers de Tigo
// ═══════════════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────────────
// ESTADO
// ───────────────────────────────────────────────────────────────────────

class CambiosTigoState {
  // Listas
  final List<CambiosTigoEntity> numerosAsignados;   // ACCION L
  final List<CambiosTigoEntity> cambiosRegistrados; // ACCION LC
  final List<CambiosTigoEntity> destinosDisponibles;// ACCION D

  // Filtros activos
  final String? search;
  final String? tipoSocioFiltro;   // 'EMPLEADO' | 'EXTERNO' | null
  final String? periodoCobrado;
  final String? estadoFiltro;      // 'P' | 'A' | null
  final List<String> periodosDisponibles;

  // Paginación
  final int pagina;
  final int tamanoPagina;

  // Loading por operacion
  final bool cargandoNumeros;
  final bool cargandoCambios;
  final bool cargandoDestinos;
  final bool guardando;
  final bool aplicando;

  // Mensajes
  final String? mensajeExito;
  final String? mensajeError;
  final String? mensajeAdvertencia; // Warning: empleado ya tiene corporativo

  // Resultado del aplicar
  final int? totalAplicados;
  final int? totalErrores;

  CambiosTigoState({
    this.numerosAsignados    = const [],
    this.cambiosRegistrados  = const [],
    this.destinosDisponibles = const [],
    this.search,
    this.tipoSocioFiltro,
    this.periodoCobrado,
    this.estadoFiltro,
    this.pagina          = 1,
    this.tamanoPagina    = 15,
    this.cargandoNumeros    = false,
    this.cargandoCambios    = false,
    this.cargandoDestinos   = false,
    this.guardando          = false,
    this.aplicando          = false,
    this.mensajeExito,
    this.mensajeError,
    this.mensajeAdvertencia,
    this.totalAplicados,
    this.totalErrores,
    this.periodosDisponibles = const [],
  });

  CambiosTigoState copyWith({
    List<CambiosTigoEntity>? numerosAsignados,
    List<CambiosTigoEntity>? cambiosRegistrados,
    List<CambiosTigoEntity>? destinosDisponibles,
    String? search,
    bool clearSearch = false,
    String? tipoSocioFiltro,
    bool clearTipoSocio = false,
    String? periodoCobrado,
    bool clearPeriodo = false,
    String? estadoFiltro,
    bool clearEstado = false,
    int? pagina,
    int? tamanoPagina,
    bool? cargandoNumeros,
    bool? cargandoCambios,
    bool? cargandoDestinos,
    bool? guardando,
    bool? aplicando,
    String? mensajeExito,
    bool clearMensajeExito = false,
    String? mensajeError,
    bool clearMensajeError = false,
    String? mensajeAdvertencia,
    bool clearMensajeAdvertencia = false,
    int? totalAplicados,
    int? totalErrores,
    List<String>? periodosDisponibles,
  }) {
    return CambiosTigoState(
      numerosAsignados:    numerosAsignados    ?? this.numerosAsignados,
      cambiosRegistrados:  cambiosRegistrados  ?? this.cambiosRegistrados,
      destinosDisponibles: destinosDisponibles ?? this.destinosDisponibles,
      search:          clearSearch     ? null : (search          ?? this.search),
      tipoSocioFiltro: clearTipoSocio  ? null : (tipoSocioFiltro ?? this.tipoSocioFiltro),
      periodoCobrado:  clearPeriodo    ? null : (periodoCobrado  ?? this.periodoCobrado),
      estadoFiltro:    clearEstado     ? null : (estadoFiltro    ?? this.estadoFiltro),
      pagina:          pagina          ?? this.pagina,
      tamanoPagina:    tamanoPagina    ?? this.tamanoPagina,
      cargandoNumeros:  cargandoNumeros  ?? this.cargandoNumeros,
      cargandoCambios:  cargandoCambios  ?? this.cargandoCambios,
      cargandoDestinos: cargandoDestinos ?? this.cargandoDestinos,
      guardando:        guardando        ?? this.guardando,
      aplicando:        aplicando        ?? this.aplicando,
      mensajeExito:
          clearMensajeExito ? null : (mensajeExito ?? this.mensajeExito),
      mensajeError:
          clearMensajeError ? null : (mensajeError ?? this.mensajeError),
      mensajeAdvertencia:
          clearMensajeAdvertencia
              ? null
              : (mensajeAdvertencia ?? this.mensajeAdvertencia),
      totalAplicados: totalAplicados ?? this.totalAplicados,
      totalErrores:   totalErrores   ?? this.totalErrores,
      periodosDisponibles: periodosDisponibles ?? this.periodosDisponibles,
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// NOTIFIER
// ───────────────────────────────────────────────────────────────────────

class CambiosTigoNotifier extends StateNotifier<CambiosTigoState> {
    final Ref ref;
  final ConsumoTigoImpl _repo = ConsumoTigoImpl();

  CambiosTigoNotifier(this.ref) : super(CambiosTigoState()) {
    //cargarNumerosAsignados();
  }

  // ── Filtros ──────────────────────────────────────────────────────────

  void setSearch(String? valor) {
    state = state.copyWith(
      search:      valor,
      clearSearch: valor == null || valor.isEmpty,
      pagina:      1,
    );
    cargarNumerosAsignados();
  }

  void setTipoSocio(String? valor) {
    state = state.copyWith(
      tipoSocioFiltro: valor,
      clearTipoSocio:  valor == null,
      pagina:          1,
    );
    cargarNumerosAsignados();
  }

void setPeriodoCobrado(String periodo) {
  state = state.copyWith(periodoCobrado: periodo);
  // Al cambiar el periodo, invalidamos el reporte para que el 
  // próximo clic en el PDF sea obligatorio ir al servidor.
  ref.invalidate(rptCambioLineaTigoProvider(periodo));
  cargarCambiosRegistrados();
}
void setEstadoFiltro(String? valor) {
    state = state.copyWith(
      estadoFiltro: valor,
      clearEstado:  valor == null,
    );
    // Cada vez que cambia el estado, recargamos el historial
    cargarCambiosRegistrados();
  }

  void setPagina(int pagina) {
    state = state.copyWith(pagina: pagina);
  }

  void setTamanoPagina(int tamanoPagina) {
    state = state.copyWith(tamanoPagina: tamanoPagina, pagina: 1);
  }

  void limpiarMensajes() {
    state = state.copyWith(
      clearMensajeExito:       true,
      clearMensajeError:       true,
      clearMensajeAdvertencia: true,
    );
  }
  // <--- NUEVO METODO PARA CARGAR PERIODOS --->
Future<void> cargarPeriodos(String periodoPorDefecto) async {
  try {
    final listaDB = await _repo.obtenerPeriodosCambio();

    // Siempre intentar usar periodoPorDefecto si existe en la lista nueva.
    // Si no existe (periodo eliminado), caer al primero.
    // Si la lista está vacía, usar 'TODOS'.
    final String? periodoInicial;
    if (listaDB.contains(periodoPorDefecto)) {
      periodoInicial = periodoPorDefecto;       // ← periodo preferido encontrado
    } else if (listaDB.isNotEmpty) {
      periodoInicial = listaDB.first;           // ← fallback al más reciente
    } else {
      periodoInicial = null;
    }

    if (!mounted) return;
    state = state.copyWith(
      periodosDisponibles: listaDB,
      periodoCobrado:      periodoInicial,
    );
    cargarCambiosRegistrados();
  } catch (e) {
    console('Error cargarPeriodos: $e');
  }
}

  // ── ACCION L: Lista unificada de numeros ──────────────────────────────

  Future<void> cargarNumerosAsignados() async {
    state = state.copyWith(
      cargandoNumeros: true,
      clearMensajeError: true,
    );
    try {
      final lista = await _repo.listarNumerosAsignados(
        CambiosTigoEntity(
          search:       (state.search?.isNotEmpty == true) ? state.search : null,
          tipoSocio:    (state.tipoSocioFiltro?.isNotEmpty == true)
                        ? state.tipoSocioFiltro! : '',
          pagina:       state.pagina,
          tamanoPagina: state.tamanoPagina,
        ),
      );
      state = state.copyWith(
        numerosAsignados: lista,
        cargandoNumeros:  false,
      );
    } catch (e) {
      console('Error cargarNumerosAsignados: $e');
      state = state.copyWith(
        cargandoNumeros: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── ACCION LC: Historial de cambios ───────────────────────────────────

Future<void> cargarCambiosRegistrados() async {
    // Si el valor seleccionado es 'TODOS' o no hay nada, enviamos vacío ('') al SP
    final String filtroPeriodo = (state.periodoCobrado == 'TODOS' || state.periodoCobrado == null) 
        ? '' 
        : state.periodoCobrado!;

    state = state.copyWith(
      cargandoCambios: true,
      clearMensajeError: true,
    );
    try {
      final lista = await _repo.listarCambiosLinea(
        CambiosTigoEntity(
          periodoCobrado: filtroPeriodo, // <--- Usamos el string vacío si es 'TODOS'
          estado: (state.estadoFiltro?.isNotEmpty == true) ? state.estadoFiltro! : '',
        ),
      );
      state = state.copyWith(
        cambiosRegistrados: lista,
        cargandoCambios:    false,
      );
    } catch (e) {
      console('Error cargarCambiosRegistrados: $e');
      state = state.copyWith(
        cargandoCambios: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── ACCION D: Destinos para dropdown ─────────────────────────────────

  Future<void> cargarDestinos({String? search, String? tipoSocio}) async {
    state = state.copyWith(cargandoDestinos: true);
    try {
      final lista = await _repo.listarDestinosLinea(
        CambiosTigoEntity(
          // search: null si vacío → SQL devuelve todos
          search:    (search?.isNotEmpty == true) ? search : null,
          // tipoSocio: null si no hay filtro → SQL devuelve EMPLEADO + EXTERNO
          tipoSocio: (tipoSocio?.isNotEmpty == true) ? tipoSocio! : '',
        ),
      );
      state = state.copyWith(
        destinosDisponibles: lista,
        cargandoDestinos:    false,
      );
    } catch (e) {
      console('Error cargarDestinos: $e');
      state = state.copyWith(cargandoDestinos: false);
    }
  }

  // ── ACCION I/U: Registrar o actualizar cambio ─────────────────────────

  Future<bool> registrarCambio(CambiosTigoEntity entity, int audUsuario) async {
    state = state.copyWith(
      guardando:               true,
      clearMensajeError:       true,
      clearMensajeExito:       true,
      clearMensajeAdvertencia: true,
    );
    try {
      await _repo.registrarCambioLinea(
        entity.copyWith(audUsuario: audUsuario),
      );

      await cargarNumerosAsignados();
       // ── FIX: si es INSERT, navegar al periodo del nuevo registro ──────
    // Si es UPDATE, mantener el periodo que el usuario ya tenía seleccionado.
    final periodoDestino = (entity.codCambio == 0)
        ? entity.periodoCobrado          // INSERT → ir al nuevo periodo
        : (state.periodoCobrado ?? entity.periodoCobrado); // UPDATE → mantener
    // ─────────────────────────────────────────────────────────────────
      
// Unificamos usando el método de clase para que la lógica sea la misma siempre
      await cargarPeriodos(periodoDestino);
      if (!mounted) return false;
      //ref.invalidate(cambiosTigoProvider);
    ref.invalidate(obtenerTigoEjecutado);
    ref.invalidate(tigoArbolDetallado);
      state = state.copyWith(
        guardando:    false,
        mensajeExito: entity.codCambio == 0
            ? 'Cambio registrado correctamente para el periodo ${entity.periodoCobrado}.'
            : 'Cambio actualizado correctamente.',
      );
      return true;
    } catch (e) {
      console('Error registrarCambio: $e');
      if (!mounted) return false;  
      final mensaje = e.toString().replaceFirst('Exception: ', '');

      if (mensaje.toUpperCase().contains('ADVERTENCIA')) {
        await cargarNumerosAsignados();
        if (state.periodoCobrado != null) {
          await cargarCambiosRegistrados();
        }
        state = state.copyWith(
          guardando:          false,
          mensajeAdvertencia: mensaje,
        );
        return true;
      }

      state = state.copyWith(
        guardando:    false,
        mensajeError: mensaje,
      );
      return false;
    }
  }

  // ── ACCION D: Eliminar cambio pendiente ───────────────────────────────

  Future<bool> eliminarCambio(int codCambio, int audUsuario) async {
    state = state.copyWith(
      guardando:         true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );
    try {
      await _repo.eliminarCambioLinea(
        CambiosTigoEntity(
          codCambio:  codCambio,
          audUsuario: audUsuario,
        ),
      );
// --- REFRESH DE DATOS ---
      await cargarNumerosAsignados();
      await cargarCambiosRegistrados(); 
      // Refrescamos la lista de periodos (por si el mes eliminado ya no tiene registros)
      await cargarPeriodos(state.periodoCobrado ?? 'TODOS');

      if (!mounted) return false; 
      state = state.copyWith(
        guardando:    false,
        mensajeExito: 'Cambio eliminado correctamente.',
      );
      return true;
    } catch (e) {
      console('Error eliminarCambio: $e');
      if (!mounted) return false;  
      state = state.copyWith(
        guardando:    false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // ── ACCION A: Aplicar cambios del periodo ─────────────────────────────

  Future<bool> aplicarCambios(String periodoCobrado, int audUsuario) async {
if (periodoCobrado.isEmpty || periodoCobrado == 'TODOS') { // <--- Validación de seguridad
      state = state.copyWith(
        mensajeError: 'Debe seleccionar un periodo específico para aplicar cambios.',
      );
      return false;
    }
    state = state.copyWith(
      aplicando:         true,
      clearMensajeError: true,
      clearMensajeExito: true,
    );
    try {
      final totalAplicados = await _repo.aplicarCambiosLinea(
        CambiosTigoEntity(
          periodoCobrado: periodoCobrado,
          audUsuario:     audUsuario,
          codCambio: 0
        ),
      );

      // Recargar listas
      await cargarNumerosAsignados();
      //state = state.copyWith(periodoCobrado: periodoCobrado);
      await cargarCambiosRegistrados();
      if (!mounted) return false;
    
    // ✅ INVALIDA AQUÍ - Después de aplicar exitosamente
    //ref.invalidate(cambiosTigoProvider);
    ref.invalidate(obtenerTigoEjecutado);
    ref.invalidate(tigoArbolDetallado);
    ref.invalidate(facturasTigoProvider);

      state = state.copyWith(
        aplicando:      false,
        totalAplicados: totalAplicados.toInt(),
        mensajeExito:
            '${totalAplicados.toInt()} cambio(s) aplicado(s) para el periodo $periodoCobrado.',
      );
      return true;
    } catch (e) {
      console('Error aplicarCambios: $e');
      state = state.copyWith(
        aplicando:    false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
  // REASIGNAR NUMERO SIN ASIGNAR
  Future<bool> asignarNumeroSinAsignar(CambiosTigoEntity entity, int audUsuario) async {
  state = state.copyWith(
    guardando: true,
    clearMensajeError: true,
    clearMensajeExito: true,
  );
  try {
    await _repo.reasignarNumeroSinAsignar(
      entity.copyWith(audUsuario: audUsuario),
    );
    await cargarNumerosAsignados();
    ref.invalidate(obtenerNroSinAsignar);
    //ref.invalidate(cambiosTigoProvider);
    ref.invalidate(obtenerTigoEjecutado);
    ref.invalidate(tigoArbolDetallado);
    ref.invalidate(facturasTigoProvider);

    if (!mounted) return false;
    state = state.copyWith(
      guardando:    false,
      mensajeExito: 'Número ${entity.telefono} asignado correctamente.',
    );
    return true;
  } catch (e) {
    if (!mounted) return false;
    state = state.copyWith(
      guardando:    false,
      mensajeError: e.toString().replaceFirst('Exception: ', ''),
    );
    return false;
  }
}
}

// ───────────────────────────────────────────────────────────────────────
// PROVIDER
// ───────────────────────────────────────────────────────────────────────

final cambiosTigoProvider =
    StateNotifierProvider.autoDispose<CambiosTigoNotifier, CambiosTigoState>(
      (ref) => CambiosTigoNotifier( ref),
    );
    // ═══════════════════════════════════════════════════════════════════════
// MÓDULO: CHIPS TIGO (PÉRDIDAS Y REPOSICIONES)
// ═══════════════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────────────
// ESTADO (STATE)
// ───────────────────────────────────────────────────────────────────────
class ChipTigoState {
  // Lista principal (Acción L)
  final List<ChipTigoEntity> chipsPerdidos;

  // Filtros y Paginación (Coherente con el SP SQL)
  final String? search;
  final int pagina;
  final int tamanoPagina;
  final String? periodoFiltro;
  final List<String> periodos;  

  // Banderas de UI
  final bool cargando;
  final bool guardando;

  // Mensajes de respuesta (Heavy SQL)
  final String? mensajeExito;
  final String? mensajeError;

  ChipTigoState({
    this.chipsPerdidos = const [],
    this.search,
    this.pagina = 1,
    this.tamanoPagina = 15, // Por defecto en el SP
    this.cargando = false,
    this.guardando = false,
    this.mensajeExito,
    this.mensajeError,
    this.periodoFiltro,
    this.periodos = const [],
  });

  ChipTigoState copyWith({
    List<ChipTigoEntity>? chipsPerdidos,
    String? search,
    bool clearSearch = false,
    int? pagina,
    int? tamanoPagina,
    bool? cargando,
    bool? guardando,
    String? mensajeExito,
    bool clearMensajeExito = false,
    String? mensajeError,
    bool clearMensajeError = false,
      String? periodoFiltro,
        List<String>? periodos,
  }) {
    return ChipTigoState(
      chipsPerdidos: chipsPerdidos ?? this.chipsPerdidos,
      search: clearSearch ? null : (search ?? this.search),
      pagina: pagina ?? this.pagina,
      tamanoPagina: tamanoPagina ?? this.tamanoPagina,
      cargando: cargando ?? this.cargando,
      guardando: guardando ?? this.guardando,
      mensajeExito: clearMensajeExito ? null : (mensajeExito ?? this.mensajeExito),
      mensajeError: clearMensajeError ? null : (mensajeError ?? this.mensajeError),
      periodoFiltro: periodoFiltro ?? this.periodoFiltro,
      periodos: periodos ?? this.periodos,
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// NOTIFIER (LÓGICA DE NEGOCIO Y CONEXIÓN CON IMPL)
// ───────────────────────────────────────────────────────────────────────
class ChipTigoNotifier extends StateNotifier<ChipTigoState> {
  final Ref ref;
  final ConsumoTigoImpl _repo = ConsumoTigoImpl();

  ChipTigoNotifier(this.ref) : super(ChipTigoState()) {
    // Cargar la lista automáticamente al inicializar el provider
    cargarPeriodos(); // Cargar periodos disponibles para el filtro
    cargarChipsPerdidos();
  }

  // ── Filtros y Paginación ──────────────────────────────────────────────
  void setSearch(String? valor) {
    state = state.copyWith(
      search: valor,
      clearSearch: valor == null || valor.isEmpty,
      pagina: 1, // Resetear a la primera página al buscar
    );
    cargarChipsPerdidos();
  }

  void setPagina(int pagina) {
    state = state.copyWith(pagina: pagina);
    cargarChipsPerdidos();
  }

  void limpiarMensajes() {
    state = state.copyWith(
      clearMensajeExito: true,
      clearMensajeError: true,
    );
  }
  void setPeriodo(String? periodo) {
  state = state.copyWith(periodoFiltro: periodo,
  pagina: 1);
  cargarChipsPerdidos();
}

  // ── ACCIÓN L: Listar ──────────────────────────────────────────────────
  Future<void> cargarChipsPerdidos() async {
    state = state.copyWith(cargando: true, clearMensajeError: true);
    try {
      final lista = await _repo.listarChipsPerdidos(
        ChipTigoEntity(
          search: (state.search?.isNotEmpty == true) ? state.search : null,
          pagina: state.pagina,
          tamanoPagina: state.tamanoPagina,
          // Campos obligatorios del entity pero ignorados por el SP en Listado
          codLinea: 0, codEmpleado: 0, fechaSolicitud: DateTime.now(),
          telefono: '', nombreCompleto: '', descripcion: '',
          audUsuarioI: 0, audFechaI: DateTime.now(), fila: 0,
          periodo: state.periodoFiltro, // Filtro adicional para el periodo cobrado
        ),
      );
      
      state = state.copyWith(
        chipsPerdidos: lista,
        cargando: false,
      );
    } catch (e) {
      console('Error cargarChipsPerdidos: $e');
      state = state.copyWith(
        cargando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── ACCIÓN I / U: Registrar o Actualizar ──────────────────────────────
  Future<bool> registrarChip(ChipTigoEntity entity, int audUsuario) async {
    state = state.copyWith(guardando: true, clearMensajeError: true, clearMensajeExito: true);
    try {
      // Ahora recibimos el String con el texto "Registro insertado correctamente"
      final msgExito = await _repo.registrarPerdidaChip(
        entity.copyWith(audUsuarioI: audUsuario),
      );

      await cargarChipsPerdidos(); 
      await cargarPeriodos();
      ref.invalidate(rptPerdidaLineasProvider);
      
      state = state.copyWith(
        guardando: false,
        mensajeExito: msgExito, // Asignamos el mensaje del SP al estado
      );
      return true;
    } catch (e) {
      console('Error registrarChip: $e');
      state = state.copyWith(
        guardando: false,
        // Limpiamos el texto "Exception: " para que el usuario solo lea el error de SQL
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // ── ACCIÓN D: Eliminar ────────────────────────────────────────────────
  Future<bool> eliminarChip(ChipTigoEntity entity) async {
    state = state.copyWith(guardando: true, clearMensajeError: true, clearMensajeExito: true);
    try {
      final exito = await _repo.eliminarRegistroPerdida(entity);
      
      if (exito) {
        await cargarChipsPerdidos(); 
        ref.invalidate(rptPerdidaLineasProvider);
        state = state.copyWith(
          guardando: false,
          mensajeExito: 'Registro eliminado correctamente.',
        );
        return true;
      }
      return false;
    } catch (e) {
      console('Error eliminarChip: $e');
      state = state.copyWith(
        guardando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
  //ACCION A: Cargar periodos disponibles para el filtro
Future<void> cargarPeriodos() async {
  try {
    final lista = await _repo.obtenerPeriodos();
    state = state.copyWith(
      periodos: lista,
      // Si el periodoFiltro es null, ponemos 'TODOS' (que debería ser el primero en la lista)
      periodoFiltro: state.periodoFiltro ?? (lista.isNotEmpty ? lista.first : 'TODOS'),
    );
  } catch (e) {
    console('Error en cargarPeriodos: $e');
  }
}
}
// 1. El Provider del Reporte que "observa" el periodo seleccionado
final rptPerdidaLineasProvider = FutureProvider.family<Uint8List, String>((ref, periodo) async {
  final repo = ref.read(consumoTigoRepositoryProvider);
  return await repo.descargarRptPerdidaLineas(periodo);
});
//provider reporte RptCambiosLineaTigo
final rptCambioLineaTigoProvider = FutureProvider.family<Uint8List, String>((ref, periodo) async {
  final repo = ref.read(consumoTigoRepositoryProvider);
  return await repo.descargarRptCambiosLineaTigo(periodo);
});
// ─────────────────────────────────────────────────────────────────────────────
// AGREGAR AL FINAL de consumo_tigo_provider.dart
// StateNotifier para ResumenDetalladoScreen
// Maneja: ejecutar periodo, filtros y estado de la pantalla
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════
// ESTADO
// ═══════════════════════════════════════════════════════════════════════
class ResumenDetalladoState {
  final bool ejecutando;
  final bool mostrarEjecutado;   // false=preview(N), true=ejecutado(K)
  final String? empresaFiltro;   // null=todas
  final String buscadorTexto;    // búsqueda en árbol
  final String? mensajeExito;
  final String? mensajeError;
  final int?    registrosProcesados;

  const ResumenDetalladoState({
    this.ejecutando          = false,
    this.mostrarEjecutado    = false,
    this.empresaFiltro,
    this.buscadorTexto       = '',
    this.mensajeExito,
    this.mensajeError,
    this.registrosProcesados,
  });

  ResumenDetalladoState copyWith({
    bool?   ejecutando,
    bool?   mostrarEjecutado,
    String? empresaFiltro,
    bool    clearEmpresa      = false,
    String? buscadorTexto,
    String? mensajeExito,
    bool    clearMensajeExito = false,
    String? mensajeError,
    bool    clearMensajeError = false,
    int?    registrosProcesados,
  }) {
    return ResumenDetalladoState(
      ejecutando:          ejecutando       ?? this.ejecutando,
      mostrarEjecutado:    mostrarEjecutado ?? this.mostrarEjecutado,
      empresaFiltro:       clearEmpresa     ? null : (empresaFiltro ?? this.empresaFiltro),
      buscadorTexto:       buscadorTexto    ?? this.buscadorTexto,
      mensajeExito:        clearMensajeExito ? null : (mensajeExito ?? this.mensajeExito),
      mensajeError:        clearMensajeError ? null : (mensajeError ?? this.mensajeError),
      registrosProcesados: registrosProcesados ?? this.registrosProcesados,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════
class ResumenDetalladoNotifier extends StateNotifier<ResumenDetalladoState> {
  final Ref ref;
  final ConsumoTigoImpl _repo = ConsumoTigoImpl();

  ResumenDetalladoNotifier(this.ref) : super(const ResumenDetalladoState());

  // ── Filtros ────────────────────────────────────────────────────────
  void setEmpresa(String? empresa) =>
      state = state.copyWith(empresaFiltro: empresa, clearEmpresa: empresa == null);

  void setBuscador(String texto) =>
      state = state.copyWith(buscadorTexto: texto.trim().toLowerCase());

  void setMostrarEjecutado(bool valor) =>
      state = state.copyWith(mostrarEjecutado: valor);

  void limpiarMensajes() => state = state.copyWith(
        clearMensajeExito: true,
        clearMensajeError: true,
      );

  // ── Ejecutar periodo (ACCION='E') — toda la lógica en SQL ──────────
  /// Llama al nuevo endpoint /ejecutarPeriodoTigo que unifica
  /// generarAnticiposTigo (B) + registrarTigoEjecutado (G)
  /// en una sola transacción con validaciones SQL.
  Future<bool> ejecutarPeriodo(String periodoCobrado, int audUsuarioI) async {
    state = state.copyWith(
      ejecutando:        true,
      clearMensajeExito: true,
      clearMensajeError: true,
    );

    try {
      // Construir entity con los datos mínimos que necesita el SP
      final entity = TigoEjecutadoEntity(
        codCuenta:            0,
        corporativo:          '',
        codEmpleado:          0,
        nombreCompleto:       '',
        descripcion:          '',
        ciNumero:             '',
        empresa:              null,
        periodoCobrado:       periodoCobrado,
        estado:               '',
        totalCobradoXCuenta:  0,
        montoCubiertoXEmpresa: 0,
        montoEmpleado:        0,
        audUsuarioI:           audUsuarioI,
        fila:                 0,
        codEmpleadoPadre:     0,
        items:                [],
      );

      final res = await _repo.ejecutarPeriodoTigo(entity);
      if (!mounted) return false;   
      // Invalidar proveedores afectados
      ref.invalidate(facturasTigoProvider);
      ref.invalidate(obtenerTigoEjecutado((null, periodoCobrado)));
      ref.invalidate(tigoArbolDetallado((null, periodoCobrado)));
      ref.invalidate(tigoResumenDetallado(periodoCobrado));

      state = state.copyWith(
        ejecutando:          false,
        mostrarEjecutado:    true,
        mensajeExito:        res.resumen,
        registrosProcesados: res.idGenerado,
      );
      return true;

    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!mounted) return false; 
      state = state.copyWith(
        ejecutando:    false,
        mensajeError:  msg,
      );
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDER — con .family para que cada pantalla tenga su instancia
// ═══════════════════════════════════════════════════════════════════════
final resumenDetalladoProvider = StateNotifierProvider.autoDispose.family<
    ResumenDetalladoNotifier,
    ResumenDetalladoState,
    String>(
  (ref, periodoCobrado) => ResumenDetalladoNotifier(ref),
);