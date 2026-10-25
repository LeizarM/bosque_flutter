import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_tipo_ticket_entity.dart';

/// Columnas de `p_list_ttk_TipoTicket` L. `toJson` es el cuerpo de
/// `/tickets/tipo/guardar`.
class TtkTipoTicketModel {
  const TtkTipoTicketModel(this.entidad);

  final TtkTipoTicketEntity entidad;

  factory TtkTipoTicketModel.fromJson(Map<String, dynamic> j) =>
      TtkTipoTicketModel(
        TtkTipoTicketEntity(
          codTipoTicket: ttkBigInt(j['codTipoTicket']),
          codEvento: ttkBigInt(j['codEvento']),
          nombre: ttkTexto(j['nombre']),
          leyenda: ttkTextoN(j['leyenda']),
          cantEmpleado: ttkInt(j['cantEmpleado']),
          cantReciente: ttkInt(j['cantReciente']),
          cantInvitado: ttkInt(j['cantInvitado']),
          colorHex: ttkTextoN(j['colorHex']),
          orden: ttkIntN(j['orden']),
          totalVales: ttkInt(j['totalVales']),
          totalParticipantes: ttkInt(j['totalParticipantes']),
          puedeEditar: ttkBool(j['puedeEditar']),
          daCartonBingo: ttkBool(j['daCartonBingo']),
          audUsuario: ttkBigInt(j['audUsuario']),
          audFecha: ttkFecha(j['audFecha']),
        ),
      );

  factory TtkTipoTicketModel.fromEntity(TtkTipoTicketEntity e) =>
      TtkTipoTicketModel(e);

  TtkTipoTicketEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codTipoTicket': entidad.codTipoTicket,
    'codEvento': entidad.codEvento,
    'nombre': entidad.nombre,
    'leyenda': entidad.leyenda,
    'cantEmpleado': entidad.cantEmpleado,
    'cantReciente': entidad.cantReciente,
    'cantInvitado': entidad.cantInvitado,
    'colorHex': entidad.colorHex,
    'orden': entidad.orden,
  });
}
