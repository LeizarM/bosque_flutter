import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_participante_entity.dart';

/// Columnas de `p_list_ttk_Bingo` A (bingos visibles para el empleado).
class TtkBingoParticipanteModel {
  const TtkBingoParticipanteModel(this.entidad);

  final TtkBingoParticipanteEntity entidad;

  factory TtkBingoParticipanteModel.fromJson(Map<String, dynamic> j) =>
      TtkBingoParticipanteModel(
        TtkBingoParticipanteEntity(
          codBingo: ttkBigInt(j['codBingo']),
          codEvento: ttkBigInt(j['codEvento']),
          nombreEvento: ttkTexto(j['nombreEvento']),
          fechaEvento: ttkFecha(j['fechaEvento']),
          estado: ttkTexto(j['estado']),
          estadoTexto: ttkTexto(j['estadoTexto']),
          filas: ttkInt(j['filas']),
          columnas: ttkInt(j['columnas']),
          letras: ttkTextoN(j['letras']),
          conComodin: ttkBool(j['conComodin']),
          nroJuegos: ttkInt(j['nroJuegos']),
          modalidad: ttkTextoN(j['modalidad']) ?? 'A',
          conAviso: ttkBool(j['conAviso']),
          maxCartonesEmpleado: ttkInt(j['maxCartonesEmpleado']),
          misCartones: ttkInt(j['misCartones']),
          cartonesDisponibles: ttkInt(j['cartonesDisponibles']),
          puedeElegir: ttkBool(j['puedeElegir']),
          puedeVerEnVivo: ttkBool(j['puedeVerEnVivo']),
          mensaje: ttkTexto(j['mensaje']),
        ),
      );

  factory TtkBingoParticipanteModel.fromEntity(TtkBingoParticipanteEntity e) =>
      TtkBingoParticipanteModel(e);

  TtkBingoParticipanteEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codBingo': entidad.codBingo,
    'codEvento': entidad.codEvento,
    'nombreEvento': entidad.nombreEvento,
    'fechaEvento': ttkFechaJson(entidad.fechaEvento),
    'estado': entidad.estado,
    'estadoTexto': entidad.estadoTexto,
    'filas': entidad.filas,
    'columnas': entidad.columnas,
    'letras': entidad.letras,
    'conComodin': ttkBandera(entidad.conComodin),
    'nroJuegos': entidad.nroJuegos,
    'modalidad': entidad.modalidad,
    'conAviso': ttkBandera(entidad.conAviso),
    'maxCartonesEmpleado': entidad.maxCartonesEmpleado,
    'misCartones': entidad.misCartones,
    'cartonesDisponibles': entidad.cartonesDisponibles,
    'puedeElegir': ttkBandera(entidad.puedeElegir),
    'puedeVerEnVivo': ttkBandera(entidad.puedeVerEnVivo),
    'mensaje': entidad.mensaje,
  });
}
