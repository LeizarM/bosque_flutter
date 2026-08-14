// Modelo del modulo Permisos RR.HH. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/domain/entities/abono_dias_entity.dart';

/// **Origen:** `POST /permiso-rrhh/abonos/detalle` → `p_list_AbonoDias`. El
/// endpoint devuelve **una lista**.
///
/// **`codAbonoDias` tiene que venir sí o sí.** El subreporte `@ACCION='B'` trae
/// `fila` y `totalDias` pero **no** el id, y sin id no hay Editar ni Eliminar:
/// el backend tiene que completarlo (con `'L'`, que sí lo trae y además no tiene
/// los INNER JOIN de `'A'`, que descartan las filas con `codRelEmplEmpr` NULL).
/// Si llega en 0, la fila se ve como un alta y el botón de editar mandaría un
/// INSERT.
class AbonoDiasModel {
  final AbonoDiasEntity _e;
  const AbonoDiasModel(this._e);

  factory AbonoDiasModel.fromJson(Map<String, dynamic> json) => AbonoDiasModel(
    AbonoDiasEntity(
      codAbonoDias: prInt(json['codAbonoDias']),
      codEmpleado: prInt(json['codEmpleado']),
      codRelEmplEmpr: prInt(json['codRelEmplEmpr']),
      // prNum: los abonos van de 0,5 a 22 y truncar medio día lo borraría.
      diasAbonados: prNum(json['diasAbonados']),
      diasAbonadosTxt: prStr(json['diasAbonadosTxt']),
      fecha: prDate(json['fecha']),
      motivo: prStr(json['motivo']),
      fila: prInt(json['fila']),
      totalDias: prNum(json['totalDias']),
      totalDiasTxt: prStr(json['totalDiasTxt']),
    ),
  );

  /// El cuerpo de la escritura. Igual que en vacación asignada, sin
  /// `audUsuarioI` ni `audFechaI` (ver `VacacionAsignadaModel.toJson`).
  ///
  /// **Va la fila completa siempre**, incluso en la edición: el UPDATE de
  /// `p_abm_AbonoDias` sí pisa `codEmpleado` y `codRelEmplEmpr`, así que una
  /// 'U' parcial dejaría un NULL en una columna NOT NULL y reventaría.
  ///
  /// **`dias` y no `diasAbonados`**, por el mismo motivo que en
  /// `VacacionAsignadaModel.toJson`: es el nombre del campo del DTO, y con el
  /// de la columna el backend recibía 0 en silencio. Acá el 0 además se rechaza
  /// del otro lado —el abono exige mayor a cero—, así que el síntoma era «no se
  /// puede abonar 0 días» sobre un formulario donde decía 3.
  Map<String, dynamic> toJson() => {
    'codAbonoDias': _e.codAbonoDias,
    'codEmpleado': _e.codEmpleado,
    'codRelEmplEmpr': _e.codRelEmplEmpr,
    'dias': _e.diasAbonados,
    'fecha': _e.fecha == null ? null : prDia(_e.fecha!),
    'motivo': _e.motivo.trim(),
  };

  AbonoDiasEntity toEntity() => _e;
}
