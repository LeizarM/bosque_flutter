// lib/core/state/talonarios_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/talonarios_impl.dart';
import 'package:bosque_flutter/domain/entities/talonario_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_grupo_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_por_grupo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_recibo_entity.dart';
import 'package:bosque_flutter/domain/repositories/talonarios_repository.dart';

/// Repositorio del módulo. Global: lo comparten todas las pantallas.
final talonariosRepositoryProvider = Provider<TalonariosRepository>((ref) {
  return TalonariosImpl();
});

/// Contador de refresco manual. Incrementarlo revalida los listados que lo
/// observan, que es como se recarga después de un alta, una entrega o un lote.
final talonariosRefreshProvider = StateProvider<int>((ref) => 0);

/// Llamar después de cualquier escritura para que las grillas se releen.
void refrescarTalonarios(WidgetRef ref) {
  ref.read(talonariosRefreshProvider.notifier).state++;
}

// ==================== CATÁLOGOS ====================

final tiposReciboProvider = FutureProvider<List<TipoReciboEntity>>((ref) async {
  ref.watch(talonariosRefreshProvider);
  return ref.watch(talonariosRepositoryProvider).listarTipos();
});

final talonarioGruposProvider = FutureProvider<List<TalonarioGrupoEntity>>((
  ref,
) async {
  ref.watch(talonariosRefreshProvider);
  return ref.watch(talonariosRepositoryProvider).listarGrupos();
});

/// Tipos asignados a un grupo. Con null trae todas las asignaciones.
final tiposPorGrupoProvider =
    FutureProvider.family<List<TalonarioPorGrupoEntity>, BigInt?>((
      ref,
      codGrupo,
    ) async {
      ref.watch(talonariosRefreshProvider);
      return ref.watch(talonariosRepositoryProvider).listarTiposPorGrupo(
        codGrupo,
      );
    });

/// Tipos que todavía NO están en el grupo, para el combo de agregar.
final tiposDisponiblesParaGrupoProvider =
    FutureProvider.family<List<TalonarioPorGrupoEntity>, BigInt>((
      ref,
      codGrupo,
    ) async {
      ref.watch(talonariosRefreshProvider);
      return ref.watch(talonariosRepositoryProvider).listarTiposDisponibles(
        codGrupo,
      );
    });

// ==================== TALONARIOS ====================

/// Clave del listado filtrado. Es un record, así que tiene igualdad
/// estructural y Riverpod cachea bien por combinación de filtros.
typedef FiltroTalonarios =
    ({
      BigInt? codTipoRecibo,
      BigInt? codEmpresa,
      BigInt? codGrupo,
      int? codEstadoActual,
      DateTime? desde,
      DateTime? hasta,
      bool incluirCerrados,
    });

/// Lo que se pide al entrar: **sin los cerrados**.
///
/// No es una preferencia estética. Los cerrados son estado terminal —no
/// admiten ninguna acción— y hoy son el 54% de las filas. Sacarlos lleva la
/// carga inicial de 1045 filas / 334 KB a 480 / 153 KB, y lo que queda es
/// justamente lo que la pantalla sirve para gestionar.
///
/// La base resuelve la consulta completa en 0 ms; el costo está en el payload
/// y en construir 1045 objetos en Dart.
const FiltroTalonarios filtroTalonariosVacio = (
  codTipoRecibo: null,
  codEmpresa: null,
  codGrupo: null,
  codEstadoActual: null,
  desde: null,
  hasta: null,
  incluirCerrados: false,
);

/// Listado con el estado ya calculado por el backend.
final talonariosProvider =
    FutureProvider.family<List<TalonarioEntity>, FiltroTalonarios>((
      ref,
      filtro,
    ) async {
      ref.watch(talonariosRefreshProvider);
      return ref.watch(talonariosRepositoryProvider).listarTalonarios(
        codTipoRecibo: filtro.codTipoRecibo,
        codEmpresa: filtro.codEmpresa,
        codGrupo: filtro.codGrupo,
        codEstadoActual: filtro.codEstadoActual,
        desde: filtro.desde,
        hasta: filtro.hasta,
        incluirCerrados: filtro.incluirCerrados,
      );
    });

/// Listos para entregar o reentregar. Es lo que alimenta la grilla de la
/// entrega masiva.
final talonariosDisponiblesProvider =
    FutureProvider.family<List<TalonarioEntity>, BigInt?>((
      ref,
      codGrupo,
    ) async {
      ref.watch(talonariosRefreshProvider);
      return ref.watch(talonariosRepositoryProvider).listarDisponibles(
        codGrupo: codGrupo,
      );
    });

/// Clave de [usoTipoEmpresaProvider].
typedef ComboTipoEmpresa = ({BigInt codTipoRecibo, BigInt codEmpresa});

/// Cuántos talonarios existen ya con esa combinación de tipo y empresa.
///
/// Sirve para avisar en el alta cuando alguien elige una sigla que nunca se
/// usó en esa empresa (p. ej. EC2, que es de Esppapel, en Impexpap).
///
/// **Es un aviso, no una regla.** No hay ninguna restricción en la base que
/// ate un tipo a una empresa, y el historial la contradiría: ER1 se usó en
/// Esppapel y en Impexpap, y PR2 en Impexpap y en Papirus. Bloquear sería
/// inventar una regla que el negocio no tiene.
final usoTipoEmpresaProvider =
    FutureProvider.family<int, ComboTipoEmpresa>((ref, combo) async {
      if (combo.codTipoRecibo == BigInt.zero || combo.codEmpresa == BigInt.zero) {
        return -1; // sin datos suficientes para opinar
      }
      final lista = await ref
          .watch(talonariosRepositoryProvider)
          .listarTalonarios(
            codTipoRecibo: combo.codTipoRecibo,
            codEmpresa: combo.codEmpresa,
          );
      return lista.length;
    });

final talonarioPorIdProvider =
    FutureProvider.family<TalonarioEntity?, BigInt>((ref, codTalonario) async {
      ref.watch(talonariosRefreshProvider);
      return ref.watch(talonariosRepositoryProvider).obtenerTalonario(
        codTalonario,
      );
    });

// ==================== EVENTOS ====================

/// Historial de un talonario, del evento más viejo al más nuevo.
final eventosTalonarioProvider =
    FutureProvider.family<List<TalonarioDetalleEntity>, BigInt>((
      ref,
      codTalonario,
    ) async {
      ref.watch(talonariosRefreshProvider);
      return ref.watch(talonariosRepositoryProvider).listarEventos(
        codTalonario,
      );
    });
