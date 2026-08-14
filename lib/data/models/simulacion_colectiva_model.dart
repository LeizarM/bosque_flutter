// Modelo del modulo Permisos RR.HH. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/domain/entities/simulacion_colectiva_entity.dart';

/// **Origen:** las tres listas de la carga colectiva —el padrón
/// (`/colectivo/empleados`, desde `p_list_Permiso @ACCION='E'`) y las dos
/// simulaciones (`/colectivo/abono-dias/simular` y
/// `/colectivo/vacacion/simular`, con los días ya calculados por persona—.
///
/// **Sin `toJson`**: esto sólo viene. Lo que viaja de ida es la lista de
/// `codEmpleado` tildados; la relación y la sucursal las resuelve el servidor
/// (ver el javadoc de la entidad).
///
/// **Los alias no son paranoia, son lo que manda el servidor hoy.** La
/// simulación del abono devuelve el `model` de la tabla —`AbonoDias`, con
/// `diasAbonados`, `diasAbonadosTxt`, `aplica` y `motivoOmision`— mientras que
/// la de vacación devuelve la forma calculada (`dias`, `entra`, `detalle`).
/// Leer una sola de las dos familias no da error: da **0 días y «entra» para
/// todos**, o sea una confirmación que dice que nadie queda afuera justo cuando
/// alguien queda afuera. Es la misma clase de falla que el `dias` de las
/// escrituras, así que se lee lo uno o lo otro.
class SimulacionColectivaModel {
  final SimulacionColectivaEntity _e;
  const SimulacionColectivaModel(this._e);

  factory SimulacionColectivaModel.fromJson(Map<String, dynamic> json) =>
      SimulacionColectivaModel(
        SimulacionColectivaEntity(
          codEmpleado: prInt(json['codEmpleado']),
          datoEmpleado: prStr(json['datoEmpleado']),
          codRelEmplEmpr: prInt(json['codRelEmplEmpr']),
          codSucursal: prInt(json['codSucursal']),
          datoSucursal: prStr(json['datoSucursal']),
          datoEmpresa: prStr(json['datoEmpresa']),
          // prNum: la vacación colectiva devuelve fracciones (4,5) por los
          // feriados de cada sucursal. Ver `permisos_rrhh_json.dart`.
          dias: prNum(json['dias'] ?? json['diasAbonados']),
          diasTxt: prStr(json['diasTxt'] ?? json['diasAbonadosTxt'] ?? ''),
          // Sin dato, la fila entra: el padrón no manda el flag y todos sus
          // empleados son elegibles. Los excluidos los marca la simulación,
          // que sí lo manda —como `entra` o como `aplica`—.
          entra: (json['entra'] ?? json['aplica'] ?? true) == true,
          detalle: prStr(json['detalle'] ?? json['motivoOmision'] ?? ''),
        ),
      );

  SimulacionColectivaEntity toEntity() => _e;
}
