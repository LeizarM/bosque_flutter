import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_carton_entity.dart';

/// Columnas de `p_list_ttk_BingoCarton` L, D y M. `toJson` es el cuerpo de
/// `/bingo/carton/asignar` (cartón y dueño).
class TtkBingoCartonModel {
  const TtkBingoCartonModel(this.entidad);

  final TtkBingoCartonEntity entidad;

  factory TtkBingoCartonModel.fromJson(Map<String, dynamic> j) =>
      TtkBingoCartonModel(
        TtkBingoCartonEntity(
          codCarton: ttkBigInt(j['codCarton']),
          codBingo: ttkBigInt(j['codBingo']),
          nroCarton: ttkInt(j['nroCarton']),
          codEmpleado: ttkBigInt(j['codEmpleado']),
          codParticipante: ttkBigInt(j['codParticipante']),
          nombreEmpleado: ttkTextoN(j['nombreEmpleado']),
          esInvitado: ttkBool(j['esInvitado']),
          origen: ttkTextoN(j['origen']),
          origenTexto: ttkTextoN(j['origenTexto']),
          fechaAsignacion: ttkFecha(j['fechaAsignacion']),
          impreso: ttkBool(j['impreso']),
          formaTexto: ttkTextoN(j['formaTexto']),
          esGanador: ttkBool(j['esGanador']),
          puedeAsignar: ttkBool(j['puedeAsignar']),
          puedeCambiarForma: ttkBool(j['puedeCambiarForma']),
          puedeLiberar: ttkBool(j['puedeLiberar']),
          audUsuario: ttkBigInt(j['audUsuario']),
          audFecha: ttkFecha(j['audFecha']),
        ),
      );

  factory TtkBingoCartonModel.fromEntity(TtkBingoCartonEntity e) =>
      TtkBingoCartonModel(e);

  TtkBingoCartonEntity toEntity() => entidad;

  /// Con bingo por vales el dueño va como participante; si no, como empleado.
  Map<String, dynamic> toJson() => ttkCuerpo({
    'codCarton': entidad.codCarton,
    'codParticipante': entidad.codParticipante,
    'codEmpleado': entidad.codParticipante == null ? entidad.codEmpleado : null,
  });
}
