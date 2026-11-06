import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_detalle_entity.dart';

/// Columnas de `p_list_thex_PlanillaDetalle` A. Los alias `hHS` y `hOtros` se
/// leen con esa grafía, tal como los serializa el backend.
class HexPlanillaDetalleModel {
  const HexPlanillaDetalleModel(this.entidad);

  final HexPlanillaDetalleEntity entidad;

  factory HexPlanillaDetalleModel.fromJson(Map<String, dynamic> j) =>
      HexPlanillaDetalleModel(
        HexPlanillaDetalleEntity(
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          nombreArea: hexTextoN(j['nombreArea']),
          idPlanilla: hexBigInt(j['idPlanilla']),
          codSucursal: hexBigInt(j['codSucursal']),
          nombreSucursal: hexTextoN(j['nombreSucursal']),
          ordenSucursal: hexInt(j['ordenSucursal']),
          idReporte: hexBigInt(j['idReporte']),
          fechaJornada: hexFecha(j['fechaJornada']),
          tipo: hexTexto(j['tipo']),
          tipoTexto: hexTexto(j['tipoTexto']),
          tipoDia: hexTextoN(j['tipoDia']),
          motivo: hexTextoN(j['motivo']),
          inicio: hexFecha(j['inicio']),
          fin: hexFecha(j['fin']),
          origenInicio: hexTexto(j['origenInicio']),
          origenFin: hexTexto(j['origenFin']),
          origenInicioTexto: hexTexto(j['origenInicioTexto']),
          origenFinTexto: hexTexto(j['origenFinTexto']),
          esPeriodoAnterior: hexBool(j['esPeriodoAnterior']),
          haberBasico: hexDecimal(j['haberBasico']),
          codPlanillaSueldo: hexBigInt(j['codPlanillaSueldo']),
          divisor: hexDecimalN(j['divisor']),
          costoHora: hexDecimal(j['costoHora']),
          hHS: hexDecimal(j['hHS']),
          hH50: hexDecimal(j['hH50']),
          hH100: hexDecimal(j['hH100']),
          hHD: hexDecimal(j['hHD']),
          hHF: hexDecimal(j['hHF']),
          hOtros: hexDecimal(j['hOtros']),
          comidas: hexTextoN(j['comidas']),
          montoHoras: hexDecimal(j['montoHoras']),
          montoComidas: hexDecimal(j['montoComidas']),
          total: hexDecimal(j['total']),
        ),
      );

  factory HexPlanillaDetalleModel.fromEntity(HexPlanillaDetalleEntity e) =>
      HexPlanillaDetalleModel(e);

  HexPlanillaDetalleEntity toEntity() => entidad;
}
