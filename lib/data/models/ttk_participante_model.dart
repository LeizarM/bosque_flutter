import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_entity.dart';

/// Columnas de `p_list_ttk_Participante` L y E. `toJson` es el cuerpo de
/// `/tickets/participante/guardar`; sin categoría, el SP no la marca como manual.
class TtkParticipanteModel {
  const TtkParticipanteModel(this.entidad);

  final TtkParticipanteEntity entidad;

  factory TtkParticipanteModel.fromJson(Map<String, dynamic> j) =>
      TtkParticipanteModel(
        TtkParticipanteEntity(
          codParticipante: ttkBigInt(j['codParticipante']),
          codEvento: ttkBigInt(j['codEvento']),
          codEmpleado: ttkBigInt(j['codEmpleado']),
          nombreCompleto: ttkTexto(j['nombreCompleto']),
          nombreInvitado: ttkTextoN(j['nombreInvitado']),
          documento: ttkTextoN(j['documento']),
          codEmpleadoAnfitrion: ttkBigInt(j['codEmpleadoAnfitrion']),
          nombreAnfitrion: ttkTextoN(j['nombreAnfitrion']),
          cargo: ttkTextoN(j['cargo']),
          fechaIngreso: ttkFecha(j['fechaIngreso']),
          categoria: ttkTextoN(j['categoria']),
          categoriaTexto: ttkTexto(j['categoriaTexto']),
          categoriaManual: ttkBool(j['categoriaManual']),
          totalVales: ttkInt(j['totalVales']),
          resumenVales: ttkTexto(j['resumenVales']),
          observacion: ttkTextoN(j['observacion']),
          puedeEditar: ttkBool(j['puedeEditar']),
          audUsuario: ttkBigInt(j['audUsuario']),
          audFecha: ttkFecha(j['audFecha']),
        ),
      );

  factory TtkParticipanteModel.fromEntity(TtkParticipanteEntity e) =>
      TtkParticipanteModel(e);

  TtkParticipanteEntity toEntity() => entidad;

  Map<String, dynamic> toJson({bool conCategoria = true}) => ttkCuerpo({
    'codParticipante': entidad.codParticipante,
    'codEvento': entidad.codEvento,
    'codEmpleado': entidad.codEmpleado,
    'nombreInvitado': entidad.nombreInvitado,
    'documento': entidad.documento,
    'codEmpleadoAnfitrion': entidad.codEmpleadoAnfitrion,
    'categoria': conCategoria ? entidad.categoria : null,
    'observacion': entidad.observacion,
  });
}
