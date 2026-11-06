import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/hex_aprobador_model.dart';
import 'package:bosque_flutter/data/models/hex_comida_model.dart';
import 'package:bosque_flutter/data/models/hex_configuracion_evento_model.dart';
import 'package:bosque_flutter/data/models/hex_encargado_opcion_model.dart';
import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/data/models/hex_parametro_clave_model.dart';
import 'package:bosque_flutter/data/models/hex_parametro_model.dart';
import 'package:bosque_flutter/data/models/hex_parametro_opcion_model.dart';
import 'package:bosque_flutter/data/models/hex_rama_empleado_model.dart';
import 'package:bosque_flutter/data/models/hex_simulacion_model.dart';
import 'package:bosque_flutter/data/models/hex_tramo_mapa_model.dart';
import 'package:bosque_flutter/data/models/hex_tramo_model.dart';
import 'package:bosque_flutter/data/repositories/hex_api_base.dart';
import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_encargado_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_clave_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_rama_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_mapa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';

/// Parámetros, tramos, comidas y aprobadores contra `/horas-extras`. La
/// vigencia nueva manda la fila completa; el resto de las escrituras, solo el
/// id y el único campo que cambia, nunca la fila entera.
class HexConfiguracionImpl extends HexApiBase
    implements HexConfiguracionRepository {
  @override
  Future<List<HexParametroEntity>> parametros({String? clave}) => listar(
    AppConstants.hexParametroListar,
    hexCuerpo({'clave': clave}),
    (j) => HexParametroModel.fromJson(j).toEntity(),
  );

  @override
  Future<HexRespuesta> nuevaVigenciaParametro(HexParametroEntity p) => escribir(
    AppConstants.hexParametroVigencia,
    HexParametroModel.fromEntity(p).toJson(),
  );

  @override
  Future<HexRespuesta> editarLeyendaParametro(BigInt id, String leyenda) =>
      escribir(
        AppConstants.hexParametroEditarLeyenda,
        hexCuerpo({'idParametro': id, 'leyenda': leyenda}),
      );

  @override
  Future<HexRespuesta> eliminarParametro(BigInt id) => escribir(
    AppConstants.hexParametroEliminar,
    hexCuerpo({'idParametro': id}),
  );

  @override
  Future<List<HexParametroClaveEntity>> catalogoParametros() => listar(
    AppConstants.hexParametroCatalogo,
    const {},
    (j) => HexParametroClaveModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<HexParametroOpcionEntity>> opcionesParametro(String clave) =>
      listar(
        AppConstants.hexParametroOpciones,
        {'clave': clave},
        (j) => HexParametroOpcionModel.fromJson(j).toEntity(),
      );

  @override
  Future<HexRespuesta> dejarDeUsarParametro(
    BigInt idParametro,
    DateTime sinUsoDesde,
  ) => escribir(
    AppConstants.hexParametroDejarDeUsar,
    hexCuerpo({
      'idParametro': idParametro,
      'sinUsoDesde': hexDiaJson(sinUsoDesde),
    }),
  );

  @override
  Future<List<HexTramoEntity>> tramos({String? tipoDia, String? codigo}) =>
      listar(
        AppConstants.hexTramoListar,
        hexCuerpo({'tipoDia': tipoDia, 'codigo': codigo}),
        (j) => HexTramoModel.fromJson(j).toEntity(),
      );

  @override
  Future<HexRespuesta> nuevaVigenciaTramo(
    HexTramoEntity t, {
    bool confirmado = false,
  }) => escribir(AppConstants.hexTramoVigencia, {
    ...HexTramoModel.fromEntity(t).toJson(),
    // Solo viaja como `true` en el reenvío; nunca como `false`.
    ...hexCuerpo({'confirmado': confirmado ? true : null}),
  });

  @override
  Future<List<HexTramoMapaEntity>> mapaTramos({
    String? tipoDia,
    DateTime? fecha,
    String? codigo,
    String? horaDesde,
    String? horaHasta,
  }) => listar(
    AppConstants.hexTramoMapa,
    hexCuerpo({
      'tipoDia': tipoDia,
      'codigo': codigo,
      'horaDesde': hexHoraN(horaDesde),
      'horaHasta': hexHoraN(horaHasta),
      'vigenteDesde': hexDiaJson(fecha),
    }),
    (j) => HexTramoMapaModel.fromJson(j).toEntity(),
  );

  @override
  Future<HexSimulacionEntity> simularJornada({
    required BigInt codEmpleado,
    required DateTime fechaJornada,
    DateTime? inicio,
    DateTime? fin,
  }) async =>
      await leerUno(
        AppConstants.hexSimuladorJornada,
        hexCuerpo({
          'codEmpleado': codEmpleado,
          'fechaJornada': hexDiaJson(fechaJornada),
          'inicio': hexFechaHoraJson(inicio),
          'fin': hexFechaHoraJson(fin),
        }),
        (j) => HexSimulacionModel.fromJson(j).toEntity(),
      ) ??
      const HexSimulacionEntity();

  @override
  Future<HexRespuesta> editarLeyendaTramo(BigInt id, String leyenda) =>
      escribir(
        AppConstants.hexTramoEditarLeyenda,
        hexCuerpo({'idTramo': id, 'leyenda': leyenda}),
      );

  @override
  Future<HexRespuesta> eliminarTramo(BigInt id) =>
      escribir(AppConstants.hexTramoEliminar, hexCuerpo({'idTramo': id}));

  @override
  Future<List<HexComidaEntity>> comidas({String? codigo}) => listar(
    AppConstants.hexComidaListar,
    hexCuerpo({'codigo': codigo}),
    (j) => HexComidaModel.fromJson(j).toEntity(),
  );

  @override
  Future<HexRespuesta> nuevaVigenciaComida(HexComidaEntity c) => escribir(
    AppConstants.hexComidaVigencia,
    HexComidaModel.fromEntity(c).toJson(),
  );

  @override
  Future<HexRespuesta> periodoComida(HexComidaEntity c, {DateTime? hasta}) =>
      escribir(AppConstants.hexComidaPeriodo, {
        ...HexComidaModel.fromEntity(c).toJson()..remove('idComida'),
        ...hexCuerpo({'vigenteHasta': hexDiaJson(hasta)}),
      });

  @override
  Future<HexRespuesta> editarLeyendaComida(
    BigInt id, {
    String? leyenda,
    String? leyendaDoble,
  }) => escribir(
    AppConstants.hexComidaEditarLeyenda,
    hexCuerpo({
      'idComida': id,
      'leyenda': leyenda,
      'leyendaDoble': leyendaDoble,
    }),
  );

  @override
  Future<HexRespuesta> eliminarComida(BigInt id) =>
      escribir(AppConstants.hexComidaEliminar, hexCuerpo({'idComida': id}));

  @override
  Future<List<HexAprobadorEntity>> aprobadores({
    BigInt? codEmpleado,
    int? nivel,
  }) => listar(
    AppConstants.hexAprobadorListar,
    hexCuerpo({'codEmpleado': codEmpleado, 'nivel': nivel}),
    (j) => HexAprobadorModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<HexRamaEmpleadoEntity>> ramaAprobador(BigInt codEmpleado) =>
      listar(
        AppConstants.hexAprobadorRama,
        hexCuerpo({'codEmpleado': codEmpleado}),
        (j) => HexRamaEmpleadoModel.fromJson(j).toEntity(),
      );

  @override
  Future<List<HexEncargadoOpcionEntity>> encargadosParaJefe() => listar(
    AppConstants.hexAprobadorEncargados,
    const {},
    (j) => HexEncargadoOpcionModel.fromJson(j).toEntity(),
  );

  @override
  Future<HexRespuesta> asignarAprobador(HexAprobadorEntity a) => escribir(
    AppConstants.hexAprobadorAsignar,
    HexAprobadorModel.fromEntity(a).toJson(),
  );

  @override
  Future<HexRespuesta> cerrarAprobador(BigInt id, {DateTime? vigenteHasta}) =>
      escribir(
        AppConstants.hexAprobadorCerrar,
        hexCuerpo({
          'idAprobador': id,
          'vigenteHasta': hexDiaJson(vigenteHasta),
        }),
      );

  @override
  Future<HexRespuesta> eliminarAprobador(BigInt id) => escribir(
    AppConstants.hexAprobadorEliminar,
    hexCuerpo({'idAprobador': id}),
  );

  @override
  Future<PaginaHex<HexConfiguracionEventoEntity>> historial(
    FiltroHistorialHex f,
  ) async {
    final filas = await listar(
      AppConstants.hexConfiguracionHistorial,
      hexCuerpo({
        'entidad': f.entidad,
        'idRegistro': f.idRegistro,
        'fechaDesde': hexDiaJson(f.desde),
        'fechaHasta': hexDiaJson(f.hasta),
        'pagina': f.pagina,
        'tamano': f.tamano,
      }),
      (j) => HexConfiguracionEventoModel.fromJson(j).toEntity(),
    );
    return (filas: filas, total: filas.isEmpty ? 0 : filas.first.totalFilas);
  }
}
