import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_empleado_bingo_entity.dart';

/// Columnas de `p_list_ttk_BingoCarton` E (quienes pueden recibir cartón).
class TtkEmpleadoBingoModel {
  const TtkEmpleadoBingoModel(this.entidad);

  final TtkEmpleadoBingoEntity entidad;

  factory TtkEmpleadoBingoModel.fromJson(Map<String, dynamic> j) =>
      TtkEmpleadoBingoModel(
        TtkEmpleadoBingoEntity(
          codParticipante: ttkBigInt(j['codParticipante']),
          codEmpleado: ttkBigInt(j['codEmpleado']),
          nombreCompleto: ttkTexto(j['nombreCompleto']),
          cargo: ttkTextoN(j['cargo']),
          categoriaTexto: ttkTexto(j['categoriaTexto']),
          valesBingo: ttkInt(j['valesBingo']),
          cartonesAsignados: ttkInt(j['cartonesAsignados']),
          puedeRecibir: ttkBool(j['puedeRecibir']),
        ),
      );

  factory TtkEmpleadoBingoModel.fromEntity(TtkEmpleadoBingoEntity e) =>
      TtkEmpleadoBingoModel(e);

  TtkEmpleadoBingoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codParticipante': entidad.codParticipante,
    'codEmpleado': entidad.codEmpleado,
    'nombreCompleto': entidad.nombreCompleto,
    'cargo': entidad.cargo,
    'categoriaTexto': entidad.categoriaTexto,
    'valesBingo': entidad.valesBingo,
    'cartonesAsignados': entidad.cartonesAsignados,
    'puedeRecibir': ttkBandera(entidad.puedeRecibir),
  });
}
