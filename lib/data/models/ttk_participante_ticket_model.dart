import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_ticket_entity.dart';

/// Columnas de `p_list_ttk_ParticipanteTicket` L. `toJson` es el cuerpo de
/// `/tickets/vale/cambiar`.
class TtkParticipanteTicketModel {
  const TtkParticipanteTicketModel(this.entidad);

  final TtkParticipanteTicketEntity entidad;

  factory TtkParticipanteTicketModel.fromJson(Map<String, dynamic> j) =>
      TtkParticipanteTicketModel(
        TtkParticipanteTicketEntity(
          codParticipanteTicket: ttkBigInt(j['codParticipanteTicket']),
          codParticipante: ttkBigInt(j['codParticipante']),
          codTipoTicket: ttkBigInt(j['codTipoTicket']),
          nombreTipo: ttkTexto(j['nombreTipo']),
          colorHex: ttkTextoN(j['colorHex']),
          cantidad: ttkInt(j['cantidad']),
          cantidadDefecto: ttkInt(j['cantidadDefecto']),
          cantidadManual: ttkBool(j['cantidadManual']),
          nroDesde: ttkIntN(j['nroDesde']),
          nroHasta: ttkIntN(j['nroHasta']),
          rangoTexto: ttkTexto(j['rangoTexto']),
          puedeEditar: ttkBool(j['puedeEditar']),
          audUsuario: ttkBigInt(j['audUsuario']),
          audFecha: ttkFecha(j['audFecha']),
        ),
      );

  factory TtkParticipanteTicketModel.fromEntity(
    TtkParticipanteTicketEntity e,
  ) => TtkParticipanteTicketModel(e);

  TtkParticipanteTicketEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codParticipante': entidad.codParticipante,
    'codTipoTicket': entidad.codTipoTicket,
    'cantidad': entidad.cantidad,
  });
}
