/// Módulo Bingo (`ttk`): configuración, panel en vivo, mis cartones y el
/// tablero público. Los estados en vivo se liberan al salir (autoDispose).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/network/tiempo_real.dart';
import 'package:bosque_flutter/core/utils/ttk_marcas_storage.dart';
import 'package:bosque_flutter/data/repositories/ttk_bingo_impl.dart';
import 'package:bosque_flutter/data/repositories/ttk_bingo_vivo_impl.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_carton_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_celda_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_ganador_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_juego_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_empleado_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_repository.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_vivo_repository.dart';

export 'package:bosque_flutter/core/network/tiempo_real.dart'
    show EstadoTiempoReal, TiempoRealNotifier;

/// Perezosos y reemplazables: las pruebas los cambian con `overrideWithValue`.
final ttkBingoRepositoryProvider = Provider<TtkBingoRepository>(
  (ref) => TtkBingoImpl(),
);

final ttkBingoVivoRepositoryProvider = Provider<TtkBingoVivoRepository>(
  (ref) => TtkBingoVivoImpl(),
);

/// El bingo que el encargado tiene abierto; lo comparten configuración y panel.
final ttkBingoElegidoProvider = StateProvider<BigInt?>((ref) => null);

final ttkBingosProvider = FutureProvider.autoDispose<List<TtkBingoEntity>>(
  (ref) => ref.watch(ttkBingoRepositoryProvider).listarBingos(),
);

final ttkJuegosProvider = FutureProvider.autoDispose
    .family<List<TtkBingoJuegoEntity>, BigInt>(
      (ref, codBingo) =>
          ref.watch(ttkBingoRepositoryProvider).listarJuegos(codBingo),
    );

typedef FiltroCartonesTtk =
    ({BigInt codBingo, bool? soloDisponibles, String buscar});

final ttkCartonesProvider = FutureProvider.autoDispose
    .family<List<TtkBingoCartonEntity>, FiltroCartonesTtk>(
      (ref, f) => ref
          .watch(ttkBingoRepositoryProvider)
          .listarCartones(
            f.codBingo,
            soloDisponibles: f.soloDisponibles,
            buscar: f.buscar,
          ),
    );

typedef FiltroEmpleadosBingoTtk = ({BigInt codBingo, String buscar});

final ttkEmpleadosBingoProvider = FutureProvider.autoDispose
    .family<List<TtkEmpleadoBingoEntity>, FiltroEmpleadosBingoTtk>(
      (ref, f) => ref
          .watch(ttkBingoRepositoryProvider)
          .empleadosParaCarton(f.codBingo, buscar: f.buscar),
    );

/// Casillas de un cartón: [encargado] usa `/carton/celdas`; si no, `/carton/ver`.
typedef ConsultaCeldasTtk = ({BigInt codCarton, bool encargado});

final ttkCeldasCartonProvider = FutureProvider.autoDispose
    .family<List<TtkBingoCeldaEntity>, ConsultaCeldasTtk>((ref, c) {
      final repo = ref.watch(ttkBingoRepositoryProvider);
      return c.encargado
          ? repo.celdasCarton(c.codCarton)
          : repo.verCarton(c.codCarton);
    });

final ttkGanadoresProvider = FutureProvider.autoDispose
    .family<List<TtkBingoGanadorEntity>, BigInt>(
      (ref, codBingo) =>
          ref.watch(ttkBingoRepositoryProvider).listarGanadores(codBingo),
    );

final ttkMisBingosProvider =
    FutureProvider.autoDispose<List<TtkBingoParticipanteEntity>>(
      (ref) => ref.watch(ttkBingoRepositoryProvider).misBingos(),
    );

final ttkCartonesDisponiblesProvider = FutureProvider.autoDispose
    .family<List<TtkBingoCartonEntity>, BigInt>(
      (ref, codBingo) =>
          ref.watch(ttkBingoRepositoryProvider).cartonesDisponibles(codBingo),
    );

final ttkMisCartonesProvider = FutureProvider.autoDispose
    .family<List<TtkBingoCartonEntity>, BigInt>(
      (ref, codBingo) =>
          ref.watch(ttkBingoRepositoryProvider).misCartones(codBingo: codBingo),
    );

/// Tablero público en vivo (participantes y proyector): nunca trae ranking.
final ttkVivoPublicoProvider = StateNotifierProvider.autoDispose.family<
  TiempoRealNotifier<TtkEstadoPublicoEntity>,
  EstadoTiempoReal<TtkEstadoPublicoEntity>,
  BigInt
>((ref, codBingo) {
  final repo = ref.watch(ttkBingoRepositoryProvider);
  final vivo = ref.watch(ttkBingoVivoRepositoryProvider);
  return TiempoRealNotifier<TtkEstadoPublicoEntity>(
    consultar: () => repo.estadoPublico(codBingo),
    version: (e) => e.version,
    suscribir:
        (alRecibir, alCambiar) =>
            vivo
                .escucharPublico(
                  codBingo,
                  alRecibir: alRecibir,
                  alCambiarConexion: alCambiar,
                )
                .cerrar,
  );
});

final ttkMarcasStorageProvider = Provider<TtkMarcasStorage>(
  (ref) => const TtkMarcasStorage(),
);

typedef ClaveMarcasTtk = ({BigInt codCarton, int nroJuego});

/// Marcas a mano de un juego del cartón (posiciones). El sistema no marca ni
/// avisa si ganó: el participante debe estar atento y gritar «¡Bingo!».
class MarcasCartonTtk extends StateNotifier<Set<int>> {
  MarcasCartonTtk(this._storage, this._clave) : super(const <int>{}) {
    _cargar();
  }

  final TtkMarcasStorage _storage;
  final ClaveMarcasTtk _clave;
  bool _tocado = false;

  Future<void> _cargar() async {
    final guardadas = await _storage.leer(_clave.codCarton, _clave.nroJuego);
    if (mounted && !_tocado) state = guardadas;
  }

  void alternar(int posicion) {
    _tocado = true;
    final nuevas = {...state};
    if (!nuevas.remove(posicion)) nuevas.add(posicion);
    state = nuevas;
    _storage.guardar(_clave.codCarton, _clave.nroJuego, nuevas);
  }
}

final ttkMarcasProvider = StateNotifierProvider.autoDispose.family<
  MarcasCartonTtk,
  Set<int>,
  ClaveMarcasTtk
>((ref, clave) => MarcasCartonTtk(ref.watch(ttkMarcasStorageProvider), clave));

/// Estado del panel del encargado: tablero, ranking, aviso y «¡Bingo!» pendientes.
final ttkVivoEncargadoProvider = StateNotifierProvider.autoDispose.family<
  TiempoRealNotifier<TtkEstadoEncargadoEntity>,
  EstadoTiempoReal<TtkEstadoEncargadoEntity>,
  BigInt
>((ref, codBingo) {
  final repo = ref.watch(ttkBingoRepositoryProvider);
  final vivo = ref.watch(ttkBingoVivoRepositoryProvider);
  return TiempoRealNotifier<TtkEstadoEncargadoEntity>(
    consultar: () => repo.estadoEncargado(codBingo),
    version: (e) => e.version,
    suscribir:
        (alRecibir, alCambiar) =>
            vivo
                .escucharEncargado(
                  codBingo,
                  alRecibir: alRecibir,
                  alCambiarConexion: alCambiar,
                )
                .cerrar,
  );
});
