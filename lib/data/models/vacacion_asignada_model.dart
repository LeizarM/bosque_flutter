// Modelo del modulo Permisos RR.HH. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';

/// **Origen:** `POST /permiso-rrhh/vacacion-asignada/historial` →
/// `p_list_vacacionAsignada @ACCION='B'`. El endpoint devuelve **una lista**.
///
/// Es el único modelo del módulo que además viaja **de ida**: [toJson] arma el
/// cuerpo del alta, la edición y la baja. Los nombres de las claves son los de
/// los parámetros del SP, para que el mapeo se lea de un lado y del otro.
///
/// **`audUsuarioI` no está y no es un olvido** (D4): la identidad la saca el
/// backend del token. Mandarla desde acá sería un permiso que se puede escribir
/// a mano. **`audFechaI` tampoco**: el SP la pisa siempre con `GETDATE()`,
/// aunque declare el parámetro.
class VacacionAsignadaModel {
  final VacacionAsignadaEntity _e;
  const VacacionAsignadaModel(this._e);

  factory VacacionAsignadaModel.fromJson(Map<String, dynamic> json) =>
      VacacionAsignadaModel(
        VacacionAsignadaEntity(
          codVacacionAsignada: prInt(json['codVacacionAsignada']),
          codEmpleado: prInt(json['codEmpleado']),
          codRelEmplEmpr: prInt(json['codRelEmplEmpr']),
          // prNum y no prInt: la columna es `float` y hay filas con 14,5 y 12,5.
          // Ver la nota de `permisos_rrhh_json.dart`.
          diasAsignados: prNum(json['diasAsignados']),
          diasAsignadosTxt: prStr(json['diasAsignadosTxt']),
          motivo: prStr(json['motivo']),
          fecha: prDate(json['fecha']),
          datoEmpleado: prStr(json['datoEmpleado']),
          datoRelacion: prStr(json['datoRelacion']),
        ),
      );

  /// El cuerpo de la escritura.
  ///
  /// Va **la fila entera** aunque el UPDATE del SP ignore `codEmpleado` y
  /// `codRelEmplEmpr`: el backend los necesita para el alta, para el chequeo de
  /// duplicado —que es por `(codEmpleado, codRelEmplEmpr, fecha)`, la misma
  /// tupla que leen los SP— y para verificar que el registro sea del empleado
  /// que se está mirando, cosa que el `DELETE` del SP no comprueba.
  ///
  /// **Los días viajan como `dias`, no como `diasAsignados`.** El campo del
  /// otro lado se llama así (`PermisoRrhhEscrituraDto.dias`) porque es el mismo
  /// para las dos tablas; `diasAsignados` es el nombre de la COLUMNA. Con el
  /// nombre de la columna, Jackson la descartaba sin decir nada —no hay
  /// `FAIL_ON_UNKNOWN_PROPERTIES`— y, como del otro lado es un `double`
  /// primitivo, llegaba **0**: la asignación se guardaba en cero días y nadie
  /// veía un error. `permisos_rrhh_contrato_test` compara estas claves contra
  /// los campos del DTO.
  Map<String, dynamic> toJson() => {
    'codVacacionAsignada': _e.codVacacionAsignada,
    'codEmpleado': _e.codEmpleado,
    'codRelEmplEmpr': _e.codRelEmplEmpr,
    'dias': _e.diasAsignados,
    'motivo': _e.motivo.trim(),
    'fecha': _e.fecha == null ? null : prDia(_e.fecha!),
  };

  VacacionAsignadaEntity toEntity() => _e;
}
