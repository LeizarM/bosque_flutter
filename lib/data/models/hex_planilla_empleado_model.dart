import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_empleado_entity.dart';

/// Columnas de `p_list_thex_PlanillaEmpleado` R. Los alias `hHS`, `cD` y
/// `mOtros` se leen con esa grafía, tal como los serializa el backend.
class HexPlanillaEmpleadoModel {
  const HexPlanillaEmpleadoModel(this.entidad);

  final HexPlanillaEmpleadoEntity entidad;

  factory HexPlanillaEmpleadoModel.fromJson(Map<String, dynamic> j) =>
      HexPlanillaEmpleadoModel(
        HexPlanillaEmpleadoEntity(
          nombreArea: hexTextoN(j['nombreArea']),
          ordenArea: hexInt(j['ordenArea']),
          idPlanilla: hexBigInt(j['idPlanilla']),
          codEmpresa: hexBigInt(j['codEmpresa']),
          nombreEmpresa: hexTextoN(j['nombreEmpresa']),
          codSucursal: hexBigInt(j['codSucursal']),
          nombreSucursal: hexTextoN(j['nombreSucursal']),
          ordenSucursal: hexInt(j['ordenSucursal']),
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          cargo: hexTextoN(j['cargo']),
          costoHora: hexDecimalN(j['costoHora']),
          hHS: hexDecimal(j['hHS']),
          mHS: hexDecimal(j['mHS']),
          hH50: hexDecimal(j['hH50']),
          mH50: hexDecimal(j['mH50']),
          hH100: hexDecimal(j['hH100']),
          mH100: hexDecimal(j['mH100']),
          hHD: hexDecimal(j['hHD']),
          mHD: hexDecimal(j['mHD']),
          hHF: hexDecimal(j['hHF']),
          mHF: hexDecimal(j['mHF']),
          cD: hexInt(j['cD']),
          cDD: hexInt(j['cDD']),
          cA: hexInt(j['cA']),
          cDA: hexInt(j['cDA']),
          cC: hexInt(j['cC']),
          cDC: hexInt(j['cDC']),
          mOtros: hexDecimal(j['mOtros']),
          totalHoras: hexDecimal(j['totalHoras']),
          totalComidas: hexDecimal(j['totalComidas']),
          total: hexDecimal(j['total']),
        ),
      );

  factory HexPlanillaEmpleadoModel.fromEntity(HexPlanillaEmpleadoEntity e) =>
      HexPlanillaEmpleadoModel(e);

  HexPlanillaEmpleadoEntity toEntity() => entidad;
}
