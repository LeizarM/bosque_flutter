import 'package:bosque_flutter/domain/entities/ttk_bingo_carton_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_celda_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_ganador_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_juego_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_empleado_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_ranking_carton_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_tickets_repository.dart';

export 'package:bosque_flutter/domain/repositories/ttk_tickets_repository.dart'
    show TtkRespuesta;

/// Bingo: configuración y cartones (encargado), panel en vivo, y la parte del
/// participante (elegir, ver e imprimir sus cartones).
abstract class TtkBingoRepository {
  // ── Configuración ──
  Future<List<TtkBingoEntity>> listarBingos({
    BigInt? codBingo,
    BigInt? codEvento,
  });
  Future<TtkRespuesta> guardarBingo(TtkBingoEntity bingo);
  Future<TtkRespuesta> abrirEleccion(BigInt codBingo);
  Future<TtkRespuesta> iniciarBingo(BigInt codBingo);
  Future<TtkRespuesta> finalizarBingo(BigInt codBingo);
  Future<List<TtkBingoJuegoEntity>> listarJuegos(BigInt codBingo);
  Future<TtkRespuesta> guardarJuego(TtkBingoJuegoEntity juego);
  Future<TtkRespuesta> generarCartones(BigInt codBingo);
  Future<List<TtkBingoCartonEntity>> listarCartones(
    BigInt codBingo, {
    bool? soloDisponibles,
    String? buscar,
    BigInt? codEmpleado,
    BigInt? codParticipante,
  });
  Future<List<TtkEmpleadoBingoEntity>> empleadosParaCarton(
    BigInt codBingo, {
    String? buscar,
  });

  /// Con bingo por vales el dueño es [codParticipante]; si no, [codEmpleado].
  /// [impreso] solo cuenta con modalidad «ambos» (null: el SP decide).
  Future<TtkRespuesta> asignarCarton(
    BigInt codCarton, {
    BigInt? codParticipante,
    BigInt? codEmpleado,
    bool? impreso,
  });
  Future<TtkRespuesta> liberarCarton(BigInt codCarton);

  /// Con modalidad «ambos»: si el cartón se entrega impreso o se juega en pantalla.
  Future<TtkRespuesta> cambiarFormaCarton(
    BigInt codCarton, {
    required bool impreso,
  });
  Future<List<TtkBingoCeldaEntity>> celdasCarton(BigInt codCarton);
  Future<List<TtkBingoCeldaEntity>> cartonesParaImprimir(
    BigInt codBingo, {
    BigInt? codEmpleado,
    int? nroDesde,
    int? nroHasta,
    bool? soloAsignados,
    bool? soloImpresos,
  });

  // ── Panel en vivo ──
  Future<TtkRespuesta> comenzarJuego(BigInt codJuego);
  Future<TtkRespuesta> finalizarJuego(BigInt codJuego);
  Future<TtkRespuesta> marcarBolillo(BigInt codBingo, int nroBolillo);
  Future<TtkRespuesta> quitarBolillo(BigInt codBingo, int nroBolillo);
  Future<TtkRankingCartonEntity?> validarCarton(BigInt codBingo, int nroCarton);
  Future<TtkRespuesta> confirmarGanador(BigInt codBingo, int nroCarton);
  Future<TtkRespuesta> anularGanador(BigInt codGanador);
  Future<List<TtkBingoGanadorEntity>> listarGanadores(BigInt codBingo);
  Future<TtkEstadoEncargadoEntity?> estadoEncargado(BigInt codBingo);
  Future<TtkEstadoPublicoEntity?> estadoPublico(BigInt codBingo);

  /// El encargado da por atendido un «¡Bingo!» de un participante.
  Future<TtkRespuesta> atenderAviso(BigInt codAviso);

  // ── Participante ──
  Future<List<TtkBingoParticipanteEntity>> misBingos();
  Future<List<TtkBingoCartonEntity>> cartonesDisponibles(BigInt codBingo);
  Future<List<TtkBingoCartonEntity>> misCartones({BigInt? codBingo});
  Future<List<TtkBingoCeldaEntity>> verCarton(BigInt codCarton);
  Future<List<TtkBingoCeldaEntity>> misCeldas({BigInt? codBingo});
  Future<TtkRespuesta> elegirCarton(BigInt codCarton);

  /// Avisa «¡Bingo!» al encargado con un cartón propio; nunca dice si ganó.
  Future<TtkRespuesta> cantarBingo(BigInt codCarton);
}
