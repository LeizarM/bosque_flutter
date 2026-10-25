import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_carton_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_celda_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_ganador_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_juego_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_participante_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_sorteo_model.dart';
import 'package:bosque_flutter/data/models/ttk_empleado_bingo_model.dart';
import 'package:bosque_flutter/data/models/ttk_estado_encargado_model.dart';
import 'package:bosque_flutter/data/models/ttk_estado_publico_model.dart';
import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/data/models/ttk_ranking_carton_model.dart';
import 'package:bosque_flutter/data/repositories/ttk_api_base.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_carton_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_celda_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_ganador_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_juego_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_sorteo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_empleado_bingo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_ranking_carton_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_repository.dart';

/// Endpoints `/bingo` del contrato (encargado, panel y participante).
class TtkBingoImpl extends TtkApiBase implements TtkBingoRepository {
  Map<String, dynamic> _bingo(BigInt codBingo) =>
      ttkCuerpo({'codBingo': codBingo});
  Map<String, dynamic> _carton(BigInt codCarton) =>
      ttkCuerpo({'codCarton': codCarton});
  Map<String, dynamic> _juego(BigInt codJuego) =>
      ttkCuerpo({'codJuego': codJuego});

  List<TtkBingoCeldaEntity> _celdas(List<TtkBingoCeldaModel> m) => [
    for (final c in m) c.toEntity(),
  ];

  // ── Configuración ──
  @override
  Future<List<TtkBingoEntity>> listarBingos({
    BigInt? codBingo,
    BigInt? codEvento,
  }) => postAndReturnList(
    endpoint: AppConstants.ttkBingoListar,
    data: ttkCuerpo({'codBingo': codBingo, 'codEvento': codEvento}),
    fromJson: (j) => TtkBingoModel.fromJson(j).toEntity(),
  );

  @override
  Future<TtkRespuesta> guardarBingo(TtkBingoEntity bingo) => escribir(
    AppConstants.ttkBingoGuardar,
    TtkBingoModel.fromEntity(bingo).toJson(),
    errorMessage: 'No se pudo guardar la configuración.',
  );

  @override
  Future<TtkRespuesta> abrirEleccion(BigInt codBingo) =>
      escribir(AppConstants.ttkBingoAbrirEleccion, _bingo(codBingo));

  @override
  Future<TtkRespuesta> iniciarBingo(BigInt codBingo) =>
      escribir(AppConstants.ttkBingoIniciar, _bingo(codBingo));

  @override
  Future<TtkRespuesta> finalizarBingo(BigInt codBingo) =>
      escribir(AppConstants.ttkBingoFinalizar, _bingo(codBingo));

  @override
  Future<List<TtkBingoJuegoEntity>> listarJuegos(BigInt codBingo) =>
      postAndReturnList(
        endpoint: AppConstants.ttkJuegoListar,
        data: _bingo(codBingo),
        fromJson: (j) => TtkBingoJuegoModel.fromJson(j).toEntity(),
      );

  @override
  Future<TtkRespuesta> guardarJuego(TtkBingoJuegoEntity juego) => escribir(
    AppConstants.ttkJuegoGuardar,
    TtkBingoJuegoModel.fromEntity(juego).toJson(),
    errorMessage: 'No se pudo guardar la figura.',
  );

  @override
  Future<TtkRespuesta> generarCartones(BigInt codBingo) =>
      escribir(AppConstants.ttkCartonGenerar, _bingo(codBingo));

