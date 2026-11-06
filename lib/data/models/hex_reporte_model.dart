import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';

/// Columnas de `p_list_thex_Reporte` L, E, D y J (la ubicación y la hora de la
/// marca por app, D30 y D31, solo vienen en D). Solo lectura: las escrituras
/// mandan el id y los datos puntuales, nunca el reporte completo.
class HexReporteModel {
  const HexReporteModel(this.entidad);

  final HexReporteEntity entidad;

  factory HexReporteModel.fromJson(Map<String, dynamic> j) => HexReporteModel(
    HexReporteEntity(
      idReporte: hexBigInt(j['idReporte']),
      codEmpleado: hexBigInt(j['codEmpleado']),
      nombreEmpleado: hexTexto(j['nombreEmpleado']),
      fechaJornada: hexFecha(j['fechaJornada']),
      tipo: hexTexto(j['tipo']),
      tipoTexto: hexTexto(j['tipoTexto']),
      tipoDia: hexTexto(j['tipoDia']),
      tipoDiaTexto: hexTexto(j['tipoDiaTexto']),
      codSucursal: hexBigInt(j['codSucursal']),
      nombreSucursal: hexTextoN(j['nombreSucursal']),
      inicio: hexFecha(j['inicio']),
      fin: hexFecha(j['fin']),
      origenInicio: hexTextoN(j['origenInicio']),
      origenFin: hexTextoN(j['origenFin']),
      motivo: hexTextoN(j['motivo']),
      horasPagables: hexDecimalN(j['horasPagables']),
      montoHoras: hexDecimalN(j['montoHoras']),
      montoComidas: hexDecimalN(j['montoComidas']),
      montoTotal: hexDecimalN(j['montoTotal']),
      comidas: hexTextoN(j['comidas']),
      costoHora: hexDecimalN(j['costoHora']),
      esProvisional: hexBool(j['esProvisional']),
      estado: hexTexto(j['estado']),
      estadoTexto: hexTexto(j['estadoTexto']),
      esEditado: hexBool(j['esEditado']),
      avisoBiometrico: hexBool(j['avisoBiometrico']),
      puedeAnular: hexBool(j['puedeAnular']),
      puedeEditarMotivo: hexBool(j['puedeEditarMotivo']),
      puedeEditarHora: hexBool(j['puedeEditarHora']),
      puedeVistoBueno: hexBool(j['puedeVistoBueno']),
      puedeAprobar: hexBool(j['puedeAprobar']),
      puedeRechazar: hexBool(j['puedeRechazar']),
      totalFilas: hexInt(j['totalFilas']),
      codEncargado: hexBigInt(j['codEncargado']),
      nombreEncargado: hexTextoN(j['nombreEncargado']),
      textoPendiente: hexTextoN(j['textoPendiente']),
      motivoRechazo: hexTextoN(j['motivoRechazo']),
      latInicio: hexDecimalN(j['latInicio']),
      lonInicio: hexDecimalN(j['lonInicio']),
      precisionInicio: hexDecimalN(j['precisionInicio']),
      latFin: hexDecimalN(j['latFin']),
      lonFin: hexDecimalN(j['lonFin']),
      precisionFin: hexDecimalN(j['precisionFin']),
      inicioApp: hexFecha(j['inicioApp']),
      finApp: hexFecha(j['finApp']),
      resumenTiempo: hexTextoN(j['resumenTiempo']),
      puedeVerDetalle: hexBool(j['puedeVerDetalle']),
      verMontos: hexBool(j['verMontos']),
      verHistorial: hexBool(j['verHistorial']),
      sinSalidaMarcada: hexBool(j['sinSalidaMarcada']),
      avisoSalida: hexTextoN(j['avisoSalida']),
    ),
  );

  factory HexReporteModel.fromEntity(HexReporteEntity e) => HexReporteModel(e);

  HexReporteEntity toEntity() => entidad;
}
