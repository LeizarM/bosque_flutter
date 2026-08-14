// Modelo del modulo Permisos RR.HH. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/data/models/tramo_saldo_model.dart';
import 'package:bosque_flutter/domain/entities/desglose_saldo_entity.dart';

/// **Origen:** `POST /permiso-rrhh/saldo/desglose` → `p_list_Permiso
/// @ACCION='D'`. El endpoint devuelve **un objeto** (`data: { ... }`), no una
/// lista: el backend ya armó la cabecera, los 5 tramos y los totales.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL. Sobre el porqué de [prNum] en
/// todo lo numérico, ver `permisos_rrhh_json.dart`.
class DesgloseSaldoModel {
  final DesgloseSaldoEntity _e;
  const DesgloseSaldoModel(this._e);

  factory DesgloseSaldoModel.fromJson(
    Map<String, dynamic> json,
  ) => DesgloseSaldoModel(
    DesgloseSaldoEntity(
      codEmpleado: prInt(json['codEmpleado']),
      datoEmpleado: prStr(json['datoEmpleado']),
      datoEmpresa: prStr(json['datoEmpresa']),
      datoCargo: prStr(json['datoCargo']),
      datoAntiguedad: prStr(json['datoAntiguedad']),
      datoFecIniBenef: prStr(json['datoFecIniBenef']),
      datoAnios: prInt(json['datoAnios']),
      fecIniPenUl: prDate(json['fecIniPenUl']),
      fecIniUlt: prDate(json['fecIniUlt']),
      codRelEmplEmpr: prInt(json['codRelEmplEmpr']),
      // Los dos flags se leen con `== true` y sin helper: viajan como
      // boolean JSON, no como el 0/1 de rol-sabados. Si el campo faltara, el
      // valor seguro es el restrictivo —sin fecha de beneficio y sin
      // desglose—, que hace que la pantalla avise en vez de mostrar cifras
      // dudosas.
      tieneFechaBeneficio: json['tieneFechaBeneficio'] == true,
      // SUPUESTO D2 — pendiente de confirmación de RR.HH. (ver plan §5).
      desgloseAplicable: json['desgloseAplicable'] == true,
      tramos:
          (json['tramos'] as List<dynamic>? ?? const [])
              .map(
                (t) =>
                    TramoSaldoModel.fromJson(
                      t as Map<String, dynamic>,
                    ).toEntity(),
              )
              .toList(),
      // SUPUESTO D1 — pendiente de confirmación de RR.HH. (ver plan §5):
      // el DEBE no incluye las duodécimas del tramo 3, igual que el legacy.
      montoTotalDebe: prNum(json['montoTotalDebe']),
      montoTotalHaber: prNum(json['montoTotalHaber']),
      montoTotal: prNum(json['montoTotal']),
      montoTotalTxt: prStr(json['montoTotalTxt']),
      etiquetaTotal: prStr(json['etiquetaTotal']),
    ),
  );

  DesgloseSaldoEntity toEntity() => _e;
}