  @override
  Future<List<TtkBingoCartonEntity>> listarCartones(
    BigInt codBingo, {
    bool? soloDisponibles,
    String? buscar,
    BigInt? codEmpleado,
    BigInt? codParticipante,
  }) => postAndReturnList(
    endpoint: AppConstants.ttkCartonListar,
    data: ttkCuerpo({
      'codBingo': codBingo,
      'soloDisponibles': ttkBandera(soloDisponibles),
      'buscar': ttkTextoN(buscar),
      'codEmpleado': codEmpleado,
      'codParticipante': codParticipante,
    }),
    fromJson: (j) => TtkBingoCartonModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<TtkEmpleadoBingoEntity>> empleadosParaCarton(
    BigInt codBingo, {
    String? buscar,
  }) => postAndReturnList(
    endpoint: AppConstants.ttkCartonEmpleados,
    data: ttkCuerpo({'codBingo': codBingo, 'buscar': ttkTextoN(buscar)}),
    fromJson: (j) => TtkEmpleadoBingoModel.fromJson(j).toEntity(),
  );

  @override
  Future<TtkRespuesta> asignarCarton(
    BigInt codCarton, {
    BigInt? codParticipante,
    BigInt? codEmpleado,
    bool? impreso,
  }) => escribir(AppConstants.ttkCartonAsignar, {
    ...TtkBingoCartonModel.fromEntity(
      TtkBingoCartonEntity(
        codCarton: codCarton,
        codParticipante: codParticipante,
        codEmpleado: codEmpleado,
      ),
    ).toJson(),
    ...ttkCuerpo({'impreso': ttkBandera(impreso)}),
  });

  @override
  Future<TtkRespuesta> liberarCarton(BigInt codCarton) =>
      escribir(AppConstants.ttkCartonLiberar, _carton(codCarton));

  @override
  Future<TtkRespuesta> cambiarFormaCarton(
    BigInt codCarton, {
    required bool impreso,
  }) => escribir(
    AppConstants.ttkCartonForma,
    ttkCuerpo({'codCarton': codCarton, 'impreso': ttkBandera(impreso)}),
  );

  @override
  Future<List<TtkBingoCeldaEntity>> celdasCarton(BigInt codCarton) async =>
      _celdas(
        await postAndReturnList(
          endpoint: AppConstants.ttkCartonCeldas,
          data: _carton(codCarton),
          fromJson: TtkBingoCeldaModel.fromJson,
        ),
      );

  @override
  Future<List<TtkBingoCeldaEntity>> cartonesParaImprimir(
    BigInt codBingo, {
    BigInt? codEmpleado,
    int? nroDesde,
    int? nroHasta,
    bool? soloAsignados,
    bool? soloImpresos,
  }) async => _celdas(
    await postAndReturnList(
      endpoint: AppConstants.ttkCartonImpresion,
      data: ttkCuerpo({
        'codBingo': codBingo,
        'codEmpleado': codEmpleado,
        'nroDesde': nroDesde,
        'nroHasta': nroHasta,
        'soloAsignados': ttkBandera(soloAsignados),
        'soloImpresos': ttkBandera(soloImpresos),
      }),
      fromJson: TtkBingoCeldaModel.fromJson,
    ),
  );

  // ── Panel en vivo ──
  @override
  Future<TtkRespuesta> comenzarJuego(BigInt codJuego) =>
      escribir(AppConstants.ttkJuegoComenzar, _juego(codJuego));

  @override
  Future<TtkRespuesta> finalizarJuego(BigInt codJuego) =>
      escribir(AppConstants.ttkJuegoFinalizar, _juego(codJuego));

  @override
  Future<TtkRespuesta> marcarBolillo(BigInt codBingo, int nroBolillo) =>
      escribir(
        AppConstants.ttkSorteoMarcar,
        TtkBingoSorteoModel.fromEntity(
          TtkBingoSorteoEntity(codBingo: codBingo, nroBolillo: nroBolillo),
        ).toJson(),
      );

  @override
  Future<TtkRespuesta> quitarBolillo(BigInt codBingo, int nroBolillo) =>
      escribir(
        AppConstants.ttkSorteoQuitar,
        TtkBingoSorteoModel.fromEntity(
          TtkBingoSorteoEntity(codBingo: codBingo, nroBolillo: nroBolillo),
        ).toJson(),
      );

  @override
  Future<TtkRankingCartonEntity?> validarCarton(
    BigInt codBingo,
    int nroCarton,
  ) async {
    final fila = await leerObjeto(
      AppConstants.ttkCartonValidar,
      ttkCuerpo({'codBingo': codBingo, 'nroCarton': nroCarton}),
    );
    return fila == null
        ? null
        : TtkRankingCartonModel.fromJson(fila).toEntity();
  }

  @override
  Future<TtkRespuesta> confirmarGanador(BigInt codBingo, int nroCarton) =>
      escribir(
        AppConstants.ttkGanadorConfirmar,
        TtkBingoGanadorModel.fromEntity(
          TtkBingoGanadorEntity(codBingo: codBingo, nroCarton: nroCarton),
        ).toJson(),
      );

  @override
  Future<TtkRespuesta> anularGanador(BigInt codGanador) => escribir(
    AppConstants.ttkGanadorAnular,
    ttkCuerpo({'codGanador': codGanador}),
  );

  @override
  Future<List<TtkBingoGanadorEntity>> listarGanadores(BigInt codBingo) =>
      postAndReturnList(
        endpoint: AppConstants.ttkGanadorListar,
        data: _bingo(codBingo),
        fromJson: (j) => TtkBingoGanadorModel.fromJson(j).toEntity(),
      );

  @override
  Future<TtkEstadoEncargadoEntity?> estadoEncargado(BigInt codBingo) async {
    final fila = await leerObjeto(
      AppConstants.ttkEstadoEncargado,
      _bingo(codBingo),
    );
    return fila == null
        ? null
        : TtkEstadoEncargadoModel.fromJson(fila).toEntity();
  }

  @override
  Future<TtkEstadoPublicoEntity?> estadoPublico(BigInt codBingo) async {
    final fila = await leerObjeto(
      AppConstants.ttkEstadoPublico,
      _bingo(codBingo),
    );
    return fila == null
        ? null
        : TtkEstadoPublicoModel.fromJson(fila).toEntity();
  }

  @override
  Future<TtkRespuesta> atenderAviso(BigInt codAviso) => escribir(
    AppConstants.ttkAvisoAtender,
    ttkCuerpo({'codAviso': codAviso}),
  );

  // ── Participante ──
  @override
  Future<List<TtkBingoParticipanteEntity>> misBingos() => postAndReturnList(
    endpoint: AppConstants.ttkMisBingos,
    fromJson: (j) => TtkBingoParticipanteModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<TtkBingoCartonEntity>> cartonesDisponibles(BigInt codBingo) =>
      postAndReturnList(
        endpoint: AppConstants.ttkCartonDisponibles,
        data: _bingo(codBingo),
        fromJson: (j) => TtkBingoCartonModel.fromJson(j).toEntity(),
      );

  @override
  Future<List<TtkBingoCartonEntity>> misCartones({BigInt? codBingo}) =>
      postAndReturnList(
        endpoint: AppConstants.ttkCartonMios,
        data: ttkCuerpo({'codBingo': codBingo}),
        fromJson: (j) => TtkBingoCartonModel.fromJson(j).toEntity(),
      );

  @override
  Future<List<TtkBingoCeldaEntity>> verCarton(BigInt codCarton) async =>
      _celdas(
        await postAndReturnList(
          endpoint: AppConstants.ttkCartonVer,
          data: _carton(codCarton),
          fromJson: TtkBingoCeldaModel.fromJson,
        ),
      );

  @override
  Future<List<TtkBingoCeldaEntity>> misCeldas({BigInt? codBingo}) async =>
      _celdas(
        await postAndReturnList(
          endpoint: AppConstants.ttkCartonMisCeldas,
          data: ttkCuerpo({'codBingo': codBingo}),
          fromJson: TtkBingoCeldaModel.fromJson,
        ),
      );

  @override
  Future<TtkRespuesta> elegirCarton(BigInt codCarton) =>
      escribir(AppConstants.ttkCartonElegir, _carton(codCarton));

  @override
  Future<TtkRespuesta> cantarBingo(BigInt codCarton) =>
      escribir(AppConstants.ttkAvisoCantar, _carton(codCarton));
}
