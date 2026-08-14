// Modelo del modulo Permisos RR.HH. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';

/// **Origen:** `POST /permiso-rrhh/permisos/kardex` → `p_list_Permiso
/// @ACCION='Q'`. El endpoint devuelve **una lista**.
///
/// **Sin `toJson`**: esto sólo viene. Lo que viaja de ida son los filtros, y
/// esos los arma `PermisosRrhhImpl.cuerpoNominaPermisos`.
class NominaPermisoModel {
  final NominaPermisoEntity _e;
  const NominaPermisoModel(this._e);

  factory NominaPermisoModel.fromJson(Map<String, dynamic> json) {
    // `cantidadDias` es el nombre de la COLUMNA y `dias` el del DTO calculado.
    // Se leen los dos: el SP devuelve el primero y el contrato promete el
    // segundo, y equivocarse no da error — da la grilla entera en cero, que es
    // exactamente el aspecto que tiene «este empleado no se tomó nada».
    final dias = prNum(json['dias'] ?? json['cantidadDias']);
    return NominaPermisoModel(
      NominaPermisoEntity(
        codPermiso: prInt(json['codPermiso']),
        codEmpleado: prInt(json['codEmpleado']),
        datoEmpleado: prStr(json['datoEmpleado']),
        tipoPermiso: prStr(json['tipoPermiso']),
        datoTipoPermiso: prStr(json['datoTipoPermiso']),
        desde: prDate(json['desde']),
        hasta: prDate(json['hasta']),
        dias: dias,
        // El backend la manda calculada; el `?? dias * 8` es para que una
        // columna que falte se vea consistente con la de al lado en vez de
        // mostrar 0 horas junto a 1,5 días.
        horas: prNum(json['horas'] ?? dias * 8),
        motivo: prStr(json['motivo']),
      ),
    );
  }

  NominaPermisoEntity toEntity() => _e;
}
