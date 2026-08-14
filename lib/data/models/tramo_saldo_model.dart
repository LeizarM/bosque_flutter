// Modelo del modulo Permisos RR.HH. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/domain/entities/tramo_saldo_entity.dart';

/// **Origen:** `POST /permiso-rrhh/saldo/desglose` → `p_list_Permiso
/// @ACCION='D'`, uno de los 5 tramos del arreglo `tramos`.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL. La `etiqueta` la escribe el SP y
/// se pasa **tal cual**.
class TramoSaldoModel {
  final TramoSaldoEntity _e;
  const TramoSaldoModel(this._e);

  factory TramoSaldoModel.fromJson(
    Map<String, dynamic> json,
  ) => TramoSaldoModel(
    TramoSaldoEntity(
      clave: prStr(json['clave']),
      etiqueta: prStr(json['etiqueta']),
      monto: prNum(json['monto']),
      montoTxt: prStr(json['montoTxt']),
      // Sin helper acá: `prStr` daría '' y '' no es un signo. Sin signo conocido
      // el tramo se trata como informativo, o sea no suma. Es el lado seguro —
      // inventar un DEBE cambiaría el total (ver D1).
      signo: json['signo']?.toString() ?? 'INFO',
      tieneDetalle: json['tieneDetalle'] == true,
    ),
  );

  TramoSaldoEntity toEntity() => _e;
}
