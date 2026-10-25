import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';

/// Una suscripción abierta al bingo en vivo; [cerrar] libera la conexión.
abstract interface class TtkSuscripcionVivo {
  void cerrar();
}

/// Canal en tiempo real (WebSocket STOMP `/ws-bingo`). Los mensajes llegan ya
/// como entidades; la reconexión con espera creciente la resuelve la fuente.
abstract class TtkBingoVivoRepository {
  TtkSuscripcionVivo escucharPublico(
    BigInt codBingo, {
    required void Function(TtkEstadoPublicoEntity estado) alRecibir,
    required void Function(bool conectado) alCambiarConexion,
  });

  TtkSuscripcionVivo escucharEncargado(
    BigInt codBingo, {
    required void Function(TtkEstadoEncargadoEntity estado) alRecibir,
    required void Function(bool conectado) alCambiarConexion,
  });
}
