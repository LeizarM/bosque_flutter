import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_vale_impresion_entity.dart';

/// Columnas de `p_list_ttk_ParticipanteTicket` P (un renglón por vale).
class TtkValeImpresionModel {
  const TtkValeImpresionModel(this.entidad);

  final TtkValeImpresionEntity entidad;

  factory TtkValeImpresionModel.fromJson(Map<String, dynamic> j) =>
      TtkValeImpresionModel(
        TtkValeImpresionEntity(
          codEvento: ttkBigInt(j['codEvento']),
          nombreEvento: ttkTexto(j['nombreEvento']),
          fechaEvento: ttkFecha(j['fechaEvento']),
          lugar: ttkTextoN(j['lugar']),
          codTipoTicket: ttkBigInt(j['codTipoTicket']),
          nombreTipo: ttkTexto(j['nombreTipo']),
          leyenda: ttkTextoN(j['leyenda']),
          colorHex: ttkTextoN(j['colorHex']),
          codParticipante: ttkBigInt(j['codParticipante']),
          nombreParticipante: ttkTexto(j['nombreParticipante']),
          categoriaTexto: ttkTexto(j['categoriaTexto']),
          nroTicket: ttkInt(j['nroTicket']),
          nroTicketTexto: ttkTexto(j['nroTicketTexto']),
        ),
      );

  factory TtkValeImpresionModel.fromEntity(TtkValeImpresionEntity e) =>
      TtkValeImpresionModel(e);

  TtkValeImpresionEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codEvento': entidad.codEvento,
    'nombreEvento': entidad.nombreEvento,
    'fechaEvento': ttkFechaJson(entidad.fechaEvento),
    'lugar': entidad.lugar,
    'codTipoTicket': entidad.codTipoTicket,
    'nombreTipo': entidad.nombreTipo,
    'leyenda': entidad.leyenda,
    'colorHex': entidad.colorHex,
    'codParticipante': entidad.codParticipante,
    'nombreParticipante': entidad.nombreParticipante,
    'categoriaTexto': entidad.categoriaTexto,
    'nroTicket': entidad.nroTicket,
    'nroTicketTexto': entidad.nroTicketTexto,
  });
}
