import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/ttk_evento_model.dart';
import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/data/models/ttk_participante_model.dart';
import 'package:bosque_flutter/data/models/ttk_participante_ticket_model.dart';
import 'package:bosque_flutter/data/models/ttk_tipo_ticket_model.dart';
import 'package:bosque_flutter/data/models/ttk_vale_impresion_model.dart';
import 'package:bosque_flutter/data/repositories/ttk_api_base.dart';
import 'package:bosque_flutter/domain/entities/ttk_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_ticket_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_tipo_ticket_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_vale_impresion_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_tickets_repository.dart';

/// Endpoints `/tickets` del contrato. `audUsuario` no viaja: el backend lo
/// toma del token.
class TtkTicketsImpl extends TtkApiBase implements TtkTicketsRepository {
  @override
  Future<List<TtkEventoEntity>> listarEventos({
    BigInt? codEvento,
    String? estado,
    int? anio,
  }) => postAndReturnList(
    endpoint: AppConstants.ttkEventoListar,
    data: ttkCuerpo({'codEvento': codEvento, 'estado': estado, 'anio': anio}),
    fromJson: (j) => TtkEventoModel.fromJson(j).toEntity(),
  );

  @override
  Future<TtkRespuesta> guardarEvento(TtkEventoEntity evento) => escribir(
    AppConstants.ttkEventoGuardar,
    TtkEventoModel.fromEntity(evento).toJson(),
    errorMessage: 'No se pudo guardar el evento.',
  );

  @override
  Future<TtkRespuesta> eliminarEvento(BigInt codEvento) => escribir(
    AppConstants.ttkEventoEliminar,
    ttkCuerpo({'codEvento': codEvento}),
  );

  @override
  Future<TtkRespuesta> emitirEvento(BigInt codEvento) => escribir(
    AppConstants.ttkEventoEmitir,
    ttkCuerpo({'codEvento': codEvento}),
  );

  @override
  Future<TtkRespuesta> volverBorrador(BigInt codEvento) => escribir(
    AppConstants.ttkEventoVolverBorrador,
    ttkCuerpo({'codEvento': codEvento}),
  );

  @override
  Future<TtkRespuesta> cerrarEvento(BigInt codEvento) => escribir(
    AppConstants.ttkEventoCerrar,
    ttkCuerpo({'codEvento': codEvento}),
  );

  @override
  Future<List<TtkTipoTicketEntity>> listarTipos(BigInt codEvento) =>
      postAndReturnList(
        endpoint: AppConstants.ttkTipoListar,
        data: ttkCuerpo({'codEvento': codEvento}),
        fromJson: (j) => TtkTipoTicketModel.fromJson(j).toEntity(),
      );

  @override
  Future<TtkRespuesta> guardarTipo(TtkTipoTicketEntity tipo) => escribir(
    AppConstants.ttkTipoGuardar,
    TtkTipoTicketModel.fromEntity(tipo).toJson(),
    errorMessage: 'No se pudo guardar el tipo de vale.',
  );

  @override
  Future<TtkRespuesta> eliminarTipo(BigInt codTipoTicket) => escribir(
    AppConstants.ttkTipoEliminar,
    ttkCuerpo({'codTipoTicket': codTipoTicket}),
  );

  @override
  Future<List<TtkParticipanteEntity>> listarParticipantes(
    BigInt codEvento, {
    String? categoria,
    String? buscar,
  }) => postAndReturnList(
    endpoint: AppConstants.ttkParticipanteListar,
    data: ttkCuerpo({
      'codEvento': codEvento,
      'categoria': categoria,
      'buscar': ttkTextoN(buscar),
    }),
    fromJson: (j) => TtkParticipanteModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<TtkParticipanteEntity>> empleadosDisponibles(
    BigInt codEvento, {
    String? buscar,
  }) => postAndReturnList(
    endpoint: AppConstants.ttkParticipanteEmpleados,
    data: ttkCuerpo({'codEvento': codEvento, 'buscar': ttkTextoN(buscar)}),
    fromJson: (j) => TtkParticipanteModel.fromJson(j).toEntity(),
  );

  @override
  Future<TtkRespuesta> generarParticipantes(BigInt codEvento) => escribir(
    AppConstants.ttkParticipanteGenerar,
    ttkCuerpo({'codEvento': codEvento}),
  );

  @override
  Future<TtkRespuesta> guardarParticipante(
    TtkParticipanteEntity participante, {
    bool conCategoria = true,
  }) => escribir(
    AppConstants.ttkParticipanteGuardar,
    TtkParticipanteModel.fromEntity(
      participante,
    ).toJson(conCategoria: conCategoria),
    errorMessage: 'No se pudo guardar el participante.',
  );

  @override
  Future<TtkRespuesta> eliminarParticipante(BigInt codParticipante) => escribir(
    AppConstants.ttkParticipanteEliminar,
    ttkCuerpo({'codParticipante': codParticipante}),
  );

  @override
  Future<TtkRespuesta> restablecerParticipante(BigInt codParticipante) =>
      escribir(
        AppConstants.ttkParticipanteRestablecer,
        ttkCuerpo({'codParticipante': codParticipante}),
      );

  @override
  Future<List<TtkParticipanteTicketEntity>> listarVales({
    BigInt? codParticipante,
    BigInt? codEvento,
  }) => postAndReturnList(
    endpoint: AppConstants.ttkValeListar,
    data: ttkCuerpo({
      'codParticipante': codParticipante,
      'codEvento': codEvento,
    }),
    fromJson: (j) => TtkParticipanteTicketModel.fromJson(j).toEntity(),
  );

  @override
  Future<TtkRespuesta> cambiarVale(TtkParticipanteTicketEntity vale) =>
      escribir(
        AppConstants.ttkValeCambiar,
        TtkParticipanteTicketModel.fromEntity(vale).toJson(),
      );

  @override
  Future<TtkRespuesta> restablecerVale(
    BigInt codParticipante,
    BigInt codTipoTicket,
  ) => escribir(
    AppConstants.ttkValeRestablecer,
    ttkCuerpo({
      'codParticipante': codParticipante,
      'codTipoTicket': codTipoTicket,
    }),
  );

  @override
  Future<TtkRespuesta> cambiarValesLote({
    required BigInt codEvento,
    required BigInt codTipoTicket,
    int? cantidad,
    List<BigInt>? participantes,
    String? categoria,
  }) => escribir(
    AppConstants.ttkValeCambiarLote,
    ttkCuerpo({
      'codEvento': codEvento,
      'codTipoTicket': codTipoTicket,
      'cantidad': cantidad,
      'participantes':
          participantes == null || participantes.isEmpty
              ? null
              : [for (final p in participantes) p.toInt()],
      'categoria': categoria,
    }),
    errorMessage: 'No se pudieron cambiar los vales.',
  );

  @override
  Future<List<TtkValeImpresionEntity>> valesParaImprimir(
    BigInt codEvento, {
    BigInt? codParticipante,
    BigInt? codTipoTicket,
  }) => postAndReturnList(
    endpoint: AppConstants.ttkValeImpresion,
    data: ttkCuerpo({
      'codEvento': codEvento,
      'codParticipante': codParticipante,
      'codTipoTicket': codTipoTicket,
    }),
    fromJson: (j) => TtkValeImpresionModel.fromJson(j).toEntity(),
  );
}
