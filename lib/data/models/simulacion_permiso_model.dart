// Modelo del modulo Permisos RR.HH. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/domain/entities/simulacion_permiso_entity.dart';

/// **Origen:** `POST /permiso-rrhh/permisos/calcular`. El endpoint devuelve **un
/// objeto** —una sola persona—, al revés que las simulaciones colectivas, que
/// devuelven lista. De ahí que el repositorio use `postAndReturnObject` y no
/// `postAndReturnList`: equivocarse ahí no da error, da `null` en silencio y la
/// pantalla muestra 0 días sobre un rango que sí tiene días.
///
/// **Del otro lado es `EmpleadoColectivoDto`**, el mismo tipo de la carga
/// colectiva: el permiso que se cruza no viaja como cuatro campos propios sino
/// como `entra` (false = no se puede guardar) y `detalle` (el motivo, ya
/// redactado y con el rango del permiso que choca adentro). Leer nombres que el
/// servidor no manda daba `entra` siempre en verdadero: el cliente fallaba
/// ABIERTO y el usuario se enteraba del choque recién al guardar.
///
/// **Sin `toJson`**: lo que viaja de ida es
/// `PermisosRrhhImpl.cuerpoSimulacionPermiso`.
class SimulacionPermisoModel {
  final SimulacionPermisoEntity _e;
  const SimulacionPermisoModel(this._e);

  factory SimulacionPermisoModel.fromJson(Map<String, dynamic> json) {
    final dias = prNum(json['dias']);
    return SimulacionPermisoModel(
      SimulacionPermisoEntity(
        dias: dias,
        horas: prNum(json['horas'] ?? dias * 8),
        horasAReponer: prNum(json['horasAReponer']),
        codSucursal: prInt(json['codSucursal']),
        datoSucursal: prStr(json['datoSucursal']),
        // **Falla cerrado**: sólo un `true` explícito habilita el guardado. El
        // campo es un `boolean` primitivo del DTO, así que siempre viene; si
        // dejara de venir, el peor caso tiene que ser un botón apagado y no una
        // escritura que el servidor ya sabe que va a rechazar.
        entra: json['entra'] == true,
        detalle: prStr(json['detalle']),
      ),
    );
  }

  SimulacionPermisoEntity toEntity() => _e;
}
