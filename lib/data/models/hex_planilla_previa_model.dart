import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';

/// Columnas de `p_list_thex_Planilla` C. Solo lectura.
class HexPendienteModel {
  const HexPendienteModel(this.entidad);

  final HexPendienteEntity entidad;

  factory HexPendienteModel.fromJson(Map<String, dynamic> j) =>
      HexPendienteModel(
        HexPendienteEntity(
          codEmpresa: hexBigInt(j['codEmpresa']),
          codSucursal: hexBigInt(j['codSucursal']),
          nombreSucursal: hexTextoN(j['nombreSucursal']),
          anio: hexInt(j['anio']),
          mes: hexInt(j['mes']),
          cantidadReportes: hexInt(j['cantidadReportes']),
        ),
      );

  factory HexPendienteModel.fromEntity(HexPendienteEntity e) =>
      HexPendienteModel(e);

  HexPendienteEntity toEntity() => entidad;
}

/// Columnas de `p_list_thex_Planilla` P. Solo lectura.
class HexPrevistaEmpleadoModel {
  const HexPrevistaEmpleadoModel(this.entidad);

  final HexPrevistaEmpleadoEntity entidad;

  factory HexPrevistaEmpleadoModel.fromJson(Map<String, dynamic> j) =>
      HexPrevistaEmpleadoModel(
        HexPrevistaEmpleadoEntity(
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          nombreArea: hexTextoN(j['nombreArea']),
          montoHoras: hexDecimal(j['montoHoras']),
          montoComidas: hexDecimal(j['montoComidas']),
          total: hexDecimal(j['total']),
          esProvisional: hexBool(j['esProvisional']),
          cantidadReportes: hexInt(j['cantidadReportes']),
          tieneAvisoBiometrico: hexBool(j['tieneAvisoBiometrico']),
          tienePeriodoAnterior: hexBool(j['tienePeriodoAnterior']),
          codEmpresa: hexBigInt(j['codEmpresa']),
          codSucursal: hexBigInt(j['codSucursal']),
          nombreSucursal: hexTextoN(j['nombreSucursal']),
        ),
      );

  factory HexPrevistaEmpleadoModel.fromEntity(HexPrevistaEmpleadoEntity e) =>
      HexPrevistaEmpleadoModel(e);

  HexPrevistaEmpleadoEntity toEntity() => entidad;
}

/// Columnas de `p_list_thex_Planilla` Q. Solo lectura.
class HexPrevistaLineaModel {
  const HexPrevistaLineaModel(this.entidad);

  final HexPrevistaLineaEntity entidad;

  factory HexPrevistaLineaModel.fromJson(Map<String, dynamic> j) =>
      HexPrevistaLineaModel(
        HexPrevistaLineaEntity(
          idReporte: hexBigInt(j['idReporte']),
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          fechaJornada: hexFecha(j['fechaJornada']),
          tipo: hexTexto(j['tipo']),
          tipoDia: hexTexto(j['tipoDia']),
          inicio: hexFecha(j['inicio']),
          fin: hexFecha(j['fin']),
          origenInicio: hexTexto(j['origenInicio']),
          origenFin: hexTexto(j['origenFin']),
          esPeriodoAnterior: hexBool(j['esPeriodoAnterior']),
          esProvisional: hexBool(j['esProvisional']),
          avisoBiometrico: hexBool(j['avisoBiometrico']),
          haberBasico: hexDecimal(j['haberBasico']),
          codPlanillaSueldo: hexBigInt(j['codPlanillaSueldo']),
          divisor: hexDecimalN(j['divisor']),
          costoHora: hexDecimal(j['costoHora']),
          concepto: hexTexto(j['concepto']),
          codigo: hexTexto(j['codigo']),
          leyenda: hexTexto(j['leyenda']),
          minutos: hexIntN(j['minutos']),
          cantidad: hexDecimal(j['cantidad']),
          multiplicador: hexDecimalN(j['multiplicador']),
          valorUnitario: hexDecimal(j['valorUnitario']),
          monto: hexDecimal(j['monto']),
          codEmpresa: hexBigInt(j['codEmpresa']),
          codSucursal: hexBigInt(j['codSucursal']),
          nombreSucursal: hexTextoN(j['nombreSucursal']),
        ),
      );

  factory HexPrevistaLineaModel.fromEntity(HexPrevistaLineaEntity e) =>
      HexPrevistaLineaModel(e);

  HexPrevistaLineaEntity toEntity() => entidad;
}

/// Columnas de `p_list_thex_Planilla` W. Solo lectura.
class HexAvisoModel {
  const HexAvisoModel(this.entidad);

  final HexAvisoEntity entidad;

  factory HexAvisoModel.fromJson(Map<String, dynamic> j) => HexAvisoModel(
    HexAvisoEntity(
      idReporte: hexBigInt(j['idReporte']),
      codEmpleado: hexBigInt(j['codEmpleado']),
      nombreEmpleado: hexTexto(j['nombreEmpleado']),
      fechaJornada: hexFecha(j['fechaJornada']),
      tipoAviso: hexTexto(j['tipoAviso']),
      detalle: hexTexto(j['detalle']),
      codSucursal: hexBigInt(j['codSucursal']),
      nombreSucursal: hexTextoN(j['nombreSucursal']),
    ),
  );

  factory HexAvisoModel.fromEntity(HexAvisoEntity e) => HexAvisoModel(e);

  HexAvisoEntity toEntity() => entidad;
}

/// Columnas de `planilla/pendientes-firma` (D39). Solo lectura.
class HexPlanillaFirmaModel {
  const HexPlanillaFirmaModel(this.entidad);

  final HexPlanillaFirmaEntity entidad;

  factory HexPlanillaFirmaModel.fromJson(Map<String, dynamic> j) =>
      HexPlanillaFirmaModel(
        HexPlanillaFirmaEntity(
          idReporte: hexBigInt(j['idReporte']),
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          fechaJornada: hexFecha(j['fechaJornada']),
          tipo: hexTexto(j['tipo']),
          tipoTexto: hexTexto(j['tipoTexto']),
          estado: hexTexto(j['estado']),
          estadoTexto: hexTexto(j['estadoTexto']),
          codEmpresa: hexBigInt(j['codEmpresa']),
          codSucursal: hexBigInt(j['codSucursal']),
          nombreSucursal: hexTextoN(j['nombreSucursal']),
          debeFirmar: hexTextoN(j['debeFirmar']),
          textoPendiente: hexTexto(j['textoPendiente']),
        ),
      );

  factory HexPlanillaFirmaModel.fromEntity(HexPlanillaFirmaEntity e) =>
      HexPlanillaFirmaModel(e);

  HexPlanillaFirmaEntity toEntity() => entidad;
}
