// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/programador_dependiente_model.dart';
import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/mi_equipo_entity.dart';

/// **Origen:** no hay tabla ni SP directo. Ver la nota.
///
/// **No sale de un SP.** Lo arma `MiEquipoDto` en el backend combinando
/// `p_list_trs_Programador` @E (quien soy yo para este modulo, resuelto por el
/// login) con @D (mi gente).
///
/// Siempre responde 200, nunca 204: si no sos programador viene
/// `esProgramador=0` con el equipo vacio, que es una respuesta valida.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class MiEquipoModel {
  final MiEquipoEntity _e;
  const MiEquipoModel(this._e);

  factory MiEquipoModel.fromJson(Map<String, dynamic> json) => MiEquipoModel(
    MiEquipoEntity(
      codUsuario: rsInt(json['codUsuario']),
      codEmpleado: rsInt(json['codEmpleado']),
      esProgramador: rsInt(json['esProgramador']),
      esReemplazo: rsInt(json['esReemplazo']),
      // Un backend viejo no lo manda: rsInt devuelve 0 y la app se comporta
      // como si no fueras de RR.HH., que es el lado seguro para equivocarse.
      esRrhh: rsInt(json['esRrhh']),
      idProgramador: rsInt(json['idProgramador']),
      codEmpleadoTitular: rsInt(json['codEmpleadoTitular']),
      jefe: rsStr(json['jefe']),
      alcance: rsStr(json['alcance']),
      codSucursal: rsInt(json['codSucursal']),
      sucursal: rsStr(json['sucursal']),
      cantidadDependientes: rsInt(json['cantidadDependientes']),
      // Cuando el que pregunta no es programador el backend puede mandar la
      // lista en null en vez de vacía; acá da lo mismo, arriba no.
      equipo: ((json['equipo'] as List?) ?? const [])
          .map(
            (e) =>
                ProgramadorDependienteModel.fromJson(e as Map<String, dynamic>).toEntity(),
          )
          .toList(),
    ),
  );

  MiEquipoEntity toEntity() => _e;
}
