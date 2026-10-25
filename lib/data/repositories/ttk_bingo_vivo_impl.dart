import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/tiempo_real.dart';
import 'package:bosque_flutter/data/models/ttk_estado_encargado_model.dart';
import 'package:bosque_flutter/data/models/ttk_estado_publico_model.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_vivo_repository.dart';

/// Tópicos del bingo sobre el canal STOMP genérico (`/ws`). Aquí solo se
/// eligen el destino y el model que convierte cada mensaje en entidad.
class TtkBingoVivoImpl implements TtkBingoVivoRepository {
  @override
  TtkSuscripcionVivo escucharPublico(
    BigInt codBingo, {
    required void Function(TtkEstadoPublicoEntity estado) alRecibir,
    required void Function(bool conectado) alCambiarConexion,
  }) => _abrir(
    AppConstants.ttkTopicoPublico(codBingo),
    (j) => alRecibir(TtkEstadoPublicoModel.fromJson(j).toEntity()),
    alCambiarConexion,
  );

  @override
  TtkSuscripcionVivo escucharEncargado(
    BigInt codBingo, {
    required void Function(TtkEstadoEncargadoEntity estado) alRecibir,
    required void Function(bool conectado) alCambiarConexion,
  }) => _abrir(
    AppConstants.ttkTopicoEncargado(codBingo),
    (j) => alRecibir(TtkEstadoEncargadoModel.fromJson(j).toEntity()),
    alCambiarConexion,
  );

  TtkSuscripcionVivo _abrir(
    String destino,
    void Function(Map<String, dynamic>) alMensaje,
    void Function(bool) alCambiarConexion,
  ) {
    final canal = CanalStomp(
      destino: destino,
      alMensaje: alMensaje,
      alCambiarConexion: alCambiarConexion,
    )..abrir();
    return _Suscripcion(canal);
  }
}

/// Adapta el canal genérico a la suscripción del dominio.
class _Suscripcion implements TtkSuscripcionVivo {
  const _Suscripcion(this._canal);

  final SuscripcionTiempoReal _canal;

  @override
  void cerrar() => _canal.cerrar();
}
