// Modelo del modulo Permisos RR.HH. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';

/// **Origen:** `POST /permiso-rrhh/saldo/ficha` → `p_list_Permiso @ACCION='C'`.
/// El endpoint devuelve **una lista** (`data: [ {...} ]`) aunque sea una fila.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL. Todo lo numérico pasa por
/// [prNum]/[prInt] y no por un `as double`: ver la nota de
/// `permisos_rrhh_json.dart`, que es el bug que aparece recién en producción.
class FichaSaldoModel {
  final FichaSaldoEntity _e;
  const FichaSaldoModel(this._e);

  factory FichaSaldoModel.fromJson(
    Map<String, dynamic> json,
  ) => FichaSaldoModel(
    FichaSaldoEntity(
      codEmpleado: prInt(json['codEmpleado']),
      datoEmpleado: prStr(json['datoEmpleado']),
      datoEmpresa: prStr(json['datoEmpresa']),
      datoCargo: prStr(json['datoCargo']),
      datoFechaBeneficio: prStr(json['datoFechaBeneficio']),
      datoAntiguedad: prStr(json['datoAntiguedad']),
      // prNum y no prInt: los días vienen en fracciones (0.4375, 0.5) y
      // truncarlos convertiría medio día de vacación en cero.
      diasNoUsados: prNum(json['diasNoUsados']),
      diasAbonados: prNum(json['diasAbonados']),
      totalDias: prNum(json['totalDias']),
      diasNoUsadosTxt: prStr(json['diasNoUsadosTxt']),
      diasAbonadosTxt: prStr(json['diasAbonadosTxt']),
      totalDiasTxt: prStr(json['totalDiasTxt']),
      // SUPUESTO D0 — pendiente de confirmación de RR.HH. (ver plan §5):
      // el alcance del saldo es la relación laboral vigente; estos tres campos
      // son los que dejan rotularlo en pantalla.
      datoRelEmplEmprVigente: prInt(json['datoRelEmplEmprVigente']),
      relacionVigenteDesde: prDate(json['relacionVigenteDesde']),
      // Sin helper a propósito: el flag viaja como boolean JSON, no como el 0/1
      // de rol-sabados. Si faltara, el valor seguro es el restrictivo — no se
      // rotula un alcance que no se puede probar.
      tieneRelacionesAnteriores: json['tieneRelacionesAnteriores'] == true,
      movimientosFueraDeRelacionVigente: prInt(
        json['movimientosFueraDeRelacionVigente'],
      ),
    ),
  );

  FichaSaldoEntity toEntity() => _e;
}
